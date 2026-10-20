#!/usr/bin/env python3
"""WorldBox 0.51.4 third-party MOD batch import staging, separate from Canglan.

Offline preparation engine for a future in-game Android document picker.
Does NOT bypass Android storage permissions, load mods into a running game,
or establish runtime compatibility.
"""
from __future__ import annotations
import argparse, json, re, shutil, tempfile, zipfile
from pathlib import Path, PurePosixPath

MAX_FILES = 4000
MAX_UNPACKED = 256 * 1024 * 1024
MAX_FILE = 64 * 1024 * 1024
MAX_RATIO = 120
MANIFEST_NAMES = ("mod.json", "manifest.json", "mod_info.json")
ID = re.compile(r"^[a-zA-Z0-9_.-]{1,100}$")
VERS = re.compile(r"\d+(?:\.\d+){1,3}")
def chinese_report(status, message, **extra):
    return {"状态": status, "中文说明": message, **extra}

def check_zip(path: Path):
    if not zipfile.is_zipfile(path):
        raise ValueError("不是有效ZIP压缩包")
    with zipfile.ZipFile(path) as z:
        infos = z.infolist()
        if len(infos) > MAX_FILES:
            raise ValueError("压缩包文件过多")
        total = 0
        names = set()
        for item in infos:
            name = item.filename.replace("\\", "/")
            p = PurePosixPath(name)
            if not name or p.is_absolute() or ".." in p.parts or ":" in name or name.startswith("//"):
                raise ValueError("压缩包包含危险路径")
            if (item.external_attr >> 16) & 0o170000 == 0o120000:
                raise ValueError("不允许符号链接")
            if item.flag_bits & 1:
                raise ValueError("暂不支持加密ZIP")
            if name.casefold() in names:
                raise ValueError("压缩包包含重复文件名")
            names.add(name.casefold())
            if item.file_size > MAX_FILE:
                raise ValueError("单文件过大")
            if item.file_size and item.file_size / max(1, item.compress_size) > MAX_RATIO:
                raise ValueError("压缩比异常，可能是解压炸弹")
            total += item.file_size
            if total > MAX_UNPACKED:
                raise ValueError("解压后体积超过安全上限")
        return infos

def manifest_from_zip(path: Path):
    with zipfile.ZipFile(path) as z:
        found = [i for i in z.infolist() if PurePosixPath(i.filename).name.lower() in MANIFEST_NAMES]
        if not found:
            raise ValueError("缺少模组清单mod.json/manifest.json")
        found.sort(key=lambda i: (len(PurePosixPath(i.filename).parts), i.filename))
        if found[0].file_size > 128 * 1024:
            raise ValueError("模组清单过大")
        data = json.loads(z.read(found[0]).decode("utf-8-sig"))
        if not isinstance(data, dict):
            raise ValueError("模组清单格式错误")
        return data

