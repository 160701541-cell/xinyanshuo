import unittest
from private_signing_gate_v31 import (parse_certificate_sha256,decide_install_path,
    OLD_PACKAGE,ISOLATED_PACKAGE,EXPECTED_OLD_SIGNER)
NEW='20087dc8c210c7c6a35a4492500324f33f36f7c5eb3a77dc62040c21281c400e'
class GateTests(unittest.TestCase):
 def test_real_old_app_same_package_different_key_must_block(self):
  x=decide_install_path(OLD_PACKAGE,EXPECTED_OLD_SIGNER,OLD_PACKAGE,NEW)
  self.assertEqual(x['reason'],'SIGNATURE_CONFLICT')
  self.assertFalse(x['safe_to_update'])
  self.assertEqual(x['recommended'],'PRESERVE_INSTALLED_APP_NO_UNINSTALL')
 def test_valid_old_signature_allows_update_only_after_version_checks(self):
  x=decide_install_path(OLD_PACKAGE,EXPECTED_OLD_SIGNER,OLD_PACKAGE,EXPECTED_OLD_SIGNER)
  self.assertTrue(x['safe_to_update'])
 def test_parallel_namespace_not_inplace_upgrade(self):
  x=decide_install_path(OLD_PACKAGE,EXPECTED_OLD_SIGNER,ISOLATED_PACKAGE,NEW)
  self.assertFalse(x['safe_to_update'])
  self.assertTrue(x['side_by_side_candidate'])
 def test_no_false_positive_signer_proof(self):
  with self.assertRaises(ValueError):parse_certificate_sha256('build passed')
  with self.assertRaises(ValueError):decide_install_path(OLD_PACKAGE,'blah',OLD_PACKAGE,NEW)
if __name__=='__main__':unittest.main()
