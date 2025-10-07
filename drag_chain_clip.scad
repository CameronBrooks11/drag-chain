// Cable chain link 
// Original: Joerg Scheuermann (https://www.thingiverse.com/thing:8239) 
// License: CC BY-SA 3.0

// ====================================================================
// Parameters
// ====================================================================

// Preview-driven tolerances and tessellation
z_fit = $preview ? 0.05 : 0;
$fn = $preview ? 32 : 128;

// [Size]
width = 30;
length = 50;
height = 20;

// [Angles]
max_angle = 50;
under_angle = 0;
over_angle = 30;

// [Variant]
inner_axis = 0; // 1=true, 0=false
closed = 0;
clip = 1;

// [Fit]
tolerance = 0.2;
toothpick = 2.1;

// [Mode]
debug = 0;
multicolor_block = 0;
mcb_height = 2;

// ====================================================================
// Core modules
// ====================================================================

module shell_outline(w, l, h, rad, span_l, bend_deg) {
  y_off = span_l / 2;
  half = rad / 2;

  difference() {
    union() {
      translate([0, 0, h / 2]) cube([w, span_l, h], true);

      // end rounds
      for (yy = [-y_off, y_off])
        translate([0, yy, rad]) rotate([0, 90, 0])
            cylinder(w, r=rad, center=true, $fs=0.5);

      // bent filler blocks
      translate([0, -y_off, rad]) rotate([bend_deg, 0, 0]) translate([0, -half, -half]) cube([w, rad, rad], true);
      translate([0, y_off, rad]) rotate([360 - bend_deg, 0, 0]) translate([0, half, -half]) cube([w, rad, rad], true);
    }
    // center slit
    translate([0, 0, -half / 2]) cube([w, l, half + z_fit], true);
  }
}

module axle_pin(x, y, z, len, rad) {
  pr = rad * 0.25;
  translate([x, y, z]) rotate([0, 90, 0])
      cylinder(len + tolerance, r1=pr * 1.25, r2=pr, center=true, $fs=0.25);
}

module axle_hole(x, y, z, len, rad) {
  pr = rad * 0.25 * 1.25;
  translate([x, y, z]) rotate([0, 90, 0])
      cylinder(len + tolerance, r1=pr + tolerance, r2=pr, center=true, $fs=0.25);
}

module outer_cut_arm(w, rad, h1, thick, bend_deg, inner_ax) {
  arm_w = (w - thick) / 2;
  thru = thick + tolerance / 2;

  translate([arm_w, 0, 0]) {
    difference() {
      union() {
        translate([0, 0, h1 / 2]) cube([thru, rad * 2, h1], true);
        translate([0, 0, h1]) rotate([bend_deg, 0, 0]) translate([0, rad / 2, 0]) cube([thru, rad, rad * 2], true);
        translate([0, 0, h1]) rotate([0, 90, 0]) cylinder(thru, r=rad, center=true, $fs=0.5);
        if (inner_ax)
          axle_hole(-1.5 * arm_w, tolerance / 2, h1, arm_w, rad);
      }
      if (!inner_ax)
        axle_pin(-tolerance / 2, tolerance / 2, h1, thick, rad);
    }
  }
}

module outer_cut(w, rad, span_l, h1, thick, bend_deg, inner_ax) {
  translate([0, span_l / 2, 0]) {
    outer_cut_arm(w, rad, h1, thick, bend_deg, inner_ax);
    mirror([1, 0, 0]) outer_cut_arm(w, rad, h1, thick, bend_deg, inner_ax);
  }
}

module inner_cut(w, rad, span_l, h1, thick, bend_deg, inner_ax) {
  w2 = w - 2 * (thick - tolerance);
  translate([0, -span_l / 2, h1]) difference() {
      union() {
        translate([0, 0, -h1 / 2]) cube([w2, rad * 2, h1], true);
        translate([0, 0, 0]) rotate([180 - bend_deg, 0, 0]) translate([0, rad / 2, 0]) cube([w2, rad, rad * 2], true);
        translate([0, 0, 0]) rotate([0, 90, 0]) cylinder(w2, r=rad, center=true, $fs=0.5);

        if (!inner_ax) {
          axle_hole((w - thick) / 2 + tolerance, -tolerance / 2, 0, thick, rad);
          mirror([1, 0, 0]) axle_hole((w - thick) / 2 + tolerance, -tolerance / 2, 0, thick, rad);
        }
      }
      if (inner_ax) {
        axle_pin(-(w2 - thick) / 2, -tolerance / 2, 0, thick, rad);
        mirror([1, 0, 0]) axle_pin(-(w2 - thick) / 2, -tolerance / 2, 0, thick, rad);
      }
    }
}

