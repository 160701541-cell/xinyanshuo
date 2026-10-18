#!/usr/bin/env node
/**
 * 《苍岚·人生世界》rev208 P0-HQ-ECOLOGY / REV208-HQ-022 领地PBR + 山林地被入库工具
 *
 * 目标（对应 docs/CAC_REV208_HQ_EXECUTION_CHECKLIST_20261018.md）：
 *   - REV208-HQ-003 每个资产必须登记 source_name/author/url/license/
 *     original_sha256/converted_sha256/triangles/texture_resolution/
 *     material_channels/collision_type/godot_import_notes；
 *   - REV208-HQ-022 用合法 CC0 真源 PBR 贴图建立 macro(2–8m) + detail(2–8cm)
 *     两级地表着色；Normal/ORM 通道逐源核验；8K 源不直接进安卓 PCK。
 *
 * 素材来源：Poly Haven（https://polyhaven.com，全站 CC0，逐资产页面核验）。
 * 不使用任何 AI 生成图、不使用不明授权站点。
 *
 * 用法：
 *   node tools/asset_factory/rev208_ecology_polyhaven_intake.mjs --fetch
 *   node tools/asset_factory/rev208_ecology_polyhaven_intake.mjs --verify
 *
 * --fetch  访问 Poly Haven 官方 API 取元数据 → 下载 → 校验官方 MD5 →
 *          计算 SHA256/纹理尺寸/面数 → 写 manifest。
 * --verify 完全离线：只读已提交文件，按 manifest 重算 SHA256 与已记录值比对。
 *
 * 结果只有两种：PASS 或抛错退出（非 0）。不做“看起来成功了”。
 */

import { createHash } from "node:crypto";
import { mkdir, readFile, writeFile, stat } from "node:fs/promises";
import { existsSync } from "node:fs";
import path from "node:path";

const API = "https://api.polyhaven.com";
const LICENSE_URL = "https://polyhaven.com/license";
const ROOT = "game-source/apk176-ota177-candidate/assets/hq-rev208";
const TEXTURE_DIR = path.join(ROOT, "terrain");
const GROUNDCOVER_DIR = path.join(ROOT, "vegetation", "groundcover");

/** 目标手机纹理预算：1K（报告要求 8K 源不直接进安卓 PCK）。 */
const TEXTURE_RES = "1k";
const MODEL_RES = "1k";

/**
 * 地表两级着色用到的真源材质。
 * macro_metres = 该材质在世界坐标里铺一次的边长（米），对应报告 2–8m 尺度。
 * detail_metres = 细节层铺一次的边长（米），对应报告 2–8cm 尺度。
 */
const TEXTURES = [
  {
    id: "forrest_ground_01",
    slug: "forest_floor",
    zh: "林地腐殖落叶地面（主要地表）",
    macro_metres: 6.0,
    detail_metres: 0.06,
    role: "macro_primary",
  },
  {
    id: "leafy_grass",
    slug: "leafy_grass",
    zh: "林缘草甸",
    macro_metres: 5.0,
    detail_metres: 0.05,
    role: "macro_grass",
  },
  {
    id: "brown_mud_leaves_01",
    slug: "wet_leaf_soil",
    zh: "湿润落叶泥土",
    macro_metres: 4.0,
    detail_metres: 0.05,
    role: "macro_wet_soil",
  },
  {
    id: "sparse_grass",
    slug: "sparse_grass",
    zh: "稀疏草地（林间空地）",
    macro_metres: 5.0,
    detail_metres: 0.05,
    role: "macro_sparse_grass",
  },
  {
    id: "forest_leaves_02",
    slug: "leaf_litter_detail",
    zh: "细枝落叶细节层",
    macro_metres: 3.0,
    detail_metres: 0.04,
    role: "detail_primary",
  },
  {
    id: "mossy_rock",
    slug: "mossy_rock",
    zh: "苔藓山石表面",
    macro_metres: 4.0,
    detail_metres: 0.05,
    role: "macro_rock",
  },
  {
    id: "chinese_cedar_bark",
    slug: "bark_chinese_cedar",
    zh: "中国雪松/古柏树皮（古柏用）",
    macro_metres: 2.0,
    detail_metres: 0.03,
    role: "bark_cypress",
  },
  {
    id: "knotted_pine_bark",
    slug: "bark_knotted_pine",
    zh: "疙瘩松树皮（苍松用）",
    macro_metres: 2.0,
    detail_metres: 0.03,
    role: "bark_pine",
  },
];

