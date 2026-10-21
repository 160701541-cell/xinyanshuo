// 卡牌背景：按名字判断“这是什么东西”，再用积木拼一张 64×40 的像素场景。
// 不是小图标，是整张卡片的底图：客栈是两层楼+腰檐+幌子+灯笼，厨房是灶台+锅+蒸汽，衙门是堂+匾+石狮。
export const SCENE_VERSION = 'scene-0.2.0';
export const W = 64, H = 40;

const P = {
  sky: '#dfe6ea', skyDusk: '#e8dfc6', skyWarm: '#efe4cb',
  wall: '#e8d6b4', wallDark: '#cbb391', wallLight: '#f6ecd6',
  roof: '#4e5762', roofDark: '#333b45', roofLight: '#6d7885',
  wood: '#8a5b38', woodDark: '#5b3a24', door: '#6b3f24',
  stone: '#a3a8a6', stoneDark: '#7a807e', ground: '#93a06d', groundDark: '#77845a',
  fire: '#e0762f', fireLight: '#f4bb57', steam: '#e6ebed',
  water: '#5f92a8', waterLight: '#8ec2d2', green: '#5f8a4a', greenLight: '#88b060',
  red: '#a8341f', redLight: '#cf5a3e', gold: '#c9a44a', ink: '#2b2620', white: '#f4efe2',
  cloth: '#b8b39c',
};

class Sheet {
  constructor(bg) { this.g = Array.from({length: H}, () => Array(W).fill(bg)); }
  px(x, y, c) { const i = Math.round(x), j = Math.round(y); if (i >= 0 && i < W && j >= 0 && j < H && c) this.g[j][i] = c; }
  rect(x, y, w, h, c) { for (let j = Math.round(y); j < Math.round(y + h); j++) for (let i = Math.round(x); i < Math.round(x + w); i++) this.px(i, j, c); }
  frame(x, y, w, h, c) { this.rect(x, y, w, 1, c); this.rect(x, y + h - 1, w, 1, c); this.rect(x, y, 1, h, c); this.rect(x + w - 1, y, 1, h, c); }
  /** 屋顶：中间高、两端低（翘檐），下端一道檐口；屋顶留脊线 */
  /** 屋顶：上窄下宽的瓦顶 + 屋脊 + 檐口 + 两个翘角 */
  roof(x, y, w, h, c = P.roof, dark = P.roofDark, light = P.roofLight, eave = 2) {
    const cx = x + w / 2;
    for (let j = 0; j < h; j++) {
      const t = (j + 1) / h;
      const half = (w / 2 - h * 1.1) + h * 1.1 * t;
      for (let i = Math.round(cx - half); i < Math.round(cx + half); i++) this.px(i, y + j, j === 0 ? light : c);
    }
    const topHalf = w / 2 - h * 1.1;
    this.rect(Math.round(cx - topHalf), y - 1, Math.round(topHalf * 2), 1, dark);   // 屋脊
    const ey = y + h;
    this.rect(Math.round(cx - w / 2 - eave), ey, w + eave * 2, 1, dark);           // 檐口
    this.px(Math.round(cx - w / 2 - eave), ey - 1, light);                          // 翘角
    this.px(Math.round(cx + w / 2 + eave - 1), ey - 1, light);
  }
  window(x, y, w, h) {
    this.rect(x, y, w, h, P.ink); this.rect(x + 1, y + 1, w - 2, h - 2, P.wallLight);
    for (let i = x + 2; i < x + w - 1; i += 2) this.rect(i, y + 1, 1, h - 2, P.wood);
  }
  lantern(x, y) {
    this.px(x, y, P.woodDark); this.rect(x - 1, y + 1, 3, 1, P.red);
    this.rect(x - 1, y + 2, 3, 2, P.redLight); this.rect(x - 1, y + 4, 3, 1, P.red); this.px(x, y + 5, P.gold);
  }
  /** 幌子：一根挑杆 + 垂下的布帘，布上有两道白横 */
  banner(x, y, h, c = P.red) {
    this.rect(x, y, 6, 1, P.woodDark); this.px(x + 5, y + 1, P.woodDark);
    this.rect(x, y + 1, 4, h, c); this.frame(x, y + 1, 4, h, P.ink);
    this.rect(x + 1, y + 3, 2, 1, P.white); this.rect(x + 1, y + 6, 2, 1, P.white);
  }
  person(x, y, robe) {
    this.rect(x, y + 1, 3, 4, robe); this.px(x + 1, y, '#e6c9a8');
    this.px(x, y + 5, P.ink); this.px(x + 2, y + 5, P.ink);
  }
  smoke(x, y, n = 4) {
    for (let i = 0; i < n; i++) { this.px(x + (i % 2), y - i * 2, P.steam); this.px(x + 1 + (i % 2), y - i * 2, P.steam); }
  }
}

