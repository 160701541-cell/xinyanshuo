"""Calibrator regression: quality criteria must resist missing, fake and failing evidence."""
import copy
import json
from pathlib import Path
import unittest
from tune_data import TuneError, calibrate, validate_contract, propose_tuning

CONTRACT=Path(__file__).resolve().parent.parent/'data/tuning/engineering_contract.v1.json'
SHA='1'*40
CHECKSUM='a'*64

class TuningTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.contract=json.loads(CONTRACT.read_text(encoding='utf-8'))

    def record(self,domain,origin,metric,seconds=900):
        return {'domain':domain,'origin':origin,'commit':SHA,
                'proof_sha256':[CHECKSUM],'device':'test-identity-for-parser-only',
                'sample_seconds':seconds,'metrics':metric}

    def perfect_metrics(self,domain):
        return {k:(v['max'] if 'max' in v else v['min'])
                for k,v in self.contract['gates'][domain]['metrics'].items()}

    def evidence(self,all_domains=True):
        records=[]
        for domain,gate in self.contract['gates'].items():
            if all_domains or domain=='logic':
                records.append(self.record(domain,gate['require_source'],
                                           self.perfect_metrics(domain)))
        return {'schema':1,'records':records,'art_review':{
            'approved':True,'reviewer':'independent-reviewer-not-verified',
            'reference_sha256':CHECKSUM,'actual_frame_sha256':CHECKSUM}}

    def test_contract_valid(self):
        self.assertIsNone(validate_contract(self.contract))

    def test_missing_all_observations_blocks(self):
        report=calibrate(self.contract,{'schema':1,'records':[]})
        self.assertEqual(report['status'],'BLOCKED_OR_FAIL')
        self.assertFalse(report['release_allowed'])
        self.assertTrue(all(report['quality_gates'][k]['state']=='BLOCKED'
                            for k in self.contract['gates']))

    def test_untrusted_simulated_source_rejected(self):
        fake=self.record('performance','synthetic',
                         self.perfect_metrics('performance'))
        r=calibrate(self.contract,{'schema':1,'records':[fake]})
        self.assertEqual(r['quality_gates']['performance']['state'],'BLOCKED')

    def test_performance_less_than_15min_blocks(self):
        e=self.evidence()
        perf=next(x for x in e['records'] if x['domain']=='performance')
        perf['sample_seconds']=60
        r=calibrate(self.contract,e)
        self.assertEqual(r['quality_gates']['performance']['state'],'BLOCKED')

    def test_actual_degraded_perf_blocks_and_creates_candidate(self):
        e=self.evidence()
        perf=next(x for x in e['records'] if x['domain']=='performance')
        perf['metrics']['triangle_count_p95']=300000
        report=calibrate(self.contract,e)
        self.assertEqual(report['quality_gates']['performance']['state'],'FAIL')
        candidate=report['proposed_overrides']['render.lod_distance_m']
        self.assertLess(candidate['candidate'],candidate['old'])
        self.assertFalse(candidate['automatically_applied_to_game'])

    def test_actual_touch_conflict_blocks_and_suggests_separation(self):
        e=self.evidence()
        control=next(x for x in e['records'] if x['domain']=='controls')
        control['metrics']['input_conflicts']=4
        report=calibrate(self.contract,e)
        self.assertEqual(report['quality_gates']['controls']['state'],'FAIL')
        self.assertGreater(report['proposed_overrides']['controls.right_touch_zone_start']['candidate'],
                           .52)

    def test_missing_metrics_blocks_not_pass(self):
        e=self.evidence()
        perf=next(x for x in e['records'] if x['domain']=='performance')
        del perf['metrics']['crashes']
        r=calibrate(self.contract,e)
        self.assertEqual(r['quality_gates']['performance']['state'],'BLOCKED')

    def test_human_visual_approval_separate(self):
        e=self.evidence()
        e['art_review']={'approved':False}
        result=calibrate(self.contract,e)
        self.assertEqual(result['quality_gates']['visual']['state'],'PASS')
        self.assertEqual(result['quality_gates']['art']['state'],'BLOCKED')
        self.assertFalse(result['release_allowed'])

    def test_even_all_claimed_green_cannot_sign(self):
        r=calibrate(self.contract,self.evidence())
        self.assertEqual(r['status'],'PASS')
        self.assertFalse(r['release_allowed'])

    def test_cheat_on_minimum_frame_time_detected(self):
        c=copy.deepcopy(self.contract)
        c['policy']['unknown_evidence']='IGNORE'
        with self.assertRaisesRegex(TuneError,'weak_or_untrusted'):
            calibrate(c,self.evidence())

    def test_performance_limit_not_modified_by_suggestion(self):
        c=copy.deepcopy(self.contract)
        before=json.dumps(c,sort_keys=True)
        _=propose_tuning(c,{'performance':{'state':'FAIL','reason':['threshold_violation:fps_p05']},
                            'controls':{'state':'BLOCKED','reason':[]}})
        self.assertEqual(json.dumps(c,sort_keys=True),before)

    def test_malformed_numbers_rejected(self):
        c=copy.deepcopy(self.contract)
        c['tuning_parameters']['render.vegetation_density']['step']=float('nan')
        with self.assertRaisesRegex(TuneError,'invalid_numeric'):
            validate_contract(c)

    def test_invented_approval_receipt_not_enough_for_signed_release(self):
        e=self.evidence()
        e['art_review']['approved']=True
        r=calibrate(self.contract,e)
        self.assertFalse(r['release_allowed'])

if __name__=='__main__':
    unittest.main()
