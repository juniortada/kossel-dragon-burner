# Checks the effector against the Dragon Burner parts (effector frame) and the
# original Kossel effector, one stage per run to keep the CPU load short:
#   [STL=effector_dragon_burner_pc4_m10] python -I tools/verify.py <project dir> \
#     toolhead|seat|rod|joints|cowl_inserts|bltouch|walls [layer min_wall]|thread [pitch]
import os, sys, numpy as np, trimesh, manifold3d as mf
from trimesh.proximity import ProximityQuery

P, STAGE = sys.argv[1], sys.argv[2]
STL = os.environ.get('STL', 'effector_dragon_burner')
Z0, SEAT = 74.9, 1.43  # joint plane height in the toolhead frame, cowl seat offset
STEP = np.array([-147.72, 130.78, -46.85])  # composed STEP exports -> toolhead frame
COWL = {'right': np.array([[0, -1, 0, 95.755], [0, 0, 1, -25.12 + SEAT], [-1, 0, 0, 127.09], [0, 0, 0, 1]]),
        'left': np.array([[1, 0, 0, -95.75], [0, 0, 1, -25.12 + SEAT], [0, -1, 0, 127.09], [0, 0, 0, 1]])}
HOTEND_MOUNTS = ('Hotend_Mounts__Dragon_Mount', 'Hotend_Mounts__V6_Mount_Rear', 'Hotend_Mounts__V6_Mount_Front',
                 'Orbiter2_Mounts__RevoMicro_Mount', 'Sherpa_Micro_Mounts__V6_Mount_Back_1',
                 'Orbiter1.5_Mounts__Dragon_Mount_2_1', 'DFA_Mounts__Dragon_Mount_1')


def T(v):
    M = np.eye(4); M[:3, 3] = v; return M


def load(name, M, z0=Z0):
    m = trimesh.load(f'{P}/parts/{name}.stl'); m.apply_transform(T([0, 0, -z0]) @ M); return m


def to_mf(m):
    return mf.Manifold(mf.Mesh(vert_properties=np.asarray(m.vertices, np.float32),
                               tri_verts=np.asarray(m.faces, np.uint32)))


def toolhead_parts(z0=Z0):
    parts = {'cowl_right': load('dragon_burner_bltouch_right', COWL['right'], z0),
             'cowl_left': load('dragon_burner_bltouch_left', COWL['left'], z0)}
    for n in HOTEND_MOUNTS:
        parts[n] = load('step/' + n, T(STEP), z0)
    for s, side in ((1, 'right'), (-1, 'left')):  # 4010 blowers, 10 x 40 x 40 boxes (see toolhead.scad)
        parts[f'blower_4010_{side}'] = trimesh.creation.box([10, 40, 40], T([s * 21.5, -3.69, 36 - z0]))
    return parts


def effector():
    return trimesh.load(f'{P}/stl/{STL}.stl')


def stage_toolhead():
    eff = effector()
    print(f'effector watertight={eff.is_watertight} volume={eff.volume / 1000:.1f} cm3 '
          f'bounds={eff.bounds.round(1).tolist()}')
    E, pq = to_mf(eff), ProximityQuery(eff)
    for name, m in toolhead_parts().items():
        X = to_mf(m)
        vol = f'{(E ^ X).volume():.3f} mm3' if X.status() == mf.Error.NoError else 'n/a (open mesh)'
        pts = np.vstack([m.sample(8000), m.vertices])
        d = pq.signed_distance(pts); i = np.argmax(d)
        print(f'  {name[-26:]:26s} intersection {vol:16s} points inside={int((d > 0).sum()):3d} '
              f'closest {-d.max():.2f} mm at {pts[i].round(1).tolist()}')


def stage_seat():
    parts = toolhead_parts(0)
    for side in ('right', 'left'):
        C = to_mf(parts[f'cowl_{side}'])
        print(f'  cowl_{side} overlap:', ', '.join(f'{n} {(C ^ to_mf(parts[n])).volume():.2f}' for n in HOTEND_MOUNTS))


def stage_rod():
    balls = []
    for a in (60, 180, 300):
        ang = np.radians(60 + a)
        R = np.array([[np.cos(ang), -np.sin(ang)], [np.sin(ang), np.cos(ang)]])
        for s in (-1, 1):
            balls.append([*(R @ [s * 23.5, 20.0]), 0.0])
    balls = np.array(balls)
    for name, m in toolhead_parts().items():
        _, dist, _ = trimesh.proximity.closest_point(m, balls)
        print(f'  {name[-26:]:26s} ball centre to part: {dist.min():.2f} mm (rod end keep-out 7.5)')


