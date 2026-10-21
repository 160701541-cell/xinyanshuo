/**
 * 原生端数据导出：一张烘焙好的地图 PNG + 一份世界 JSON。
 * 原生 Java 只读这两样，不再跑 WebView、不再解析 JS。
 */
import {writeFileSync, mkdirSync} from 'node:fs';
import {execFileSync} from 'node:child_process';
import {layoutTown, streetsFor, ART} from '../buildings.mjs';
import {STRUCTURES, STREAMS, CITY, LANDMARKS, ROUTES, PLACE_METERS} from '../overworld.mjs';
import {PLACES, VERSION} from '../core.mjs';
import {generateWorld} from '../worldmap.mjs';
import {paintTown, gridSVG} from '../content/townart.mjs';
import {BEASTS, beastAt} from '../content/beasts.mjs';
import {PLANET, DOMAINS, VOID_STONES, VOID_REALM, MORTAL_KM_PER_DAY, MORTAL_YEARS} from '../stardomains.mjs';

const OUT = new URL('../android-native/app/src/main/assets/', import.meta.url).pathname;
mkdirSync(OUT, {recursive: true});

const town = layoutTown('linan', STRUCTURES);
const grid = paintTown(town, {streets: streetsFor(STRUCTURES), streams: STREAMS, walls: {half: 750}, gates: CITY.gates});
writeFileSync('/tmp/native-map.svg', gridSVG(grid, 2048));
execFileSync('rsvg-convert', ['-w', '2048', '-h', '2048', '/tmp/native-map.svg', '-o', `${OUT}map.png`]);

const places = PLACES.map(p => ({id: p.id, name: p.name, type: p.type, zone: p.zone, size: p.population || 0}));
const structures = STRUCTURES.map(s => ({id: s.id, name: s.name, kind: s.kind, x: s.x, y: s.y, w: s.w, h: s.h, note: s.note || ''}));

// 妖兽巢穴与 JS 端同规则（种子固定为 county-0.47）
const hash = s => { let h = 2166136261; for (let i = 0; i < s.length; i++) { h ^= s.charCodeAt(i); h = Math.imul(h, 16777619); } return (h >>> 0) / 4294967296; };
const DEN = [{name:'松林深处',x:9200,y:6100},{name:'黑水潭',x:-12400,y:7600},{name:'断魂谷',x:15800,y:-4300},{name:'青云后山',x:10800,y:-6900},{name:'蛇盘岭',x:-7600,y:-9200},{name:'铁背洞',x:4300,y:11200},{name:'白毛崖',x:-15200,y:-3100},{name:'赤鳞涧',x:18200,y:8800},{name:'王巢',x:21200,y:-12000}];
const seed = 'county-0.47';
const dens = DEN.map((d, i) => {
  const b = BEASTS[Math.min(BEASTS.length - 1, Math.floor(hash(`${seed}:den:${i}:kind`) * BEASTS.length))];
  const realm = Math.min(3, Math.floor(hash(`${seed}:den:${i}:realm`) * 2) + (i >= 7 ? 1 : 0) + (i === 8 ? 1 : 0));
  const one = beastAt(b.id, realm);
  return {id: `den-${i}`, name: d.name, x: d.x, y: d.y, beast: one.name, beastId: b.id, realm,
    meters: one.meters, hp: one.hp, dmg: one.dmg, move: one.move?.name || '', count: 2 + Math.floor(hash(`den-${i}` + seed) * 4)};
});

// 街上的真人：从户册里挑，给一个可见的行踪（都在城内，便于遇见）
const NAMES = ['阿绫','周砚','柳七','何九','陈六娘','王二','苏小满','倪三','沈青','程五'];
const npcs = NAMES.map((name, i) => {
  const a = i / NAMES.length * Math.PI * 2;
  return {id: 'npc-' + i, name, job: ['厨娘','货郎','脚夫','木匠','账房','更夫','药童','织工','茶博士','挑夫'][i],
    x: Math.round(Math.cos(a) * 260), y: Math.round(Math.sin(a) * 300)};
});

// 碰撞：院墙与主屋的矩形（米），原生端据此挡住穿模
const blocks = [];
for (const b of town) {
  if (b.kind === 'garden' || b.kind === 'field') continue;
  for (const part of b.parts) {
    if (part.t === 'house' || part.t === 'wing' || part.t === 'wall') {
      blocks.push({x: part.x, y: part.y, w: part.w, h: part.h});
    }
  }
}

const world = {
  version: 'native-0.1.0', game: VERSION, seed,
  extent: 840, cell: 4, imageSize: 2048,
  city: {name: CITY.name || '临安县城', half: CITY.half || 750, gates: CITY.gates || []},
  places, structures, dens, npcs, blocks, roads: ROUTES,
  landmarks: LANDMARKS.map(l => ({id: l.id, name: l.name, x: l.x, y: l.y, type: l.type, active: !!l.active})),
  routes: ROUTES, streams: STREAMS,
  planet: PLANET, domains: DOMAINS, voidStones: VOID_STONES, mortalKmPerDay: MORTAL_KM_PER_DAY, mortalYears: MORTAL_YEARS, voidRealm: VOID_REALM,
  metrics: (() => { const m = generateWorld({seed, grid: 96}); return {regions: m.regions.length, km2: m.totalKm2}; })()
};
writeFileSync(`${OUT}world.json`, JSON.stringify(world));
console.log('native assets:', places.length, 'places', structures.length, 'structures', dens.length, 'dens');
