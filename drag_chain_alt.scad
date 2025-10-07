// Cable chain link
// modified from: https://www.thingiverse.com/thing:3952761/files

$fn = 32;

// ---------------- Parameters ----------------
cable_size = [12, 12]; // [height, width] of cable cross-section
wall_thickness = 2;
barrel_thickness = 3;
gap_clearance = 1;
support_dims = [2, 0.5, 0.2]; // [length, offset_y, trim_z]
fillet_radius = 1;
epsilon = 0.001;

link_dims = [
  (cable_size[1] + 2 * wall_thickness) / sqrt(2), // inner diagonal
  cable_size[1] + 2 * wall_thickness, // outer span
];

show_assembled = false;

// ---------------- Build ----------------
link_middle();

if (show_assembled)
  r([0, -45, 0], [-wall_thickness / 2 + gap_clearance / 2 + link_dims[1] / 2, 0, link_dims[0] / 2 + gap_clearance / 4]) {
    t([link_dims[1] + gap_clearance, 0, link_dims[1] / 2 + 2 * wall_thickness]) mirror([0, 0, 1]) link_middle();
    t([2 * (link_dims[1] + gap_clearance), 0, 0]) link_middle();
  }

// ============================================================================
// Core link body
// ============================================================================
module link_middle() {
  for (mirror_y = [0, 1])
    mirror([0, mirror_y, 0]) {
      // hole barrels
      t(
        [
          link_dims[1] / 2 + gap_clearance / 2 - wall_thickness / 2,
          cable_size[0] / 2 + barrel_thickness / 2 + wall_thickness + gap_clearance / 2,
          link_dims[1] / 2 - wall_thickness,
        ]
      )
        r([90, 0, 0])
          rounded_cylinder(d=[link_dims[0] + gap_clearance / 2, link_dims[1]], h=barrel_thickness, center=true, r=[0, fillet_radius, 0, fillet_radius]);

      // connection barrels
      t(
        [
          -link_dims[1] / 2 - gap_clearance / 2 - wall_thickness / 2,
          (cable_size[0] + barrel_thickness + wall_thickness + gap_clearance / 2) / 2,
          link_dims[1] / 2 - wall_thickness,
        ]
      )
        r([90, 0, 0])
          rounded_cylinder(d=[0, link_dims[0] - gap_clearance / 2], h=barrel_thickness + wall_thickness + gap_clearance / 2, center=true, r=[0, 0, 0, fillet_radius]);

      // mid support
      t(
        [
          -link_dims[1] / 2 - gap_clearance / 2 - wall_thickness / 2,
          cable_size[0] / 2 + wall_thickness + support_dims[1],
          -wall_thickness,
        ]
      )
        rounded_cube([support_dims[0], barrel_thickness, (link_dims[1] - link_dims[0]) / 2 + gap_clearance / 4 - support_dims[2]], center=[1, 0, 0]);

      // inner side wall
      t([0, (cable_size[0] + wall_thickness + barrel_thickness + gap_clearance / 2) / 2, -wall_thickness])
        rounded_cube([wall_thickness, wall_thickness + barrel_thickness + gap_clearance / 2, wall_thickness + link_dims[0] / 2], r=[fillet_radius, fillet_radius, fillet_radius], center=[1, 1, 0]);

      // front wall with hole
      difference() {
        t([-wall_thickness / 2, cable_size[0] / 2 + wall_thickness + barrel_thickness / 2 + gap_clearance / 2, -wall_thickness])
          rounded_cube([gap_clearance / 2 + link_dims[1] / 2, barrel_thickness, link_dims[1]], r=[fillet_radius, fillet_radius, fillet_radius], center=[0, 1, 0], r5=[0, fillet_radius, fillet_radius], r7=[0, fillet_radius, fillet_radius]);
        t([link_dims[1] / 2 + gap_clearance / 2 - wall_thickness / 2, cable_size[0] / 2 + barrel_thickness / 2 + wall_thickness, link_dims[1] / 2 - wall_thickness])
          r([90, 0, 0])
            rounded_cylinder(d=[0, (link_dims[0] + link_dims[1]) / 2], h=cable_size[0], center=true);
      }

      // rear wall
      t([wall_thickness / 2, (cable_size[0] + wall_thickness) / 2, -wall_thickness])
        rounded_cube([wall_thickness + gap_clearance / 2 + link_dims[1] / 2, wall_thickness, wall_thickness + link_dims[0] / 2], r=[fillet_radius, fillet_radius, fillet_radius], center=[2, 1, 0]);
    }

  // base floors
  t([-wall_thickness / 2, 0, 0])
    rounded_cube([gap_clearance / 2 + link_dims[1] / 2, cable_size[0] + 2 * barrel_thickness + 2 * wall_thickness, wall_thickness], r=[fillet_radius, fillet_radius, fillet_radius], center=[0, 1, 2]);
  t([wall_thickness / 2, 0, 0])
    rounded_cube([wall_thickness + gap_clearance / 2 + link_dims[1] / 2, cable_size[0] + 2 * wall_thickness, wall_thickness], r=[fillet_radius, fillet_radius, fillet_radius], center=[2, 1, 2]);
}

