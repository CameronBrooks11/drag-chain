// Drag chain with mounts 
// Source: https://www.printables.com/model/353066
// License: CC BY 4.0 (c) R. Linder

// ---------------- Parameters ----------------

// Preview-driven tolerances and tessellation
zFite = $preview ? 0.05 : 0;
$fn = $preview ? 32 : 128;

// Internal height (min 5)
link_height = 10;

// Internal width  (min 5)
link_width = 10;

// Shell thickness (typ 1.8, min 1.4)
shell_thickness = 1.8;

// Extra link extension (mm)
link_xtend = 10;

// Pin chamfer to ease insertion
pin_release = 1; // [0:off, 1:On]

// Number of links to print
number_of_links = 2;

// Anti-stick clearance (try reducing feedrate first)
anti_stick = 0.15; // [0.0:0.01:0.35]

// Output selection
part_selection = 3; // [0:Chain only, 1:Male mount, 2:Female mount, 3:Chain with mounts]

// ---------------- Derived ----------------
linkHeight = link_height + 2 * shell_thickness;
linkWidth = link_width + 4 * shell_thickness;
linkLength = link_height * 2.8;
pinRad = linkHeight / 6;
pinSpace = ( (linkLength / 2) - (linkHeight / 2)) * 2;
tabLen = linkHeight / 2;

// ============================ Mounts ================================
module mount_female(part_only = 0) {
  difference() {
    union() {
      difference() {
        translate([linkHeight / 2, 0, 0])
          hull() {
            translate([0, pinSpace / 2, 0]) cylinder(h=linkWidth + 0.6, r=linkHeight / 2, $fs=0.5);
            translate([-linkHeight / 2, -pinSpace / 6, 0]) cube([linkHeight, 1, linkWidth + 0.6]);
            translate([0, -pinSpace * 1.5, 0]) cube([linkHeight / 2, 5, linkWidth + 0.6]);
          }
        end_female(1, part_only);
      }
    }
    translate([-shell_thickness, -pinSpace * 1.5 - 0.6, shell_thickness * 2])
      cube([linkHeight, pinSpace * 2.5, linkWidth - 4 * shell_thickness + 0.6]);

    // M3 holes
    if (link_width >= 10) {
      for (off = [0:2]) {
        rotate([0, 90, 0])
          translate([-linkWidth / 2 - off - link_width / 6 + 0.6, -linkLength / 2.5 - (linkLength / 6), link_height + 0.6])
            cylinder(h=shell_thickness * 2, r=1.6);
        rotate([0, 90, 0])
          translate([-linkWidth / 2 + off + link_width / 6 - 1.2, -linkLength / 2.5 + (linkLength / 6), link_height + 0.6])
            cylinder(h=shell_thickness * 2, r=1.6);
      }
    } else {
      rotate([0, 90, 0])
        translate([-linkWidth / 2 - 0.3, -linkLength / 2.5, link_height + 0.6])
          cylinder(h=shell_thickness * 2, r=1.6);
    }
  }
}

