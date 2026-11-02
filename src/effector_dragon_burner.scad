// Kossel Mini effector for the Dragon Burner toolhead (chirpy2605, V0.2 version)
// with its BLTouch/3DTouch cowl remix (printables.com/model/822570), bowden.
//
// Derived from effector.scad in github.com/jcrocholl/kossel (GPLv3). The ball
// joint bosses are that file's code, untouched: same separation, offset,
// height, cones, M3 holes and nut traps, so DELTA_EFFECTOR_OFFSET stays 20.
//
// The effector takes the place of the Dragon Burner extruder mount: it sits
// right on top of the toolhead, with a plug that fills the extruder mount
// pocket over the hotend mount. The PTFE coupling stays on top of the hotend
// and passes through a hole along the nozzle axis; for a hotend with no
// coupling (ptfe_fitting = PC4-M10 or PC4-M6) the tube goes through the
// effector into the heatsink and the fitting screws into a printed thread on
// the effector top. It is fixed with
//   - 2 x M3x25 from behind into the cowl's top inserts (the ones every
//     Dragon Burner extruder mount screws into),
//   - 2 x M3x35 through the cowl front into heat inserts in the rear plate,
//     which copies the Voron V0.2 X carriage face,
//   - 2 x M3x10 BHCS from behind into the heat inserts at the rear of the ducts
//     (replaces the rear brace), through legs that pass behind the 4010
//     blowers.
// The extruder screw patterns (Sherpa Mini, Orbiter, ...) cannot be used: at
// this toolhead orientation their holes cross the tower A/B joint screws.
//
// Frame: origin on the nozzle axis, z up from the toolhead frame zero (the
// nozzle tip of a V6 sits at about z = 1.5), toolhead front towards -y, tower C
// (rear) at +y, towers A/B at 210/330 deg. Same x/y/z as toolhead.scad; the
// effector is rendered with its joint mid-plane at z = 0.
// Print upside down: effector top face on the bed, plate pointing up.

include <configuration.scad>;

/* [Kossel rod joints - do not change] */
separation = 40;  // Distance between ball joint mounting faces.
offset = 20;  // Same as DELTA_EFFECTOR_OFFSET in Marlin.
height = 8;
cone_r1 = 2.5;
cone_r2 = 14;

/* [Toolhead placement] */
// Cowl top is at z = 70.8; the effector sits 0.1 above it.
effector_bottom_z = 70.9;
joint_plane_z = effector_bottom_z + height/2;

/* [Dragon Burner interface, toolhead frame] */
// Cowl and hotend mount rear faces: y = 11.31..11.32.
face_y = 11.46;
// Rear faces of the duct tabs: y = 16.31, up to z = 15.9.
tab_face_y = 16.41;
tab_top_z = 16.9;
plate_rear_y = tab_face_y + 6;  // M3x10 BHCS: 3.9 mm into the duct inserts.

// 4010 blowers (in neither the cowl STL nor the STEP): between the cowl side
// walls (|x| = 16.5) and the duct edge, standing on the duct top (z = 16) up
// to the cowl top lip (z = 56), across the whole toolhead depth (y up to
// 16.31, like the duct tabs). Only the legs pass behind them.
fan_inner_x = 16.5;
fan_z = [16, 56];
fan_rear_y = 16.31;
fan_clearance = 0.5;

main_screw_x = 12.5;
main_screw_z = 56.95;
insert_d = 4.7;  // Same hole the Dragon Burner uses for its own inserts.
insert_depth = 5;

duct_screw_x = 20.9;
duct_screw_z = 10.9;
leg_w = 9.5;
leg_bottom_z = 5.5;

// Plug in the extruder mount pocket: hotend mount top at z = 63.92, cowl top
// wall (with the extruder mount inserts) from y = -10.09 forwards.
plug_bottom_z = 63.97;
plug_front_y = -9.62;  // Same as the Dragon Burner extruder mounts.
plug_half_w = 18;  // Narrower than the stock mounts, clear of the A/B rod ends.

// Cowl top inserts for the extruder mount: x = +-12.5, z = 67.36, insert from
// y = -10.09 to -14.09. An M3x25 seated at y = 11 ends at y = -14.
cowl_screw_x = 12.5;
cowl_screw_z = 67.36;
cowl_screw_head_d = 6.5;
cowl_screw_seat_y = 11;

/* [PTFE] */
// none: the hotend carries its own PTFE coupling, which passes through the
// effector. PC4-M10 / PC4-M6: the hotend has none; the PTFE tube goes through
// the effector into the heatsink and the fitting screws into the effector top.
ptfe_fitting = "none";  // [none, PC4-M10, PC4-M6]

