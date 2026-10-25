import {readFileSync} from 'node:fs';
import {join} from 'node:path';
import {auditCultivationReadiness} from './cultivation_readiness.mjs';
const root=process.argv[2]||new URL('../campaigns/first-life/',import.meta.url).pathname;
try {
  const state=JSON.parse(readFileSync(join(root,'game_state.json'),'utf8'));
  const index=JSON.parse(readFileSync(join(root,'campaign_index.json'),'utf8'));
  const report=auditCultivationReadiness({state,index});
  process.stdout.write(JSON.stringify(report,null,2)+'\n');
  if(!report.ready) process.exitCode=2;
} catch(error) {
  console.error('BLOCKED:',error.message);
  process.exitCode=1;
}