module mount_male() {
  difference() {
    union() {
      difference() {
        union() {
          translate([linkHeight / 2, 0, 0])
            hull() {
              translate([0, pinSpace, 0]) cube([linkHeight / 2, 5, linkWidth + 0.6]);
              translate([0, -pinSpace / 2, 0]) cylinder(h=linkWidth + 0.6, r=linkHeight / 2, $fs=0.5);
              translate([-linkHeight / 2, -pinSpace / 6, 0]) cube([linkHeight, 1, linkWidth + 0.6]);
            }
          translate([0, -(linkLength + tabLen) / 2, shell_thickness + 0.3])
            cube([(linkHeight + shell_thickness) / 2, tabLen * 2, linkWidth - 2 * shell_thickness + 0.2]);
        }
        end_male();
      }
      // Locking pins (0.2 mm narrower)
      translate([linkHeight / 2, -pinSpace / 2 - 1.5, 0.4])
        cylinder(h=linkWidth - 0.2, r=pinRad - 0.25);
    }

    // Top chamfer + front chamfer + wire hole
    translate([linkHeight / 2 + 1, -linkLength / 2 - sqrt(tabLen * tabLen * 2), 0])
      rotate([0, 0, 45]) cube([tabLen, tabLen, linkWidth]);
    translate([linkHeight / 2 - 0.6, -linkLength / 2 - tabLen + 0.6, 0])
      rotate([0, 0, 70]) cube([2.5, 5, linkWidth + 5]);
    translate([-shell_thickness, -pinSpace * 1.5, shell_thickness * 2])
      cube([linkHeight, pinSpace * 3.5, linkWidth - 4 * shell_thickness + 0.6]);

    // M3 holes
    if (link_width >= 10) {
      for (off = [0:2]) {
        rotate([0, 90, 0])
          translate([-linkWidth / 2 - off - link_width / 6 + 0.6, linkLength / 3 + (linkLength / 6), link_height + 0.6])
            cylinder(h=shell_thickness * 2, r=1.6);
        rotate([0, 90, 0])
          translate([-linkWidth / 2 + off + link_width / 6 - 1.2, linkLength / 3 - (linkLength / 6), link_height + 0.6])
            cylinder(h=shell_thickness * 2, r=1.6);
      }
    } else {
      rotate([0, 90, 0])
        translate([-linkWidth / 2 - 0.3, linkLength / 2, link_height + 0.6])
          cylinder(h=shell_thickness * 2, r=1.6);
    }
  }
}

// ============================= Link =================================
m_th = link_height;
m_r = linkHeight / 2;
m_45_h = sin(45) * m_r;

module link_unit() {
  difference() {
    union() {
      difference() {
        union() {
          translate([linkHeight / 2, 0, 0])
            hull() {
              translate([0, link_xtend + pinSpace / 2, 0]) cylinder(h=linkWidth + 0.6, r=linkHeight / 2, $fs=0.5);
              translate([0, -pinSpace / 2, 0]) cylinder(h=linkWidth + 0.6, r=linkHeight / 2, $fs=0.5);
            }
          // Keep bottom angle at 45°
          translate([m_r * 3, -m_th - m_45_h, 0])
            linear_extrude(linkWidth + 0.6)
              polygon([[-m_r, m_th], [m_45_h - 2 * m_r, 2 * m_45_h - m_r], [-m_r, m_45_h]]);
          translate([m_r * 3, m_th + m_45_h + link_xtend, 0])
            mirror([0, 1, 0])
              linear_extrude(linkWidth + 0.6)
                polygon([[-m_r, m_th], [m_45_h - 2 * m_r, 2 * m_45_h - m_r], [-m_r, m_45_h]]);
          translate([0, -(linkLength + tabLen) / 2, shell_thickness + anti_stick / 2])
            cube([(linkHeight + shell_thickness) / 2, tabLen * 2, linkWidth - 2 * shell_thickness + 0.2]);
        }
        end_male();
        end_female(part_only=1);
      }
      // Locking pins (0.2 mm narrower)
      translate([linkHeight / 2, -pinSpace / 2 - 1.5, 0.4])
        cylinder(h=linkWidth - 0.2, r=pinRad - 0.25);
    }

    // Stopper chamfers
    translate([linkHeight / 2 + 1, -linkLength / 2 - sqrt(tabLen * tabLen * 2), 0])
      rotate([0, 0, 45]) cube([tabLen, tabLen, linkWidth]);
    translate([linkHeight / 2 - 0.6, -linkLength / 2 - tabLen + 0.6, 0])
      rotate([0, 0, 70]) cube([2.5, 5, linkWidth + 5]);

    // Cable hole
    translate([shell_thickness + 0.2, -linkLength / 2 - tabLen, shell_thickness * 2])
      cube([linkHeight - 2 * shell_thickness, link_xtend + linkLength + tabLen + 1, linkWidth - 4 * shell_thickness + 0.6]);

    // Trim top brace
    translate([0, -pinSpace - 2 * pinRad, shell_thickness * 2])
      cube([linkHeight + 3, linkLength / 2, linkWidth - 4 * shell_thickness + 0.6]);

    // Pin chamfers to ease joining
    if (pin_release == 1) {
      translate([linkHeight / 2 - pinRad, -pinSpace / 2 - 1.5, -2 * pinRad - 1.5])
        rotate([60, 0, 0]) cube(pinRad * 2 + 1);
      translate([linkHeight / 2 - pinRad, -pinSpace / 2 - 1.5 - (pinRad + 0.25) * 2, linkWidth + pinRad + 1.5])
        rotate([300, 0, 0]) cube(pinRad * 2 + 1);
    }
    // Overhang relief on pins
    translate([linkHeight / 2 - sin(60) * (pinRad * 2 + 1) + (pinRad - 0.25) * 2, -pinSpace + pinRad, -2 * pinRad + 1.5])
      rotate([0, 30, 0]) cube(pinRad * 2 + 1);
    translate([linkHeight / 2 + (pinRad - 0.25), -pinSpace / 2 - 2 * pinRad, linkWidth - pinRad / 2])
      rotate([0, 330, 0]) cube(pinRad * 2 + 1);
  }
}

