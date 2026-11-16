// Parametric cable drag chain link
//
// Adapted from Joerg Scheuermann's cable chain link,
// https://www.thingiverse.com/thing:8239, licensed CC BY-SA 3.0.
// Changes by Cameron Brooks: new defaults (width 40, over_angle 40), a hole_tolerance
// parameter for the axle holes, and a refactor of the axle radius and the cut helpers'
// arguments.
// This adaptation is licensed CC BY-SA 4.0; see LICENSE.

// ====================================================================
// Parameters
// ====================================================================

// Preview-driven tolerances and tessellation
$fn = $preview ? 32 : 128;
z_fight = $preview ? 0.05 : 0;

/* [Size] */
// Outside width of a link (mm)
width = 40;
// Length of a link (mm)
length = 50;
// Height of a link (mm)
height = 20;
// Wall thickness (mm)
thickness = 2;

/* [Angles] */
// Bend limit one way (degrees)
under_angle = 10;
// Bend limit the other way (degrees)
over_angle = 40;

/* [Variant] */
inner_axis = false;
top_style = "clip"; // ["clip", "closed"]

/* [Fit] */
// Clearance between moving parts (mm)
tolerance = 0.2;
// Extra clearance in the axle holes (mm)
hole_tolerance = 0.5;

// ====================================================================
// Core modules
// ====================================================================

module shell_outline(width, length, height, rad, span_l, bend_deg) {
  y_off = span_l / 2;
  half = rad / 2;

  difference() {
    union() {
      translate([0, 0, height / 2]) cube([width, span_l, height], true);

      // end rounds
      for (yy = [-y_off, y_off])
        translate([0, yy, rad]) rotate([0, 90, 0])
            cylinder(width, r=rad, center=true, $fs=0.5);

      // bent filler blocks
      translate([0, -y_off, rad]) rotate([bend_deg, 0, 0]) translate([0, -half, -half]) cube([width, rad, rad], true);
      translate([0, y_off, rad]) rotate([360 - bend_deg, 0, 0]) translate([0, half, -half]) cube([width, rad, rad], true);
    }
    // clear out bottom
    translate([0, 0, -half / 2]) cube([width + z_fight, length + z_fight, half + z_fight], true);
  }
}

module axle_pin(x, y, z, length, rad) {
  translate([x, y, z]) rotate([0, 90, 0])
      cylinder(length + tolerance, r1=rad * 1.25, r2=rad, center=true);
}

module axle_hole(x, y, z, length, rad) {
  base_radius = rad + hole_tolerance;
  translate([x, y, z]) rotate([0, 90, 0])
      cylinder(length + tolerance, r1=base_radius + tolerance, r2=base_radius, center=true);
}

module outer_cut_arm(width, rad, h1, thick, bend_deg, inner_ax) {
  arm_w = (width - thick) / 2;
  thru = thick + tolerance / 2;

  translate([arm_w, 0, 0]) {
    difference() {
      union() {
        translate([0, 0, 0]) cube([thru, rad * 2, rad * 2], true);
        translate([0, 0, h1]) rotate([bend_deg, 0, 0]) translate([0, rad / 2, 0]) cube([thru, rad, rad * 2], true);
        translate([0, 0, h1]) rotate([0, 90, 0]) cylinder(thru, r=rad, center=true, $fs=0.5);
        if (inner_ax)
          axle_hole(-1.5 * arm_w, tolerance / 2, h1, arm_w, rad / 4);
      }
      if (!inner_ax)
        axle_pin(-tolerance / 2, tolerance / 2, h1, thick, rad / 4);
    }
  }
}

module outer_cut(width, rad, h1, thick, bend_deg, inner_ax) {
  outer_cut_arm(width, rad, h1, thick, bend_deg, inner_ax);
  mirror([1, 0, 0]) outer_cut_arm(width, rad, h1, thick, bend_deg, inner_ax);
}

module inner_cut(width, rad, span_l, thick, bend_deg, inner_ax) {
  w2 = width - 2 * (thick - tolerance);
  translate([0, -span_l / 2, rad]) difference() {
      union() {
        translate([0, 0, -rad / 2]) cube([w2, rad * 2, rad], true);
        translate([0, 0, 0]) rotate([180 - bend_deg, 0, 0]) translate([0, rad / 2, 0]) cube([w2, rad, rad * 2], true);
        translate([0, 0, 0]) rotate([0, 90, 0]) cylinder(w2, r=rad, center=true, $fs=0.5);

        if (!inner_ax) {
          axle_hole((width - thick) / 2 + tolerance, -tolerance / 2, 0, thick, rad / 4);
          mirror([1, 0, 0]) axle_hole((width - thick) / 2 + tolerance, -tolerance / 2, 0, thick, rad / 4);
        }
      }
      if (inner_ax) {
        axle_pin(-(w2 - thick) / 2, -tolerance / 2, 0, thick, rad / 4);
        mirror([1, 0, 0]) axle_pin(-(w2 - thick) / 2, -tolerance / 2, 0, thick, rad / 4);
      }
    }
}