const scenes = {
  inn(s) {
    s.rect(0, 28, W, 12, P.ground); s.rect(0, 36, W, 4, P.groundDark);
    s.rect(8, 8, 48, 20, P.wall); s.rect(8, 8, 48, 1, P.wallDark);
    s.rect(8, 17, 48, 1, P.wallDark);                       // 楼层线
    s.roof(5, 2, 54, 7); s.roof(7, 17, 50, 3, P.roof, P.roofDark, P.roofLight, 1);  // 腰檐
    s.window(12, 10, 7, 5); s.window(45, 10, 7, 5);
    s.window(12, 20, 6, 4); s.window(46, 20, 6, 4);
    s.rect(24, 18, 16, 4, P.ink); s.rect(25, 19, 14, 2, P.gold);   // 匾
    s.rect(27, 22, 10, 6, P.door); s.frame(27, 22, 10, 6, P.woodDark); s.rect(31, 22, 2, 6, P.woodDark);
    s.banner(1, 9, 12); s.banner(58, 9, 12, P.gold);
    s.lantern(18, 9); s.lantern(44, 9);
    s.rect(23, 28, 18, 1, P.stone); s.rect(25, 29, 14, 1, P.stoneDark);
    s.person(6, 29, '#8a8f5e');
  },
  kitchen(s) {
    s.rect(0, 20, W, 20, '#7d6b4e'); s.rect(0, 32, W, 8, '#5f5138');
    for (let x = 2; x < W; x += 8) s.rect(x, 20, 1, 20, '#5f5138');
    s.roof(6, 2, 52, 6, '#4a4034', '#332c23', '#5e5243', 1);
    s.rect(14, 26, 36, 8, P.stone); s.frame(14, 26, 36, 8, P.stoneDark);
    s.rect(21, 22, 22, 5, '#3b3630'); s.frame(21, 22, 22, 5, P.ink);       // 大锅（圆角）
    s.rect(20, 23, 1, 3, P.ink); s.rect(43, 23, 1, 3, P.ink);
    s.rect(22, 21, 20, 1, P.stoneDark);
    s.rect(48, 4, 3, 10, P.stoneDark); s.smoke(49, 3, 3);
    s.rect(6, 16, 1, 8, P.woodDark); s.rect(7, 22, 4, 1, P.iron || P.stoneDark);
    s.rect(24, 27, 16, 4, P.fire); s.rect(27, 28, 10, 2, P.fireLight);
    s.smoke(30, 20, 5); s.smoke(34, 21, 3);
    for (let i = 0; i < 4; i++) { s.rect(10 + i * 3, 10, 2, 3, P.green); s.px(11 + i * 3, 9, P.greenLight); }
    s.rect(50, 12, 1, 8, P.woodDark); s.rect(47, 13, 7, 2, P.wood);
    s.person(8, 27, '#8a8f5e'); s.person(44, 27, '#a08b70');
    s.rect(46, 30, 8, 1, P.wood); s.rect(47, 31, 6, 1, P.woodDark);
  },
  office(s) {
    s.rect(0, 30, W, 10, P.stone); s.rect(0, 37, W, 3, P.stoneDark);
    s.rect(9, 12, 46, 18, P.wall); s.frame(9, 12, 46, 18, P.wallDark);
    s.roof(5, 4, 54, 8, P.roof, P.roofDark, P.roofLight, 3);
    s.rect(23, 8, 18, 4, P.ink); s.rect(24, 9, 16, 2, P.gold);
    s.rect(28, 20, 8, 10, P.door); s.frame(28, 20, 8, 10, P.woodDark);
    s.window(15, 18, 7, 6); s.window(42, 18, 7, 6);
    s.rect(13, 28, 5, 2, P.stoneDark); s.rect(14, 26, 3, 2, P.stone);     // 石狮
    s.rect(46, 28, 5, 2, P.stoneDark); s.rect(47, 26, 3, 2, P.stone);
    s.rect(5, 16, 1, 12, P.woodDark); s.rect(3, 16, 5, 3, P.red);          // 旗
    s.rect(58, 16, 1, 12, P.woodDark); s.rect(56, 16, 5, 3, P.red);
    s.person(19, 29, '#7b8f9c');
  },
  forge(s) {
    s.rect(0, 22, W, 18, '#5f5446'); s.rect(0, 33, W, 7, '#463e34');
    for (let x = 0; x < W; x += 16) s.rect(x, 22, 1, 18, '#4b4238');
    s.roof(4, 2, 56, 6, '#3d372f', '#28231d', '#52493d', 1);
    s.rect(10, 20, 16, 12, P.stoneDark); s.rect(11, 21, 14, 10, P.stone);   // 炉
    s.rect(13, 23, 10, 6, P.fire); s.rect(15, 24, 6, 4, P.fireLight);
    s.px(12, 25, P.fireLight); s.px(23, 24, P.fire); s.px(22, 27, P.fireLight);
    s.rect(24, 8, 3, 8, P.stoneDark); s.smoke(25, 7, 3);
    s.rect(34, 26, 12, 3, P.stoneDark); s.rect(36, 23, 8, 3, P.stone);      // 砧
    s.rect(44, 16, 2, 10, P.woodDark); s.rect(41, 15, 8, 2, P.wood);        // 锤
    s.rect(8, 8, 1, 6, P.ink); s.rect(13, 8, 1, 7, P.ink); s.rect(18, 8, 1, 6, P.ink);  // 挂兵器
    s.person(52, 26, '#7b6a52');
  },
  herb(s) {
    s.rect(0, 14, W, 26, P.green); s.rect(0, 34, W, 6, '#5f7440');
    for (let j = 0; j < 4; j++) {
      s.rect(6, 18 + j * 5, 52, 3, '#718c49');
      for (let i = 0; i < 12; i++) {
        const x = 8 + i * 4, y = 19 + j * 5;
        s.rect(x, y, 1, 2, P.greenLight); s.px(x, y - 1, P.white); s.px(x + 1, y, P.green);
      }
    }
    for (let x = 1; x < W - 1; x += 3) { s.px(x, 12, P.wood); s.px(x, 11, P.woodDark); }
    s.rect(1, 13, W - 2, 1, P.woodDark);
    s.rect(50, 2, 2, 10, P.woodDark); s.rect(42, 4, 16, 1, P.wood);          // 晒药架
    s.rect(44, 5, 3, 3, P.green); s.rect(49, 5, 3, 3, P.greenLight); s.rect(54, 5, 3, 3, P.redLight);
    s.person(24, 22, '#8a8f5e');
  },
  gate(s) {
    s.rect(0, 0, W, H, P.stone);
    for (let y = 0; y < H; y += 3) s.rect(0, y, W, 1, P.stoneDark);
    for (let y = 0; y < H; y += 3) for (let x = (y / 3) % 2 ? 0 : 4; x < W; x += 8) s.rect(x, y, 1, 3, P.stoneDark);
    s.roof(6, 1, 52, 6, P.roof, P.roofDark, P.roofLight, 2);
    s.rect(4, 8, 56, 2, P.stoneDark);
    for (let x = 6; x < 58; x += 6) s.rect(x, 10, 3, 2, P.stone);            // 垛口
    s.rect(17, 22, 30, 18, P.stoneDark);                                    // 门洞
    s.rect(18, 23, 28, 17, P.door);
    for (let y = 25; y < 40; y += 3) for (let x = 21; x < 45; x += 4) s.px(x, y, P.gold);
    s.rect(31, 23, 2, 17, P.woodDark);
    s.rect(20, 13, 24, 3, P.ink); s.rect(21, 14, 22, 1, P.gold);            // 门额
    s.rect(29, 0, 1, 3, P.woodDark);
    s.person(8, 30, '#7b8f9c'); s.person(52, 30, '#8a8f5e');
  },
  dock(s) {
    s.rect(0, 0, W, 24, P.sky); s.rect(0, 24, W, 16, P.water);
    s.rect(0, 22, W, 2, P.ink);
    for (let i = 0; i < 9; i++) s.rect(3 + i * 3, 28 + (i % 3) * 2, 6, 1, P.waterLight);
    s.rect(4, 22, 32, 2, P.wood); s.frame(4, 22, 32, 2, P.woodDark);
    for (let x = 6; x < 36; x += 5) s.rect(x, 24, 1, 5, P.woodDark);
    s.rect(40, 26, 18, 4, P.wood); s.rect(41, 30, 16, 2, P.woodDark);        // 船
    s.rect(48, 18, 1, 8, P.woodDark); s.rect(45, 16, 8, 3, P.wallLight);     // 船篷
    s.rect(0, 2, 2, 20, P.green); s.rect(2, 6, 2, 3, P.greenLight); s.rect(2, 13, 2, 3, P.greenLight);
    s.person(10, 18, '#8a8f5e');
  },
  field(s) {
    s.rect(0, 0, W, 14, P.skyWarm);
    s.rect(8, 6, 14, 8, P.wall); s.roof(6, 2, 18, 5, P.roof, P.roofDark, P.roofLight, 0); s.rect(14, 9, 3, 5, P.door);
    s.rect(0, 14, W, 26, P.green);
    for (let j = 0; j < 5; j++) {
      s.rect(0, 16 + j * 5, W, 1, '#6f8a48');
      for (let i = 0; i < 15; i++) {
        const x = 2 + i * 4, y = 15 + j * 5;
        s.rect(x, y - 2, 1, 2, P.greenLight); s.px(x, y - 3, '#d8cf6a');
      }
    }
    s.person(40, 22, '#8a8f5e'); s.person(24, 30, '#a08b70');
  },
  school(s) {
    s.rect(0, 0, W, H, P.wallLight);
    s.rect(0, 26, W, 14, P.wood); s.rect(0, 33, W, 7, P.woodDark);
    s.roof(4, 2, 56, 7, P.roof, P.roofDark, P.roofLight, 1);
    s.rect(6, 12, 20, 12, P.sky);
    for (let i = 0; i < 4; i++) { s.rect(8 + i * 4, 12, 2, 12, P.green); s.rect(7 + i * 4, 16, 4, 1, P.greenLight); }
    s.rect(34, 16, 22, 8, P.woodDark); s.rect(36, 14, 18, 2, P.wood);        // 案
    s.rect(38, 10, 12, 3, P.wall); s.rect(39, 11, 10, 1, P.ink);             // 摊开的书
    s.person(46, 24, '#9a8fb0'); s.person(20, 24, '#8a8f5e');
  },
  temple(s) {
    s.rect(0, 0, W, H, '#d6cdb4');
    s.rect(0, 30, W, 10, P.stoneDark);
    s.rect(10, 12, 44, 18, P.wall); s.frame(10, 12, 44, 18, P.red);
    s.roof(4, 3, 56, 9, P.roof, P.roofDark, P.roofLight, 3);
    s.rect(25, 13, 14, 5, P.ink); s.rect(26, 14, 12, 3, P.gold);
    s.rect(28, 21, 8, 9, P.door); s.frame(28, 21, 8, 9, P.woodDark);
    s.rect(26, 31, 12, 5, P.woodDark); s.rect(24, 30, 16, 2, P.wood);        // 供桌
    s.rect(30, 26, 4, 4, P.stone); s.px(31, 25, P.fireLight); s.px(32, 25, P.fire);  // 香炉
    s.rect(8, 14, 1, 16, P.woodDark); s.rect(5, 15, 5, 12, P.red);            // 幡
    s.rect(55, 14, 1, 16, P.woodDark); s.rect(54, 15, 5, 12, P.red);
  },
  house(s) {
    s.rect(0, 20, W, 20, P.ground); s.rect(0, 34, W, 6, P.groundDark);
    s.rect(12, 10, 32, 16, P.wall); s.rect(12, 10, 32, 1, P.wallDark);
    s.roof(9, 3, 38, 7, P.roof, P.roofDark, P.roofLight, 1);
    s.rect(25, 17, 7, 9, P.door); s.frame(25, 17, 7, 9, P.woodDark);
    s.window(15, 14, 6, 4); s.window(36, 14, 6, 4);
    s.rect(4, 22, 2, 12, P.woodDark); s.rect(56, 22, 2, 12, P.woodDark);     // 院墙柱
    for (let i = 0; i < 3; i++) s.rect(50, 24 + i * 3, 8, 1, P.green);
    s.person(8, 24, '#a08b70');
  },
  generic(s) {
    s.rect(0, 0, W, H, '#d9d3c2');
    s.rect(0, 26, W, 14, '#b8b09a');
    s.rect(16, 12, 32, 14, '#cdc6b2'); s.frame(16, 12, 32, 14, '#9a9382');
    s.roof(12, 5, 40, 7, '#8e8878', '#6d685b', '#a9a394', 1);
    s.rect(28, 18, 8, 8, '#9a9382');
    s.rect(6, 16, 4, 10, '#c4bda9'); s.rect(54, 16, 4, 10, '#c4bda9');
  }
};

