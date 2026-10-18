import {writeFileSync, mkdirSync, existsSync} from 'node:fs';
import {resolve} from 'node:path';
import {pathToFileURL} from 'node:url';
import {createHash} from 'node:crypto';

// 2.5D 场景底板与道具：全部自产（SiliconFlow / Kwai-Kolors），风格锁在“国风手绘厚涂 + 强暖光”。
const STYLE = '高清中国古风手绘游戏场景原画，厚重笔触与细致线稿，暖金色主光源从左上斜射，冷青色阴影补光，空气中有薄雾与飘落的光尘，色彩浓郁但不脏，层次分明';
const NEG = '不要像素风，不要低模3D渲染截图，不要卡通描边矢量图，不要人物，不要角色，不要UI界面，不要文字，不要水印，不要边框，不要拼贴多格，不要半成品草图';

export const jobs = [
  {id: 'plate01_shanmen_day', size: '1024x1024', subject: '青岚宗山门广场：正中一座厚重青石牌坊山门，匾额为空白石匾，两侧延展青瓦围墙与石阶踏跺，广场铺着不规则青石板，墙根几丛野草，左右各一株老松，远处层叠山峦与薄雾。斜俯视约35度，主体居中偏下，画面上三分之一留给远山与天空，空场景'},
  {id: 'plate02_bamboo_dusk', size: '1024x1024', subject: '黄昏竹林小径：一条被踩实的黄土小径向画面深处延伸，两侧密生翠竹与低矮蕨草，竹叶缝隙漏下斜射的暖金色夕光，地面有斑驳光斑与薄雾，远处竹影渐隐。斜俯视约35度，主体居中，画面上方留出竹林顶部，空场景'},
  {id: 'plate03_night_lantern_street', size: '1024x1024', subject: '雨夜宗门石街：湿漉漉的青石板反射橙红灯笼光，两侧是深色木构廊柱与挑檐，檐下挂一排暖黄灯笼，街心一座小型石灯台，雨丝与地面水光倒影，远处雾气中一盏孤灯。斜俯视约35度，主体居中偏下，空场景'},
  {id: 'prop01_stone_lantern', size: '1024x1024', subject: '一座中国古代石灯笼，青灰花岗岩石料，方形基座、雕花立柱、四面灯室与层叠石檐，灯室内透出暖黄光，顶部宝珠。纯浅灰色空白背景，单一完整物件居中，四周留空'},
  {id: 'prop02_market_stall', size: '1024x1024', subject: '一座中国古代小型木集市摊位，浅米色粗布篷、深棕木立柱与木柜台，台面摆两只竹篮与一叠粗陶碗，篷布边缘有磨损布边，完整独立摊位。纯浅灰色空白背景，单一完整物件居中，四周留空'},
  {id: 'prop03_incense_burner', size: '1024x1024', subject: '一尊中国古代青铜三足香炉，炉盖有镂空缠枝纹与宝珠钮，双立耳，炉腹铸云雷纹，铜绿与暗金交错，三足稳立，炉内逸出一缕青烟。纯浅灰色空白背景，单一完整物件居中，四周留空'},
];

export function makePrompt(job) {
  const isProp = job.id.startsWith('prop');
  const tail = isProp
    ? '35到45度斜俯视可见顶面与正面，真实比例，清晰完整轮廓，无景深虚化。' + NEG + '不要院落、房屋、树木、山水、人物、地面铺装。不是场景图，不是整套物件。'
    : '斜俯视游戏场景，可用于16:9裁切，水平方向内容延伸、上下可裁，画面无遮挡主体，' + NEG + '。场景中绝不出现人和角色。';
  return STYLE + '。' + job.subject + '。' + tail;
}

async function main() {
  const dest = resolve(process.argv[2] || 'game-source/apk176-ota177-candidate/hd2d/artgen-batch01');
  mkdirSync(dest, {recursive: true});
  if (!process.env.SILICONFLOW_API_KEY) throw Error('Missing SILICONFLOW_API_KEY; zero generation calls');
  for (const job of jobs) {
    const out = resolve(dest, job.id);
    if (existsSync(out + '.json') && (existsSync(out + '.png') || existsSync(out + '.jpg'))) { console.log('SKIP_EXISTING', job.id); continue; }
    const prompt = makePrompt(job);
    writeFileSync(out + '.prompt.txt', prompt);
    writeFileSync(out + '.request.json', JSON.stringify({id: job.id, status: 'REQUEST_STARTED', at: new Date().toISOString()}));
    const response = await fetch('https://api.siliconflow.cn/v1/images/generations', {
      method: 'POST',
      headers: {Authorization: 'Bearer ' + process.env.SILICONFLOW_API_KEY, 'Content-Type': 'application/json'},
      body: JSON.stringify({model: 'Kwai-Kolors/Kolors', prompt, image_size: job.size, batch_size: 1}),
      signal: AbortSignal.timeout(180000),
    });
    if (!response.ok) throw Error('Generation ' + job.id + ': HTTP ' + response.status + '; no retry');
    const url = (await response.json()).images?.[0]?.url;
    if (!url?.startsWith('https://')) throw Error('Missing HTTPS result for ' + job.id);
    const image = await fetch(url, {signal: AbortSignal.timeout(90000)});
    if (!image.ok) throw Error('Image download failed; no generation retry');
    const bytes = Buffer.from(await image.arrayBuffer());
    const ext = bytes.subarray(0, 8).toString('hex') === '89504e470d0a1a0a' ? 'png' : bytes.subarray(0, 3).toString('hex') === 'ffd8ff' ? 'jpg' : null;
    if (!ext || bytes.length < 30000) throw Error('Invalid image payload for ' + job.id);
    writeFileSync(out + '.' + ext, bytes);
    writeFileSync(out + '.json', JSON.stringify({id: job.id, batch: 'hd2d-artgen-batch01', model: 'Kwai-Kolors/Kolors', provider: 'SiliconFlow /v1/images/generations', file: job.id + '.' + ext, bytes: bytes.length, sha256: createHash('sha256').update(bytes).digest('hex'), status: 'GENERATED_UNAPPROVED', run_url: process.env.RUN_URL || null}, null, 2) + '\n');
    console.log('GENERATED', job.id, bytes.length);
  }
}
if (process.argv[1] && import.meta.url === pathToFileURL(resolve(process.argv[1])).href) main().catch(e => { console.error(e.message); process.exitCode = 1; });