// ============================== Ends ================================
module end_male() {
  translate([-0.6, -linkLength / 2, linkWidth + 0.4 - shell_thickness])
    cube([linkHeight + 1, pinRad * 6 - shell_thickness, shell_thickness + 0.7]);
  translate([-0.6, -linkLength / 2, -0.6])
    cube([linkHeight + 1, pinRad * 6 - shell_thickness, shell_thickness + 0.8]);
  translate([-0.6, -(linkLength + tabLen) / 2 - 0.6, 0])
    cube([shell_thickness + 1.2 + anti_stick, pinRad * 2.5 + tabLen + 0.6, linkWidth + 0.6]);
}

module end_female(mount, part_only) {
  xtend = (part_only != 0) ? link_xtend : 0;

  translate([linkHeight / 2, xtend + pinSpace / 2 + 1.5, -1])
    cylinder(h=linkWidth + 3, r=pinRad);

  // Brace cut-away
  translate([-0.6, xtend + pinRad * 2.5, shell_thickness - anti_stick])
    cube([linkHeight + 2, pinRad * 3 + 1.2, linkWidth - 2 * shell_thickness + 0.6 + 2 * anti_stick]);

  // Top brace trim
  translate([linkHeight - shell_thickness - 0.6, pinRad * 2, shell_thickness - anti_stick])
    cube([2 * shell_thickness, pinRad * 4, linkWidth - 2 * shell_thickness + 0.6 + 2 * anti_stick]);

  // Extra slot if extended
  if (xtend > 0)
    translate([-0.6, pinRad * 2, shell_thickness - anti_stick])
      cube([linkHeight + 2, xtend - pinRad * 2, linkWidth - 2 * shell_thickness + 0.6 + 2 * anti_stick]);

  if (mount)
    translate([-zFite, -zFite, shell_thickness])
      cube([linkHeight - shell_thickness + zFite, linkLength / 2 + zFite, linkWidth - 2 * shell_thickness + 0.6]);
  else
    translate([shell_thickness + 0.2, xtend - 0.6, shell_thickness - anti_stick])
      cube([linkHeight - 2 * shell_thickness, linkLength / 2 + 0.6, linkWidth - 2 * shell_thickness + 0.6 + 2 * anti_stick]);
}

// ============================== Build ===============================
rotate([0, 90, 0]) {
  if (part_selection == 1) {
    mount_male();
  } else if (part_selection == 2) {
    mount_female(part_only=0);
  } else if (part_selection <= 3) {
    if (part_selection == 3) {
      translate([0, link_xtend, 0]) mount_female();
      translate([0, (number_of_links + 1) * (link_xtend + pinSpace + 3), 0]) mount_male();
    }
    for (cnt = [0:number_of_links - 1])
      translate([0, (cnt + 1) * (link_xtend + pinSpace + 3), 0]) link_unit();
  } else {
    echo("Invalid Part Selection");
  }
}
