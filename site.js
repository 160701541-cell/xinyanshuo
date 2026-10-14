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

  // The log feed is generated from the private canonical main development
  // log by GitHub Actions. Only explicitly sanitized content is mirrored.
  // GitHub Pages/CDN propagation is usually seconds/minutes, not milliseconds.
  const developmentList = document.getElementById('development-list');
  const developmentSync = document.getElementById('development-sync');
  const developmentCount = document.getElementById('development-count');
  const moreButton = document.getElementById('development-more');
  const historyList = document.getElementById('release-history');
  const releaseSync = document.getElementById('release-sync');
  let allEntries = [];
  let visibleCount = 7;
  let lastDevelopmentDigest = '';
  let lastReleaseDigest = '';

  const safeDate = iso => {
    if (typeof iso !== 'string') return '时间待同步';
    const n = new Date(iso);
    return Number.isFinite(n.getTime())
      ? n.toLocaleString('zh-CN', { timeZone: 'Asia/Shanghai',
          year: 'numeric', month: '2-digit', day: '2-digit',
          hour: '2-digit', minute: '2-digit', hour12: false }) + '（北京时间）'
      : '时间待同步';
  };
  const getFreshJSON = async path => {
    const separator = path.includes('?') ? '&' : '?';
    const url = path + separator + 't=' + Math.floor(Date.now() / 50000);
    const r = await fetch(url, { cache: 'no-store' });
    if (!r.ok) throw new Error(path + ' (' + r.status + ')');
    return r.json();
  };
  const clear = element => { while (element.firstChild) element.firstChild.remove(); };
  const addText = (parent, tag, className, value) => {
    const node = document.createElement(tag);
    if (className) node.className = className;
    node.textContent = String(value);
    parent.appendChild(node);
    return node;
  };
  function renderDevelopment() {
    if (!developmentList) return;
    clear(developmentList);
    allEntries.slice(0, visibleCount).forEach(item => {
      const details = document.createElement('details');
      details.className = 'log-entry';
      const summary = document.createElement('summary');
      addText(summary, 'span', 'log-date', String(item.date || '开发记录').slice(0, 12));
      addText(summary, 'span', 'log-title', String(item.title || '未命名开发记录').slice(0, 190));
      addText(summary, 'span', 'log-tag', '实际工作日志');
      details.appendChild(summary);
      addText(details, 'div', 'log-content', String(item.body || '暂无详细说明').slice(0, 10000));
      developmentList.appendChild(details);
    });
    if (!allEntries.length) {
      addText(developmentList, 'p', 'loading-copy', '暂无可以公开的工作记录；请查看最新签名版本日志。');
    }
    developmentCount.textContent = '已展示 ' + Math.min(allEntries.length, visibleCount)
      + ' / ' + allEntries.length + ' 条正式开发记录';
    moreButton.hidden = visibleCount >= allEntries.length;
  }
  async function loadDevelopment() {
    try {
      const feed = await getFreshJSON('./data/development.json');
      if (feed.schema !== 1 || feed.channel !== 'public-development-log'
          || !Array.isArray(feed.entries) || feed.entries.length > 200
          || !feed.entries.every(item => typeof item.title === 'string' && typeof item.body === 'string')) {
        throw new Error('Unexpected development log schema');
      }
      const digest = JSON.stringify([feed.source_commit, feed.synced_at, feed.entries.length]);
      if (digest !== lastDevelopmentDigest) {
        allEntries = feed.entries;
        visibleCount = 7;
        lastDevelopmentDigest = digest;
        renderDevelopment();
      }
      developmentSync.textContent = '源码日志同步：' + safeDate(feed.synced_at);
      developmentSync.title = '源文件：' + String(feed.source_file || 'docs/DEVELOPMENT_LOG.md');
    } catch (e) {
      if (!allEntries.length) {
        clear(developmentList);
        addText(developmentList, 'p', 'loading-copy', '开发日志暂时无法读取。更新服务和游戏本身不受影响，请稍后重试。');
      }
      developmentSync.textContent = '正在等待工作日志同步';
    }
  }
  if (moreButton) moreButton.addEventListener('click', () => {
    visibleCount += 10;
    renderDevelopment();
  });

  function versionCard(item, live) {
    const card = document.createElement('article');
    card.className = 'release-item';
    const top = document.createElement('div');
    top.className = 'version-top';
    addText(top, 'span', 'version-label', live ? 'LATEST SIGNED RELEASE' : 'SIGNED RELEASE HISTORY');
    addText(top, 'span', 'signed-badge', '已签名发布');
    card.appendChild(top);
    addText(card, 'h3', '', '资源更新 #' + item.revision);
    addText(card, 'p', '', item.notes || '已发布并经过数字签名验证的游戏内容包。');
    addText(card, 'time', '', item.first_seen_utc
      ? ('官网首次记录：' + safeDate(item.first_seen_utc)) : '历史签名版本 · 原始精确发布时间未记录');
    if (item.version_name) addText(card, 'span', 'version-label', '关联Android基础包：' + item.version_name);
    if (item.sha256) addText(card, 'code', '', 'PCK SHA-256：' + item.sha256);
    return card;
  }
  async function loadReleases() {
    try {
      const [history, latest] = await Promise.all([
        getFreshJSON('./data/updates.json'),
        getFreshJSON('./android-preview/latest.json')
      ]);
      if (history.schema !== 1 || history.channel !== 'signed-releases'
          || !Array.isArray(history.entries) || history.entries.length > 200
          || latest.channel !== 'android-preview'
          || !Number.isSafeInteger(latest.revision) || latest.revision < 100
          || typeof latest.signature !== 'string' || latest.signature.length < 128
          || !/^[a-f0-9]{64}$/.test(latest.sha256)) throw new Error('Unsigned update metadata');
      const ordered = history.entries.filter(v => Number.isSafeInteger(v.revision)
        && v.revision <= latest.revision && /^[a-f0-9]{64}$/.test(v.sha256 || ''));
      const liveEntry = ordered.find(v => v.revision === latest.revision) || {};
      const current = Object.assign({}, liveEntry, {
        revision: latest.revision, sha256: latest.sha256,
        notes: liveEntry.notes || String(latest.notes || '签名内容已发布')
      });
      const list = [current].concat(ordered.filter(v => v.revision < latest.revision));
      const digest = list.map(v => String(v.revision) + v.sha256).join('|');
      if (digest !== lastReleaseDigest) {
        clear(historyList);
        list.slice(0, 12).forEach((item, i) => historyList.appendChild(versionCard(item, i === 0)));
        lastReleaseDigest = digest;
      }
      releaseSync.textContent = '当前签名内容：#' + latest.revision
        + ' · 历史版本记录 ' + list.length + ' 条 · 页面约60秒检查新版本；正式签名和兼容性校验仍在游戏客户端执行。';
    } catch (_) {
      if (!lastReleaseDigest) {
        clear(historyList);
        addText(historyList, 'p', 'loading-copy', '暂时无法获取带有签名凭证的更新历史。请以游戏内检查更新为准。');
      }
      releaseSync.textContent = '更新日志服务稍后重试；未验证版本不会显示。';
    }
  }
  // The contact controls do not require any third-party script, account
  // login, or external tracking. The public QQ invite was provided by the
  // project owner for publication on the official site.
  const copyQQ = document.getElementById('copy-qq');
  if (copyQQ) copyQQ.addEventListener('click', async () => {
    try {
      if (!navigator.clipboard || !window.isSecureContext) throw new Error('Clipboard API unavailable');
      await navigator.clipboard.writeText('160701541');
      copyQQ.textContent = '已复制 QQ：160701541 ✓';
    } catch (_) {
      copyQQ.textContent = 'QQ：160701541（可长按复制）';
    }
    setTimeout(() => { copyQQ.textContent = '复制QQ号'; }, 3000);
  });
  const menu = Array.from(document.querySelectorAll('.side-nav a'));
  for (const item of menu) item.addEventListener('click', () => {
    for (const link of menu) link.classList.toggle('active',link === item);
  });
  loadDevelopment();
  loadReleases();
  setInterval(() => {
    if (document.visibilityState !== 'hidden') {
      loadDevelopment();
      loadReleases();
    }
  }, 60000);
  document.addEventListener('visibilitychange', () => {
    if (document.visibilityState === 'visible') {
      loadDevelopment();
      loadReleases();
    }
  });
})();
