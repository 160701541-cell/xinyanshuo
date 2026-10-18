import {writeFileSync, mkdirSync, existsSync} from 'node:fs';
import {resolve} from 'node:path';
import {pathToFileURL} from 'node:url';
import {createHash} from 'node:crypto';

const STYLE = '像素艺术游戏场景，16位机时代的精细像素背景，硬边缘像素块，无抗锯齿，无平滑渐变，有限调色板不超过48色，每个像素块边界清晰，横版RPG的平视场景，细节靠像素密度而不是笔触';
const CAMERA = '机位与人物视线齐平，视线水平，向下俯角3到8度，一点透视，地平线在上三分之一处，前景空地从画面底边延伸到中景，下方三分之一是可站人的平地';
const PALETTE = '配色要同时出现六种色相并各占可辨比例：黛青与石青（瓦顶、远山、冷部阴影）、青灰石板（地面、台阶、墙）、苔绿与竹青（植被）、朱砂与丹漆（柱、门、幡、灯笼）、月白（雾、云、水面）、暖金（灯火、法器）；用像素抖动点阵做过渡，不允许整幅偏黄，不允许整体压暗，不允许模糊';
const NEG = '不要抗锯齿，不要模糊，不要柔光，不要平滑渐变，不要3D渲染，不要照片，不要厚涂，不要水彩，不要油画，不要喷枪，不要景深虚化，不要俯视鸟瞰，不要人物，不要文字招牌，不要印章水印，不要边框拼贴';

export const jobs = [
  {id: 'px01_shanmen', subject: '青石山门与九级台阶，晨光斜射，两侧石灯与松树，远处云海与黛色山脊'},
  {id: 'px02_market', subject: '坊市长街，两侧木构店铺挑檐与素纸灯笼，街边竹筐与摊位，青石板路面，街口老槐树，远处山影'},
  {id: 'px03_court', subject: '宗门正殿广场，重檐大殿与朱红立柱，九级踏跺，两侧青瓦院墙与石灯，落叶与树影'},
  {id: 'px04_bamboo', subject: '竹林小径，午后的斜射光柱，土石小径向深处收拢，两侧翠竹与蕨草'}
];

export function makePrompt(job) {
  return STYLE + '。' + job.subject + '。' + CAMERA + '。' + PALETTE + '。画面中不出现人和动物。' + NEG + '。';
}

async function main() {
  const dest = resolve(process.argv[2] || 'game-source/apk176-ota177-candidate/hd2d/artgen-pixel01');
  mkdirSync(dest, {recursive: true});
  if (!process.env.SILICONFLOW_API_KEY) throw Error('Missing SILICONFLOW_API_KEY; zero generation calls');
  for (const job of jobs) {
    const out = resolve(dest, job.id);
    if (existsSync(out + '.json') && (existsSync(out + '.png') || existsSync(out + '.jpg'))) { console.log('SKIP_EXISTING', job.id); continue; }
    const prompt = makePrompt(job);
    writeFileSync(out + '.prompt.txt', prompt);
    const response = await fetch('https://api.siliconflow.cn/v1/images/generations', {
      method: 'POST',
      headers: {Authorization: 'Bearer ' + process.env.SILICONFLOW_API_KEY, 'Content-Type': 'application/json'},
      body: JSON.stringify({model: 'Kwai-Kolors/Kolors', prompt, image_size: '1024x1024', batch_size: 1}),
      signal: AbortSignal.timeout(180000),
    });
    if (!response.ok) throw Error('Generation ' + job.id + ': HTTP ' + response.status + '; no retry');
    const body = await response.json();
    const url = body.images?.[0]?.url;
    if (!url?.startsWith('https://')) throw Error('Missing HTTPS result for ' + job.id);
    const image = await fetch(url, {signal: AbortSignal.timeout(90000)});
    if (!image.ok) throw Error('Image download failed; no generation retry');
    const bytes = Buffer.from(await image.arrayBuffer());
    const ext = bytes.subarray(0, 8).toString('hex') === '89504e470d0a1a0a' ? 'png' : bytes.subarray(0, 3).toString('hex') === 'ffd8ff' ? 'jpg' : null;
    if (!ext || bytes.length < 30000) throw Error('Invalid image payload for ' + job.id);
    writeFileSync(out + '.' + ext, bytes);
    writeFileSync(out + '.json', JSON.stringify({id: job.id, batch: 'hd2d-artgen-pixel01', model: 'Kwai-Kolors/Kolors', file: job.id + '.' + ext, bytes: bytes.length, sha256: createHash('sha256').update(bytes).digest('hex'), status: 'GENERATED_UNAPPROVED', run_url: process.env.RUN_URL || null}, null, 2) + '\n');
    console.log('GENERATED', job.id, bytes.length);
  }
}
if (process.argv[1] && import.meta.url === pathToFileURL(resolve(process.argv[1])).href) main().catch(e => { console.error(e.message); process.exitCode = 1; });
