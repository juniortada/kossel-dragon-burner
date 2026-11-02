// Interference checks and previews: render with -D part="..." or -D view="...".
LIBRARY = true;
include <effector_dragon_burner.scad>
include <toolhead.scad>
part = "none";
view = "none";
side = "right";
module toolhead_e(hotend=false) translate([0, 0, -joint_plane_z]) toolhead(side, hotend, ptfe_fitting == "none");
// Rough PC4 fitting on the effector top and the PTFE tube down into the
// heatsink (its depth depends on the hotend), in the effector frame.
module pc4_body(m10) translate([0, 0, height/2]) {
  translate([0, 0, -(m10 ? 7 : 5)]) cylinder(d=m10 ? 10 : 6, h=m10 ? 7 : 5, $fn=32);
  cylinder(d=(m10 ? 14 : 10)/cos(30), h=5, $fn=6);
}
module pc4_collet(m10) translate([0, 0, height/2 + 5]) cylinder(d=m10 ? 12 : 8, h=8, $fn=32);
module ptfe_tube() translate([0, 0, -joint_plane_z + 47]) cylinder(d=4, h=joint_plane_z - 47 + height/2 + 30, $fn=16);
module tube_bore() cylinder(d=4.2, h=300, center=true, $fn=16);
module pc4_fitting_and_tube() if (ptfe_fitting != "none") {
  m10 = ptfe_fitting == "PC4-M10";
  color("gold") pc4_body(m10);
  color("royalblue") pc4_collet(m10);
  color("white") ptfe_tube();
}
// Keeps x <= 0, for a section at x = 0 seen from +x. The colour goes on each
// cut part, so the cut faces take it.
module half() difference() { children(); translate([0, -150, -150]) cube(300); }
// Traxxas 5347 rod end: housing about 11 mm across and 7 mm thick on the
// joint screw; keepout = 7.5 mm sphere around the ball for tilt.
module rod_ends(keepout=false)
  rotate([0, 0, 60]) for (a = [60:120:359]) rotate([0, 0, a]) for (s = [-1, 1]) scale([s, 1, 1])
    translate([separation/2, offset, 0])
      if (keepout) translate([3.5, 0, 0]) sphere(r=7.5, $fn=32);
      else rotate([0, 90, 0]) cylinder(d=11, h=7, $fn=32);
if (part == "rodend_vs_plate") intersection() { rod_ends(true); translate([0, 0, -joint_plane_z]) toolhead_mount(); }
if (view == "assembly") {
  color("mediumpurple") effector_dragon_burner();
  toolhead_e(true);
  pc4_fitting_and_tube();
  color("dimgray") rod_ends();
  color("black") rotate([0, 0, 60]) for (a = [60:120:359]) rotate([0, 0, a]) for (s = [-1, 1]) scale([s, 1, 1])
    translate([separation/2 + 3.5, offset, 0]) rotate([-35, 0, 0]) translate([0, 0, 8]) cylinder(d=6, h=40, $fn=16);
}
if (view == "section") {
  m10 = ptfe_fitting == "PC4-M10";
  color("mediumpurple") half() effector_dragon_burner();
  translate([0, 0, -joint_plane_z]) {
    color("orange") half() bltouch_cowl(side);
    color("dimgray") half() v6_mount();
    color("silver") half() difference() { v6_hotend(); tube_bore(); }
  }
  color("gold") half() difference() { pc4_body(m10); tube_bore(); }
  color("royalblue") half() difference() { pc4_collet(m10); tube_bore(); }
  color("white") half() ptfe_tube();
}
if (view == "effector") color("mediumpurple") effector_dragon_burner();
if (view == "print") color("mediumpurple") rotate([180, 0, 0]) translate([0, 0, -height/2]) effector_dragon_burner();