module mid_core(len, rad, thick, is_closed) {
  if (is_closed)
    cube([rad * 2, len, rad * 2], true);
  else {
    for (zz = [0, thick])
      translate([0, 0, zz]) rotate([90, 90, 0]) cylinder(len, r=rad, center=true, $fn=50);
    translate([0, 0, thick / 2]) cube([2 * rad, len, thick], true);
  }
}

module mid_segment(w, rad, len, h_in, span_l, h1, thick, over, under, inner_ax, is_closed) {
  th = max(thick, thick * h_in / w);
  hh = h_in - (is_closed ? 2 : 1) * th;
  ww = w - 4 * thick;
  rr = hh / 2;

  scale([ww / hh, 1, 1])
    translate([0, 0, rr + th]) {
      translate([0, h1, 0]) mid_core(len, rr, th, is_closed);
      translate([0, span_l / 2 + 0.1, 0]) {
        // positive bend block
        difference() {
          rotate([over, 0, 0]) union() {
              translate([0, len / 4, 0]) mid_core(len / 2, rr, th, is_closed);
              translate([0, len / 4, -rr]) cube([2 * rr, len / 2, 2 * rr], true);
            }
          translate([0, len / 4, -rr]) cube([2 * rr, len / 2, 2 * rr], true);
        }
        // negative bend block
        difference() {
          rotate([-under, 0, 0]) union() {
              translate([0, len / 4, 0]) mid_core(len / 2, rr, th, is_closed);
              translate([0, len / 4, rr]) cube([2 * rr, len / 2, 2 * rr], true);
            }
          translate([0, len / 4, rr]) cube([2 * rr + z_fit, len / 2 + z_fit, 2 * rr], true);
        }
      }
    }
}

module clip_block(w, h, len, tol = 0) {
  tol2 = 2 * tol;
  c_w = len / 10 + tol;
  c_thick = 1.5 + tol;
  c_len = 5;
  c_cyl_diam = 2 + tol2;

  translate([0, 0, h - (c_thick - tol2) / 2]) union() {
      cube([w + tol2, c_w, c_thick], true);
      for (sg = [1, -1])
        translate([sg * (w / 2 - (c_thick - tol2) / 2), 0, -c_len / 2])
          rotate([0, 0, sg == 1 ? 0 : 180]) union() {
              cube([c_thick, c_w, c_len + tol], true);
              translate([-c_thick / 2, 0, -(c_len / 2 - c_cyl_diam / 2)])
                rotate([90, 0, 0]) cylinder(c_w, r=c_cyl_diam / 2, center=true, $fs=0.25);
            }
    }
}

module toothpick_hole(w, h, is_closed) {
  if (!is_closed)
    translate([0, 0, h - 1.5]) rotate([0, 90, 0])
        cylinder(w + 1, r=toothpick / 2, center=true, $fs=0.25);
}

module chain_link(w, l, h, under_deg, over_deg, inner_ax, is_closed, use_clip) {
  thick = min(2, max(1, 0.1 * w));
  rad = h / 2;
  len = max(l, 2 * (h + thick));
  span = len - 2 * rad;
  h1 = rad;
  under = min(max_angle, under_deg);
  over = min(max_angle, over_deg);

  difference() {
    shell_outline(w, len, h, rad, span, under);
    outer_cut(w, rad + z_fit, span, h1, thick, over, inner_ax);
    mid_segment(w, rad, len, h, span, h1, thick, over, under, inner_ax, is_closed);
    inner_cut(w, rad + z_fit, span, h1, thick, over, inner_ax);
    if (use_clip && !is_closed)
      clip_block(w, h, len, tolerance);
    else
      toothpick_hole(w, h, is_closed);
  }

  if (use_clip && !is_closed)
    translate([0, 2 + h + len / 2, (len / 10) / 2]) rotate([90, 0, 0]) clip_block(w, h, len);
}

module debug(w, l, h, under_deg, over_deg, inner_ax, is_closed) {
  thick = min(2, max(1, 0.1 * w));
  rad = h / 2;
  len = max(l, 2 * (h + thick));
  span = len - 2 * rad;
  y_off = span / 2 + 0.1;
  z_off = rad;

  chain_link(w, l, h, under_deg, over_deg, inner_ax, is_closed);
  translate([0, -y_off, z_off])
    rotate([min(max_angle, under_deg), 0, 0])
      translate([0, -y_off, -z_off])
        chain_link(w, l, h, under_deg, over_deg, inner_ax, is_closed);
  translate([0, y_off, z_off])
    rotate([min(max_angle, over_deg), 0, 0])
      translate([0, y_off, -z_off])
        chain_link(w, l, h, under_deg, over_deg, inner_ax, is_closed);
}

// ====================================================================
// Output selection
// ====================================================================
if (multicolor_block)
  translate([0, 0, height / 2]) cube([width + 2, length + 2, mcb_height], center=true);
else if (debug)
  debug(width, length, height, 30, 30, true, false);
else
  chain_link(width, length, height, under_angle, over_angle, inner_axis, closed, clip);