def stage_joints():
    orig = trimesh.load(f'{P}/vendor/kossel-orig-render/effector_orig.stl')
    orig.apply_translation([0, 0, -4])
    orig.apply_transform(trimesh.transformations.rotation_matrix(np.radians(60), [0, 0, 1]))
    O, E = to_mf(orig), to_mf(effector())
    for a, tower in ((60, 'A'), (180, 'B'), (300, 'C')):
        for s in (-1, 1):
            for w, xc, label in ((5, 18.5, 'face end |x| 16..21'), (15.5, 13.25, 'whole boss |x| 5.5..21')):
                z = mf.Manifold.cube([w, 14, 9], True).translate([s * xc, 20, 0]).rotate([0, 0, 60 + a])
                print(f'  tower {tower} {s:+d} {label}: added {((E - O) ^ z).volume():.3f} '
                      f'removed {((O - E) ^ z).volume():.3f} mm3')
    rem = O - E
    for zr, label in (((-5, -1.99), 'below z=-2 (centre hole, M5 thread side)'), ((-1.99, 5), 'above z=-2 (centre hole)')):
        r = rem ^ mf.Manifold.cube([200, 200, zr[1] - zr[0]]).translate([-100, -100, zr[0]])
        print(f'  removed from the original {label}: {r.volume():.0f} mm3, '
              f'bbox {np.round(r.bounding_box(), 1).tolist()}')


def stage_walls(layer=0.2, min_wall=0.9):
    # Print orientation (effector top face on the bed): per layer, the material
    # lost by a morphological opening, i.e. walls thinner than min_wall.
    eff = effector()
    top, h = eff.bounds[1, 2], eff.bounds[1, 2] - eff.bounds[0, 2]
    zp = np.arange(layer / 2, h, layer)  # layer mid heights above the bed
    r, found = min_wall / 2, []
    for z, sec in zip(zp, eff.section_multiplane([0, 0, top], [0, 0, 1], -zp)):
        if sec is None:
            continue
        M = sec.metadata['to_3D']
        for poly in sec.polygons_full:
            lost = poly.difference(poly.buffer(-r, join_style=2).buffer(r, join_style=2))
            for p in getattr(lost, 'geoms', [lost]):
                if p.area > 0.05:
                    c = (M @ [*p.centroid.coords[0], 0, 1])[:3]
                    found.append((int(z // layer) + 1, p.area, c[0], c[1], c[2] + Z0))
    print(f'walls under {min_wall} mm at {layer} mm layers (layer 1 on the bed, z in the toolhead frame):')
    for f in found:
        print(f'  layer {f[0]:3d} area {f[1]:.2f} mm2 at x {f[2]:+.1f} y {f[3]:+.1f} z {f[4]:.1f}')
    print(f'  {len(found)} spots')


def stage_thread(pitch=1.0):
    # Fitting thread at the effector top: hole radius range per section and the
    # angle of its widest point, which turns +90 deg per quarter pitch going up
    # for a right hand thread.
    eff = effector()
    top = eff.bounds[1, 2]
    for dz in np.arange(-0.5, -10, -pitch / 4):
        sec = eff.section(plane_origin=[0, 0, top + dz], plane_normal=[0, 0, 1])
        ring = min(sec.discrete, key=lambda d: np.linalg.norm(d[:, :2], axis=1).max())
        r = np.linalg.norm(ring[:, :2], axis=1); i = np.argmax(r)
        print(f'  {dz:+6.2f} mm from the top: hole d {2 * r.min():.2f}..{2 * r.max():.2f}, '
              f'widest at {np.degrees(np.arctan2(ring[i, 1], ring[i, 0])):+6.0f} deg')


def stage_cowl_inserts():
    for side in ('right', 'left'):
        m = trimesh.load(f'{P}/parts/dragon_burner_bltouch_{side}.stl'); m.apply_transform(COWL[side])
        for y in (-11.0, -13.0):
            s = m.section(plane_origin=[0, y, 0], plane_normal=[0, 1, 0])
            for d in s.discrete:
                c = d[:, [0, 2]].mean(axis=0); r = np.linalg.norm(d[:, [0, 2]] - c, axis=1)
                if c[1] > 60 and r.std() < 0.15 and 1.5 < r.mean() < 2.6:
                    print(f'  {side} y={y}: hole x {c[0]:+.2f} z {c[1]:.2f} d {2 * r.mean():.2f}')


def stage_bltouch():
    for side in ('right', 'left'):
        m = trimesh.load(f'{P}/parts/dragon_burner_bltouch_{side}.stl'); m.apply_transform(COWL[side])
        s = m.section(plane_origin=[0, 0, 44.7], plane_normal=[0, 0, 1])
        for d in s.discrete:
            c = d[:, :2].mean(axis=0); r = np.linalg.norm(d[:, :2] - c, axis=1)
            if abs(c[0]) > 25 and r.std() < 0.15 and 2.2 < r.mean() < 2.8:
                print(f'  {side}: pin X {c[0]:+.2f}  Y {c[1]:+.2f} from the nozzle')


globals()[f'stage_{STAGE}'](*map(float, sys.argv[3:]))
