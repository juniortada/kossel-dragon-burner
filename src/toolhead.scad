// Dragon Burner v8 (V0.2) parts with the BLTouch/3DTouch cowl remix, placed in
// the toolhead frame used by effector_dragon_burner.scad: origin on the hotend
// axis, z up (the nozzle tip of a V6 sits at about z = 1.5), front towards -y.
//
// The hotend mounts come from chirpy2605's Dragon_Burner_v0.2_v8.step, which
// shows the hotend/extruder mount stack 13.25 mm higher than it sits on the
// cowl screws. The cowl sits 1.43 mm further back than the STEP shows, which
// is where the hotend mount front touches it; the cowl and hotend mount rear
// faces then line up at y = 11.31..11.32.

STEP_TO_TOOLHEAD = [-147.72, 130.78, -46.85];
cowl_seat_dy = 1.43;

module bltouch_cowl(side="right") {
  if (side == "right")
    multmatrix([[0, -1, 0, 95.755], [0, 0, 1, -25.12 + cowl_seat_dy], [-1, 0, 0, 127.09], [0, 0, 0, 1]])
      import("../parts/dragon_burner_bltouch_right.stl");
  else
    multmatrix([[1, 0, 0, -95.75], [0, 0, 1, -25.12 + cowl_seat_dy], [0, -1, 0, 127.09], [0, 0, 0, 1]])
      import("../parts/dragon_burner_bltouch_left.stl");
}

module v6_mount() translate(STEP_TO_TOOLHEAD) {
  import("../parts/step/Hotend_Mounts__V6_Mount_Rear.stl");
  import("../parts/step/Hotend_Mounts__V6_Mount_Front.stl");
}

// Rough E3D V6 envelope: 62 mm from heatsink top to nozzle tip.
module v6_hotend() translate([0, 0, 63.1 - 62]) {
  cylinder(d1=1, d2=7, h=3, $fn=24);
  translate([-8, -4.5, 3]) cube([20, 16, 11.5]);
  translate([0, 0, 14.5]) cylinder(d=3, h=5, $fn=12);
  translate([0, 0, 19.5]) cylinder(d=22.3, h=26, $fn=48);
  translate([0, 0, 45.5]) cylinder(d=16, h=16.5, $fn=36);
}

// Rough PTFE coupling of a bowden V6 (PC4-M10: 14 mm hex) on the heatsink top.
module ptfe_coupling() translate([0, 0, 63.2]) {
  cylinder(d=14/cos(30), h=5, $fn=6);
  cylinder(d=11, h=13, $fn=32);
}

// 4010 part cooling blowers as boxes (neither the cowl STL nor the STEP has
// them), from their pocket: cowl side walls at |x| = 16.5, duct top at z = 16,
// cowl top lip at z = 56, the whole toolhead depth (y -23.69..16.31).
module blowers_4010() for (s = [-1, 1]) scale([s, 1, 1])
  translate([16.5, -23.69, 16]) cube([10, 40, 40]);

module toolhead(side="right", with_hotend=true, coupling=true) {
  color("orange") bltouch_cowl(side);
  color("dimgray") v6_mount();
  color("darkslategray") blowers_4010();
  if (with_hotend) {
    color("silver") v6_hotend();
    if (coupling) color("royalblue") ptfe_coupling();
  }
}
