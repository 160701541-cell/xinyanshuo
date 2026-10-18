import {writeFileSync, mkdirSync, existsSync} from 'node:fs';
import {resolve} from 'node:path';
import {pathToFileURL} from 'node:url';
import {createHash} from 'node:crypto';

const STYLE = '高清中国古风手绘游戏场景原画，厚重笔触与细致线稿，暖金色主光源从左上斜射，冷青色阴影补光，空气中有薄雾与飘落的光尘，色彩浓郁但不脏，层次分明';
const PROP_STYLE = '单件游戏道具素材，高清中国古风手绘插画，细致线稿与木石纹理，青灰与深棕低饱和自然配色，暖光从左上来';
const NEG = '不要像素风，不要低模3D渲染截图，不要卡通描边矢量图，不要人物，不要角色，不要UI界面，不要文字，不要水印，不要边框，不要拼贴多格，不要半成品草图';

export const jobs = [
  {
    "id": "plate04_market_day",
    "subject": "坊市白日长街：两侧密集木构店铺与挑檐，檐下挂布招与幌子（无字），街心摆了七八个摊位，青石板路湿润反光，街口一棵大槐树，行人不见但地上有散落竹篮与货担，远处山影。斜俯视约35度，主体居中偏下"
  },
  {
    "id": "plate05_courtyard_night",
    "subject": "宗门后山庭院夜景：一方青石庭院，中央石桌石凳，四周矮墙与竹丛，檐下两盏暖黄灯笼，月光把地面照成冷蓝，墙头远处露出殿角剪影，地上落着几片叶。斜俯视约35度，主体居中偏下"
  },
  {
    "id": "plate06_mountain_path",
    "subject": "盘山石阶：一条窄石阶向云雾深处盘上山脊，两侧悬崖与苍松，脚下是云海翻涌，晨光从云缝里斜射成一束金色光柱，石阶上有积水。斜俯视约35度，主体居中"
  },
  {
    "id": "plate07_alchemy_room",
    "subject": "宗门丹房内部：一间木构石地面的炼丹房，正中一尊青铜大丹炉冒着青烟，四周药架与陶罐、竹筛，窗棂漏进斜射阳光与光柱浮尘，墙角堆柴。斜俯视约35度，主体居中偏下"
  },
  {
    "id": "prop01_stone_lantern",
    "subject": "一件孤立的中国古代石灯笼道具，方座、立柱、四面灯室、层叠石檐与宝珠顶，暖黄灯光从灯室透出"
  },
  {
    "id": "prop02_market_stall",
    "subject": "一件孤立的中国古代木制集市摊位道具，浅米色粗布篷、四根木柱、木柜台，台面两只竹篮"
  }
];

export function makePrompt(job) {
  if (job.id.startsWith('prop')) {
    return PROP_STYLE + '。' + job.subject + '。纯浅灰色均匀背景，整个画面只有这一件物体，物体完整、四边留空、不接触画面边缘，不出现地面、墙面、阴影投射、其他任何物件。35到45度斜俯视，真实比例，轮廓清晰，无景深虚化。' + NEG + '。这是一张单物件切图，不是场景，不是院落，不是室内。';
  }
  return STYLE + '。' + job.subject + '。斜俯视游戏场景，可用于16:9裁切，水平方向内容延伸、上下可裁，' + NEG + '。场景中绝不出现人和角色。';
}

async function main() {
  const dest = resolve(process.argv[2] || 'game-source/apk176-ota177-candidate/hd2d/artgen-batch02');
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
    writeFileSync(out + '.json', JSON.stringify({id: job.id, batch: 'hd2d-artgen-batch02', model: 'Kwai-Kolors/Kolors', file: job.id + '.' + ext, bytes: bytes.length, sha256: createHash('sha256').update(bytes).digest('hex'), status: 'GENERATED_UNAPPROVED', run_url: process.env.RUN_URL || null}, null, 2) + '\n');
    console.log('GENERATED', job.id, bytes.length);
  }
}
if (process.argv[1] && import.meta.url === pathToFileURL(resolve(process.argv[1])).href) main().catch(e => { console.error(e.message); process.exitCode = 1; });
