/* Video player. Sources are plain MP4/MKV files, which the TV's own media
 * pipeline plays directly (including MKV with several audio and subtitle
 * tracks, when the TV exposes them).
 *
 * Most CCloud video servers only accept connections from Iranian IPs. If a
 * file does not start within a while, the player says so instead of
 * spinning forever. */
(function () {
  var $ = function (id) { return document.getElementById(id); };
  var root, video, overlay, st = null, hideTimer = 0, stallTimer = 0, saveTimer = 0, handler = null;
  var START_TIMEOUT = 25000;

  function fmt(t) {
    t = Math.max(0, Math.floor(t || 0));
    var h = Math.floor(t / 3600), m = Math.floor(t / 60) % 60, s = t % 60;
    return (h ? h + ':' + (m < 10 ? '0' : '') : '') + m + ':' + (s < 10 ? '0' : '') + s;
  }
  function host(u) { var m = /^https?:\/\/([^/]+)/.exec(u); return m ? m[1] : u; }

  function savePos() {
    if (st && st.src && video.duration) Store.savePosition(st.src.url, video.currentTime, video.duration);
  }

  function fail(msg) {
    clearTimeout(stallTimer);
    if (!st) return;
    $('spinner').classList.add('hidden');
    $('ovMsg').textContent = msg;
    $('ovMsg').classList.remove('hidden');
    showOverlay($('btnQuality'));
  }

  function attach(src, startAt) {
    st.src = src;
    st.started = false;
    $('ovMsg').classList.add('hidden');
    $('btnQuality').textContent = 'کیفیت: ' + src.quality;
    video.pause();
    video.removeAttribute('src'); video.load();
    $('spinner').classList.remove('hidden');
    video.src = src.url;
    // A property handler rather than addEventListener({ once }), which older webOS lacks.
    video.onloadedmetadata = function () {
      video.onloadedmetadata = null;
      if (!st || st.src !== src) return;
      var t = startAt != null ? startAt : Store.position(src.url);
      if (t > 0) { try { video.currentTime = t; } catch (e) {} if (startAt == null) UI.toast('ادامه از ' + fmt(t)); }
      updateTrackButtons();
    };
    video.play().catch(function () {});
    clearTimeout(stallTimer);
    stallTimer = setTimeout(function () {
      if (st && st.src === src && !st.started) {
        fail('سرور ' + host(src.url) + ' پاسخ نمی‌دهد. بیشتر سرورهای CCloud فقط از داخل ایران در دسترس هستند. کیفیت دیگری را امتحان کنید.');
      }
    }, START_TIMEOUT);
  }

  /* ctx: { title, sub, sources, source, next?: { open: fn } } */
  function open(ctx) {
    if (!ctx.sources || !ctx.sources.length) { UI.toast('لینکی برای پخش وجود ندارد'); return; }
    if (st) teardown();
    st = { ctx: ctx, src: null, started: false };
    $('ovTitle').textContent = ctx.title;
    $('ovSub').textContent = ctx.sub || '';
    $('btnNext').classList.toggle('hidden', !ctx.next);
    root.classList.remove('hidden');
    Nav.pushScope(overlay);
    handler = onKey; Nav.pushHandler(handler);
    showOverlay();
    attach(ctx.source || ctx.sources[0]);
    saveTimer = setInterval(savePos, 10000);
  }

  function teardown() {
    savePos();
    clearTimeout(hideTimer); clearTimeout(stallTimer); clearInterval(saveTimer);
    video.pause(); video.removeAttribute('src'); video.load();
    Nav.popScope(overlay); Nav.popHandler(handler);
    st = null;
  }

  function close() {
    if (!st) return;
    teardown();
    root.classList.add('hidden'); overlay.classList.add('hidden');
    App.afterPlayer();
  }

  function showOverlay(focusEl) {
    overlay.classList.remove('hidden');
    if (focusEl) Nav.focus(focusEl);
    else if (!Nav.current || !overlay.contains(Nav.current)) Nav.focus($('btnPlay'));
    armHide();
  }
  function hideOverlay() { overlay.classList.add('hidden'); clearTimeout(hideTimer); }
  function armHide() {
    clearTimeout(hideTimer);
    hideTimer = setTimeout(function () {
      if (!video.paused && !UI.modalOpen() && $('ovMsg').classList.contains('hidden')) hideOverlay();
    }, 5000);
  }

  function toggle() { if (video.paused) video.play().catch(function () {}); else video.pause(); }
  function seek(d) {
    if (!video.duration) return;
    video.currentTime = Math.max(0, Math.min(video.duration - 1, video.currentTime + d));
  }

  function tracks(kind) {
    var l = video[kind];
    var out = [];
    if (!l) return out;
    for (var i = 0; i < l.length; i++) out.push(l[i]);
    return out;
  }
  function trackName(t, i) { return t.label || t.language || ('#' + (i + 1)); }
  function updateTrackButtons() {
    $('btnAudio').classList.toggle('hidden', tracks('audioTracks').length < 2);
    $('btnSubs').classList.toggle('hidden', !tracks('textTracks').length);
  }

  function act(name) {
    if (!st) return;
    if (name === 'play') toggle();
    else if (name === 'back10') seek(-10);
    else if (name === 'fwd30') seek(30);
    else if (name === 'next' && st.ctx.next) { var n = st.ctx.next; savePos(); n.open(); }
    else if (name === 'quality') {
      UI.pick('کیفیت', st.ctx.sources.map(function (s, i) { return { label: s.quality + ' · ' + (s.type || '').toUpperCase(), value: i }; }),
        st.ctx.sources.indexOf(st.src), function (i) {
          var s = st.ctx.sources[i];
          var digits = /^\d+/.exec(s.quality);
          if (digits) Store.setPref('qualityPrefix', digits[0]);
          var t = st.started ? video.currentTime : null;
          attach(s, t);
        });
    } else if (name === 'audio') {
      var a = tracks('audioTracks');
      var cur = a.filter(function (t) { return t.enabled; })[0];
      UI.pick('صدا', a.map(function (t, i) { return { label: trackName(t, i), value: i }; }), a.indexOf(cur), function (i) {
        a.forEach(function (t, j) { t.enabled = j === i; });
      });
    } else if (name === 'subs') {
      var s = tracks('textTracks');
      var on = s.filter(function (t) { return t.mode === 'showing'; })[0];
      var opts = [{ label: 'خاموش', value: -1 }].concat(s.map(function (t, i) { return { label: trackName(t, i), value: i }; }));
      UI.pick('زیرنویس', opts, on ? s.indexOf(on) : -1, function (i) {
        s.forEach(function (t, j) { t.mode = j === i ? 'showing' : 'disabled'; });
      });
    }
  }

  function onKey(key) {
    if (UI.modalOpen()) return false;
    var K = Nav.K, hidden = overlay.classList.contains('hidden');
    if (Nav.isBack(key)) { if (!hidden && !video.paused) hideOverlay(); else close(); return true; }
    if (key === K.PLAY) { video.play().catch(function () {}); showOverlay(); return true; }
    if (key === K.PAUSE) { video.pause(); showOverlay(); return true; }
    if (key === K.PLAYPAUSE) { toggle(); showOverlay(); return true; }
    if (key === K.STOP) { close(); return true; }
    if (key === K.RW) { seek(-10); showOverlay(); return true; }
    if (key === K.FF) { seek(30); showOverlay(); return true; }
    if (key === K.YELLOW) { act('quality'); return true; }
    if (hidden) {
      // RTL layout, but the remote's arrows keep their physical meaning.
      if (key === K.ENTER) { toggle(); showOverlay(); return true; }
      if (key === K.LEFT) { seek(-10); showOverlay($('progress')); return true; }
      if (key === K.RIGHT) { seek(10); showOverlay($('progress')); return true; }
      if (key === K.UP || key === K.DOWN) { showOverlay(); return true; }
      return true;
    }
    armHide();
    if (Nav.current === $('progress') && (key === K.LEFT || key === K.RIGHT)) { seek(key === K.LEFT ? -10 : 10); return true; }
    return false;
  }

  function init() {
    root = $('player'); video = $('video'); overlay = $('overlay');
    $('controls').addEventListener('click', function (e) {
      var b = e.target.closest('[data-act]'); if (b) { act(b.dataset.act); armHide(); }
    });
    $('progress').addEventListener('click', toggle);
    video.addEventListener('playing', function () {
      if (!st) return;
      st.started = true; clearTimeout(stallTimer);
      $('ovMsg').classList.add('hidden');
      $('spinner').classList.add('hidden'); $('btnPlay').textContent = 'توقف'; armHide();
    });
    video.addEventListener('pause', function () { if (st) { $('btnPlay').textContent = 'پخش'; savePos(); showOverlay(); } });
    video.addEventListener('waiting', function () { if (st) $('spinner').classList.remove('hidden'); });
    video.addEventListener('error', function () {
      if (!st || !video.getAttribute('src')) return;
      var code = video.error && video.error.code;
      fail(code === 4
        ? 'این فایل پخش نمی‌شود یا سرور ' + host(st.src.url) + ' در دسترس نیست. کیفیت دیگری را امتحان کنید.'
        : 'خطا در پخش (' + code + '). کیفیت دیگری را امتحان کنید.');
    });
    video.addEventListener('ended', function () {
      if (!st) return;
      Store.savePosition(st.src.url, 0, 0);
      if (st.ctx.next) showOverlay($('btnNext')); else showOverlay();
    });
    video.addEventListener('timeupdate', function () {
      var d = video.duration || 0, t = video.currentTime;
      $('progFill').style.width = d ? (t / d * 100) + '%' : '0';
      $('tCur').textContent = fmt(t); $('tDur').textContent = fmt(d);
      var b = video.buffered; if (d && b.length) $('progBuf').style.width = (b.end(b.length - 1) / d * 100) + '%';
    });
    document.addEventListener('visibilitychange', function () { if (document.hidden && st) { savePos(); video.pause(); } });
  }

  window.Player = { init: init, open: open, close: close, get active() { return !!st; } };
})();
