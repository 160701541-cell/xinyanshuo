#!/usr/bin/env python3
"""Prepare ORIGINAL bridge source for a PRIVATE exact-APK Mono build.

No game binaries, loader DLLs, entitlement patches or saves are copied.
The generated adapter intentionally does not reference either NML runtime.
It is a build candidate; Android launch and input remain DEVICE_PENDING.
"""
import argparse
from pathlib import Path


def prepare(root: Path, output: Path):
    observer = (root / 'nml-observer-v07/Code/XianxiaObserverV07.cs').read_text()
    replacements = {
        'using NeoModLoader.api;': '',
        'BasicMod<XianxiaObserverV07>': 'MonoBehaviour',
        'protected override void OnModLoad()': 'void Start()',
    }
    for old, new in replacements.items():
        if observer.count(old) != 1:
            raise ValueError('Observer adapter source contract changed: ' + old)
        observer = observer.replace(old, new)
    bridge = (root / 'private-apk-lab/XianxiaMonoBridge.cs').read_text()
    hook = 'obj.AddComponent(typeof(Overlay));'
    if bridge.count(hook) != 1:
        raise ValueError('Bridge bootstrap source contract changed')
    bridge = bridge.replace(hook, hook + '\n            obj.AddComponent(typeof(XianxiaWorldBox.XianxiaObserverV07));')
    sources = [bridge, observer, (root / 'private-apk-lab/DiagnosticLog.cs').read_text(),
               (root / 'private-apk-lab/IntegratedModBootstrap.cs').read_text()] + [
        (root / path).read_text() for path in (
            'huge-map-mod/GiantMapOptionsV11.cs',
            'huge-map-mod/ObserverFrameGuardV12.cs',
            'ui/ModTextAccessibilityV13.cs',
        )
    ]
    imports, body = set(), []
    for source in sources:
        for line in source.splitlines():
            if line.startswith('using '):
                imports.add(line)
            else:
                body.append(line)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text('\n'.join(sorted(imports) + body) + '\n', encoding='utf8')
    print('ORIGINAL_MONO_ADAPTER_SOURCE_READY; DEVICE_PENDING')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    prepare(Path(__file__).resolve().parents[1], args.out)
