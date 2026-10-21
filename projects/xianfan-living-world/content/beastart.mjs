/**
 * 妖兽像素画：32×32 画布，按物种画侧身像（朝右）。
 * 色调沿用地图：土黄脊背、深褐暗部、浅色腹部、暗红口鼻、骨色獠牙。
 */
export const BEAST_ART_VERSION = 'beastart-0.1.0';
export const GW = 48, GH = 48;

const PAL = {
  '1': '#8a6a3f', // 背
  '2': '#5f4727', // 暗部
  '3': '#c0a068', // 受光
  '4': '#e8dcbc', // 腹/牙
  '5': '#4a3a24', // 眼/爪
  '6': '#a63a2e', // 口/血纹
  '7': '#6d7f4a', // 藤/鳞点缀
  '8': '#6fd0c4', // 妖气青
  '9': '#e0b34e', // 妖王金
  'a': '#8a5ab0', // 魔纹紫
  'b': '#c0392b', // 血瞳
};

class Canvas {
  constructor() { this.g = Array.from({ length: GH }, () => Array(GW).fill('.')); }
  set(x, y, c) {
    x = Math.round(x); y = Math.round(y);
    if (x < 0 || y < 0 || x >= GW || y >= GH || c === '.') return;
    this.g[y][x] = c;
  }
  rect(x, y, w, h, c) { for (let j = 0; j < h; j++) for (let i = 0; i < w; i++) this.set(x + i, y + j, c); }
  ell(cx, cy, rx, ry, c) {
    for (let y = Math.floor(cy - ry); y <= Math.ceil(cy + ry); y++)
      for (let x = Math.floor(cx - rx); x <= Math.ceil(cx + rx); x++) {
        const dx = (x - cx) / rx, dy = (y - cy) / ry;
        if (dx * dx + dy * dy <= 1) this.set(x, y, c);
      }
  }
  line(x0, y0, x1, y1, c, w = 1) {
    const n = Math.max(Math.abs(x1 - x0), Math.abs(y1 - y0)) * 2 + 1;
    for (let i = 0; i <= n; i++) {
      const t = i / n, x = x0 + (x1 - x0) * t, y = y0 + (y1 - y0) * t;
      for (let k = 0; k < w; k++) this.set(x, y + k, c);
    }
  }
  /** 描边：凡是紧贴空白的实心像素，压成暗色，像地图上的建筑一样有硬边 */
  outline(dark = '5') {
    const src = this.g.map(r => r.slice());
    for (let y = 0; y < GH; y++) for (let x = 0; x < GW; x++) {
      if (src[y][x] === '.') continue;
      const nb = [[1,0],[-1,0],[0,1],[0,-1]];
      if (nb.some(([dx, dy]) => {
        const nx = x + dx, ny = y + dy;
        return nx < 0 || ny < 0 || nx >= GW || ny >= GH || src[ny][nx] === '.';
      })) this.g[y][x] = dark;
    }
  }
  out() { return this.g.map(r => r.join('')); }
}

/** 青鬃狼：细长身、四条有膝的长腿、竖耳、蓬尾 */
function wolf(g) {
  g.ell(22, 27, 12, 5.0, '1');                 // 躯干
  g.ell(22, 24.6, 10.4, 2.6, '3');             // 背脊受光
  g.ell(19, 30, 9, 2.0, '4');                   // 腹
  g.line(10, 26, 3, 20, '1', 3);                // 尾根
  g.line(4, 20, 1.5, 14, '1', 3);               // 尾梢
  g.line(3, 19, 1, 13, '3', 1);
  g.ell(36, 22.6, 5.6, 4.6, '1');               // 头
  g.ell(38, 24.4, 3.6, 2.6, '3');               // 吻
  g.rect(39.4, 24, 2, 3, '2');                  // 鼻
  g.rect(34.6, 20.6, 2, 2, '5'); g.rect(37.4, 20.6, 2, 2, '5');   // 眼
  g.line(33.6, 19.4, 32.6, 13.4, '1', 2);       // 耳
  g.line(36.4, 19.0, 36.6, 13.0, '1', 2);
  g.line(33.4, 19.2, 32.8, 15.0, '6', 1);       // 耳内
  g.line(38.6, 27.4, 39.6, 29.4, '6', 1);       // 舌
  for (const [lx, off] of [[13, 0], [17.4, -1], [26, 1], [30.4, 0]]) {   // 腿：错开走位
    g.rect(lx, 30, 3, 5, '1');
    g.rect(lx + off * 0.7, 35, 3, 6, '3');
    g.rect(lx + off * 1.2, 41, 3, 2, '5');
  }
  g.outline();
}

