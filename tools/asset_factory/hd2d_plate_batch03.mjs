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
    "subject": "\u574a\u5e02\u767d\u65e5\u957f\u8857\uff1a\u955c\u5934\u7ad9\u5728\u8857\u4e2d\u592e\u5411\u8857\u9053\u6df1\u5904\u770b\uff0c\u4e24\u4fa7\u662f\u8fde\u7ef5\u7684\u6728\u6784\u5e97\u94fa\u4e0e\u6311\u6a90\u3001\u5e03\u62db\u5e4c\u5b50\uff08\u65e0\u5b57\uff09\uff0c\u8857\u8fb9\u6446\u7740\u4e03\u516b\u4e2a\u8d27\u644a\u4e0e\u7af9\u7b50\uff0c\u9752\u77f3\u677f\u8def\u9762\u6e7f\u6da6\u53cd\u5149\u5e76\u5728\u7eb5\u6df1\u65b9\u5411\u6536\u62e2\uff0c\u8857\u53e3\u4e00\u68f5\u5927\u69d0\u6811\uff0c\u8fdc\u5904\u5c71\u5f71\u4e0e\u8584\u96fe"
  },
  {
    "id": "plate09_sect_courtyard_day",
    "subject": "\u5b97\u95e8\u6b63\u6bbf\u524d\u5ead\u9662\uff1a\u955c\u5934\u7ad9\u5728\u9662\u4e2d\u6b63\u5bf9\u5927\u6bbf\uff0c\u4e00\u6bb5\u4e5d\u7ea7\u77f3\u9636\u901a\u5411\u6bbf\u95e8\uff0c\u6bbf\u524d\u4e24\u6839\u6731\u7ea2\u7acb\u67f1\u4e0e\u533e\u989d\uff08\u7a7a\u767d\u77f3\u533e\uff09\uff0c\u4e24\u4fa7\u9752\u74e6\u56f4\u5899\u4e0e\u77f3\u706f\uff0c\u5730\u9762\u6ee1\u662f\u6591\u9a73\u5149\u5f71\u4e0e\u843d\u53f6\uff0c\u8fdc\u5904\u6bbf\u89d2\u5c42\u53e0"
  },
  {
    "id": "plate10_inn_interior",
    "subject": "\u5ba2\u6808\u5927\u5802\u5185\u90e8\uff1a\u955c\u5934\u7ad9\u5728\u5802\u4e2d\uff0c\u6b63\u5bf9\u957f\u6761\u6728\u67dc\u53f0\u4e0e\u9152\u575b\u67b6\uff0c\u5de6\u53f3\u5404\u6446\u56db\u5f20\u65b9\u684c\u6761\u51f3\uff0c\u623f\u6881\u6728\u6784\u3001\u7eb8\u7a97\u900f\u8fdb\u6696\u5149\u4e0e\u5149\u67f1\u6d6e\u5c18\uff0c\u5730\u9762\u662f\u9752\u7816"
  },
  {
    "id": "plate11_night_street_low",
    "subject": "\u96e8\u591c\u5b97\u95e8\u77f3\u8857\uff1a\u955c\u5934\u7ad9\u5728\u8857\u5fc3\uff0c\u4e24\u4fa7\u6df1\u8272\u6728\u6784\u5eca\u67f1\u6311\u6a90\uff0c\u6a90\u4e0b\u6302\u4e00\u6392\u6696\u9ec4\u706f\u7b3c\uff0c\u6e7f\u77f3\u677f\u53cd\u5c04\u6a59\u7ea2\u706f\u5149\u4e0e\u96e8\u4e1d\uff0c\u8fdc\u5904\u96fe\u91cc\u4e00\u76cf\u5b64\u706f"
  },
  {
    "id": "prop03_flag_pole",
    "subject": "\u4e00\u4ef6\u5b64\u7acb\u7684\u4e2d\u56fd\u53e4\u4ee3\u6728\u65d7\u6746\u9053\u5177\uff0c\u6df1\u68d5\u6728\u67f1\u3001\u77f3\u8d28\u5939\u6746\u5ea7\u3001\u9876\u7aef\u60ac\u4e00\u9762\u892a\u8272\u5e03\u5e61\uff08\u65e0\u5b57\uff09\uff0c\u5e61\u5e03\u8fb9\u7f18\u78e8\u635f"
  },
  {
    "id": "prop04_clay_jar_stack",
    "subject": "\u4e00\u4ef6\u5b64\u7acb\u7684\u4e2d\u56fd\u53e4\u4ee3\u9676\u7f38\u5806\u9053\u5177\uff0c\u4e09\u53ea\u7c97\u9676\u5927\u7f38\u53e0\u653e\u5728\u6728\u6258\u76d8\u4e0a\uff0c\u7f38\u53e3\u76d6\u7af9\u7f16\u76d6\uff0c\u9676\u9762\u6709\u91c9\u75d5\u4e0e\u88c2\u7eb9"
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

if (process.argv[1] && import.meta.url === pathToFileURL(resolve(process.argv[1])).href) main().catch(e => { console.error(e.message); process.exitCode = 1; });
