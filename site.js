'use strict';
(() => {
  const badge = document.getElementById('status-badge');
  const title = document.getElementById('release-title');
  const notes = document.getElementById('release-notes');
  const revision = document.getElementById('revision');
  const size = document.getElementById('pack-size');
  document.getElementById('year').textContent = String(new Date().getFullYear());
  // The public website hosts APK + signed PCK independently, under the SAME
  // GitHub Pages origin. Never feed the APK manifest to the PCK update parser.
  const apkStatus = document.getElementById('apk-download-status');
  const apkButton = document.getElementById('apk-download-link');
  const apkHash = document.getElementById('apk-hash');
  fetch('./android-preview/base-latest.json', { cache: 'no-store' })
    .then(r => { if (!r.ok) throw new Error('APK not published'); return r.json(); })
    .then(d => {
      // Only allow same-site, explicitly namespaced APK files.
      if (d.schema !== 1 || d.channel !== 'android-preview-base-apk' ||
          !Number.isSafeInteger(d.version_code) || d.version_code < 1102 ||
          d.package_name !== 'org.canglan.ancient25d.preview' ||
          typeof d.file !== 'string' ||
          !/^android-preview\/base\/[A-Za-z0-9._-]+\.apk$/.test(d.file) ||
          typeof d.sha256 !== 'string' || !/^[a-f0-9]{64}$/.test(d.sha256) ||
          !Number.isSafeInteger(d.size_bytes) || d.size_bytes <= 10000000 ||
          typeof d.signature_cert_sha256 !== 'string' ||
          d.signature_cert_sha256 !== '353c65d2bdde16509b33c976e9bed615013080b071629cfbf7fdeb43e4217057') {
        throw new Error('Invalid base APK metadata');
      }
      apkButton.href = './' + d.file;
      apkButton.download = d.file.split('/').pop();
      apkButton.hidden = false;
      const mib = (d.size_bytes / 1048576).toFixed(1);
      apkButton.textContent = '下载 Android 基础 APK (' + mib + ' MB)';
      const landscape = d.orientation === 'landscape_native_manifest_verified';
      apkStatus.textContent = '固定签名 Android APK v' + d.version_name +
        ' · Android code ' + d.version_code +
        (landscape
          ? '。原生横屏已通过安装包清单验证，手机实际操作/美术仍待测试。'
          : '。注意：旧版原生锁定竖屏，新横屏包尚未取代它。');
      apkHash.textContent = '文件 SHA-256：' + d.sha256;
    })
    .catch(() => {
      apkStatus.textContent = '基础 APK 暂未通过公开发布校验。请勿下载不明来源安装包。';
      apkButton.hidden = true;
    });

  // Display-only metadata. Cryptographic verification is ALWAYS performed
  // by the signed, immutable Godot APK before loading any executable PCK.
  fetch('./android-preview/latest.json', { cache: 'no-store' })
    .then(r => { if (!r.ok) throw new Error('not published'); return r.json(); })
    .then(d => {
      if (d.channel !== 'android-preview' || !Number.isSafeInteger(d.revision) ||
          typeof d.signature !== 'string' || d.signature.length < 128 ||
          typeof d.sha256 !== 'string' || !/^[a-f0-9]{64}$/.test(d.sha256)) return;
      badge.textContent = '已发布';
      badge.classList.remove('pending');
      badge.classList.add('ready');
      title.textContent = '世界资源更新 #' + d.revision;
      notes.textContent = typeof d.notes === 'string' ? d.notes.slice(0, 256) : '新资源已准备好，进入游戏检查更新。';
      revision.textContent = '#' + d.revision;
      size.textContent = Number.isFinite(d.size_bytes) ? (d.size_bytes / 1048576).toFixed(2) + ' MB' : '—';
    })
    .catch(() => { /* Missing feed is NORMAL before first actual signed release. */ });
})();
