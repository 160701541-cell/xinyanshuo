'use strict';
(() => {
  const badge = document.getElementById('status-badge');
  const title = document.getElementById('release-title');
  const notes = document.getElementById('release-notes');
  const revision = document.getElementById('revision');
  const size = document.getElementById('pack-size');
  document.getElementById('year').textContent = String(new Date().getFullYear());
  // Official community: plain digits are copyable even if a mobile browser
  // does not support the external QQ deep-link URI.
  const copyQQ = document.getElementById('copy-qq');
  if (copyQQ) copyQQ.addEventListener('click', async () => {
    const original = copyQQ.textContent;
    try {
      await navigator.clipboard.writeText('160701541');
      copyQQ.textContent = '已复制 160701541';
    } catch (_) {
      // Copy fallback for WebViews and non-secure contexts.
      const input = document.createElement('textarea');
      input.value = '160701541';
      input.setAttribute('readonly', '');
      input.style.position = 'fixed';
      input.style.opacity = '0';
      document.body.appendChild(input);
      input.select();
      const copied = document.execCommand('copy');
      input.remove();
      copyQQ.textContent = copied ? '已复制 160701541' : 'QQ：160701541（长按复制）';
    }
    setTimeout(() => { copyQQ.textContent = original; }, 2800);
  });

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
        + ' · 历史版本记录 ' + list.length + ' 条 · 页面约120秒检查新版本；正式签名和兼容性校验仍在游戏客户端执行。';
    } catch (_) {
      if (!lastReleaseDigest) {
        clear(historyList);
        addText(historyList, 'p', 'loading-copy', '暂时无法获取带有签名凭证的更新历史。请以游戏内检查更新为准。');
      }
      releaseSync.textContent = '更新日志服务稍后重试；未验证版本不会显示。';
    }
  }
  // Project control room: static JSON is EVENT-PUSHED from GitHub Actions.
  // The visitor polls CDN data every 120s, NEVER the private GitHub API.
  // Thus unlimited visitors do NOT exhaust the GitHub REST rate limit.
  const observerRows = document.getElementById('build-observer-rows');
  const observerPRs = document.getElementById('build-observer-prs');
  const observerSync = document.getElementById('build-observer-sync');
  const apkLive = document.getElementById('build-apk-state');
  const apkDetail = document.getElementById('build-apk-note');
  const workflowLive = document.getElementById('build-workflow-state');
  const workflowDetail = document.getElementById('build-workflow-note');
  const statusText = {
    queued: '等待构建', requested: '等待启动', pending: '等待启动', waiting: '等待资源',
    in_progress: '正在执行', completed: '构建已结束'
  };
  const conclusionText = {
    success: '成功', failure: '失败', cancelled: '已取消',
    timed_out: '已超时', skipped: '已跳过', startup_failure: '未能启动',
    action_required: '等待人工处理', neutral: '已结束', stale: '已过期'
  };
  let lastObserverDigest = '';
  async function loadBuildObserver() {
    if (!observerRows) return;
    try {
      const feed = await getFreshJSON('./data/build-status.json');
      if (feed.schema !== 1 || feed.channel !== 'canglan-build-observer'
          || !Array.isArray(feed.runs) || feed.runs.length > 25
          || !feed.runs.every(x => Number.isSafeInteger(x.id)
            && typeof x.workflow === 'string' && typeof x.status === 'string')) {
        throw new Error('Invalid observer channel');
      }
      const digest = JSON.stringify(feed);
      if (digest !== lastObserverDigest) {
        clear(observerRows);
        if (observerPRs) {
          clear(observerPRs);
          const recentPRs = Array.isArray(feed.pull_requests)
            ? feed.pull_requests.slice(0, 8) : [];
          if (!recentPRs.length) {
            addText(observerPRs, 'p', 'loading-copy',
              '尚未收到最新的PR打开、更新或合并事件；请以GitHub实际提交为准。');
          }
          recentPRs.forEach(pr => {
            if (!Number.isSafeInteger(pr.number) || pr.number <= 0) return;
            const card = document.createElement('article');
            card.className = 'observer-run';
            addText(card, 'strong', 'observer-run-title', '#' + pr.number + ' · '
              + String(pr.title || '开发任务').slice(0, 120));
            const merged = pr.state === 'merged';
            const state = merged ? '已合并'
              : pr.state === 'closed' ? '已关闭'
              : pr.draft ? '草案 / 进行中' : '待审核 / 开发中';
            addText(card, 'span', 'observer-pill' + (merged ? ' passed' : ''), state);
            addText(card, 'p', 'observer-run-meta',
              String(pr.scope || '开发分支') + ' · '
              + String(pr.branch || '未知分支').slice(0, 55) + ' · 更新于：'
              + safeDate(pr.last_event_utc));
            const link = document.createElement('a');
            link.href = 'https://github.com/160701541-cell/canglan-world/pull/' + pr.number;
            link.target = '_blank';
            link.rel = 'noopener noreferrer';
            link.textContent = '查看真实PR进度 ↗';
            card.appendChild(link);
            observerPRs.appendChild(card);
          });
        }
        clear(observerRows);
        const latest = feed.runs.slice(0, 9);
        if (!latest.length) {
          addText(observerRows, 'p', 'loading-copy', '尚无新的工作流事件，等待下一次GitHub运行回传。');
        }
        latest.forEach(run => {
          const card = document.createElement('article');
          card.className = 'observer-run';
          const status = run.status === 'completed'
            ? (conclusionText[run.conclusion] || '已结束')
            : (statusText[run.status] || '状态待确认');
          const dt = new Date(run.last_event_utc || '');
          const age = Number.isFinite(dt.getTime()) ? Date.now() - dt.getTime() : NaN;
          const delayed = run.status !== 'completed' && (Number.isNaN(age) || age > 40 * 60000);
          const state = delayed ? '超过40分钟无新事件 · 待确认' : status;
          addText(card, 'strong', 'observer-run-title', String(run.workflow).slice(0, 120));
          addText(card, 'span', 'observer-pill' + (run.conclusion === 'failure' ? ' failed' : run.conclusion === 'success' ? ' passed' : ''), state);
          addText(card, 'p', 'observer-run-meta', String(run.scope || '开发任务')
            + ' · ' + String(run.branch || '未知分支').slice(0, 50)
            + ' · 最近事件：' + safeDate(run.last_event_utc));
          const link = document.createElement('a');
          link.textContent = 'GitHub构建 #' + String(run.id) + ' ↗';
          link.href = 'https://github.com/160701541-cell/canglan-world/actions/runs/' + run.id;
          link.target = '_blank';
          link.rel = 'noopener noreferrer';
          card.appendChild(link);
          observerRows.appendChild(card);
        });
        lastObserverDigest = digest;
      }
      const apk = feed.signed_release || {};
      apkLive.textContent = apk.apk_published
        ? '已发布 APK v' + String(apk.apk_version || '?') : '尚未完成APK实体文件核验';
      apkDetail.textContent = apk.apk_published
        ? 'Android code ' + String(apk.apk_code) + ' · 官方同证书 · 已校验文件SHA256'
        : '仅凭CI绿色不能证明新包已发布；请查看已签名下载入口';
      const newest = feed.runs[0];
      workflowLive.textContent = newest
        ? (newest.status === 'completed'
          ? (conclusionText[newest.conclusion] || '已结束')
          : (statusText[newest.status] || '等待确认'))
        : '暂未收到构建事件';
      workflowDetail.textContent = newest
        ? String(newest.workflow).slice(0, 100)
          + ' · #' + newest.id + ' · ' + safeDate(newest.last_event_utc)
        : 'GitHub事件推送到官网，不查询私有仓库API';
      if (observerSync) {
        const newestTime = newest ? newest.last_event_utc : feed.observed_at_utc;
        const age = Date.now() - new Date(newestTime || '').getTime();
        const freshness = Number.isFinite(age) && age > 40 * 60000
          ? ' · 注意：最后事件距今超过40分钟，任务运行状态请点开GitHub确认。'
          : '';
        observerSync.textContent = '最新可见工作流事件：'
          + safeDate(newestTime) + ' · 官网静态数据每120秒检查；非持续GitHub API轮询。'
          + freshness;
      }
    } catch (error) {
      if (observerSync) observerSync.textContent =
        '构建监测数据暂时无法同步；未知不代表成功或失败。请以GitHub构建记录及签名APK清单为准。';
      if (workflowLive) workflowLive.textContent = '监测暂不可用 · 状态待确认';
      if (apkLive) apkLive.textContent = '暂无法校验最新APK';
    }
  }

  loadDevelopment();
  loadReleases();
  loadBuildObserver();
  setInterval(() => {
    if (document.visibilityState !== 'hidden') {
      loadDevelopment();
      loadReleases();
      loadBuildObserver();
    }
  }, 120000);
  document.addEventListener('visibilitychange', () => {
    if (document.visibilityState === 'visible') {
      loadDevelopment();
      loadReleases();
      loadBuildObserver();
    }
  });
})();
