import importlib.util
from pathlib import Path
import struct
import unittest

path=Path(__file__).parent/'private-apk-lab/clone_resource_table.py'
spec=importlib.util.spec_from_file_location('resource_clone',path)
module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module)


def fixture(name='com.mkarpenko.worldbox',copies=1):
    package=bytearray(304)
    struct.pack_into('<HHII',package,0,0x200,288,len(package),0x7f)
    encoded=name.encode('utf-16le');package[12:12+len(encoded)]=encoded
    package[288:]=b'0123456789abcdef'
    return struct.pack('<HHII',2,12,12+len(package)*copies,copies)+package*copies


class ResourceIdentityTests(unittest.TestCase):
    def test_only_fixed_package_name_field_changes(self):
        before=fixture();after=module.patch_resource_table(before)
        self.assertEqual(len(before),len(after))
        self.assertEqual(before[:24],after[:24])
        self.assertEqual(before[280:],after[280:])
        self.assertEqual(after[24:280].decode('utf-16le').split('\0')[0],'com.xinyanshuo.worldbox.lab13')
        self.assertEqual(struct.unpack_from('<I',after,20)[0],0x7f)

    def test_rejects_missing_duplicate_and_oversized_identity(self):
        for data,new in [(fixture('other'),'ok'),(fixture(copies=2),'ok'),(fixture(),'x'*128)]:
            with self.assertRaises(ValueError):module.patch_resource_table(data,new=new)

    def test_rejects_truncated_table(self):
        with self.assertRaises(ValueError):module.patch_resource_table(fixture()[:-1])


if __name__=='__main__':unittest.main()