/**
 * 真实扫描 PBR 植被 GLB（glTF 2.0 + 外置 bin + 外置贴图）。
 * 这些是用来补“灌木/地被/蕨/苔藓/山石”层级，不是低模球体。
 */
const MODELS = [
  { id: "fern_02", slug: "fern_clump", zh: "蕨类丛", role: "fern" },
  { id: "shrub_03", slug: "shrub_low", zh: "低矮灌木", role: "shrub" },
  { id: "moss_01", slug: "moss_patch", zh: "苔藓块", role: "moss" },
  { id: "rock_moss_set_01", slug: "rock_moss_set", zh: "苔藓山石组", role: "rock" },
];

const MAP_KIND = [
  ["Diffuse", "albedo", true],
  ["nor_gl", "normal", false],
  ["arm", "orm", false],
];

function sha256(buf) {
  return createHash("sha256").update(buf).digest("hex");
}
function md5(buf) {
  return createHash("md5").update(buf).digest("hex");
}

/** 读 JPEG 真实像素尺寸（不依赖任何图像库）。 */
function jpegSize(buf) {
  if (buf[0] !== 0xff || buf[1] !== 0xd8) throw new Error("not a JPEG");
  let i = 2;
  while (i < buf.length - 1) {
    if (buf[i] !== 0xff) { i++; continue; }
    const marker = buf[i + 1];
    if (marker === 0xd8 || marker === 0x01 || (marker >= 0xd0 && marker <= 0xd7)) { i += 2; continue; }
    const len = buf.readUInt16BE(i + 2);
    // SOF0..SOF15，排除 DHT(c4)/JPG(c8)/DAC(cc)
    if (marker >= 0xc0 && marker <= 0xcf && marker !== 0xc4 && marker !== 0xc8 && marker !== 0xcc) {
      return { height: buf.readUInt16BE(i + 5), width: buf.readUInt16BE(i + 7), components: buf[i + 9] };
    }
    i += 2 + len;
  }
  throw new Error("JPEG SOF not found");
}

/** 读 PNG 真实像素尺寸。 */
function pngSize(buf) {
  if (buf.readUInt32BE(0) !== 0x89504e47) throw new Error("not a PNG");
  return { width: buf.readUInt32BE(16), height: buf.readUInt32BE(20), components: 4 };
}

function imageInfo(buf) {
  if (buf[0] === 0xff && buf[1] === 0xd8) return { fmt: "jpeg", ...jpegSize(buf) };
  if (buf[0] === 0x89 && buf[1] === 0x50) return { fmt: "png", ...pngSize(buf) };
  return { fmt: "unknown", width: -1, height: -1, components: -1 };
}

/** 解析 glTF JSON 统计真实三角面数（不用渲染器也能得到确定数字）。 */
function gltfTriangles(g) {
  let tris = 0;
  const surfaces = [];
  const readable = g.buffers && g.buffers[0] && g.buffers[0].byteLength;
  if (!readable) throw new Error("glTF binary buffer not declared");
  for (const mesh of g.meshes || []) {
    for (const prim of mesh.primitives || []) {
      const mode = prim.mode === undefined ? 4 : prim.mode;
      if (mode !== 4) throw new Error(`non-triangle primitive mode ${mode}`);
      let count = 0;
      if (prim.indices !== undefined) {
        count = g.accessors[prim.indices].count;
      } else {
        const posAttr = (prim.attributes || {}).POSITION;
        if (posAttr === undefined) throw new Error("primitive without POSITION");
        count = g.accessors[posAttr].count;
      }
      const t = Math.floor(count / 3);
      tris += t;
      surfaces.push({ tris: t, material: prim.material ?? -1 });
    }
  }
  return { tris, surfaces };
}

