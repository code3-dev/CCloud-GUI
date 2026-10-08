/* CCloud API client, the same endpoints the CCloud desktop app uses
 * (github.com/code3-dev/CCloud-GUI, lib/src/repositories). Like the desktop
 * app, a failed request is retried on the helper servers. */
(function () {
  var KEY = '4F5A9C3D9A86FA54EACEDDD635185';
  var SERVERS = ['https://server-hi-speed-iran.info', 'https://hostinnegar.com', 'https://windowsdiba.info'];
  var good = 0; // index of the server that answered last

  function fetchText(url, ms) {
    // XMLHttpRequest rather than fetch + AbortController, which older webOS lacks.
    return new Promise(function (resolve, reject) {
      var x = new XMLHttpRequest();
      x.open('GET', url);
      x.timeout = ms || 20000;
      x.onload = function () { if (x.status === 200) resolve(x.responseText); else reject(new Error('HTTP ' + x.status)); };
      x.onerror = function () { reject(new Error('network error')); };
      x.ontimeout = function () { reject(new Error('timeout')); };
      x.send();
    });
  }

  // path is everything after /api, without the key, e.g. "genre/all".
  // The server wants a trailing slash; without it, it answers with a redirect.
  function call(path) {
    var order = [good].concat(SERVERS.map(function (_, i) { return i; }).filter(function (i) { return i !== good; }));
    var i = 0;
    function attempt() {
      var idx = order[i];
      return fetchText(SERVERS[idx] + '/api/' + path + '/' + KEY + '/').then(function (t) {
        good = idx;
        return JSON.parse(t);
      }, function (e) {
        if (++i < order.length) return attempt();
        throw new Error('Could not reach the CCloud servers (' + e.message + ')');
      });
    }
    return attempt();
  }

  function list(x) { return Array.isArray(x) ? x : []; }

  function poster(p) {
    return {
      id: p.id, type: p.type === 'serie' ? 'serie' : 'movie', title: p.title || '',
      description: (p.description || '').replace(/\r/g, ''),
      year: p.year || 0, imdb: p.imdb || 0, duration: p.duration || '',
      image: p.image || '', cover: p.cover || p.image || '',
      genres: list(p.genres).map(function (g) { return g.title; }),
      countries: list(p.country).map(function (c) { return c.title; }),
      sources: list(p.sources).map(source)
    };
  }
  function source(s) {
    return { id: s.id, quality: s.quality || 'تیزر', type: (s.type || '').toLowerCase(), url: s.url || '' };
  }

  // Sort orders, as in the desktop app's FilterType.
  var SORTS = [
    { value: 'created', label: 'جدیدترین' },
    { value: 'year', label: 'سال انتشار' },
    { value: 'imdb', label: 'امتیاز IMDb' }
  ];

  window.Api = {
    SORTS: SORTS,
    // Home rows: genres with their newest posters.
    home: function () {
      return call('first').then(function (d) {
        return list(d.genres).map(function (g) {
          return { id: g.id, title: g.title, items: list(g.posters).map(poster) };
        }).filter(function (g) { return g.items.length; });
      });
    },
    movies: function (o) {
      return call('movie/by/filtres/' + (o.genre || 0) + '/' + (o.sort || 'created') + '/' + (o.page || 0)).then(function (d) { return list(d).map(poster); });
    },
    series: function (o) {
      return call('serie/by/filtres/' + (o.genre || 0) + '/' + (o.sort || 'created') + '/' + (o.page || 0)).then(function (d) { return list(d).map(poster); });
    },
    // Movies and series together, by genre and/or country (0 = any).
    posters: function (o) {
      return call('poster/by/filtres/' + Math.max(0, o.genre || 0) + '/' + (o.country || 0) + '/' + (o.sort || 'created') + '/' + (o.page || 0)).then(function (d) { return list(d).map(poster); });
    },
    genres: function () {
      return call('genre/all').then(function (d) {
        return list(d).map(function (g) { return { id: g.id, title: g.title }; })
          .sort(function (a, b) { return a.title.localeCompare(b.title, 'fa'); });
      });
    },
    countries: function () {
      return call('country/all').then(function (d) {
        return list(d).map(function (c) { return { id: c.id, title: c.title, image: c.image }; });
      });
    },
    search: function (q) {
      return call('search/' + encodeURIComponent(q)).then(function (d) { return list(d.posters).map(poster); });
    },
    seasons: function (serieId) {
      return call('season/by/serie/' + serieId).then(function (d) {
        return list(d).map(function (s) {
          return {
            id: s.id, title: s.title || '',
            episodes: list(s.episodes).map(function (e) {
              return { id: e.id, title: e.title || '', description: e.description || '', image: e.image || '', sources: list(e.sources).map(source) };
            })
          };
        });
      });
    }
  };
})();
