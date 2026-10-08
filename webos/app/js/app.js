/* Screens, routing and shared UI. The screens follow the CCloud desktop
 * app: movies, series, search, favorites, countries and settings, plus a
 * home screen built from the API's own home rows. */
(function () {
  var $ = function (id) { return document.getElementById(id); };
  var view = $('view');
  var stack = [];

  function h(tag, attrs, children) {
    var el = document.createElement(tag);
    Object.keys(attrs || {}).forEach(function (k) {
      if (k === 'class') el.className = attrs[k];
      else if (k === 'text') el.textContent = attrs[k];
      else el.setAttribute(k, attrs[k]);
    });
    (children || []).forEach(function (c) { if (c) el.appendChild(typeof c === 'string' ? document.createTextNode(c) : c); });
    return el;
  }
  function errText(e) { return (e && e.message) || String(e); }
  function loading(text) { return h('div', { class: 'loading', text: text || 'در حال بارگذاری…' }); }
  function fa(n) { return String(n).replace(/\d/g, function (d) { return '۰۱۲۳۴۵۶۷۸۹'[d]; }); }

  /* ---------- toast / picker ---------- */
  var toastTimer = 0;
  function toast(msg, ms) {
    var t = $('toast');
    t.textContent = msg; t.classList.remove('hidden');
    clearTimeout(toastTimer);
    toastTimer = setTimeout(function () { t.classList.add('hidden'); }, ms || 3500);
  }
  var modal = { open: false, prevFocus: null, handler: null };
  function pick(title, options, selected, onPick) {
    var box = $('modalBox');
    box.innerHTML = '';
    box.appendChild(h('h3', { text: title }));
    var selEl = null;
    options.forEach(function (o) {
      var b = h('button', { class: 'opt focusable' + (o.value === selected ? ' sel' : ''), text: o.label });
      b.addEventListener('click', function () { closeModal(); onPick(o.value); });
      if (o.value === selected) selEl = b;
      box.appendChild(b);
    });
    modal.open = true; modal.prevFocus = Nav.current;
    $('modal').classList.remove('hidden');
    box.scrollTop = 0;
    Nav.pushScope(box);
    modal.handler = function (key) { if (Nav.isBack(key)) { closeModal(); return true; } return false; };
    Nav.pushHandler(modal.handler);
    if (selEl) Nav.focus(selEl); else Nav.first();
  }
  function closeModal() {
    if (!modal.open) return;
    modal.open = false;
    $('modal').classList.add('hidden');
    Nav.popScope($('modalBox')); Nav.popHandler(modal.handler);
    if (modal.prevFocus && document.body.contains(modal.prevFocus)) Nav.focus(modal.prevFocus);
  }
  window.UI = { toast: toast, pick: pick, modalOpen: function () { return modal.open; } };

  /* ---------- cards ---------- */
  var seenObs = 'IntersectionObserver' in window ? new IntersectionObserver(function (entries) {
    entries.forEach(function (e) {
      if (!e.isIntersecting) return;
      seenObs.unobserve(e.target);
      e.target.src = e.target.dataset.src;
    });
  }, { rootMargin: '600px 900px' }) : null;
  function lazyImg(src, cls) {
    var i = new Image();
    i.className = cls; i.decoding = 'async';
    i.onerror = function () { i.style.visibility = 'hidden'; };
    if (src) { i.dataset.src = src; if (seenObs) seenObs.observe(i); else i.src = src; }
    return i;
  }
  function card(p) {
    var c = h('button', { class: 'card focusable' }, [
      h('div', { class: 'frame' }, [
        lazyImg(p.image, 'poster'),
        p.imdb ? h('span', { class: 'badge' }, [h('b', { text: '★ ' }), String(p.imdb)]) : null,
        p.type === 'serie' ? h('span', { class: 'kind', text: 'سریال' }) : null
      ]),
      h('div', { class: 'name', text: p.title + (p.year ? ' (' + p.year + ')' : '') })
    ]);
    c.addEventListener('click', function () { go('details', { poster: p }); });
    return c;
  }

  /* ---------- routing ---------- */
  var routes = {};
  function settle(entry, el) {
    if (stack[stack.length - 1] !== entry || Nav.moves !== entry.moves || Player.active || modal.open) return;
    if (el) Nav.focus(el); else Nav.first();
  }
  function render(entry) {
    view.innerHTML = '';
    view.appendChild(entry.el);
    if (entry.scroll) entry.el.scrollTop = entry.scroll;
    document.querySelectorAll('.menu-item').forEach(function (m) {
      m.classList.toggle('active', m.dataset.route === stack[0].route);
    });
  }
  function go(route, params, reset) {
    var top = stack[stack.length - 1];
    if (top && !reset) { top.focus = Nav.current; top.scroll = top.el.scrollTop; }
    if (reset) stack = [];
    var entry = { route: route, params: params || {}, el: h('div', { class: 'scroller' }), moves: Nav.moves };
    stack.push(entry);
    render(entry);
    routes[route](entry.el, entry.params, entry);
  }
  function back() {
    if (stack.length > 1) {
      stack.pop();
      var e = stack[stack.length - 1];
      render(e);
      if (e.onShow) e.onShow();
      if (e.focus && document.body.contains(e.focus)) Nav.focus(e.focus); else Nav.first();
      return true;
    }
    var menu = $('menu');
    if (!menu.contains(Nav.current)) { Nav.focus(menu.querySelector('.menu-item.active') || menu.querySelector('.menu-item')); return true; }
    window.close();
    return true;
  }
  function afterPlayer() {
    var e = stack[stack.length - 1];
    if (e && e.onShow) e.onShow();
    if (Nav.current && document.body.contains(Nav.current) && !Nav.current.closest('#player')) Nav.focus(Nav.current);
    else if (e && e.focus && document.body.contains(e.focus)) Nav.focus(e.focus);
    else Nav.first();
  }

  /* A grid that loads more pages as focus nears the end. load(page) returns
   * a promise of posters; pages start at 0, as in the API. */
  function grid(el, entry, load, emptyText) {
    var g = h('div', { class: 'grid' });
    var more = loading();
    el.appendChild(g); el.appendChild(more);
    var page = 0, busy = false, done = false, ids = {}, gen = {};
    function next() {
      if (busy || done) return;
      busy = true;
      var mine = gen;
      load(page).then(function (list) {
        if (mine !== gen) return;
        busy = false; page++;
        var first = null, added = 0;
        list.forEach(function (p) {
          var k = p.type + p.id;
          if (ids[k]) return;
          ids[k] = true; added++;
          var c = card(p); if (!first) first = c; g.appendChild(c);
        });
        if (!added) { done = true; more.remove(); }
        if (!g.children.length) el.appendChild(h('div', { class: 'empty', text: emptyText || 'چیزی پیدا نشد.' }));
        if (page === 1 && first) settle(entry, first);
      }, function (e) { if (mine !== gen) return; busy = false; more.textContent = 'خطا: ' + errText(e); });
    }
    function check() {
      var cards = g.children, cur = Nav.current;
      for (var i = Math.max(0, cards.length - 14); i < cards.length; i++) if (cards[i] === cur) { next(); break; }
    }
    entry.onNav = check;
    next();
    return { stop: function () { gen = null; } };
  }

  /* ---------- screens ---------- */
  routes.home = function (el, params, entry) {
    var box = h('div', {}, [loading()]);
    el.appendChild(box);
    Api.home().then(function (rows) {
      box.innerHTML = '';
      var settled = false;
      rows.forEach(function (r) {
        var items = h('div', { class: 'row-items', 'data-row': '1' });
        r.items.forEach(function (p) { items.appendChild(card(p)); });
        var all = h('button', { class: 'more focusable', text: 'همه' });
        all.addEventListener('click', function () { go('list', { title: r.title, genre: r.id }); });
        items.appendChild(all);
        box.appendChild(h('section', { class: 'row' }, [h('h2', { text: r.title }), items]));
        if (!settled) { settled = true; settle(entry, items.firstChild); }
      });
      if (!rows.length) box.appendChild(h('div', { class: 'empty', text: 'چیزی پیدا نشد.' }));
    }, function (e) {
      box.innerHTML = '';
      var retry = h('button', { class: 'btn primary focusable', text: 'تلاش دوباره' });
      retry.addEventListener('click', function () { go('home', {}, true); });
      box.appendChild(h('div', { class: 'empty', text: 'خطا: ' + errText(e) }));
      box.appendChild(retry);
      settle(entry, retry);
    });
  };

  routes.list = function (el, params, entry) {
    el.appendChild(h('h1', { class: 'page-title', text: params.title }));
    grid(el, entry, function (page) { return Api.posters({ genre: params.genre, country: params.country, page: page }); });
  };

  // Movies and Series: genre and sort filters, as in the desktop app.
  function catalog(kind) {
    return function (el, params, entry) {
      var p = Store.prefs();
      var state = { genre: 0, genreTitle: 'همه ژانرها', sort: p[kind + 'Sort'] || 'created' };
      var title = kind === 'movies' ? 'فیلم‌ها' : 'سریال‌ها';
      var gBtn = h('button', { class: 'btn focusable' });
      var sBtn = h('button', { class: 'btn focusable' });
      var body = h('div');
      el.appendChild(h('h1', { class: 'page-title', text: title }));
      el.appendChild(h('div', { class: 'filters' }, [gBtn, sBtn]));
      el.appendChild(body);
      var current = null;
      function label() {
        gBtn.textContent = 'ژانر: ' + state.genreTitle;
        sBtn.textContent = 'مرتب‌سازی: ' + Api.SORTS.filter(function (s) { return s.value === state.sort; })[0].label;
      }
      function load(focusFirst) {
        label();
        if (current) current.stop();
        body.innerHTML = '';
        entry.moves = focusFirst ? Nav.moves : -1;
        current = grid(body, entry, function (page) { return Api[kind]({ genre: state.genre, sort: state.sort, page: page }); });
      }
      gBtn.addEventListener('click', function () {
        Api.genres().then(function (gs) {
          var opts = [{ label: 'همه ژانرها', value: 0 }].concat(gs.map(function (g) { return { label: g.title, value: g.id }; }));
          pick('ژانر', opts, state.genre, function (id) {
            state.genre = id;
            state.genreTitle = opts.filter(function (o) { return o.value === id; })[0].label;
            load(false);
          });
        }, function (e) { toast('خطا: ' + errText(e)); });
      });
      sBtn.addEventListener('click', function () {
        pick('مرتب‌سازی', Api.SORTS, state.sort, function (v) { state.sort = v; Store.setPref(kind + 'Sort', v); load(false); });
      });
      load(true);
    };
  }
  routes.movies = catalog('movies');
  routes.series = catalog('series');

  routes.countries = function (el, params, entry) {
    el.appendChild(h('h1', { class: 'page-title', text: 'کشورها' }));
    var box = h('div', { class: 'chips' }, [loading()]);
    el.appendChild(box);
    Api.countries().then(function (cs) {
      box.innerHTML = '';
      cs.forEach(function (c) {
        var b = h('button', { class: 'chip focusable' }, [c.image ? lazyImg(c.image, '') : null, c.title]);
        b.addEventListener('click', function () { go('list', { title: c.title, country: c.id }); });
        box.appendChild(b);
      });
      settle(entry, box.firstChild);
    }, function (e) { box.textContent = 'خطا: ' + errText(e); });
  };

  routes.search = function (el, params, entry) {
    var input = h('input', { class: 'input focusable', type: 'text', placeholder: 'نام فیلم یا سریال' });
    var btn = h('button', { class: 'btn primary focusable', text: 'جستجو' });
    var results = h('div');
    el.appendChild(h('div', { class: 'search-box' }, [input, btn]));
    el.appendChild(results);
    function run() {
      var q = input.value.trim();
      results.innerHTML = '';
      if (!q) return;
      // Search returns a single page.
      grid(results, { moves: -1 }, function (page) { return page ? Promise.resolve([]) : Api.search(q); }, 'نتیجه‌ای برای «' + q + '» پیدا نشد.');
    }
    btn.addEventListener('click', run);
    input.addEventListener('submit-input', function () { input.blur(); run(); });
    settle(entry, input);
  };

  routes.favorites = function (el, params, entry) {
    el.appendChild(h('h1', { class: 'page-title', text: 'علاقه‌مندی‌ها' }));
    var g = h('div', { class: 'grid' });
    el.appendChild(g);
    function fill() {
      var keep = Nav.current && g.contains(Nav.current) ? Array.prototype.indexOf.call(g.children, Nav.current) : -1;
      g.innerHTML = '';
      var favs = Store.favorites();
      favs.forEach(function (p) { g.appendChild(card(p)); });
      if (!favs.length) g.appendChild(h('div', { class: 'empty', text: 'هنوز چیزی اضافه نکرده‌اید. در صفحه هر فیلم، «افزودن به علاقه‌مندی‌ها» را بزنید.' }));
      if (keep >= 0) Nav.focus(g.children[Math.min(keep, g.children.length - 1)]);
    }
    entry.onShow = fill;
    fill();
    settle(entry, g.querySelector('.card'));
  };

  routes.settings = function (el, params, entry) {
    var qBtn = h('button', { class: 'btn focusable' });
    qBtn.addEventListener('click', function () {
      var opts = ['480', '720', '1080'];
      pick('کیفیت پیش‌فرض', [{ label: 'خودکار', value: '' }].concat(opts.map(function (o) { return { label: o, value: o }; })), Store.prefs().qualityPrefix || '', function (v) {
        Store.setPref('qualityPrefix', v);
        qBtn.textContent = 'کیفیت پیش‌فرض: ' + (v || 'خودکار');
      });
    });
    qBtn.textContent = 'کیفیت پیش‌فرض: ' + (Store.prefs().qualityPrefix || 'خودکار');
    var favBtn = h('button', { class: 'btn focusable', text: 'پاک کردن علاقه‌مندی‌ها' });
    favBtn.addEventListener('click', function () { Store.clearFavorites(); toast('علاقه‌مندی‌ها پاک شد.'); });
    var posBtn = h('button', { class: 'btn focusable', text: 'پاک کردن سابقه تماشا' });
    posBtn.addEventListener('click', function () { Store.clearPositions(); toast('سابقه تماشا پاک شد.'); });
    el.appendChild(h('div', { class: 'settings' }, [
      h('h1', { class: 'page-title', text: 'تنظیمات' }),
      h('div', { class: 'actions' }, [qBtn, favBtn, posBtn]),
      h('h2', { text: 'درباره' }),
      h('p', { text: 'نسخه تلویزیون LG از CCloud، با همان سرورها و داده‌های برنامه دسکتاپ CCloud (github.com/code3-dev/CCloud-GUI).' }),
      h('p', { text: 'بیشتر سرورهای ویدیو فقط از داخل ایران در دسترس هستند. اگر ویدیویی شروع نشد، کیفیت یا لینک دیگری را امتحان کنید.' })
    ]));
    settle(entry, qBtn);
  };

  /* ---------- details ---------- */
  function sourceLabel(s) { return s.quality + (s.type ? ' · ' + s.type.toUpperCase() : ''); }

  // Preferred source: one matching the chosen quality prefix (e.g. "720"), else the first non-trailer.
  function preferred(sources) {
    var real = sources.filter(function (s) { return s.quality !== 'تیزر'; });
    var pref = Store.prefs().qualityPrefix;
    return (pref && real.filter(function (s) { return s.quality.indexOf(pref) === 0; })[0]) || real[0] || sources[0];
  }

  routes.details = function (el, params, entry) {
    var p = params.poster;
    var favBtn = h('button', { class: 'btn focusable' });
    function favLabel() { favBtn.textContent = Store.isFavorite(p) ? '★ حذف از علاقه‌مندی‌ها' : '☆ افزودن به علاقه‌مندی‌ها'; }
    favLabel();
    favBtn.addEventListener('click', function () { toast(Store.toggleFavorite(p) ? 'به علاقه‌مندی‌ها اضافه شد' : 'از علاقه‌مندی‌ها حذف شد'); favLabel(); });

    var meta = h('div', { class: 'd-meta' }, [
      p.year ? h('span', { text: String(p.year) }) : null,
      p.imdb ? h('span', {}, [h('b', { text: 'IMDb ' }), String(p.imdb)]) : null,
      p.duration ? h('span', { text: p.duration }) : null,
      p.countries && p.countries.length ? h('span', { text: p.countries.join('، ') }) : null
    ]);
    var actions = h('div', { class: 'actions' });
    var below = h('div');
    var backdrop = h('div', { class: 'backdrop' });
    if (p.cover) backdrop.style.backgroundImage = 'url("' + p.cover.replace(/"/g, '%22') + '")';
    el.appendChild(h('div', { class: 'details' }, [
      backdrop,
      h('div', { class: 'd-head' }, [
        h('img', { class: 'd-poster', src: p.image }),
        h('div', { class: 'd-info' }, [
          h('h1', { text: p.title }), meta,
          p.genres && p.genres.length ? h('div', { class: 'd-meta', text: p.genres.slice(0, 6).join(' · ') }) : null,
          h('p', { class: 'd-desc', text: p.description }),
          actions
        ])
      ]),
      below
    ]));

    if (p.type === 'serie') seriesDetails(p, actions, below, favBtn, entry);
    else movieDetails(p, actions, below, favBtn, entry);
  };

  function movieDetails(p, actions, below, favBtn, entry) {
    // Favorites only keep a summary, so fetch the sources when they are missing.
    var have = p.sources && p.sources.length ? Promise.resolve(p) : Api.search(p.title).then(function (list) {
      return list.filter(function (x) { return x.id === p.id && x.type === p.type; })[0] || p;
    });
    actions.appendChild(loading());
    have.then(function (full) {
      actions.innerHTML = '';
      var sources = full.sources || [];
      if (!sources.length) {
        actions.appendChild(favBtn);
        below.appendChild(h('div', { class: 'empty', text: 'لینکی برای پخش این عنوان وجود ندارد.' }));
        settle(entry, favBtn);
        return;
      }
      var play = h('button', { class: 'btn primary focusable', text: '▶ پخش' });
      play.addEventListener('click', function () { Player.open({ title: p.title, sub: p.year ? String(p.year) : '', sources: sources, source: preferred(sources) }); });
      actions.appendChild(play); actions.appendChild(favBtn);
      below.appendChild(h('h2', { class: 'section-title', text: 'کیفیت‌ها' }));
      var row = h('div', { class: 'actions sources' });
      sources.forEach(function (s) {
        var b = h('button', { class: 'btn focusable', text: sourceLabel(s) });
        b.addEventListener('click', function () { Player.open({ title: p.title, sub: sourceLabel(s), sources: sources, source: s }); });
        row.appendChild(b);
      });
      below.appendChild(row);
      settle(entry, play);
    }, function (e) { actions.innerHTML = ''; actions.appendChild(favBtn); toast('خطا: ' + errText(e)); settle(entry, favBtn); });
  }

  function seriesDetails(p, actions, below, favBtn, entry) {
    actions.appendChild(favBtn);
    var seasonsBox = h('div', { class: 'chips', 'data-row': '1' });
    var eps = h('div', { class: 'episodes' });
    below.appendChild(h('h2', { class: 'section-title', text: 'فصل‌ها' }));
    below.appendChild(seasonsBox);
    below.appendChild(eps);
    eps.appendChild(loading());
    var seasons = [], cur = 0;

    function playEpisode(si, ei, source) {
      var s = seasons[si], e = s.episodes[ei];
      var nextIdx = ei + 1 < s.episodes.length ? [si, ei + 1] : (si + 1 < seasons.length && seasons[si + 1].episodes.length ? [si + 1, 0] : null);
      var nextEp = nextIdx && seasons[nextIdx[0]].episodes[nextIdx[1]];
      var src = source || preferred(e.sources);
      // Keep the same quality for the next episode where it exists.
      var nextSrc = function () {
        var list = nextEp.sources;
        return list.filter(function (x) { return x.quality === src.quality; })[0];
      };
      Player.open({
        title: p.title, sub: s.title + ' · ' + e.title, sources: e.sources, source: src,
        next: nextEp && nextEp.sources.length ? { open: function () { playEpisode(nextIdx[0], nextIdx[1], nextSrc()); } } : null
      });
    }

    function showSeason(si) {
      cur = si;
      Array.prototype.forEach.call(seasonsBox.children, function (c, i) { c.classList.toggle('on', i === si); });
      eps.innerHTML = '';
      var s = seasons[si];
      s.episodes.forEach(function (e, ei) {
        var src = preferred(e.sources);
        var pos = src ? Store.position(src.url) : 0;
        var b = h('button', { class: 'ep focusable' }, [
          h('span', { class: 'n', text: fa(ei + 1) }),
          h('span', { text: e.title }),
          pos ? h('span', { class: 'pos', text: 'ادامه' }) : null
        ]);
        if (!e.sources.length) b.disabled = true;
        // Plays the preferred quality; the player's Quality button switches.
        b.addEventListener('click', function () { playEpisode(si, ei); });
        eps.appendChild(b);
      });
      if (!s.episodes.length) eps.appendChild(h('div', { class: 'empty', text: 'قسمتی وجود ندارد.' }));
    }
    entry.onShow = function () { if (seasons.length) { var f = Nav.current, idx = Array.prototype.indexOf.call(eps.children, f); showSeason(cur); if (idx >= 0) Nav.focus(eps.children[idx]); } };

    Api.seasons(p.id).then(function (list) {
      seasons = list;
      eps.innerHTML = '';
      list.forEach(function (s, si) {
        var b = h('button', { class: 'chip focusable', text: s.title });
        b.addEventListener('click', function () { showSeason(si); Nav.focus(eps.querySelector('.focusable') || b); });
        seasonsBox.appendChild(b);
      });
      if (!list.length) { eps.appendChild(h('div', { class: 'empty', text: 'قسمتی برای این سریال ثبت نشده است.' })); settle(entry, favBtn); return; }
      showSeason(0);
      settle(entry, seasonsBox.firstChild);
    }, function (e) { eps.innerHTML = ''; eps.appendChild(h('div', { class: 'empty', text: 'خطا: ' + errText(e) })); settle(entry, favBtn); });
  }

  /* ---------- keys ---------- */
  Nav.pushHandler(function (key) {
    if (Player.active) return false;
    if (Nav.isBack(key)) return back();
    return false;
  });
  document.addEventListener('keydown', function () {
    var top = stack[stack.length - 1];
    if (top && top.onNav) setTimeout(top.onNav, 0);
  });

  document.querySelectorAll('.menu-item').forEach(function (m) {
    m.addEventListener('click', function () { go(m.dataset.route, {}, true); });
  });

  window.App = { go: go, afterPlayer: afterPlayer };

  Player.init();
  go('home', {}, true);
})();
