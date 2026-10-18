import {writeFileSync, mkdirSync, existsSync} from 'node:fs';
import {resolve} from 'node:path';
import {pathToFileURL} from 'node:url';
import {createHash} from 'node:crypto';

const STYLE = '高清中国古风手绘游戏场景原画，厚重笔触与细致线稿，暖金色主光源从左上斜射，冷青色阴影补光，空气中有薄雾与飘落的光尘，色彩浓郁但不脏，层次分明';
const PROP_STYLE = '单件游戏道具素材，高清中国古风手绘插画，细致线稿与木石纹理，青灰与深棕低饱和自然配色，暖光从左上来';
const NEG = '不要像素风，不要低模3D渲染截图，不要卡通描边矢量图，不要人物，不要角色，不要UI界面，不要文字，不要水印，不要边框，不要拼贴多格，不要半成品草图';

export const jobs = [
  {
    "id": "plate08_market_street_day",
    "subject": "坊市白日长街：镜头站在街中央向街道深处看，两侧是连绵的木构店铺与挑檐、布招幌子（无字），街边摆着七八个货摊与竹筐，青石板路面湿润反光并在纵深方向收拢，街口一棵大槐树，远处山影与薄雾"
  },
  {
    "id": "plate09_sect_courtyard_day",
    "subject": "宗门正殿前庭院：镜头站在院中正对大殿，一段九级石阶通向殿门，殿前两根朱红立柱与一块空白石匾，两侧青瓦围墙与石灯，地面满是斑驳光影与落叶，远处殿角层叠"
  },
  {
    "id": "plate10_inn_interior",
    "subject": "客栈大堂内部：镜头站在堂中，正对长条木柜台与酒坛架，左右各摆四张方桌条凳，房梁木构、纸窗透进暖光与光柱浮尘，地面是青砖"
  },
  {
    "id": "plate11_night_street_low",
    "subject": "雨夜宗门石街：镜头站在街心，两侧深色木构廊柱挑檐，檐下挂一排暖黄灯笼，湿石板反射橙红灯光与雨丝，远处雾里一盏孤灯"
  },
  {
    "id": "prop03_flag_pole",
    "subject": "一件孤立的中国古代木旗杆道具，深棕木柱、石质夹杆座、顶端悬一面褪色布幡（无字），幡布边缘磨损"
  },
  {
    "id": "prop04_clay_jar_stack",
    "subject": "一件孤立的中国古代陶缸堆道具，三只粗陶大缸叠放在木托盘上，缸口盖竹编盖，陶面有釉痕与裂纹"
  }
];

export function makePrompt(job) {
  const isProp = job.id.startsWith('prop');
  const CAMERA = '第三人称跟随视角构图，镜头高度约与人物视线齐平，视线几乎水平、向下俯角不超过10度，地平线位于画面上部三分之一处，空地面从画面底边一直延伸到中远处并在纵深方向自然收拢，画面下方三分之一是可以站人的空地';
  if (isProp) {
    return PROP_STYLE + '。' + job.subject + '。纯浅灰色均匀背景，整个画面只有这一件物体，物体完整、四边留空、不接触画面边缘，35到45度斜俯视可见顶面与正面，真实比例，清晰完整轮廓，无景深虚化，无地面无墙面无投影。这是一张单物件切图，不是场景，不是院落，不是室内。' + NEG + '。不要院落、房屋、树木、山水、人物。';
  }
  return STYLE + '。' + job.subject + '。' + CAMERA + '。画面中绝不出现人和角色。' + NEG + '。不要俯视，不要鸟瞰，不要航拍，不要高角度俯拍，不要屋顶俯视地图视角。';
}

async function main() {
  const dest = resolve(process.argv[2] || 'game-source/apk176-ota177-candidate/hd2d/artgen-batch03');
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
    writeFileSync(out + '.json', JSON.stringify({id: job.id, batch: 'hd2d-artgen-batch03', model: 'Kwai-Kolors/Kolors', file: job.id + '.' + ext, bytes: bytes.length, sha256: createHash('sha256').update(bytes).digest('hex'), status: 'GENERATED_UNAPPROVED', run_url: process.env.RUN_URL || null}, null, 2) + '\n');
    console.log('GENERATED', job.id, bytes.length);
  }
}
if (process.argv[1] && import.meta.url === pathToFileURL(resolve(process.argv[1])).href) main().catch(e => { console.error(e.message); process.exitCode = 1; });