def inspect(path: Path, game_version="0.51.4", installed=None):
    installed = installed or {}
    try:
        check_zip(path)
        m = manifest_from_zip(path)
        mod_id = str(m.get("id") or m.get("mod_id") or "").strip()
        if not ID.fullmatch(mod_id):
            raise ValueError("缺少合法模组ID")
        title = str(m.get("name") or mod_id)[:100]
        target = str(m.get("game_version") or m.get("worldbox_version") or "")
        deps = m.get("dependencies") or []
        conflicts = m.get("conflicts") or []
        if not isinstance(deps, list) or not isinstance(conflicts, list):
            raise ValueError("依赖与冲突清单必须是数组")
        deps = [str(x) for x in deps]
        conflicts = [str(x) for x in conflicts]
        if len(deps) > 100 or len(conflicts) > 100:
            raise ValueError("依赖或冲突条目过多")
        missing = [x for x in deps if x not in installed]
        blocked = [x for x in conflicts if x in installed]
        if mod_id in installed:
            blocked.append("已有同名模组："+mod_id)
        # Missing/unknown game version is NEVER classified as confirmed compatible.
        if target and VERS.search(target) and VERS.search(game_version):
            expected = VERS.search(target).group()
            current = VERS.search(game_version).group()
            version_ok = expected == current
        else:
            version_ok = None
        if version_ok is False:
            return chinese_report("不兼容", f"{title}声明适用于WorldBox {target}，当前为{game_version}", 模组ID=mod_id, 依赖缺失=missing, 冲突=blocked)
        if blocked:
            return chinese_report("存在冲突", f"{title}与已安装模组存在ID冲突或互斥声明", 模组ID=mod_id, 依赖缺失=missing, 冲突=blocked)
        if missing:
            return chinese_report("缺少依赖", f"{title}需要先安装其他模组", 模组ID=mod_id, 依赖缺失=missing, 冲突=[])
        if version_ok is None:
            return chinese_report("兼容性未知", f"{title}未提供可核验的游戏版本；需要实际加载测试", 模组ID=mod_id, 依赖缺失=[], 冲突=[])
        return chinese_report("静态检查通过", f"{title}清单版本匹配，但仍需游戏内实际加载测试", 模组ID=mod_id, 依赖缺失=[], 冲突=[])
    except (OSError, ValueError, zipfile.BadZipFile, UnicodeError, json.JSONDecodeError) as e:
        return chinese_report("拒绝导入", str(e))

def batch_import(paths, destination: Path, game_version="0.51.4"):
    # Scan all inputs first so batch dependency resolution does not depend on input order.
    indexed = {}
    for path in paths:
        try:
            check_zip(path)
            manifest = manifest_from_zip(path)
            mid = str(manifest.get("id") or manifest.get("mod_id") or "")
            if ID.fullmatch(mid) and mid not in indexed:
                indexed[mid] = path
        except (OSError, ValueError, zipfile.BadZipFile, UnicodeError, json.JSONDecodeError):
            pass
    reports = []
    # Presence in batch is not treated as already installed: do not hide unresolved dependencies.
    for path in paths:
        result = inspect(path, game_version)
        result["文件"] = path.name
        result["批次可用依赖"] = [x for x in result.get("依赖缺失", []) if x in indexed]
        if result["状态"] != "静态检查通过":
            reports.append(result)
            continue
        mid = result["模组ID"]
        dest = destination / mid
        if dest.exists():
            result["状态"], result["中文说明"] = "拒绝覆盖", "目标模组目录已存在，请先备份并手动处理"
            reports.append(result)
            continue
        destination.mkdir(parents=True, exist_ok=True)
        with tempfile.TemporaryDirectory(dir=destination) as td:
            stage = Path(td) / "contents"
            stage.mkdir()
            try:
                with zipfile.ZipFile(path) as z:
                    for info in z.infolist():
                        if info.is_dir():
                            continue
                        out = stage.joinpath(*PurePosixPath(info.filename.replace("\\", "/")).parts)
                        out.parent.mkdir(parents=True, exist_ok=True)
                        with z.open(info) as src, out.open("wb") as dst:
                            shutil.copyfileobj(src, dst, length=1024 * 1024)
                stage.rename(dest)
                result["状态"] = "已安全暂存"
                result["中文说明"] = "文件已安全解压到隔离暂存目录；尚未安装或加载到游戏"
            except Exception:
                result["状态"], result["中文说明"] = "解压失败", "文件解压异常，已回滚本次暂存"
        reports.append(result)
    return reports

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("archives", nargs="+", type=Path)
    ap.add_argument("--staging", type=Path, required=True)
    ap.add_argument("--report", type=Path, required=True)
    ap.add_argument("--game-version", default="0.51.4")
    a=ap.parse_args()
    result=batch_import(a.archives,a.staging,a.game_version)
    a.report.parent.mkdir(parents=True,exist_ok=True)
    a.report.write_text(json.dumps(result,ensure_ascii=False,indent=2)+"\n",encoding="utf8")
    for r in result:print(r["文件"],r["状态"],r["中文说明"])
if __name__=="__main__":main()
