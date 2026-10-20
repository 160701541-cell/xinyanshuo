import importlib.util,json,tempfile,unittest,zipfile
from pathlib import Path
P=Path(__file__).parent
spec=importlib.util.spec_from_file_location("manager",P/"mod-manager"/"batch_import_v20.py")
m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
class ModManagerTests(unittest.TestCase):
 def make(self,root,name,entries):
  p=root/name
  with zipfile.ZipFile(p,"w") as z:
   for n,v in entries.items():z.writestr(n,v)
  return p
 def test_safe_batch_staging(self):
  with tempfile.TemporaryDirectory() as t:
   root=Path(t)
   p=self.make(root,"a.zip",{"mod.json":json.dumps({"id":"hello","name":"中文模组","game_version":"0.51.4"}),"Code/main.cs":"hello"})
   r=m.batch_import([p],root/"stage")
   self.assertEqual(r[0]["状态"],"已安全暂存")
   self.assertTrue((root/"stage"/"hello"/"Code"/"main.cs").exists())
 def test_traversal_rejected(self):
  with tempfile.TemporaryDirectory() as t:
   root=Path(t);p=self.make(root,"bad.zip",{"../evil":"oops","mod.json":'{"id":"x"}'})
   self.assertEqual(m.inspect(p)["状态"],"拒绝导入")
 def test_version_mismatch(self):
  with tempfile.TemporaryDirectory() as t:
   root=Path(t);p=self.make(root,"v.zip",{"mod.json":'{"id":"x","game_version":"0.49.0"}'})
   self.assertEqual(m.inspect(p)["状态"],"不兼容")
 def test_unknown_is_not_compatible(self):
  with tempfile.TemporaryDirectory() as t:
   root=Path(t);p=self.make(root,"u.zip",{"mod.json":'{"id":"x"}'})
   self.assertEqual(m.inspect(p)["状态"],"兼容性未知")
 def test_conflicts_and_dependencies(self):
  with tempfile.TemporaryDirectory() as t:
   root=Path(t);p=self.make(root,"d.zip",{"mod.json":'{"id":"x","game_version":"0.51.4","dependencies":["need"],"conflicts":["bad"]}'})
   self.assertEqual(m.inspect(p)["状态"],"缺少依赖")
   self.assertEqual(m.inspect(p,installed={"bad":{}})["状态"],"存在冲突")
 def test_reject_overwrite(self):
  with tempfile.TemporaryDirectory() as t:
   root=Path(t);p=self.make(root,"x.zip",{"mod.json":'{"id":"x","game_version":"0.51.4"}'})
   self.assertEqual(m.batch_import([p],root/"s")[0]["状态"],"已安全暂存")
   self.assertEqual(m.batch_import([p],root/"s")[0]["状态"],"拒绝覆盖")
 def test_chinese_catalog(self):
  d=json.loads((P/"localization"/"zh_cn_v20.json").read_text(encoding="utf8"))
  self.assertEqual(d["interface"]["Kingdoms"],"王国列表")
  self.assertEqual(d["interface"]["Mod Manager"],"模组管理器")
if __name__=="__main__":unittest.main()
