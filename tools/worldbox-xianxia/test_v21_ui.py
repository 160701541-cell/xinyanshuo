import unittest
from pathlib import Path
R=Path(__file__).parent
S=(R/"ui"/"ChineseModManagerV21.cs").read_text(encoding="utf8")
O=(R/"nml-observer-v07"/"Code"/"XianxiaObserverV07.cs").read_text(encoding="utf8")
class ChineseModUiTests(unittest.TestCase):
 def test_game_toolbar_launches_manager(self):
  self.assertIn('"中文模组管理器"',O)
  self.assertIn('ChineseModManagerV21.Draw(ui,button,label,box)',O)
 def test_scans_private_directory_only(self):
  self.assertIn('Application.persistentDataPath',S)
  self.assertIn('Directory.GetDirectories(Folder)',S)
  self.assertNotIn('/Android/data/',S)
 def test_does_not_claim_to_install(self):
  self.assertIn('尚未安装或启用',S)
  self.assertNotIn('InstallMod(',S)
 def test_bounds_ui_entries(self):
  self.assertIn('MaxEntries=48',S)
  self.assertIn('Math.Min(Names.Count,6)',S)
if __name__=="__main__":unittest.main()
