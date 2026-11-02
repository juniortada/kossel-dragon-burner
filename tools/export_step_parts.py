# Export the hotend mounts and the bowden mount placed in Dragon_Burner_v0.2_v8.step.
import sys
from OCP.STEPCAFControl import STEPCAFControl_Reader
from OCP.XCAFDoc import XCAFDoc_DocumentTool
from OCP.TDocStd import TDocStd_Document
from OCP.TCollection import TCollection_ExtendedString
from OCP.TDF import TDF_LabelSequence, TDF_Label
from OCP.TDataStd import TDataStd_Name
from OCP.StlAPI import StlAPI_Writer
from OCP.BRepMesh import BRepMesh_IncrementalMesh
doc = TDocStd_Document(TCollection_ExtendedString("doc"))
r = STEPCAFControl_Reader(); r.SetNameMode(True); r.ReadFile(sys.argv[1]); r.Transfer(doc)
st = XCAFDoc_DocumentTool.ShapeTool_s(doc.Main())
def name(l):
    n = TDataStd_Name()
    return n.Get().ToExtString().rsplit(':', 1)[0] if l.FindAttribute(TDataStd_Name.GetID_s(), n) else "?"
def children(l):
    lab = l
    if st.IsReference_s(l):
        lab = TDF_Label(); st.GetReferredShape_s(l, lab)
    comps = TDF_LabelSequence()
    if st.IsAssembly_s(lab): st.GetComponents_s(lab, comps)
    return [comps.Value(i) for i in range(1, comps.Length() + 1)]
def export(l, nm):
    shp = st.GetShape_s(l)
    BRepMesh_IncrementalMesh(shp, 0.1, False, 0.5, True)
    StlAPI_Writer().Write(shp, f"{sys.argv[2]}/{nm}.stl"); print('wrote', nm)
roots = TDF_LabelSequence(); st.GetFreeShapes(roots)
for top in children(roots.Value(1)):
    if name(top) == 'Sherpa_Micro_Mounts':
        for c in children(top):
            export(c, name(c).replace(' ', '_').replace('(', '').replace(')', ''))
    if name(top) == 'Bowden_Mount (1)':
        export(top, 'Bowden_Mount_1')