// ============================================================================
// Rounded cylinder (2D profile revolve)
// ============================================================================
module rounded_cylinder(d = [20, 40], h = 30, center = false, r = [0, 0, 0, 0], chamfer = 0) {
  t([0, 0, -h / 2 * (center ? 1 : 0)])
    rotate_extrude(convexity=10) {
      // Core rectangular body
      difference() {
        t([d[0] / 2, 0]) square([(d[1] - d[0]) / 2, h]);
        for (i = [0:3])
          if (r[i] > 0)
            t([(i % 2 ? d[1] / 2 - r[i] : d[0] / 2), (i < 2 ? 0 : h - r[i])])
              square([r[i], r[i]]);
      }
      // Filleted or inverse corners
      for (i = [0:3])
        let (
          rr = r[i],
          x_sq = (i % 2 ? d[1] / 2 - max(rr, 0) : d[0] / 2),
          y_sq = (i < 2 ? 0 : h - max(rr, 0)),
          x_arc = (i % 2 ? d[1] / 2 - rr : d[0] / 2 + rr),
          y_arc = (i < 2 ? (rr > 0 ? rr : -rr) : h - (rr > 0 ? rr : -rr))
        ) if (rr > 0) {
          intersection() {
            t([x_arc, y_arc]) circle(r=rr);
            t([x_sq, y_sq]) square([rr, rr]);
          }
        } else {
          difference() {
            t([x_arc, y_arc]) square([-rr, -rr]);
            t([x_arc - (i % 2 ? rr : 0), y_arc - (i < 2 ? rr : 0)]) circle(r=-rr);
          }
        }
    }
}

// ============================================================================
// Rounded cube (corner sphere-hull generator)
// ============================================================================
module rounded_cube(
  size = [3, 3, 3],
  r = [0, 0, 0],
  r0 = [-1, -1, -1],
  r1 = [-1, -1, -1],
  r2 = [-1, -1, -1],
  r3 = [-1, -1, -1],
  r4 = [-1, -1, -1],
  r5 = [-1, -1, -1],
  r6 = [-1, -1, -1],
  r7 = [-1, -1, -1],
  chamfer = [0, 0, 0, 0],
  chamfer_angle = 60,
  center = [0, 0, 0],
  not = 0.00001
) {
  function saturate(v) = [max(not, v.x), max(not, v.y), max(not, v.z)];
  function apply_default(a, b) = (a.x == -1 && a.y == -1 && a.z == -1) ? b : a;

  _r0 = saturate(apply_default(r0, r));
  _r1 = saturate(apply_default(r1, r));
  _r2 = saturate(apply_default(r2, r));
  _r3 = saturate(apply_default(r3, r));
  _r4 = saturate(apply_default(r4, r));
  _r5 = saturate(apply_default(r5, r));
  _r6 = saturate(apply_default(r6, r));
  _r7 = saturate(apply_default(r7, r));

  module corner(pos, rad, mir) {
    t(pos) scale(rad) intersection() { sphere(1); mirror(mir) cube(1); }
  }

  module base_cube() {
    hull() {
      corner([_r0.x, _r0.y, _r0.z], _r0, [1, 1, 1]);
      corner([size.x - _r1.x, _r1.y, _r1.z], _r1, [0, 1, 1]);
      corner([_r2.x, size.y - _r2.y, _r2.z], _r2, [1, 0, 1]);
      corner([size.x - _r3.x, size.y - _r3.y, _r3.z], _r3, [0, 0, 1]);
      corner([_r4.x, _r4.y, size.z - _r4.z], _r4, [1, 1, 0]);
      corner([size.x - _r5.x, _r5.y, size.z - _r5.z], _r5, [0, 1, 0]);
      corner([_r6.x, size.y - _r6.y, size.z - _r6.z], _r6, [1, 0, 0]);
      corner([size.x - _r7.x, size.y - _r7.y, size.z - _r7.z], _r7, [0, 0, 0]);
    }

    // optional chamfers
    if (chamfer[0]) r([0, 90, 0]) half_triangle3d(90 - chamfer_angle, size.y / (chamfer[2] + 1), size.x);
    if (chamfer[2]) tr([0, size.y, 0], [0, 90, 0]) mirror([0, 1, 0]) half_triangle3d(90 - chamfer_angle, size.y / (chamfer[0] + 1), size.x);
    if (chamfer[1]) tr([0, size.y, 0], [90, 90, 0]) half_triangle3d(90 - chamfer_angle, size.x / (chamfer[3] + 1), size.y);
    if (chamfer[3]) tr([size.x, size.y, 0], [90, 90, 0]) mirror([0, 1, 0]) half_triangle3d(90 - chamfer_angle, size.x / (chamfer[1] + 1), size.y);
  }

  module half_triangle3d(angle = 45, h = 10, z = 10) linear_extrude(z) half_triangle(angle, h);
  module half_triangle(angle = 45, h = 10) {
    base = h * tan(angle);
    x_side = 2.1 * base * cos(angle);
    y_side = h / cos(angle) + base;
    intersection() {
      tr([base, 0, 0], [0, 0, angle]) t([-x_side, 0, 0]) square([x_side, y_side]);
      square([2.2 * base, 1.1 * h]);
    }
  }

  t([-size.x / 2 * center.x, -size.y / 2 * center.y, -size.z / 2 * center.z]) base_cube();
}

// ============================================================================
// Transform helpers
// ============================================================================
module t(v = [0, 0, 0]) translate(v) children();
module r(a = [0, 0, 0], rp = [0, 0, 0]) translate(rp) rotate(a) translate(-rp) children();
module tr(v = [0, 0, 0], a = [0, 0, 0], rp = [0, 0, 0]) t(v) r(a, rp) children();
module rt(a = [0, 0, 0], rp = [0, 0, 0], v = [0, 0, 0]) r(a, rp) t(v) children();
module u() union() children();