const ALIAS = new Map();
for (const [id, words] of Object.entries({
  inn: ['客栈', '酒楼', '旅店', '驿', '客舍', '店'],
  kitchen: ['厨房', '官厨', '后厨', '伙房', '灶'],
  office: ['衙门', '县衙', '官署', '官府', '衙', '堂', '邸'],
  forge: ['铁匠铺', '铁铺', '铁炉', '炉', '兵器铺', '匠'],
  herb: ['药圃', '药园', '灵田', '药', '草', '丹房'],
  gate: ['南门', '城门', '城楼', '关', '门'],
  dock: ['渡口', '码头', '船', '津', '桥'],
  field: ['田畴', '田', '畦', '农', '稼', '麦', '禾'],
  school: ['县学', '学塾', '书院', '学', '塾', '书'],
  temple: ['土地庙', '庙', '祠', '观', '寺', '殿'],
  house: ['民居', '民宅', '宅', '院', '屋', '家']
})) for (const w of words) if (!ALIAS.has(w)) ALIAS.set(w, id);

/** 名字 → 场景 id：整名 → 最长包含 → generic */
export function sceneIdFor(name = '') {
  const n = String(name);
  for (const [word, id] of ALIAS) if (n === word) return id;
  let best = null;
  for (const [word, id] of ALIAS) if (n.includes(word) && (!best || word.length > best.word.length)) best = {word, id};
  return best ? best.id : 'generic';
}

export function sceneFor(name) {
  const id = sceneIdFor(name);
  const s = new Sheet(id === 'dock' ? P.sky : '#e9e3d2');
  (scenes[id] || scenes.generic)(s);
  return {id, rows: s.g.map(r => r.join('\u0001')), w: W, h: H};
}

/** 出 SVG：卡牌背景用它，预览图也用它，同一份配方 */
export function sceneSVG(scene, width = 480, height = 300) {
  const sx = width / scene.w, sy = height / scene.h;
  let out = `<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="${height}" viewBox="0 0 ${width} ${height}" shape-rendering="crispEdges">`;
  for (let j = 0; j < scene.h; j++) {
    const cells = scene.rows[j].split('\u0001');
    let i = 0;
    while (i < cells.length) {
      const c = cells[i];
      let n = 1;
      while (i + n < cells.length && cells[i + n] === c) n++;
      out += `<rect x="${(i * sx).toFixed(2)}" y="${(j * sy).toFixed(2)}" width="${(n * sx).toFixed(2)}" height="${sy.toFixed(2)}" fill="${c}"/>`;
      i += n;
    }
  }
  return out + '</svg>';
}

export const SCENES = Object.keys(scenes);
