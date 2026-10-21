// 小人素材：沿用《苍岚》时期已经验过的那一套 CC0 素材（不是另画一套）。
// 走图 48×48、3 列 ×4 行（下 / 左 / 右 / 上，每向 3 帧）；头像用汉服人物整图裁头部。
export const WALK_DIRS = ['down', 'left', 'right', 'up'];
export const FRAME_PX = 48;
export const SHEETS = {
  hero: 'people/hero_walk.png',        // 官差、捕快、军士
  farmer: 'people/farmer_walk.png',    // 农户、渔民、脚夫
  merchant: 'people/merchant_walk.png', // 商贩、掌柜、匠人
  woodsman: 'people/woodsman_walk.png', // 山民、修士、游侠
};
export const PORTRAITS = { male: 'people/han_male.png', female: 'people/han_female.png' };

const RULES = [
  [/官|吏|捕|兵|将|军|卒|差|衙/, 'hero'],
  [/商|贩|掌柜|伙计|账|牙|行商|摊/, 'merchant'],
  [/农|渔|樵|船|脚|佃|猎|牧|田/, 'farmer'],
  [/修|道|僧|剑|宗|观|散修|真人/, 'woodsman'],
];

export function sheetFor(person) {
  const job = (person && (person.job || person.role)) || '';
  for (const [re, sheet] of RULES) if (re.test(job)) return sheet;
  return 'woodsman';
}

/** 朝向：dx/dy 是世界坐标下的位移；静止时用 person.face，缺省朝下。 */
export function dirFor(dx, dy, fallback) {
  if (dx === undefined || (dx === 0 && dy === 0)) return fallback || 'down';
  if (Math.abs(dx) >= Math.abs(dy)) return dx < 0 ? 'left' : 'right';
  return dy < 0 ? 'up' : 'down';
}

export function rowOf(dir) {
  const i = WALK_DIRS.indexOf(dir);
  return i < 0 ? 0 : i;
}

/** 走路动画帧：站着时停在中间帧，走起来循环 0,1,2。 */
export function stepOf(moving, clock) {
  if (!moving) return 1;
  return Math.floor((clock || 0) / 170) % 3;
}

export class PeopleBank {
  constructor(base = '') { this.base = base; this.images = {}; this.ready = false; }

  async load() {
    const jobs = Object.entries(SHEETS).map(async ([k, path]) => {
      const img = await loadImage(this.base + path);
      this.images[k] = img;
    });
    const faces = Object.entries(PORTRAITS).map(async ([k, path]) => {
      const img = await loadImage(this.base + path);
      this.images['portrait_' + k] = img;
    });
    await Promise.all([...jobs, ...faces]).catch(() => {});
    this.ready = Object.keys(this.images).length >= 4;
    return this.ready;
  }

  sheet(person) { return this.images[sheetFor(person)] || null; }
  portrait(person) {
    const sex = person && person.sex === '女' ? 'female' : 'male';
    return this.images['portrait_' + sex] || this.images.portrait_male || null;
  }

  /** 画一个行走小人：脚底落在 (x,y)，总高 h 像素。 */
  draw(ctx, person, x, y, h, dir = 'down', step = 1) {
    const img = this.sheet(person);
    if (!img) return false;
    const sx = step * FRAME_PX, sy = rowOf(dir) * FRAME_PX;
    const w = h * 0.75, hh = h;
    ctx.imageSmoothingEnabled = false;
    ctx.drawImage(img, sx, sy, FRAME_PX, FRAME_PX, x - w / 2, y - hh, w, hh);
    ctx.imageSmoothingEnabled = true;
    return true;
  }

  /** 画一个头像：将领、修士在世界图上是头像，不是小人。 */
  drawPortrait(ctx, person, x, y, r) {
    const img = this.portrait(person);
    if (!img) return false;
    // 取头部：立绘里脑袋大致在上半部中间，别把帽子和肩膀一起裁进来
    const size = Math.min(img.width * 0.82, img.height * 0.46);
    const sx = (img.width - size) / 2, sy = Math.min(img.height * 0.10, img.height - size), sh = size;
    ctx.save();
    ctx.beginPath(); ctx.arc(x, y, r, 0, Math.PI * 2); ctx.closePath(); ctx.clip();
    ctx.imageSmoothingEnabled = true;
    ctx.drawImage(img, sx, sy, size, sh, x - r, y - r, r * 2, r * 2);
    ctx.restore();
    return true;
  }
}

function loadImage(src) {
  return new Promise((resolve, reject) => {
    const img = new Image();
    img.onload = () => resolve(img);
    img.onerror = () => reject(new Error('image failed: ' + src));
    img.src = src;
  });
}
