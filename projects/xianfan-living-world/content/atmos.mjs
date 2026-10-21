/**
 * 天光与天气：太阳角度、暖冷色调、云影、雨丝。
 * 全部是纯函数，输入（世界小时 + 天气 + 时间）→ 输出参数，
 * canvas 与离线预览共用同一份公式，不各画各的。
 */
export const ATMOS_VERSION = 'atmos-0.1.0';

export const SUNRISE = 5.6, SUNSET = 18.4;

/** 太阳方位：0 = 东，π = 西；高度 0..1 */
export function sunAt(hour = 12) {
  const h = ((hour % 24) + 24) % 24;
  const day = h >= SUNRISE && h <= SUNSET;
  const t = day ? (h - SUNRISE) / (SUNSET - SUNRISE) : 0;
  const el = day ? Math.sin(Math.PI * t) : 0;
  const az = day ? Math.PI * t : 0;
  // 晨昏暖光，正午偏白，夜里偏青冷
  let tint;
  if (!day) tint = { r: 96, g: 112, b: 148, a: 0.42 };
  else if (el < 0.34) tint = { r: 255, g: 168, b: 104, a: 0.26 };
  else if (el < 0.7) tint = { r: 255, g: 226, b: 178, a: 0.16 };
  else tint = { r: 255, g: 250, b: 226, a: 0.07 };
  return { day, elevation: el, azimuth: az, tint };
}

/** 影子方向（米）：光从东来，影子往西 */
export function shadowOf(hour = 12) {
  const s = sunAt(hour);
  if (!s.day) return { dx: 0, dy: 0, len: 0 };
  const d = Math.cos(s.azimuth);              // 东 +1 → 西 −1
  return { dx: -d, dy: -0.25, len: (1 - s.elevation) * 1.6 + 0.3 };
}

function hash2(x, y) {
  let h = Math.imul(x | 0, 374761393) ^ Math.imul(y | 0, 668265263);
  h = Math.imul(h ^ (h >>> 13), 1274126177);
  return ((h ^ (h >>> 16)) >>> 0) / 4294967296;
}
function smooth(t) { return t * t * (3 - 2 * t); }
function noise2(x, y) {
  const xi = Math.floor(x), yi = Math.floor(y);
  const xf = x - xi, yf = y - yi;
  const u = smooth(xf), v = smooth(yf);
  const a = hash2(xi, yi), b = hash2(xi + 1, yi), c = hash2(xi, yi + 1), d = hash2(xi + 1, yi + 1);
  return a * (1 - u) * (1 - v) + b * u * (1 - v) + c * (1 - u) * v + d * u * v;
}

/** 云影：两层不同速度的云叠在一起，按时间往东南飘 */
export function cloudShadowAt(x, y, seconds = 0, scale = 1) {
  const t = seconds / 1000;
  const n1 = noise2((x + t * 14) / (520 * scale), (y + t * 6) / (520 * scale));
  const n2 = noise2((x - t * 22) / (190 * scale), (y + t * 9) / (190 * scale));
  const v = n1 * 0.65 + n2 * 0.35;
  return Math.max(0, Math.min(1, (v - 0.46) * 2.4));   // 0 = 无云影，1 = 最暗
}

export const WEATHER_FX = {
  晴:   { cloud: 0.18, rain: 0,    wet: 0,    fog: 0 },
  多云: { cloud: 0.55, rain: 0,    wet: 0,    fog: 0.04 },
  阴:   { cloud: 0.82, rain: 0.12, wet: 0.25, fog: 0.10 },
  小雨: { cloud: 0.9,  rain: 0.62, wet: 0.7,  fog: 0.16 },
  大风: { cloud: 0.45, rain: 0,    wet: 0.1,  fog: 0.05 },
};

export function weatherFx(weather = '晴') {
  return WEATHER_FX[weather] || WEATHER_FX['晴'];
}

/** 雨丝：返回归一化坐标（0..1）的雨点，带速度与长度 */
export function rainDrops(seed = 1, count = 120, seconds = 0) {
  const drops = [];
  for (let i = 0; i < count; i++) {
    const a = hash2(seed + i * 7, 31), b = hash2(seed + i * 13, 71);
    const speed = 0.75 + b * 0.6;
    const y = (a + (seconds / 1000) * speed * 1.7) % 1;
    drops.push({ x: b, y, len: 0.02 + b * 0.03, v: speed });
  }
  return drops;
}

/** 一帧要用的全部参数，界面只调这一个 */
export function atmosphereOf({ hour = 12, weather = '晴', seconds = 0 } = {}) {
  const sun = sunAt(hour);
  const fx = weatherFx(weather);
  const cloudDark = Math.round(fx.cloud * 46);
  return {
    ...sun,
    ...fx,
    shadow: shadowOf(hour),
    cloudDark,
    rainDrops: fx.rain > 0 ? rainDrops(7, Math.round(160 * fx.rain), seconds) : [],
    wind: fx.cloud > 0.6 ? 1.35 : 1,
  };
}
