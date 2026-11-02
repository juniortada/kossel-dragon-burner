# List hotend/extruder mounts of Dragon_Burner_v0.2_v8.step with world placement
# (nested assembly locations composed), export them, and print their vertical holes.
import sys, json
from OCP.STEPCAFControl import STEPCAFControl_Reader
from OCP.XCAFDoc import XCAFDoc_DocumentTool
from OCP.TDocStd import TDocStd_Document
from OCP.TCollection import TCollection_ExtendedString
from OCP.TDF import TDF_LabelSequence, TDF_Label
from OCP.TDataStd import TDataStd_Name
from OCP.TopLoc import TopLoc_Location
from OCP.TopExp import TopExp_Explorer
from OCP.TopAbs import TopAbs_FACE
from OCP.TopoDS import TopoDS
from OCP.BRepAdaptor import BRepAdaptor_Surface
from OCP.GeomAbs import GeomAbs_Cylinder
from OCP.Bnd import Bnd_Box
from OCP.BRepBndLib import BRepBndLib
from OCP.StlAPI import StlAPI_Writer
from OCP.BRepMesh import BRepMesh_IncrementalMesh
step, outdir = sys.argv[1], sys.argv[2]
doc = TDocStd_Document(TCollection_ExtendedString("doc"))
r = STEPCAFControl_Reader(); r.SetNameMode(True); r.ReadFile(step); r.Transfer(doc)
st = XCAFDoc_DocumentTool.ShapeTool_s(doc.Main())
def name(l):
    n = TDataStd_Name()
    return n.Get().ToExtString().rsplit(':', 1)[0] if l.FindAttribute(TDataStd_Name.GetID_s(), n) else "?"
def referred(l):
    if st.IsReference_s(l):
        lab = TDF_Label(); st.GetReferredShape_s(l, lab); return lab
    return l
def children(l):
    lab = referred(l); comps = TDF_LabelSequence()
    if st.IsAssembly_s(lab): st.GetComponents_s(lab, comps)
    return [comps.Value(i) for i in range(1, comps.Length() + 1)]
GROUPS = {'Hotend_Mounts', 'Sherpa_Micro_Mounts', 'Orbiter2_Mounts', 'Orbiter1.5_Mounts', 'DFA_Mounts'}
WANT_IN_GROUP = ('Dragon_Mount', 'V6_Mount', 'Sherpa_Micro_Mount', 'Orbiter2_Mount', 'Orbiter1.5_Mount', 'DFA_Mount', 'RevoMicro')
ROOT_EXTRUDER = {'LGX_Lite_Mount', 'Sherpa_Mini_Mount', 'Bowden_Mount (1)', 'Bowden_Mount_285', 'G2SA_Sherpa_Mount',
                 'G2SA_Orbiter_Mount', 'RoundTrip_Mount', 'WristWatch_BMG_Mount', 'WristWatch_G2_Mount'}
out = []
def report(shape, group, nm):
    b = Bnd_Box(); BRepBndLib.Add_s(shape, b); bb = [round(v, 2) for v in b.Get()]
    holes = set()
    ex = TopExp_Explorer(shape, TopAbs_FACE)
    while ex.More():
        s = BRepAdaptor_Surface(TopoDS.Face_s(ex.Current()))
        if s.GetType() == GeomAbs_Cylinder:
            c = s.Cylinder(); d = c.Axis().Direction(); p = c.Axis().Location()
            if abs(abs(d.Z()) - 1) < 1e-6 and c.Radius() < 9:
                fb = Bnd_Box(); BRepBndLib.Add_s(TopoDS.Face_s(ex.Current()), fb); f = fb.Get()
                holes.add((round(p.X(), 2), round(p.Y(), 2), round(c.Radius(), 2), round(f[2], 1), round(f[5], 1)))
        ex.Next()
    fn = f"{group}__{nm}".replace(' ', '_').replace('(', '').replace(')', '')
    BRepMesh_IncrementalMesh(shape, 0.1, False, 0.5, True); StlAPI_Writer().Write(shape, f"{outdir}/{fn}.stl")
    out.append({'group': group, 'name': nm, 'file': fn, 'bbox': bb, 'zholes': sorted(holes)})
roots = TDF_LabelSequence(); st.GetFreeShapes(roots)
for top in children(roots.Value(1)):
    tn = name(top); tloc = st.GetLocation_s(top)
    if tn in GROUPS:
        for c in children(top):
            cn = name(c)
            if cn.startswith(WANT_IN_GROUP):
                report(st.GetShape_s(c).Moved(tloc), tn, cn)
    elif tn in ROOT_EXTRUDER:
        report(st.GetShape_s(top), 'root', tn)
json.dump(out, open(f"{outdir}/mounts.json", 'w'), indent=1)
for o in out: print(o['group'], '|', o['name'], o['bbox'])
