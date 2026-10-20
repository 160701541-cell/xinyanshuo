"""Tests that the Chinese/English localization files are actually installed
under NML's auto-discovery Locales folder for both Android package variants.
Does not load WorldBox or redistribute the commercial APK.
"""
import json
import struct
import tempfile
import unittest
import zipfile
from pathlib import Path
from package_android_compiled_mod import pack,ROOT as NML_ROOT,UID
from package_android_mono_source import create,ROOT as MONO_ROOT

HERE=Path(__file__).resolve().parent
LOCALES=HERE/"localization"/"nml-locales"

class AutoLocaleTests(unittest.TestCase):
 def test_both_language_packs_valid_and_same_keys(self):
  cz=json.loads((LOCALES/"cz.json").read_text(encoding="utf8"))
  en=json.loads((LOCALES/"en.json").read_text(encoding="utf8"))
  self.assertEqual(set(cz),set(en))
  self.assertGreaterEqual(len(cz),30)
  self.assertEqual(cz["xinyanshuo.wb.mod_manager"],"中文模组管理器")
  self.assertEqual(cz["xinyanshuo.wb.one_tap_chinese"],"一键选择简中")
  self.assertTrue(all(k.startswith("xinyanshuo.wb.") for k in cz))
 def test_compiled_includes_locale_dir_and_checksums(self):
  with tempfile.TemporaryDirectory() as td:
   d=Path(td)
   dll=bytearray(4096);dll[:2]=b"MZ";struct.pack_into("<I",dll,0x3c,0x80);dll[0x80:0x84]=b"PE\x00\x00"
   (d/"own.dll").write_bytes(dll)
   (d/"mod.json").write_text(json.dumps({"name":"NML test","GUID":UID,"author":"test",
    "version":"0.25","description":"test","ModType":1,"targetGameBuild":725}),encoding="utf8")
   out=d/"compiled.zip"
   pack(d/"own.dll",d/"mod.json",out,LOCALES)
   with zipfile.ZipFile(out) as z:
    names=z.namelist()
    self.assertEqual(len(names),6)
    for lang in ("cz","en"):
     self.assertIn(f"{NML_ROOT}/Locales/{lang}.json",names)
     self.assertEqual(json.loads(z.read(f"{NML_ROOT}/Locales/{lang}.json")),
                      json.loads((LOCALES/(lang+".json")).read_text(encoding="utf8")))
    self.assertEqual(z.testzip(),None)
 def test_legacy_source_includes_locales_but_no_foreign_dll(self):
  with tempfile.TemporaryDirectory() as td:
   d=Path(td)
   (d/"observer.cs").write_text(
    "class MyMod:BasicMod<MyMod>{void OnModLoad(){} void Test(){World.world.GetTile(0,0);}}",
    encoding="utf8")
   (d/"mod.json").write_text(json.dumps({"GUID":UID,"ModType":1,"name":"test"}),encoding="utf8")
   out=d/"mono.zip"
   create(d/"observer.cs",d/"mod.json",out,(),LOCALES)
   with zipfile.ZipFile(out) as z:
    files=z.namelist()
    for lang in ("cz","en"):
     self.assertIn(f"{MONO_ROOT}/Locales/{lang}.json",files)
    self.assertNotIn(f"{MONO_ROOT}/{UID}.dll",files)
    self.assertEqual(z.testzip(),None)
 def test_reject_untrusted_keys_and_broken_locale_json(self):
  with tempfile.TemporaryDirectory() as td:
   d=Path(td)
   (d/"cz.json").write_text('{"foreign.othermod.label":"伪造"}',encoding="utf8")
   (d/"en.json").write_text('{"xinyanshuo.wb.valid":"Fine"}',encoding="utf8")
   dll=bytearray(4096);dll[:2]=b"MZ";struct.pack_into("<I",dll,0x3c,0x80);dll[0x80:0x84]=b"PE\x00\x00"
   (d/"file.dll").write_bytes(dll)
   (d/"mod.json").write_text(json.dumps({"name":"test","GUID":UID,"author":"test","version":"0.25",
    "description":"test","ModType":1,"targetGameBuild":725}),encoding="utf8")
   with self.assertRaises(ValueError):
    pack(d/"file.dll",d/"mod.json",d/"invalid.zip",d)
 def test_csharp_ui_actually_uses_packed_nml_labels(self):
  cs=(HERE/"nml-observer-v07"/"Code"/"XianxiaObserverV07.cs").read_text()
  guide=(HERE/"localization"/"OriginalMenuGuideV22.cs").read_text()
  manager=(HERE/"ui"/"ChineseModManagerV21.cs").read_text()
  self.assertIn('OwnLocaleLabelsV25.Get("mod_manager"',cs)
  self.assertIn('OwnLocaleLabelsV25.Get("one_tap_chinese"',guide)
  self.assertIn('OwnLocaleLabelsV25.Get("mod_reload"',manager)
if __name__=="__main__": unittest.main()