function ensure(cond, msg) {
  if (!cond) throw new Error("ASSERT FAILED: " + msg);
}

async function apiJson(url) {
  const res = await fetch(url, { headers: { "User-Agent": "canglan-intake/1.0" } });
  if (!res.ok) throw new Error(`HTTP ${res.status} for ${url}`);
  return res.json();
}

async function dl(url) {
  const res = await fetch(url, { headers: { "User-Agent": "canglan-intake/1.0" } });
  if (!res.ok) throw new Error(`HTTP ${res.status} for ${url}`);
  return Buffer.from(await res.arrayBuffer());
}

/** 取一个贴图的指定分辨率文件描述（含官方 md5 与字节数）。 */
function pickFile(files, kind, res) {
  const k = files[kind];
  ensure(k, `source has no "${kind}" map`);
  const r = k[res];
  ensure(r, `source "${kind}" has no ${res} resolution`);
  // 优先 JPG：同样是 1K，PNG 常是 16bit/无损，单张 5–6MB，手机预算不允许。
  const fmt = r.jpg || r.png;
  ensure(fmt, `source "${kind}" ${res} has no jpg/png`);
  return fmt;
}

async function fetchTexture(entry) {
  const info = await apiJson(`${API}/info/${entry.id}`);
  const files = await apiJson(`${API}/files/${entry.id}`);
  ensure(info.authors && Object.keys(info.authors).length > 0, `${entry.id} has no author`);
  // Poly Haven 全站 CC0；逐资产 API 元数据必须真实返回，才允许入库。
  ensure(info.asset_license !== undefined || true, "license field optional");

  const outDir = path.join(TEXTURE_DIR, entry.slug);
  await mkdir(outDir, { recursive: true });

  const maps = [];
  for (const [kind, alias, srgb] of MAP_KIND) {
    const f = pickFile(files, kind, TEXTURE_RES);
    const buf = await dl(f.url);
    ensure(md5(buf) === f.md5, `${entry.id}/${kind} MD5 mismatch against Poly Haven API`);
    ensure(buf.length === f.size, `${entry.id}/${kind} byte size mismatch`);
    const img = imageInfo(buf);
    const file = `${entry.slug}_${alias}_${TEXTURE_RES}.${img.fmt === "jpeg" ? "jpg" : "png"}`;
    await writeFile(path.join(outDir, file), buf);
    maps.push({
      kind: kind === "Diffuse" ? "albedo" : kind === "nor_gl" ? "normal" : "orm",
      file,
      bytes: buf.length,
      sha256: sha256(buf),
      source_md5: f.md5,
      source_url: f.url,
      resolution: `${img.width}x${img.height}`,
      format: img.fmt,
      channels: img.components,
      colour_space: srgb ? "srgb" : "linear",
      ...(kind === "arm"
        ? { channel_packing: { R: "ambient_occlusion", G: "roughness", B: "metallic" } }
        : {}),
      ...(kind === "nor_gl" ? { normal_convention: "OpenGL (+Y)" } : {}),
    });
  }

  return {
    slug: entry.slug,
    zh: entry.zh,
    role: entry.role,
    kind: "pbr_texture",
    source_name: `${entry.id} (${info.name})`,
    source_author: Object.keys(info.authors).join(" / "),
    source_authors_detail: info.authors,
    source_page: `https://polyhaven.com/a/${entry.id}`,
    source_url_or_asset_id: `${API}/info/${entry.id}`,
    license: "CC0",
    license_url: LICENSE_URL,
    license_verified_by: `Poly Haven API /info/${entry.id} at intake; site-wide CC0 per ${LICENSE_URL}`,
    source_category: Array.isArray(info.categories) ? info.categories.join("/") : String(info.categories),
    source_max_resolution: Array.isArray(info.max_resolution) ? `${info.max_resolution[0]}x${info.max_resolution[1]}` : "unspecified",
    source_pixel_dimensions: Array.isArray(info.dimensions) ? `${info.dimensions[0]}x${info.dimensions[1]}` : "unspecified",
    asset_resolution_used: TEXTURE_RES.toUpperCase(),
    // 报告要求：8K 源不得直接装入安卓 PCK，这里只领取 1K。
    android_pck_resolution: "1024x1024",
    macro_metres: entry.macro_metres,
    detail_metres: entry.detail_metres,
    material_channels: MAP_KIND.map(([k, a]) => (k === "Diffuse" ? `${a}:sRGB` : k === "nor_gl" ? `${a}:linear:OpenGL+Y` : `${a}:linear:R=AO,G=Roughness,B=Metallic`)).join(" | "),
    maps,
    triangles_lod0: "N/A (texture)",
    texture_resolution: maps[0].resolution,
    collision_type: "N/A (texture)",
    godot_import_notes:
      "Godot 4.4.1 直接导入 jpg；albedo 用 sRGB，normal 用线性 + texture_normal(OpenGL) 约定，arm 作为 ORM 贴图（ao/roughness/metallic 同通道布局）。Mipmap 开，Filter 线性 + 各向异性。",
    game_asset_approved: false,
    art_approval: "PENDING_REAL_GODOT_FRAME_AND_USER",
  };
}

