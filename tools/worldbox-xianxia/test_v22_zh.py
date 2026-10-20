import unittest
from pathlib import Path
R=Path(__file__).parent
L=(R/"localization"/"ChineseLocalizationV22.cs").read_text(encoding="utf8")
M=(R/"ui"/"ChineseModManagerV21.cs").read_text(encoding="utf8")
class ChineseTranslationTests(unittest.TestCase):
 def test_game_kingdom_and_diplomacy_terms(self):
  for item in ['{"Kingdoms","王国列表"}','{"Diplomacy","外交"}','{"Population","人口"}','{"Traits","特质"}']:
   self.assertIn(item,L)
 def test_mod_manager_terms(self):
  for item in ['{"Mod Manager","模组管理器"}','{"Dependencies","依赖"}','{"Conflicts","冲突"}']:
   self.assertIn(item,L)
 def test_custom_override_is_opt_in_private(self):
  self.assertIn("Application.persistentDataPath",L)
  self.assertIn("zh_cn_overrides.txt",L)
  self.assertIn("UserTerms.TryGetValue(original,out translated)",L)
 def test_ui_can_import_glossary(self):
  self.assertIn("ChineseLocalizationV22.LoadUserTranslations()",M)
 def test_no_game_assets_modified(self):
  self.assertNotIn("Assembly-CSharp.dll",L)
  self.assertNotIn("PlayerPrefs.DeleteAll",L)
if __name__=="__main__":unittest.main()
