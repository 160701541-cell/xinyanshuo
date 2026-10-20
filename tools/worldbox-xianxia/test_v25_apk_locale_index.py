import importlib.util,json,struct,tempfile,unittest,zipfile
from pathlib import Path
ROOT=Path(__file__).parent
MODULE=ROOT/"localization"/"audit_apk_locales_v25.py"
spec=importlib.util.spec_from_file_location("audit_v25",MODULE)
audit=importlib.util.module_from_spec(spec);spec.loader.exec_module(audit)

def named(name):
    data=name.encode("ascii")
    return struct.pack("<I",len(data))+data+b"\x00"*12

class ApkLocaleIndexTests(unittest.TestCase):
 def make(self,folder,names,include=True):
    p=folder/"private.apk"
    with zipfile.ZipFile(p,"w") as z:
        if include:
            b=b"not copyrighted text\x00"*20+b"".join(named(n) for n in names)
            z.writestr(audit.INDEX_PATH,b)
        else:z.writestr("assets/other","data")
    return p
 def test_recognize_existing_builtin_simplified_chinese_and_english(self):
    with tempfile.TemporaryDirectory() as td:
        p=self.make(Path(td),["locales/cz/kingdoms","locales/en/kingdoms",
          "locales/cz/ui_options","locales/en/ui_options","locales/en/ui_tabs",
          "locales/cz/kingdoms"])
        r=audit.inspect(p)
        self.assertEqual(r["原版简体中文资源组数"],2)
        self.assertEqual(r["原版英文资源组数"],3)
        self.assertEqual(r["简中与英文共同存在资源组数"],2)
        self.assertEqual(r["英文有但简中无的资源组名"],["ui_tabs"])
        self.assertEqual(r["语言数量"],2)
 def test_ignore_fabricated_non_length_prefixed_bytes(self):
    with tempfile.TemporaryDirectory() as td:
        p=Path(td)/"x.apk"
        with zipfile.ZipFile(p,"w") as z:
            z.writestr(audit.INDEX_PATH,b"x"*128+b"locales/cz/kingdoms")
        self.assertEqual(audit.inspect(p)["原版简体中文资源组数"],0)
 def test_missing_index_is_not_claimed_as_no_language(self):
    with tempfile.TemporaryDirectory() as td:
        p=self.make(Path(td),[],include=False)
        with self.assertRaisesRegex(ValueError,"不包含预期"):
            audit.inspect(p)
 def test_only_pathnames_not_proprietary_text(self):
    with tempfile.TemporaryDirectory() as td:
        p=self.make(Path(td),["locales/en/kingdoms","locales/cz/kingdoms"])
        out=json.dumps(audit.inspect(p),ensure_ascii=False)
        self.assertIn("仅检查Unity语言资源索引中的名称",out)
        self.assertIn("资源组名称存在≠每条游戏文本已翻译",out)
if __name__=="__main__":unittest.main()