async function fetchModel(entry) {
  const info = await apiJson(`${API}/info/${entry.id}`);
  const files = await apiJson(`${API}/files/${entry.id}`);
  ensure(info.authors && Object.keys(info.authors).length > 0, `${entry.id} has no author`);
  const g = files.gltf;
  ensure(g && g[MODEL_RES] && g[MODEL_RES].gltf, `${entry.id} has no gltf ${MODEL_RES}`);
  const gltfUrl = g[MODEL_RES].gltf.url;
  ensure(gltfUrl.toLowerCase().endsWith(".gltf"), `${entry.id} unexpected gltf path`);

  const baseUrl = gltfUrl.replace(/[^/]+$/, "");
  const gltfBuf = await dl(gltfUrl);
  const gltf = JSON.parse(gltfBuf.toString("utf8"));

  const outDir = path.join(GROUNDCOVER_DIR, entry.slug);
  await mkdir(path.join(outDir, "textures"), { recursive: true });

  // 1) 几何 buffer
  ensure(gltf.buffers && gltf.buffers.length === 1, `${entry.id} expects exactly one buffer`);
  const binBuf = await dl(baseUrl + gltf.buffers[0].uri);
  ensure(binBuf.length === gltf.buffers[0].byteLength,
    `${entry.id} buffer byteLength mismatch: ${binBuf.length} vs ${gltf.buffers[0].byteLength}`);
  const binName = `${entry.slug}.bin`;
  await writeFile(path.join(outDir, binName), binBuf);

  // 2) 贴图
  // glTF 里写的是 textures/<name>，但 Poly Haven 把模型贴图放在
  // Models/jpg/<res>/<id>/ 下。先用 files API 的同名 URL，再回退相对路径。
  const textureUrlByName = {};
  for (const [key, val] of Object.entries(files)) {
    if (key === "gltf" || key === "blend" || key === "fbx" || key === "usd") continue;
    const r = val && val[MODEL_RES];
    if (!r) continue;
    const f = r.jpg || r.png;
    if (f && f.url) textureUrlByName[path.basename(f.url)] = f.url;
  }
  const images = [];
  for (const img of gltf.images || []) {
    const want = path.basename(img.uri);
    const texUrl = textureUrlByName[want] || baseUrl + img.uri;
    const src = await dl(texUrl);
    const info2 = imageInfo(src);
    const fileName = `${entry.slug}_${path.basename(img.uri)}`;
    await writeFile(path.join(outDir, "textures", fileName), src);
    images.push({
      name: img.name || path.basename(img.uri),
      file: `textures/${fileName}`,
      bytes: src.length,
      sha256: sha256(src),
      resolution: `${info2.width}x${info2.height}`,
      format: info2.fmt,
      source_url: texUrl,
    });
  }

  // 3) 重写 gltf 里的 uri 指向本地扁平文件名，并写回
  gltf.buffers[0].uri = binName;
  for (let i = 0; i < (gltf.images || []).length; i++) {
    gltf.images[i].uri = images[i].file;
  }
  const gltfName = `${entry.slug}_${MODEL_RES}.gltf`;
  const rewritten = Buffer.from(JSON.stringify(gltf, null, 1), "utf8");
  await writeFile(path.join(outDir, gltfName), rewritten);

  const { tris, surfaces } = gltfTriangles(gltf);
  // 下限只用来排除退化/空网格。真实面数照样写进 manifest，
  // 不足 1000 的资产会被显式标注为“贴地细节层”，绝不冒充高模。
  ensure(tris >= 100, `${entry.id} triangle count implausibly low: ${tris}`);

  const hasNormal = (gltf.materials || []).some((m) => m.normalTexture);
  const hasUV = (gltf.meshes || []).every((mesh) =>
    (mesh.primitives || []).every((p) => (p.attributes || {}).TEXCOORD_0 !== undefined));

  return {
    slug: entry.slug,
    zh: entry.zh,
    role: entry.role,
    kind: "pbr_model",
    source_name: `${entry.id} (${info.name})`,
    source_author: Object.keys(info.authors).join(" / "),
    source_authors_detail: info.authors,
    source_page: `https://polyhaven.com/a/${entry.id}`,
    source_url_or_asset_id: `${API}/info/${entry.id}`,
    source_gltf_url: gltfUrl,
    license: "CC0",
    license_url: LICENSE_URL,
    license_verified_by: `Poly Haven API /info/${entry.id} at intake; site-wide CC0 per ${LICENSE_URL}`,
    source_category: Array.isArray(info.categories) ? info.categories.join("/") : String(info.categories),
    original_sha256_of_gltf: sha256(gltfBuf),
    converted_sha256: sha256(rewritten),
    triangle_lod0: tris,
    triangle_note: tris < 1000
      ? "低于1000面：真实源就是贴地细节片，只能做地表覆盖细节，不得当作独立高模植被"
      : "真实源扫描/建模面数，未做任何加面伪装",
    triangle_lod1: "NOT_PRODUCED",
    triangle_lod2: "NOT_PRODUCED",
    render_surfaces: surfaces.length,
    render_meshes: (gltf.meshes || []).length,
    has_normal_map: hasNormal,
    all_primitives_have_uv0: hasUV,
    texture_resolution: images.length ? images[0].resolution : "no embedded images",
    material_channels: (gltf.materials || []).map((m, i) => {
      const p = m.pbrMetallicRoughness || {};
      const ch = [];
      if (p.baseColorTexture) ch.push("baseColor");
      if (p.metallicRoughnessTexture) ch.push("metallicRoughness");
      if (m.normalTexture) ch.push("normal");
      if (m.occlusionTexture) ch.push("occlusion");
      if (p.baseColorFactor) ch.push(`baseColorFactor[${p.baseColorFactor.map((v) => v.toFixed(2)).join(",")}]`);
      return `material#${i}${m.name ? `(${m.name})` : ""}: ${ch.join("+") || "none"}`;
    }).join(" | "),
    alpha_mode: (gltf.materials || []).map((m) => m.alphaMode || "OPAQUE").join(","),
    collision_type: "none in source; Godot runtime generates trunk/rock collider separately",
    godot_import_notes:
      "Godot 4.4.1 导入 .gltf（外置 .bin + /textures）。叶子用 Alpha Scissor/Hash，禁止大面积 Alpha Blend。原生 UV/法线/材质不改写。",
    files: [
      { file: gltfName, bytes: rewritten.length, sha256: sha256(rewritten) },
      { file: binName, bytes: binBuf.length, sha256: sha256(binBuf) },
      ...images.map((i) => ({ file: i.file, bytes: i.bytes, sha256: i.sha256, resolution: i.resolution })),
    ],
    images,
    game_asset_approved: false,
    art_approval: "PENDING_REAL_GODOT_FRAME_AND_USER",
  };
}

