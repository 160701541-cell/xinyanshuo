import {readFileSync,writeFileSync,existsSync} from 'node:fs';
import {join} from 'node:path';
import {inspect,checkpoint} from './campaign_guard.mjs';

export function restore(root) {
  const names=['state_core.json','state_world.json','family.json','initial_rolls_public.json'];
  for(const name of names)if(!existsSync(join(root,name)))throw Error('缺档案：'+name);
  const [core,world,family,rolls]=names.map(name=>JSON.parse(readFileSync(join(root,name),'utf8')));
  const state={...core,...world,family,initial_rolls_public:rolls};
  const path=join(root,'game_state.json');
  if(existsSync(path)) {
    const existing=JSON.parse(readFileSync(path,'utf8'));
    if(JSON.stringify(existing)!==JSON.stringify(state))
      throw Error('完整状态与拆分原始档冲突：拒绝覆盖');
  } else writeFileSync(path,JSON.stringify(state,null,2)+'\n');
  return state;
}
const root=process.argv[3]||new URL('../campaigns/first-life/',import.meta.url).pathname;
if(process.argv[1]?.endsWith('restore_campaign.mjs')){
  try {
    const state=restore(root);
    const report=process.argv[2]==='checkpoint'?checkpoint(root):inspect(root);
    console.log(JSON.stringify({ok:true,player:state.player.name,turns:report.turns,full_state_verified:report.full_state_verified,checkpoint:report.created||false},null,2));
  } catch(error) {console.error('BLOCKED:',error.message);process.exitCode=1;}
}
