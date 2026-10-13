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
          !/^[a-f0-9]{64}$/.test(d.signature_cert_sha256)) {
        throw new Error('Invalid base APK metadata');
      }
      apkButton.href = './' + d.file;
      apkButton.download = d.file.split('/').pop();
      apkButton.hidden = false;
      const mib = (d.size_bytes / 1048576).toFixed(1);
      apkButton.textContent = '下载 Android 基础 APK (' + mib + ' MB)';
      apkStatus.textContent = '长期签名技术测试包 v' + d.version_name +
        ' · Android code ' + d.version_code +
        '。注意：v102 原生锁定竖屏，非已修复横屏的新版本。';
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