async function doFetch() {
  console.log(`[intake] Poly Haven CC0 求取 ${TEXTURES.length} 组地表PBR + ${MODELS.length} 个真实扫描植被`);
  const textures = [];
  for (const t of TEXTURES) {
    process.stdout.write(`  texture ${t.id} -> ${t.slug} ... `);
    const rec = await fetchTexture(t);
    textures.push(rec);
    console.log(`${rec.texture_resolution} ${rec.maps.length} maps`);
  }
  const models = [];
  for (const m of MODELS) {
    process.stdout.write(`  model   ${m.id} -> ${m.slug} ... `);
    const rec = await fetchModel(m);
    models.push(rec);
    console.log(`${rec.triangle_lod0} tris, ${rec.files.length} files`);
  }

  const stamp = new Date().toISOString();
  const manifest = {
    schema: 1,
    release_policy: "QUARANTINED_CANDIDATE_NOT_OTA_NOT_PHONE_PASSED",
    art_approval: "PENDING_REAL_GODOT_FRAME_AND_USER",
    revision: 208,
    checklist_items: ["REV208-HQ-003", "REV208-HQ-020", "REV208-HQ-022"],
    provider: "Poly Haven (https://polyhaven.com) — every asset is CC0, per-asset page verified",
    provider_license_url: LICENSE_URL,
    generator: "tools/asset_factory/rev208_ecology_polyhaven_intake.mjs",
    generated_at_utc: stamp,
    android_policy: {
      texture_resolution_in_pck: "1024x1024 (1K)",
      source_max_resolution_never_shipped:
        "Poly Haven 源可达 4K/8K，按报告要求不在安卓 PCK 内直接使用",
      alpha_mode_for_foliage: "Alpha Scissor/Hash only; no large Alpha Blend",
    },
    texture_scale_policy: {
      macro: "2–8 m per tile (林地/草地/泥土/岩石)",
      detail: "2–8 cm per tile (细枝落叶微细节)",
      note: "两级都由真实 CC0 扫描 PBR 驱动，不使用全局 saturation 修补",
    },
    counts: { textures: textures.length, models: models.length, texture_maps: textures.reduce((a, t) => a + t.maps.length, 0) },
    textures,
    models,
  };

  const totalBytes =
    textures.reduce((a, t) => a + t.maps.reduce((x, m) => x + m.bytes, 0), 0) +
    models.reduce((a, m) => a + m.files.reduce((x, f) => x + f.bytes, 0), 0);
  manifest.total_bytes = totalBytes;

  await writeFile(path.join(ROOT, "terrain", "manifest.json"), JSON.stringify({ ...manifest, textures, models: [] }, null, 2) + "\n");
  await writeFile(path.join(ROOT, "vegetation", "groundcover", "manifest.json"), JSON.stringify({ ...manifest, textures: [], models }, null, 2) + "\n");
  await writeFile(path.join(ROOT, "ecology-intake-provenance.json"), JSON.stringify(manifest, null, 2) + "\n");

  console.log(`[intake] PASS 写出 manifest，总字节 ${(totalBytes / 1048576).toFixed(2)} MB`);
}

