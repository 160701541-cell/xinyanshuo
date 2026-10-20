#!/usr/bin/env python3
"""Repack a private user-owned APK copy; never install or publish it.

Requires a separately compiled and IL-verified Mono bridge/assembly pair.
This creates an UNSIGNED candidate, not a verified playable release.
"""
import argparse
import copy
import hashlib
import io
import json
from pathlib import Path
import zipfile


def sha(data):
    return hashlib.sha256(data).hexdigest()


def package(apk, patched, plugin, out, report):
    inputs = [apk, patched, plugin]
    if out.resolve() in [p.resolve() for p in inputs] or report.resolve() in [p.resolve() for p in inputs]:
        raise ValueError('Never overwrite inputs')
    if out.exists() or report.exists():
        raise FileExistsError('Use a fresh output path for each candidate')
    archive = 'assets/Mono/Managed.zip'
    assembly = 'Assembly-CSharp.dll'
    companion = 'WorldBoxXianxiaMonoBridge.dll'
    changes, removed, managed_changes = [], [], []
    before = apk.read_bytes()
    with zipfile.ZipFile(io.BytesIO(before)) as src:
        if len(src.namelist()) != len(set(src.namelist())):
            raise ValueError('Ambiguous duplicate APK entries')
        with zipfile.ZipFile(io.BytesIO(src.read(archive))) as managed:
            if managed.namelist().count(assembly) != 1 or companion in managed.namelist():
                raise ValueError('Unexpected managed archive layout')
            buffer = io.BytesIO()
            with zipfile.ZipFile(buffer, 'w') as dest:
                for info in managed.infolist():
                    data = managed.read(info.filename)
                    if info.filename == assembly:
                        replacement = patched.read_bytes()
                        managed_changes.append({'path': assembly, 'before': sha(data), 'after': sha(replacement)})
                        data = replacement
                    if info.filename == 'Assembly-CSharp.pdb':
                        managed_changes.append({'path': info.filename, 'action': 'remove_stale_symbols'})
                        continue
                    dest.writestr(copy.copy(info), data)
                dest.writestr(companion, plugin.read_bytes(), compress_type=zipfile.ZIP_DEFLATED)
                managed_changes.append({'path': companion, 'action': 'add_original_plugin', 'sha256': sha(plugin.read_bytes())})
        out.parent.mkdir(parents=True, exist_ok=True)
        with zipfile.ZipFile(out, 'w') as dest:
            for info in src.infolist():
                upper = info.filename.upper()
                if upper.startswith('META-INF/') and (upper.endswith(('.RSA', '.DSA', '.EC', '.SF')) or upper == 'META-INF/MANIFEST.MF'):
                    removed.append(info.filename)
                    continue
                data = src.read(info.filename)
                if info.filename == archive:
                    data = buffer.getvalue()
                    changes.append(archive)
                dest.writestr(copy.copy(info), data)
        with zipfile.ZipFile(out) as check:
            if check.testzip() is not None:
                raise ValueError('APK CRC check failed')
            for name in src.namelist():
                if name not in changes + removed and src.read(name) != check.read(name):
                    raise ValueError('Unexpected APK modification: ' + name)
    if apk.read_bytes() != before:
        raise ValueError('Original APK changed')
    result = {
        'status': 'UNSIGNED_DEVICE_PENDING', 'original_sha256': sha(before),
        'candidate_sha256': sha(out.read_bytes()), 'changed_apk_entries': changes,
        'removed_signature_entries': removed, 'managed_changes': managed_changes,
        'manifest_unchanged': True, 'native_libraries_unchanged': True,
        'dex_unchanged': True, 'permissions_unchanged': True,
        'existing_device_saves_accessed': False, 'device_saves_backed_up': False,
        'device_launch_verified': False, 'other_mods_integrated': False,
        'install_allowed': False,
        'release_blockers': ['Android device QA absent', 'Existing device save backup absent',
                             'New certificate cannot replace existing installation without signature compatibility',
                             'Third-party MOD integration not complete'],
    }
    report.parent.mkdir(parents=True, exist_ok=True)
    report.write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n')
    print('PRIVATE_UNSIGNED_CANDIDATE_READY; NOT_A_PLAYABLE_RELEASE')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ('apk', 'patched', 'plugin', 'out', 'report'):
        parser.add_argument('--' + name, type=Path, required=True)
    args = parser.parse_args()
    package(args.apk, args.patched, args.plugin, args.out, args.report)
