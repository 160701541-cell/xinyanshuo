"""Run generated WorldBox materials through real pixel and graph assertions."""
import hashlib,json,sys,tempfile,zipfile
from pathlib import Path
from PIL import Image
sys.path.insert(0,str(Path(__file__).parent))
from material_factory_v35 import catalog_entries,make,package
ROOT=Path(__file__).parent
def main():
 seed=json.loads((ROOT/"catalog_seed.json").read_text(encoding="utf8"))
 assert len(seed["families"])==10
 with tempfile.TemporaryDirectory() as td:
  out=Path(td)/"build";report=make(out)
  items=report["items"];names={i["id"] for i in items}
  assert len(items)>=160,(len(items),"too few generated sprites")
  assert len(items)==len(names)
  assert len(report["recipes"])>=70,"only raw icon graph without actual processing recipes"
  assert {"wbx_copper_coin","wbx_silver_ingot","wbx_gold_ingot","wbx_spirit_stone_low",
          "wbx_qi_herb","wbx_imperial_palace_level3","wbx_wheat_processed"}<=names
  assert set(x["target_tab"] for x in items)=={"nature","creation","noosphere"}
  for recipe in report["recipes"]:
   assert set(recipe["inputs"])<=names,recipe
   assert set(recipe["outputs"])<=names,recipe
   assert all(v>0 for v in recipe["inputs"].values())
  index=(out/"resource_index.tsv").read_text(encoding="utf8").splitlines()
  assert len(index)==len(items)+1,(len(index),len(items))
  assert index[0].split("\t")==["id","name","family","tab","icon"]
  assert len(index[1].split("\t"))==5
  for row in items:
   img=Image.open(out/row["icon"])
   assert img.size==(32,32) and img.mode=="RGBA",(row,img.size,img.mode)
   assert img.getextrema()[3][0]==0,"background must be transparent"
   assert img.getextrema()[3][1]==255,"foreground opaque"
   assert row["atlas_rect"][2:]==[32,32]
  atlas=Image.open(out/report["atlas"])
  assert atlas.width==16*34
  report2=make(Path(td)/"again")
  checksum=hashlib.sha256((out/"resource_atlas.png").read_bytes()).hexdigest()
  checksum2=hashlib.sha256((Path(td)/"again"/"resource_atlas.png").read_bytes()).hexdigest()
  assert checksum==checksum2,"batch generation must be deterministic"
  archive=Path(td)/"v35.zip";package(out,archive)
  with zipfile.ZipFile(archive) as z:
   assert z.testzip() is None
   assert len(z.namelist())>=len(items)+3
   assert all(not n.startswith("/") and ".." not in n.split("/") for n in z.namelist())
 print("PASS_V35_PIXEL_ART_FACTORY","icons",len(items),"recipes",len(report["recipes"]),
       "atlas",atlas.size,"sha256",checksum)
if __name__=="__main__":main()