module mid_core(length, rad, thick, is_closed) {
  if (is_closed)
    cube([rad * 2, length, rad * 2], true);
  else {
    for (zz = [0, thick])
      translate([0, 0, zz]) rotate([90, 90, 0]) cylinder(length, r=rad, center=true, $fn=50);
    translate([0, 0, thick / 2]) cube([2 * rad, length, thick], true);
  }
}

module mid_segment(width, rad, length, h_in, span_l, h1, thick, over, under, inner_ax, is_closed) {
  th = max(thick, thick * h_in / width);
  hh = h_in - (is_closed ? 2 : 1) * th;
  ww = width - 4 * thick;
  rr = hh / 2;

  scale([ww / hh, 1, 1]) {
    translate([0, 0, rr + th]) {
      translate([0, h1, 0]) mid_core(length, rr, th, is_closed);
      translate([0, span_l / 2 + 0.1, 0]) {
        // positive bend block
        difference() {
          rotate([over, 0, 0]) union() {
              translate([0, length / 4, 0]) mid_core(length / 2, rr, th, is_closed);
              translate([0, length / 4, -rr]) cube([2 * rr, length / 2, 2 * rr], true);
            }
          translate([0, length / 4, -rr]) cube([2 * rr, length / 2, 2 * rr], true);
        }
        // negative bend block
        difference() {
          rotate([-under, 0, 0]) union() {
              translate([0, length / 4, 0]) mid_core(length / 2, rr, th, is_closed);
              translate([0, length / 4, rr]) cube([2 * rr, length / 2, 2 * rr], true);
            }
          translate([0, length / 4, rr]) cube([2 * rr + z_fight, length / 2 + z_fight, 2 * rr], true);
        }
      }
    }
  }
}

module clip_block(width, height, length, tol = 0) {
  tol2 = 2 * tol;
  c_w = length / 10 + tol;
  c_thick = 1.5 + tol;
  c_len = 5;
  c_cyl_diam = 2 + tol2;

  translate([0, 0, height - (c_thick - tol2) / 2]) union() {
      cube([width + tol2, c_w, c_thick], true);
      for (sg = [1, -1])
        translate([sg * (width / 2 - (c_thick - tol2) / 2), 0, -c_len / 2])
          rotate([0, 0, sg == 1 ? 0 : 180]) union() {
              cube([c_thick, c_w, c_len + tol], true);
              translate([-c_thick / 2, 0, -(c_len / 2 - c_cyl_diam / 2)])
                rotate([90, 0, 0]) cylinder(c_w, r=c_cyl_diam / 2, center=true, $fs=0.25);
            }
    }
}

module chain_link(width, length, height, thick, under_deg, over_deg, inner_ax, style) {
  // derived parameters
  rad = height / 2;
  length_safe = max(length, 2 * (height + thick));
  span = length - 2 * rad;

  // validate and interpret style
  style = (style != "clip" && style != "closed") ? "clip" : style;
  if (style != "clip" && style != "closed")
    echo(str("Warning: style must be 'clip' or 'closed', using 'clip'"));
  is_closed = (style == "closed") ? true : false;
  use_clip = (style == "clip") ? true : false;

  // limit angles to reasonable values
  max_angle = 50;
  under = min(max_angle, under_deg);
  if (under_deg > max_angle)
    echo(str("Warning: under angle limited to ", max_angle, " deg"));
  over = min(max_angle, over_deg);
  if (over_deg > max_angle)
    echo(str("Warning: over angle limited to ", max_angle, " deg"));

  // build drag chain link with clip block if requested
  difference() {
    shell_outline(width, length_safe, height, rad, span, under);
    translate([0, span / 2, 0])
      outer_cut(width, rad, rad, thick, over, inner_ax);
    mid_segment(width, rad, length_safe, height, span, rad, thick, over, under, inner_ax, is_closed);
    inner_cut(width, rad, span, thick, over, inner_ax);
    if (use_clip)
      clip_block(width, height, length_safe, tolerance);
  }

  if (use_clip)
    translate([0, 2 + height + length_safe / 2, (length_safe / 10) / 2]) rotate([90, 0, 0]) clip_block(width, height, length_safe);
}

// ====================================================================
// Build
// ====================================================================
chain_link(width, length, height, thickness, under_angle, over_angle, inner_axis, top_style);
