import re
import unittest
from pathlib import Path
ROOT=Path(__file__).parent
LOC=ROOT/"localization"
BRIDGE=(LOC/"NativeLocaleBridgeV23.cs").read_text(encoding="utf8")
GLOSS=(LOC/"ChineseMenuGlossaryV23.cs").read_text(encoding="utf8")
HELP=(LOC/"OriginalMenuGuideV22.cs").read_text(encoding="utf8")
OVERLAY=(LOC/"RuntimeChineseOverlayV22.cs").read_text(encoding="utf8")
WORKFLOW=Path(__file__).resolve().parents[2]/".github"/"workflows"/"worldbox-external-mod-lab-v22.yml"
class NativeLocaleTests(unittest.TestCase):
 def test_genuine_nml_chinese_language_identifier(self):
  self.assertIn('"cz"',BRIDGE)
  self.assertIn('NeoModLoader.General.LM',BRIDGE)
  self.assertIn('LocalizedTextManager',BRIDGE)
 def test_does_not_guess_worldbox_keys_or_force_language(self):
  self.assertIn('Member(manager,"_localized_text")',BRIDGE)
  self.assertIn('add.Invoke(null,new object[]{"cz",key,chinese})',BRIDGE)
  self.assertNotIn('setLanguage(',BRIDGE)
  self.assertIn('SkippedExisting++',BRIDGE)
 def test_uses_bounded_il2cpp_enumerator_fallback(self):
  self.assertIn('MaxDictionaryRead=16000',BRIDGE)
  self.assertIn('GetEnumerator',BRIDGE)
  self.assertIn('MaxRegistrations=3000',BRIDGE)
 def test_broad_menu_glossary(self):
  terms=re.findall(r'^\s*\{"([^"]+)","([^"]+)"\},?$',GLOSS,re.M)
  self.assertGreaterEqual(len(terms),500)
  self.assertEqual(len(set(k.lower() for k,v in terms)),len(terms))
  for term in ['Royal Palace','Main Menu','World Laws','Import Files','Upgrade Cost','Emperor','Underworld']:
   self.assertIn(term,dict(terms))
 def test_game_ui_exposes_real_key_registration(self):
  self.assertIn('NativeLocaleBridgeV23.RegisterActualKeys()',HELP)
  self.assertIn('NativeLocaleBridgeV23.ActivateChinese()',HELP)
 def test_remains_non_destructive(self):
  self.assertIn('RuntimeChineseOverlayV22.SetEnabled',HELP)
  self.assertNotIn('Assembly-CSharp.dll',BRIDGE)
  self.assertNotIn('PlayerPrefs.DeleteAll',BRIDGE)
 def test_ci_packages_actual_translator_and_scenario(self):
  ci=WORKFLOW.read_text(encoding="utf8")
  for item in ['NativeLocaleScenarioV23.csproj','ChineseMenuGlossaryV23.cs','NativeLocaleBridgeV23.cs','LocaleTypes.csproj']:
   self.assertIn(item,ci)
if __name__=="__main__":
 unittest.main()
