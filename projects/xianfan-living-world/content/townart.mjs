// 地图也按同一套像素画风拼：4 米一格，屋、街、城墙、树都用积木摆。
// 卡牌场景与地图共用一套色板，风格才是一套。
export const TOWNART_VERSION = 'townart-0.1.0';
export const CELL = 4;                        // 米/格
export const EXTENT = 840;                    // ±米
const N = Math.round((EXTENT * 2) / CELL);

export const PAL = {
  grass: ['#8fae5e', '#87a757', '#98b766', '#7fa050'],
  field: ['#c2c355', '#b3b84c', '#cdcb63'],
  street: '#d8c9a0', streetEdge: '#b9a87e', rut: '#c3b389',
  yard: '#d9cba6', wallStone: '#b6a17c', wallShade: '#8f7c5c',
  roofTile: '#4e5762', roofDark: '#333b45', roofLight: '#6d7885', roofRidge: '#828d9a',
  thatch: '#bb9455', thatchDark: '#8d6f3d', thatchLight: '#d6b273',
  wood: '#7a5132', woodDark: '#54371f', gate: '#5d3a22',
  water: '#5f92a8', waterLight: '#8ec2d2', bank: '#c8bb92',
  tree: '#4f7f3f', treeLight: '#6fa257', treeDark: '#33552b',
  cityWall: '#a89a80', cityWallDark: '#857a63', cityWallTop: '#c0b498',
  dirt: '#bfae86', plaza: '#cfc3a0',
};

const idx = (x, y) => y * N + x;
const inB = (x, y) => x >= 0 && y >= 0 && x < N && y < N;

export class Grid {
  constructor(fill = PAL.grass[0]) { this.c = new Array(N * N).fill(fill); }
  set(x, y, col) { x |= 0; y |= 0; if (inB(x, y) && col) this.c[idx(x, y)] = col; }
  get(x, y) { return inB(x, y) ? this.c[idx(x, y)] : null; }
  rect(x, y, w, h, col) {
    for (let j = y; j < y + h; j++) for (let i = x; i < x + w; i++) this.set(i, j, col);
  }
  frame(x, y, w, h, t, col) {
    this.rect(x, y, w, t, col); this.rect(x, y + h - t, w, t, col);
    this.rect(x, y, t, h, col); this.rect(x + w - t, y, t, h, col);
  }
  circle(cx, cy, r, col) { for (let j = -r; j <= r; j++) for (let i = -r; i <= r; i++) if (i * i + j * j <= r * r) this.set(cx + i, cy + j, col); }
  lineTo(x1, y1, x2, y2, width, pick) {
    const steps = Math.max(1, Math.round(Math.hypot(x2 - x1, y2 - y1) / CELL));
    for (let s = 0; s <= steps; s++) {
      const t = s / steps, cx = x1 + (x2 - x1) * t, cy = y1 + (y2 - y1) * t;
      const r = width / 2;
      for (let j = -r; j <= r; j += CELL / 2) for (let i = -r; i <= r; i += CELL / 2) {
        const gxx = Math.round((cx + i + EXTENT) / CELL), gyy = Math.round((cy + j + EXTENT) / CELL);
        this.set(gxx, gyy, typeof pick === 'function' ? pick(i, j, r) : pick);
      }
    }
  }
  /** 俯视屋顶：瓦垄 + 正脊 + 檐口 */
  roof(x, y, w, h, kind = 'home', ridge = 'ew') {
    const base = kind === 'thatch' ? PAL.thatch : PAL.roofTile;
    const dark = kind === 'thatch' ? PAL.thatchDark : PAL.roofDark;
    const light = kind === 'thatch' ? PAL.thatchLight : PAL.roofLight;
    this.rect(x, y, w, h, base);
    this.frame(x, y, w, h, 1, dark);
    if (ridge === 'ew') {
      const ry = y + Math.floor(h / 2);
      this.rect(x, ry, w, 1, PAL.roofRidge);
      for (let i = x + 1; i < x + w - 1; i += 2) {
        this.set(i, y + 1, light); this.set(i, y + h - 2, dark);
      }
    } else {
      const rx = x + Math.floor(w / 2);
      this.rect(rx, y, 1, h, PAL.roofRidge);
      for (let j = y + 1; j < y + h - 1; j += 2) {
        this.set(x + 1, j, light); this.set(x + w - 2, j, dark);
      }
    }
  }
  tree(cx, cy, r = 3) {
    this.circle(cx, cy, r, PAL.treeDark);
    this.circle(cx, cy, r - 1, PAL.tree);
    this.circle(cx - 1, cy - 1, Math.max(1, r - 2), PAL.treeLight);
  }
  well(cx, cy) { this.circle(cx, cy, 2, PAL.wallStone); this.circle(cx, cy, 1, PAL.water); }
}

/** 把米坐标换成格 */
export function gx(x) { return Math.round((x + EXTENT) / CELL); }
export function gy(y) { return Math.round((y + EXTENT) / CELL); }