// Through-hole for the PTFE coupling on top of the bowden hotend. The heatsink
// top sits at z = 63.2, inside the V6 mount top bore (15.9) up to z = 63.83.
// 17 clears a 14 mm hex across the corners (16.2: PC4-M10, PC4-01).
connector_clear_d = 17;

ptfe_clear_d = 4.6;  // 4 mm PTFE tube, loose: the fitting holds it.
// Fitting thread: major diameter, pitch, depth from the effector top.
fitting_thread = ptfe_fitting == "PC4-M10" ? [10, 1, 9] : [6, 1, 7];
thread_clearance = 0.3;  // On the diameter, for a printed thread.
thread_chamfer = 0.8;

plate_top_z = effector_bottom_z + 0.5;  // Overlaps the slab by 0.5 mm.
plate_upper_z = 44;  // Hotend mount rear face spans z 47.4..63.9.
plate_half_w = duct_screw_x + leg_w/2;
plate_neck_half_w = 16;  // Keeps clear of the tower C rod ends.
// Beside the M3x25 counterbores (z 64.1..70.6) the neck widens as far as the
// tower C rod ends allow (keep-out sphere r 7.5 at x +-23.5, y 20, z 74.9):
// 2.5 mm or more of wall, 0.5 mm or more from the keep-out.
neck_profile = [[18.8, 67.6], [17.9, 69], [17.2, 69.9], [16.6, 70.6]];

web_x = [6.5, plate_neck_half_w];
web_rear_y = 16.5;  // Tower C nut traps start at y = 16.65.

// ---------------------------------------------------------------------------
// Original Kossel effector code, rotated 60 degrees so the joint pairs face
// towers at 90/210/330 degrees. Only the hotend hole and the 6 hotend mount
// holes were left out.
module kossel_joints() {
  rotate([0, 0, 60]) for (a = [60:120:359]) rotate([0, 0, a]) {
    rotate([0, 0, 30]) translate([offset-2, 0, 0])
      cube([10, 13, height], center=true);
    for (s = [-1, 1]) scale([s, 1, 1]) {
      translate([0, offset, 0]) difference() {
        intersection() {
          cube([separation, 40, height], center=true);
          translate([0, -4, 0]) rotate([0, 90, 0])
            cylinder(r=10, h=separation, center=true);
          translate([separation/2-7, 0, 0]) rotate([0, 90, 0])
            cylinder(r1=cone_r2, r2=cone_r1, h=14, center=true, $fn=24);
        }
        rotate([0, 90, 0])
          cylinder(r=m3_radius, h=separation+1, center=true, $fn=12);
        rotate([90, 0, 90])
          cylinder(r=m3_nut_radius, h=separation-24, center=true, $fn=6);
      }
    }
  }
}

module kossel_joint_screw_holes() {
  rotate([0, 0, 60]) for (a = [60:120:359]) rotate([0, 0, a])
    translate([0, offset, 0]) rotate([0, 90, 0])
      cylinder(r=m3_radius, h=separation+1, center=true, $fn=12);
}

module kossel_effector() {
  cylinder(r=offset-3, h=height, center=true, $fn=60);
  kossel_joints();
}
// ---------------------------------------------------------------------------

module y_slab(y0, y1) {
  translate([0, y1, 0]) rotate([90, 0, 0]) linear_extrude(y1 - y0) children();
}

module upper_plate_profile() {
  half = concat([[plate_half_w, plate_upper_z], [plate_half_w, 62]], neck_profile,
                [[plate_neck_half_w, plate_top_z]]);
  polygon(concat(half, [for (i = [len(half) - 1:-1:0]) [-half[i][0], half[i][1]]]));
}

module leg_profile(z0, z1) {
  for (s = [-1, 1]) translate([s*duct_screw_x - leg_w/2, z0]) square([leg_w, z1 - z0]);
}

