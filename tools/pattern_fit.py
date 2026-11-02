# Wall between each extruder screw hole (vertical M3, r 1.7) and the Kossel joint
# screws (along the boss axes, r 1.525, t 5..20.5) and nut traps (hex r 3.35, t 6..8),
# for the toolhead as placed (alpha 0) and turned 180 degrees.
import math
PATTERNS = {
    'Sherpa Mini / LGX Lite / RoundTrip / G2SA Sherpa': [(-21.8, 0.0), (21.7, 0.0)],
    'Orbiter v2 / G2SA Orbiter / WristWatch': [(-19.5, 0.0), (17.5, 0.0)],
    'Sherpa Micro': [(-14.0, 0.0), (18.0, 0.0)],
    'Orbiter v1.5': [(-16.5, -0.9), (18.0, 6.0)],
    'DFA': [(-17.8, -3.0), (22.7, -3.0)],
}
HOLE_R, SCREW_R, NUT_R = 1.7, 1.525, 3.35
def features():
    for pair_deg in (90, 210, 330):
        n = (math.cos(math.radians(pair_deg)), math.sin(math.radians(pair_deg)))
        d = (-n[1], n[0])
        c = (20 * n[0], 20 * n[1])
        yield pair_deg, c, d
def wall(p):
    worst = (99, '')
    for pair_deg, c, d in features():
        v = (p[0] - c[0], p[1] - c[1])
        t = v[0] * d[0] + v[1] * d[1]
        perp = abs(v[0] * d[1] - v[1] * d[0])
        at = abs(t)
        # screw: segment |t| in [5, 20.5]
        tt = min(max(at, 5), 20.5)
        ds = math.hypot(at - tt, perp) - SCREW_R - HOLE_R
        # nut trap: hex approximated by its corner radius, |t| in [6, 8]
        tn = min(max(at, 6), 8)
        dn = max(perp - NUT_R, 0) if 6 <= at <= 8 else math.hypot(at - tn, max(perp - NUT_R, 0))
        dn -= HOLE_R
        for val, what in ((ds, f'screw {pair_deg}'), (dn, f'nut {pair_deg}')):
            if val < worst[0]: worst = (val, what)
    return worst
for name, holes in PATTERNS.items():
    for alpha in (0, 180):
        res = []
        for x, y in holes:
            if alpha == 180: x, y = -x, -y
            w, what = wall((x, y))
            res.append(f'({x:+.1f},{y:+.1f}) wall {w:+.2f} [{what}]')
        print(f'{name:48s} a={alpha:3d}: ' + '  '.join(res))