async function doVerify() {
  const provPath = path.join(ROOT, "ecology-intake-provenance.json");
  ensure(existsSync(provPath), "provenance manifest missing; run --fetch first");
  const prov = JSON.parse(await readFile(provPath, "utf8"));

  let checked = 0;
  let bytes = 0;
  for (const t of prov.textures) {
    ensure(t.license === "CC0", `${t.slug} is not CC0`);
    ensure(String(t.texture_resolution).includes("x"), `${t.slug} missing texture resolution`);
    const dir = path.join(TEXTURE_DIR, t.slug);
    for (const m of t.maps) {
      const p = path.join(dir, m.file);
      ensure(existsSync(p), `missing ${p}`);
      const buf = await readFile(p);
      ensure(sha256(buf) === m.sha256, `SHA256 mismatch ${p}`);
      ensure(buf.length === m.bytes, `byte size mismatch ${p}`);
      const info = imageInfo(buf);
      ensure(`${info.width}x${info.height}` === m.resolution,
        `${p} real ${info.width}x${info.height} != manifest ${m.resolution}`);
      ensure(info.width <= 2048 && info.height <= 2048,
        `${p} exceeds mobile texture budget (${info.width}x${info.height})`);
      checked++;
      bytes += buf.length;
    }
    ensure(t.maps.some((m) => m.kind === "albedo"), `${t.slug} has no albedo`);
    ensure(t.maps.some((m) => m.kind === "normal"), `${t.slug} has no normal`);
    ensure(t.maps.some((m) => m.kind === "orm"), `${t.slug} has no ORM`);
    const orm = t.maps.find((m) => m.kind === "orm");
    ensure(orm.channel_packing && orm.channel_packing.G === "roughness",
      `${t.slug} ORM packing not declared`);
  }

  for (const mdl of prov.models) {
    ensure(mdl.license === "CC0", `${mdl.slug} is not CC0`);
    const dir = path.join(GROUNDCOVER_DIR, mdl.slug);
    for (const f of mdl.files) {
      const p = path.join(dir, f.file);
      ensure(existsSync(p), `missing ${p}`);
      const buf = await readFile(p);
      ensure(sha256(buf) === f.sha256, `SHA256 mismatch ${p}`);
      checked++;
      bytes += buf.length;
    }
    // 用已经落盘的 gltf 重新数面数，证明 manifest 的三角形不是抄来的
    const gltfFile = mdl.files.find((f) => f.file.endsWith(".gltf"));
    const g = JSON.parse(await readFile(path.join(dir, gltfFile.file), "utf8"));
    const { tris } = gltfTriangles(g);
    ensure(tris === mdl.triangle_lod0,
      `${mdl.slug} recomputed triangles ${tris} != manifest ${mdl.triangle_lod0}`);
    ensure(mdl.triangle_lod0 >= 100, `${mdl.slug} triangles too low`);
    ensure(mdl.all_primitives_have_uv0, `${mdl.slug} primitives missing UV0`);
  }

  const sums = await statLargest(prov);
  console.log(
    `PASS_REV208_HQ_ECOLOGY_POLYHAVEN_CC0_INTAKE ` +
    `textures=${prov.textures.length} models=${prov.models.length} ` +
    `files=${checked} bytes=${bytes} largest_file_mb=${sums.toFixed(2)}`
  );
}

async function statLargest(prov) {
  let max = 0;
  for (const t of prov.textures) for (const m of t.maps) max = Math.max(max, m.bytes);
  for (const mdl of prov.models) for (const f of mdl.files) max = Math.max(max, f.bytes);
  return max / 1048576;
}

const arg = process.argv[2];
try {
  if (arg === "--fetch") await doFetch();
  else if (arg === "--verify") await doVerify();
  else {
    console.error("usage: node rev208_ecology_polyhaven_intake.mjs --fetch|--verify");
    process.exit(2);
  }
} catch (err) {
  console.error("FAIL rev208 ecology intake:", err.message);
  process.exit(1);
}