// Rear plate, plug and the web through the slab, in the toolhead frame.
module toolhead_mount() {
  difference() {
    union() {
      y_slab(face_y, plate_rear_y) {
        upper_plate_profile();
        leg_profile(tab_top_z, plate_upper_z + 1);
      }
      y_slab(tab_face_y, plate_rear_y) leg_profile(leg_bottom_z, tab_top_z + 1);
      translate([-plug_half_w, plug_front_y, plug_bottom_z])
        cube([2*plug_half_w, face_y + 0.5 - plug_front_y, plate_top_z - plug_bottom_z]);
      // Web through the effector slab between the centre disc and the tower C
      // bosses, so the plate does not start in mid air when printed upside down.
      for (s = [-1, 1]) scale([s, 1, 1])
        translate([web_x[0], face_y, plate_top_z])
          cube([web_x[1] - web_x[0], web_rear_y - face_y, joint_plane_z + height/2 - plate_top_z]);
    }
    // Heat inserts for the 2 x M3x35 from the cowl front. The hole goes
    // through, so M3x40 with a nut at the back also works.
    for (s = [-1, 1]) translate([s*main_screw_x, 0, main_screw_z]) rotate([-90, 0, 0]) {
      translate([0, 0, face_y - 1]) cylinder(d=insert_d, h=insert_depth + 1, $fn=32);
      cylinder(d=3.4, h=50, $fn=24);
    }
    // 2 x M3x25 from behind into the cowl top inserts.
    for (s = [-1, 1]) translate([s*cowl_screw_x, 0, cowl_screw_z]) rotate([-90, 0, 0]) {
      translate([0, 0, plug_front_y - 1]) cylinder(d=3.4, h=50, $fn=24);
      translate([0, 0, cowl_screw_seat_y]) cylinder(d=cowl_screw_head_d, h=20, $fn=32);
    }
    // M3x10 BHCS from behind into the duct inserts.
    for (s = [-1, 1]) translate([s*duct_screw_x, 0, duct_screw_z]) rotate([-90, 0, 0])
      cylinder(d=3.4, h=50, $fn=24);
    // Room for the 4010 blowers.
    for (s = [-1, 1]) scale([s, 1, 1])
      translate([fan_inner_x - fan_clearance, face_y - 1, fan_z[0] - fan_clearance])
        cube([20, fan_rear_y + fan_clearance - face_y + 1, fan_z[1] - fan_z[0] + 2*fan_clearance]);
    // Chamfer the back of the leg ends.
    for (s = [-1, 1]) translate([s*duct_screw_x, plate_rear_y, leg_bottom_z])
      rotate([45, 0, 0]) cube([leg_w + 2, 3, 3], center=true);
  }
}

// Depth (0 at the crest, 1 at the root) of the ISO metric screw profile over
// one pitch: crest flat P/8, flanks 5P/16, root flat P/4.
function thread_depth(t) = let(t = t - floor(t))
  t < 1/16 || t > 15/16 ? 0 : t < 6/16 ? (t - 1/16)*16/5 : t <= 10/16 ? 1 : (15/16 - t)*16/5;

// Right hand internal thread, depth h below z = 0, as the screw to subtract
// (grown by thread_clearance), with a 45 deg lead-in that is chamfer wider than
// the thread at z = 0 and goes on 1 mm above it. Swept as rings of n points,
// one ring every 1/n pitch, so ring k is ring 0 turned by k points. The lead-in
// is a floor on the ring radius rather than a separate cone, so no boolean
// meets the thread crests at a grazing angle and leaves slivers.
module thread_cut(d, pitch, h, chamfer, n=48) {
  r_max = (d + thread_clearance)/2;
  rings = round(n*(h + 1)/pitch);
  function z(k) = k*pitch/n - h;
  function r(i, k) = max(r_max - 0.5413*pitch*thread_depth((i - k)/n), r_max + chamfer + z(k));
  function v(k, i) = k*n + (i % n);
  polyhedron(
    points=[for (k = [0:rings], i = [0:n - 1]) [r(i, k)*cos(360*i/n), r(i, k)*sin(360*i/n), z(k)]],
    faces=concat(
      [[for (i = [0:n - 1]) v(0, i)]],
      [for (k = [0:rings - 1], i = [0:n - 1], t = [0, 1])
        t == 0 ? [v(k, i), v(k + 1, i), v(k + 1, i + 1)] : [v(k, i), v(k + 1, i + 1), v(k, i + 1)]],
      [[for (i = [n - 1:-1:0]) v(rings, i)]]),
    convexity=4);
}

// PTFE path along the nozzle axis, in the effector frame.
module ptfe_passage() {
  if (ptfe_fitting == "none") {
    // PTFE coupling on top of the hotend.
    translate([0, 0, -joint_plane_z + plug_bottom_z - 1]) cylinder(d=connector_clear_d, h=100, $fn=64);
  } else {
    translate([0, 0, -joint_plane_z + plug_bottom_z - 1]) cylinder(d=ptfe_clear_d, h=100, $fn=32);
    // The lead-in also takes the first layer squish (top face on the bed).
    translate([0, 0, height/2])
      thread_cut(fitting_thread[0], fitting_thread[1], fitting_thread[2], thread_chamfer);
  }
}

module effector_dragon_burner() {
  difference() {
    union() {
      kossel_effector();
      translate([0, 0, -joint_plane_z]) toolhead_mount();
    }
    kossel_joint_screw_holes();
    ptfe_passage();
  }
}

if (is_undef(LIBRARY)) effector_dragon_burner();