export function paintTown(town, {streets = [], streams = [], walls = null, gates = [], fields = true} = {}) {
  const g = new Grid();
  // 草皮打点，避免一片死绿
  let s = 20261022;
  const rnd = () => (s = (s * 1664525 + 1013904223) % 4294967296) / 4294967296;
  for (let j = 0; j < N; j++) for (let i = 0; i < N; i++) {
    const r = rnd();
    g.c[idx(i, j)] = PAL.grass[r < 0.42 ? 1 : r < 0.72 ? 0 : r < 0.9 ? 2 : 3];
  }
  // 城外田块
  if (fields) {
    for (let j = 0; j < N; j += 9) for (let i = 0; i < N; i += 9) {
      const mx = i * CELL - EXTENT, my = j * CELL - EXTENT;
      if (Math.abs(mx) < 800 && Math.abs(my) < 800) continue;
      if (rnd() < 0.42) {
        const col = PAL.field[(rnd() * 3) | 0];
        g.rect(i, j, 8, 8, col);
        for (let k = 0; k < 8; k += 2) g.rect(i, j + k, 8, 1, '#a8ad46');
        if (rnd() < 0.3) g.tree(i + 4, j + 4, 2);
      }
    }
  }
  // 河与岸
  for (const poly of streams) {
    for (let i = 0; i < poly.length - 1; i++) {
      const [x1, y1] = poly[i], [x2, y2] = poly[i + 1];
      g.lineTo(x1, y1, x2, y2, 16, PAL.bank);
      g.lineTo(x1, y1, x2, y2, 11, PAL.water);
      g.lineTo(x1, y1, x2, y2, 2, PAL.waterLight);
    }
  }
  // 街道
  for (const st of streets) {
    g.lineTo(st.x1, st.y1, st.x2, st.y2, st.w + 4, PAL.streetEdge);
    g.lineTo(st.x1, st.y1, st.x2, st.y2, st.w, PAL.street);
    if (st.kind === 'avenue') g.lineTo(st.x1, st.y1, st.x2, st.y2, 2, PAL.rut);
  }
  // 院落
  for (const b of town) {
    const X = gx(b.x), Y = gy(b.y), W = Math.max(3, Math.round(b.w / CELL)), H = Math.max(3, Math.round(b.h / CELL));
    if (b.kind === 'field' || b.kind === 'garden') {
      g.rect(X, Y, W, H, PAL.field[1]);
      for (let k = 1; k < H - 1; k += 2) g.rect(X + 1, Y + k, W - 2, 1, '#9aa844');
      continue;
    }
    if (b.kind === 'pond') { g.circle(X + W / 2, Y + H / 2, Math.max(3, W / 2), PAL.water); continue; }
    if (b.kind === 'street-tree') { g.tree(X + 1, Y + 1, 2); continue; }
    // 院墙 + 院内
    g.rect(X, Y, W, H, PAL.yard);
    g.frame(X, Y, W, H, 1, PAL.wallStone);
    for (let i = X + 1; i < X + W - 1; i += 3) g.set(i, Y + H - 1, PAL.wallShade);
    for (const part of b.parts) {
      const px = gx(part.x), py = gy(part.y), pw = Math.max(1, Math.round(part.w / CELL)), ph = Math.max(1, Math.round(part.h / CELL));
      if (part.t === 'house' || part.t === 'wing') {
        g.rect(px + 1, py + 2, pw, ph, '#6d7d50');                  // 落影
        g.roof(px, py, pw, ph, part.roof || 'home', part.ridge || 'ew');
        g.rect(px, py + ph - 1, pw, 1, PAL.roofDark);               // 檐下阴影
        g.rect(px + Math.floor(pw / 2), py + ph - 3, 1, 1, PAL.wood); // 门
        if (part.roof === 'shop' || b.kind === 'shop') g.rect(px + 1, py - 1, 2, 1, '#a8341f');
      } else if (part.t === 'gate') {
        g.rect(px, py, Math.max(2, pw), 1, PAL.gate);
        if (b.kind === 'shop' || b.kind === 'official' || b.kind === 'inn') {
          g.rect(px + 1, py - 2, Math.max(2, pw - 2), 1, '#a8341f');   // 门楣的一块红
        }
      } else if (part.t === 'well') {
        g.well(px, py);
      } else if (part.t === 'tree') {
        g.tree(px, py, 2);
      } else if (part.t === 'stall') {
        g.rect(px, py, pw, ph, '#c46436');
      } else if (part.t === 'pond') {
        g.circle(px, py, 3, PAL.water);
      }
    }
  }
  // 城墙与城门
  if (walls) {
    const t = 2;
    const half = Math.round((walls.half || 750) / CELL);   // 半径是米，换算成格
    const mid = Math.round(N / 2);
    g.frame(mid - half, mid - half, half * 2, half * 2, t + 1, PAL.cityWallDark);
    g.frame(mid - half, mid - half, half * 2, half * 2, t, PAL.cityWall);
    for (let i = mid - half; i < mid + half; i += 4) {
      g.set(i, mid - half, PAL.cityWallTop);
      g.set(i, mid + half, PAL.cityWallTop);
      g.set(mid - half, i, PAL.cityWallTop);
      g.set(mid + half, i, PAL.cityWallTop);
    }
    for (const gate of gates) {
      const gxp = gx(gate.x), gyp = gy(gate.y);
      g.rect(gxp - 3, gyp - 3, 7, 7, PAL.dirt);
      g.rect(gxp - 2, gyp - 2, 5, 5, PAL.gate);
    }
  }
  return g;
}

export function gridSVG(grid, width) {
  const px = width / N;
  let out = `<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="${width}" viewBox="0 0 ${width} ${width}" shape-rendering="crispEdges">`;
  for (let j = 0; j < N; j++) {
    let i = 0;
    while (i < N) {
      const c = grid.c[idx(i, j)];
      let n = 1;
      while (i + n < N && grid.c[idx(i + n, j)] === c) n++;
      out += `<rect x="${(i * px).toFixed(2)}" y="${(j * px).toFixed(2)}" width="${(n * px).toFixed(2)}" height="${px.toFixed(2)}" fill="${c}"/>`;
      i += n;
    }
  }
  return out + '</svg>';
}
