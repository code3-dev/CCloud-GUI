/* Saved state, kept in localStorage like the desktop app's
 * shared_preferences: favorites, watch positions and preferences. */
(function () {
  function read(k, d) { try { var v = JSON.parse(localStorage.getItem('ccloud:' + k)); return v == null ? d : v; } catch (e) { return d; } }
  function write(k, v) { try { localStorage.setItem('ccloud:' + k, JSON.stringify(v)); } catch (e) {} }

  // Only what a card and the details screen need; sources are fetched again.
  function slim(p) {
    return { id: p.id, type: p.type, title: p.title, year: p.year, imdb: p.imdb, image: p.image, cover: p.cover, description: p.description, genres: p.genres, countries: p.countries, duration: p.duration };
  }

  window.Store = {
    favorites: function () { return read('favorites', []); },
    isFavorite: function (p) { return read('favorites', []).some(function (f) { return f.id === p.id && f.type === p.type; }); },
    toggleFavorite: function (p) {
      var list = read('favorites', []), i = -1;
      list.forEach(function (f, j) { if (f.id === p.id && f.type === p.type) i = j; });
      if (i >= 0) list.splice(i, 1); else list.unshift(slim(p));
      write('favorites', list);
      return i < 0;
    },
    clearFavorites: function () { write('favorites', []); },

    // Positions are keyed by video URL, so each quality and episode resumes on its own.
    position: function (url) { return (read('positions', {})[url] || {}).t || 0; },
    savePosition: function (url, t, d) {
      var all = read('positions', {});
      if (!d || t < 30 || t > d - 60) delete all[url];
      else all[url] = { t: Math.floor(t), at: Date.now() };
      var keys = Object.keys(all);
      if (keys.length > 300) keys.sort(function (a, b) { return all[a].at - all[b].at; }).slice(0, keys.length - 300).forEach(function (k) { delete all[k]; });
      write('positions', all);
    },
    clearPositions: function () { write('positions', {}); },

    prefs: function () { return read('prefs', {}); },
    setPref: function (k, v) { var p = read('prefs', {}); p[k] = v; write('prefs', p); }
  };
})();