/** 铁背豕：粗筒身、短腿、獠牙、背刺 */
function boar(g) {
  g.ell(22, 28, 13.4, 7.6, '1');
  g.ell(22, 24.4, 11.6, 4.0, '2');              // 鬃背
  g.ell(22, 31, 10.4, 2.6, '4');
  for (let i = 0; i < 8; i++) g.line(12 + i * 2.8, 21.6, 11.2 + i * 2.8, 16.4, '5', 1);  // 背刺
  g.ell(35, 26, 5.6, 5.2, '1');                 // 头
  g.ell(37.6, 28.4, 3.4, 2.8, '3');             // 鼻盘
  g.set(39, 28.6, '5'); g.set(40, 28.6, '5');
  g.rect(33.4, 23.6, 2, 2, '5'); g.rect(36.6, 23.6, 2, 2, '5');
  g.line(33, 22, 31.6, 18.4, '1', 2);           // 耳
  g.line(41.4, 31.4, 43.4, 27.6, '4', 1);       // 獠牙
  g.line(39.6, 31.8, 41.2, 28.6, '4', 1);
  g.line(9, 27, 3, 24, '1', 1);                 // 尾
  for (const lx of [12, 16.4, 25.6, 30]) { g.rect(lx, 34, 4, 6, '1'); g.rect(lx, 40, 4, 2, '5'); }
  g.outline();
}

/** 白毛猿：直立、长臂、宽肩、大脸盘 */
function ape(g) {
  g.ell(23, 27, 9.6, 9.0, '1');                 // 躯干
  g.ell(23, 22, 8.4, 5.4, '3');                 // 胸毛
  g.ell(23, 16, 6.4, 5.4, '1');                 // 头
  g.ell(23, 17.6, 4.6, 3.8, '3');               // 面盘
  g.rect(20.8, 15.2, 2, 2, '5'); g.rect(24.4, 15.2, 2, 2, '5');
  g.line(20.4, 20.4, 22.4, 20.8, '5', 1);       // 嘴
  g.line(18.6, 12.6, 16.6, 9.6, '1', 2);        // 耳
  g.line(27.4, 12.6, 29.4, 9.6, '1', 2);
  g.rect(10, 20, 4, 16, '1');                   // 臂
  g.rect(32, 20, 4, 16, '1');
  g.rect(9, 34, 6, 3, '3');                     // 拳
  g.rect(31, 34, 6, 3, '3');
  g.rect(17.4, 35, 4.6, 9, '1');                // 腿
  g.rect(24.0, 35, 4.6, 9, '1');
  g.rect(16.4, 43, 6.4, 2, '5'); g.rect(23.4, 43, 6.4, 2, '5');
  g.outline();
}

/** 赤鳞蟒：S 形长身、抬头、信子、鳞点 */
function serpent(g) {
  g.line(2, 43, 14, 39, '1', 5);
  g.line(14, 39, 26, 33, '1', 5);
  g.line(26, 33, 30, 25, '1', 5);
  g.line(30, 25, 31, 17, '1', 5);               // 颈
  g.ell(34, 14, 6.0, 4.2, '1');                 // 头
  g.ell(36.4, 14.6, 3.4, 2.4, '3');
  g.rect(33.4, 12, 2, 2, '5'); g.rect(36.6, 12, 2, 2, '5');
  g.line(40, 15, 43.6, 13.4, '6', 1);           // 信子
  g.line(43.6, 13.4, 46, 13.0, '6', 1);
  g.line(2, 40, 14, 36, '3', 2);                // 背光
  g.line(14, 36, 26, 30, '3', 2);
  g.line(26, 30, 30, 23, '3', 2);
  g.line(30, 23, 31, 17, '3', 2);
  for (const [x, y] of [[8, 41], [12, 40], [19, 36], [24, 33], [28, 28], [30, 22], [31, 18]]) g.set(x, y, '7');
  g.outline();
}

