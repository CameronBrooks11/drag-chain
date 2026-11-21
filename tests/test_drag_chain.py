"""Render drag_chain.scad and check that links fit and bend as set.

usage: python3 tests/test_drag_chain.py [OPENSCAD]

- The link renders with --hardwarnings in each variant. OpenSCAD exits 0 on a
  failed assert when exporting, so a WARNING or ERROR line fails the check,
  whatever the exit status.
- A clip link prints as two parts, the link and its clip; a closed one as one.
- Two links joined at the axle and turned to over_angle (40) or under_angle
  (10) overlap by under 1 mm3: the axle pins only graze their holes. Turned
  5 degrees further, they overlap by over 10 mm3: the link stops the bend.
- An angle over 50 degrees is limited to 50, with a warning.
"""

import os
import struct
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LIB = os.path.join(ROOT, "drag_chain.scad")
results = []


def check(label, ok, got):
    results.append(bool(ok))
    print(f"{'ok  ' if ok else 'FAIL'} {label}: {got}")


def render(openscad, out, *args):
    r = subprocess.run([openscad, "--hardwarnings", "--export-format", "binstl", "-o", out, *args],
                       capture_output=True, text=True)
    bad = [l for l in r.stderr.splitlines() if l.startswith(("WARNING", "ERROR"))]
    if r.returncode and "top level object is empty" not in r.stderr.lower():
        bad = bad or [f"exit {r.returncode}"]
    return r, bad


def solids(path):
    """Volume of each separate solid in a binary STL, by joining shared corners."""
    data = open(path, "rb").read()
    (n,) = struct.unpack_from("<I", data, 80)
    tris = [struct.unpack_from("<9f", data, 84 + i * 50 + 12) for i in range(n)]
    parent = {}

    def find(v):
        while parent[v] != v:
            parent[v] = parent[parent[v]]
            v = parent[v]
        return v

    for t in tris:
        pts = (t[0:3], t[3:6], t[6:9])
        for p in pts:
            parent.setdefault(p, p)
        root = find(pts[0])
        for p in pts[1:]:
            parent[find(p)] = root
    vols = {}
    for t in tris:
        a, b, c = t[0:3], t[3:6], t[6:9]
        vols[find(a)] = vols.get(find(a), 0) + (a[0] * (b[1] * c[2] - b[2] * c[1]) - a[1] * (b[0] * c[2] - b[2] * c[0])
                                                + a[2] * (b[0] * c[1] - b[1] * c[0])) / 6
    return list(vols.values())


def main():
    openscad = sys.argv[1] if len(sys.argv) > 1 else "openscad"
    with tempfile.TemporaryDirectory() as tmp:
        stl = os.path.join(tmp, "out.stl")
        probe = os.path.join(tmp, "probe.scad")

        for label, defines, parts in [
            ("clip link", [], 2),
            ("closed link", ["-D", 'top_style="closed"'], 1),
            ("clip link, inner axle", ["-D", "inner_axis=true"], 2),
            ("60 x 80 x 30 link", ["-D", "width=60", "-D", "length=80", "-D", "height=30", "-D", "thickness=3"], 2),
        ]:
            _, bad = render(openscad, stl, *defines, LIB)
            got = None if bad else len(solids(stl))
            check(f"{label} renders as {parts} part(s)", got == parts, bad[0] if bad else f"{got} part(s)")

        # Link B joined to link A's end: one pitch (length - height = 30) along y, turned about
        # the shared axle, at z = height / 2.
        for inner in ("false", "true"):
            for name, angle, limit in [("over", 40, True), ("over", 45, False),
                                       ("under", -10, True), ("under", -15, False)]:
                with open(probe, "w") as f:
                    f.write(f'use <{LIB}>\n$fn = 48;\nmodule l() chain_link(40, 50, 20, 2, 10, 40, {inner}, "closed");\n'
                            f"intersection() {{ l(); translate([0, 15, 10]) rotate([{angle}, 0, 0])"
                            " translate([0, 15, -10]) l(); }\n")
                r, bad = render(openscad, stl, probe)
                overlap = 0 if "top level object is empty" in r.stderr.lower() else (None if bad else sum(solids(stl)))
                ok = overlap is not None and (overlap < 1 if limit else overlap > 10)
                check(f"inner_axis={inner}: two links turned {abs(angle)} deg {name} "
                      f"{'bend freely' if limit else 'collide'}", ok,
                      bad[0] if bad else f"overlap {overlap:.2f} mm3")

        r, bad = render(openscad, stl, "-D", "over_angle=60", LIB)
        warned = 'ECHO: "Warning: over angle limited to 50 deg"' in r.stderr
        check("over_angle 60 is limited to 50 with a warning", warned and not bad,
              bad[0] if bad else ("warned" if warned else "no warning"))

    print(f"{sum(results)} of {len(results)} checks passed")
    sys.exit(0 if all(results) else 1)


main()
