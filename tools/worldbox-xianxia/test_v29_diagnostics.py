"""Run real JVM diagnostic export behavior with synthetic logs only."""
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT=Path(__file__).parent
class DiagnosticExportTests(unittest.TestCase):
    def test_actual_java_summary_and_full_zip(self):
        javac=shutil.which("javac")
        java=shutil.which("java")
        self.assertTrue(javac and java,"Java JDK required to validate Android diagnostics helper")
        with tempfile.TemporaryDirectory() as td:
            subprocess.run([javac,"-encoding","UTF-8","-source","8","-target","8","-d",td,
                str(ROOT/"private-apk-lab/DiagnosticReport.java"),
                str(ROOT/"tests/DiagnosticReportScenario.java")],check=True,timeout=40)
            result=subprocess.run([java,"-cp",td,
                "com.xinyanshuo.worldbox.lab13.DiagnosticReportScenario"],
                check=True,capture_output=True,text=True,timeout=30)
            self.assertIn("PASS_DIAGNOSTIC_EXPORT",result.stdout)

if __name__=="__main__":unittest.main()