/** 山君：厚身、大猫头、条纹、粗尾 */
function tiger(g) {
  g.ell(22, 28, 13.4, 7.0, '1');
  g.ell(22, 24.6, 11.4, 3.4, '3');
  for (const x of [12, 17, 22, 27, 31]) g.line(x, 23.4, x - 1.6, 32.6, '2', 1);   // 虎纹
  g.ell(35, 22, 7.2, 6.4, '1');                 // 头
  g.ell(36, 24.4, 4.8, 4.0, '3');               // 面
  g.rect(32.8, 20, 2.4, 2.4, '5'); g.rect(37.6, 20, 2.4, 2.4, '5');
  g.line(30.4, 17.4, 28.6, 12.4, '1', 2);       // 耳
  g.line(40.4, 17.4, 41.6, 12.6, '1', 2);
  g.line(30.2, 17.2, 29.2, 14.0, '2', 1);       // 耳内
  g.line(40.2, 17.2, 41.0, 14.2, '2', 1);
  g.ell(34.6, 28.6, 2.2, 1.4, '4');             // 吻部浅色
  g.line(32.2, 24.4, 33.6, 26.0, '2', 1);       // 颊斑
  g.line(34.4, 27.6, 38.4, 28.4, '6', 1);       // 口
  g.line(6, 24, 1.6, 17, '1', 4);               // 尾
  g.line(2, 17.4, 1.6, 13, '2', 2);
  for (const lx of [12, 17, 27, 32]) { g.rect(lx, 33, 4, 8, '1'); g.rect(lx, 40, 4, 3, '5'); }
  g.outline();
}

const PAINTERS = { wolf, boar, ape, serpent, tiger };
const HEADS = { wolf: [36, 22], boar: [35, 26], ape: [23, 16], serpent: [34, 14], tiger: [35, 22] };
const EYES = [['wolf', [34.6, 20.6]], ['wolf', [37.4, 20.6]]];

/** 境界越高，样子本身在变：妖兵起有妖气纹，妖将生角与骨刺，妖王披金纹、双瞳血红 */
function evolve(g, id, realm = 0) {
  if (realm <= 0) return;
  const [hx, hy] = HEADS[id] || [24, 16];

  if (realm >= 1) {
    // 妖气：眼睛发青光，身侧浮起几缕青丝
    g.rect(hx - 1.4, hy - 0.6, 2, 2, '8');
    g.rect(hx + 1.6, hy - 0.6, 2, 2, '8');
    for (let i = 0; i < 3; i++) g.set(8 + i * 3, 20 - i, '8');
    g.set(hx - 5, hy + 5, '8');
    g.set(hx + 5, hy + 6, '8');
  }
  if (realm >= 2) {
    // 妖将：额生独角、背脊骨刺、爪尖泛青
    g.line(hx, hy - 4.6, hx - 1.6, hy - 8.4, '9', 2);
    g.line(hx + 0.6, hy - 4.6, hx + 2.2, hy - 7.6, '9', 1);
    for (let i = 0; i < 4; i++) g.line(10 + i * 4, 21, 9.4 + i * 4, 17.6, 'a', 1);
    for (const cx of [12, 17, 27, 32]) g.rect(cx, 40, 4, 2, '8');
  }
  if (realm >= 3) {
    // 妖王：骨甲镶金、瞳色转血、周身妖气环
    g.line(hx - 3.4, hy + 1.6, hx + 3.4, hy + 1.6, '9', 1);
    g.rect(hx - 2.4, hy + 2.6, 1.6, 1.6, 'b');
    g.rect(hx + 2.4, hy + 2.6, 1.6, 1.6, 'b');
    // 妖气环：只在身侧与身后，不在脸上乱点
    for (const [ax, ay] of [[hx - 10, hy - 4], [hx - 11, hy + 2], [hx - 9, hy + 7], [hx + 9, hy - 3], [hx + 10, hy + 3], [5, hy + 6], [3, hy + 1]]) {
      if (ax > 1 && ay > 1) g.set(ax, ay, 'a');
    }
    // 脊背镶金 + 尾尖镶金
    g.line(11, 21.4, 29, 21.4, '9', 1);
    g.set(2, 14, '9'); g.set(3, 15, '9');
    g.line(hx - 6, hy - 2, hx - 4, hy - 5, '9', 1);
    g.line(hx + 6, hy - 2, hx + 4, hy - 5, '9', 1);
  }
}

export function beastArt(id, realm = 0) {
  const paint = PAINTERS[id];
  if (!paint) return null;
  const g = new Canvas();
  paint(g);
  evolve(g, id, Math.max(0, Math.min(3, realm)));
  return { id, realm, w: GW, h: GH, rows: g.out() };
}

export function beastArtSVG(id, size = 128, realm = 0) {
  const art = beastArt(id, realm);
  if (!art) return '';
  const px = size / GW;
  const parts = [];
  art.rows.forEach((row, y) => {
    for (let x = 0; x < row.length; x++) {
      const ch = row[x];
      if (ch === '.') continue;
      parts.push(`<rect x="${(x * px).toFixed(2)}" y="${(y * px).toFixed(2)}" width="${px.toFixed(2)}" height="${px.toFixed(2)}" fill="${PAL[ch]}"/>`);
    }
  });
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${size}" height="${size}" viewBox="0 0 ${size} ${size}" shape-rendering="crispEdges">${parts.join('')}</svg>`;
}
