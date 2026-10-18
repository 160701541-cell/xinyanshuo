import {writeFileSync, mkdirSync, existsSync} from 'node:fs';
import {resolve} from 'node:path';
import {pathToFileURL} from 'node:url';
import {createHash} from 'node:crypto';

const STYLE = '3D 游戏引擎实时渲染画面，虚幻引擎5品质，PBR 物理材质与真实光照，软阴影与环境光遮蔽，体积光与轻微景深，国风写实场景，色彩自然丰富（青灰石、朱红木、翠绿植被、暖黄灯光），材质细节锐利、纹理清晰';
const PROP_STYLE = '单件游戏道具素材，高清中国古风手绘插画，细致线稿与木石纹理，青灰与深棕低饱和自然配色，暖光从左上来';
const NEG = '不要像素风，不要卡通描边矢量图，不要手绘，不要厚涂插画，不要水彩，不要笔触感，不要插画风，不要扁平色块，不要海报感，不要人物，不要角色，不要UI界面，不要文字，不要水印，不要边框，不要拼贴多格，不要半成品草图';

export const jobs = [
  {
    "id": "plate12_market_3d",
    "subject": "坊市白日长街：镜头站在街中央向街道深处看，两侧连绵木构店铺与挑檐、灯笼与布招（无字），街边七八个摊位与竹筐木桶，青石板路面有水洼反光，街口一棵大槐树，远处山峦与薄雾"
  },
  {
    "id": "plate13_court_3d",
    "subject": "宗门正殿前庭院：镜头站在院中正对大殿，九级石阶通向殿门，殿前朱红立柱与空白石匾，两侧青瓦围墙与石灯，地面斑驳光影与落叶，殿角层叠"
  },
  {
    "id": "plate14_inn_3d",
    "subject": "客栈大堂内部：镜头站在堂中正对长条木柜台与酒坛架，左右各四张方桌条凳，木梁屋顶挂着几盏暖黄灯笼，纸窗透进天光，青砖地面"
  },
  {
    "id": "plate15_bamboo_3d",
    "subject": "黄昏竹林小径：踩实的土石小径向深处延伸，两侧翠竹与蕨草，竹叶缝隙漏下斜射暖光，地面光斑与薄雾"
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
  const dest = resolve(process.argv[2] || 'game-source/apk176-ota177-candidate/hd2d/artgen-batch04');
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
    writeFileSync(out + '.json', JSON.stringify({id: job.id, batch: 'hd2d-artgen-batch04', model: 'Kwai-Kolors/Kolors', file: job.id + '.' + ext, bytes: bytes.length, sha256: createHash('sha256').update(bytes).digest('hex'), status: 'GENERATED_UNAPPROVED', run_url: process.env.RUN_URL || null}, null, 2) + '\n');
    console.log('GENERATED', job.id, bytes.length);
  }
}
if (process.argv[1] && import.meta.url === pathToFileURL(resolve(process.argv[1])).href) main().catch(e => { console.error(e.message); process.exitCode = 1; });
