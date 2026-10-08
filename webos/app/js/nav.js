/* Spatial navigation for the TV remote.
 *
 * Every actionable element has the class `focusable`; arrows move focus to
 * the nearest focusable in that direction inside the current scope, OK
 * clicks it. Views and the player push key handlers that get first look at
 * each key press. Works with the Magic Remote pointer too (hover focuses,
 * click is a normal click). */
(function () {
  var K = {
    LEFT: 37, UP: 38, RIGHT: 39, DOWN: 40, ENTER: 13, BACK: 461, ESC: 27, BACKSPACE: 8,
    PLAY: 415, PAUSE: 19, PLAYPAUSE: 179, STOP: 413, FF: 417, RW: 412,
    RED: 403, GREEN: 404, YELLOW: 405, BLUE: 406
  };
  var current = null;
  var moves = 0;         // bumped on every user arrow press
  var scopes = [];      // stack of root elements; top one restricts navigation
  var handlers = [];    // stack of fn(key, event) -> true if handled

  function scope() { return scopes.length ? scopes[scopes.length - 1] : document.body; }
  function visible(el) { return el.getClientRects().length > 0 && !el.closest('.hidden'); }
  function isInput(el) { return el && (el.tagName === 'INPUT' || el.tagName === 'TEXTAREA'); }

  function focus(el) {
    if (!el) return;
    if (current && current !== el) current.classList.remove('focused');
    var trap = el.closest('[data-trap]');
    if (trap && current && !trap.contains(current)) trap._outside = current;
    current = el;
    el.classList.add('focused');
    if (!isInput(el)) {
      if (isInput(document.activeElement)) document.activeElement.blur();
      try { el.focus({ preventScroll: true }); } catch (e) { el.focus(); }
    }
    ensureVisible(el);
    var row = el.closest('[data-row]');
    if (row) row._last = el;
  }

  function ensureVisible(el) {
    var p = el.parentElement;
    while (p && p !== document.body) {
      var cs = getComputedStyle(p);
      var r = el.getBoundingClientRect(), pr = p.getBoundingClientRect();
      if (/(auto|scroll)/.test(cs.overflowX) && p.scrollWidth > p.clientWidth) {
        var padX = 60;
        if (r.left < pr.left + padX) p.scrollLeft -= (pr.left + padX - r.left);
        else if (r.right > pr.right - padX) p.scrollLeft += (r.right - pr.right + padX);
      }
      if (/(auto|scroll)/.test(cs.overflowY) && p.scrollHeight > p.clientHeight) {
        var padY = 140;
        if (r.top < pr.top + padY) p.scrollTop -= (pr.top + padY - r.top);
        else if (r.bottom > pr.bottom - padY) p.scrollTop += (r.bottom - pr.bottom + padY);
      }
      p = p.parentElement;
    }
  }

  function candidates() {
    return Array.prototype.filter.call(scope().querySelectorAll('.focusable'), function (el) {
      return el !== current && visible(el) && !el.disabled;
    });
  }

  function usable(el) { return el && document.body.contains(el) && visible(el) && scope().contains(el); }

  function move(dir) {
    var list = candidates();
    if (!usable(current)) {
      focus(first());
      return true;
    }
    // A container with data-trap="up,down" keeps those directions inside it;
    // leaving it any other way returns to where focus was before entering.
    var trap = current.closest('[data-trap]');
    if (trap) {
      if (trap.dataset.trap.split(',').indexOf(dir) >= 0) {
        list = list.filter(function (el) { return trap.contains(el); });
      } else {
        list = list.filter(function (el) { return !trap.contains(el); });
        if (usable(trap._outside)) { focus(trap._outside); return true; }
      }
    }
    var a = current.getBoundingClientRect();
    var ax = a.left + a.width / 2, ay = a.top + a.height / 2;
    var best = null, bestScore = Infinity;
    list.forEach(function (el) {
      var b = el.getBoundingClientRect();
      var bx = b.left + b.width / 2, by = b.top + b.height / 2;
      var primary, secondary;
      if (dir === 'right') { if (b.left < a.right - 5 && bx <= ax + 5) return; primary = Math.max(0, b.left - a.right); secondary = Math.abs(by - ay); }
      else if (dir === 'left') { if (b.right > a.left + 5 && bx >= ax - 5) return; primary = Math.max(0, a.left - b.right); secondary = Math.abs(by - ay); }
      else if (dir === 'down') { if (b.top < a.bottom - 5 && by <= ay + 5) return; primary = Math.max(0, b.top - a.bottom); secondary = Math.abs(bx - ax); }
      else { if (b.bottom > a.top + 5 && by >= ay - 5) return; primary = Math.max(0, a.top - b.bottom); secondary = Math.abs(bx - ax); }
      var horizontal = dir === 'left' || dir === 'right';
      var score = primary + secondary * (horizontal ? 3 : 0.6);
      if (score < bestScore) { bestScore = score; best = el; }
    });
    // Entering a horizontal row from above/below: return to the item that
    // was focused there last time, if it is roughly in view.
    if (best && (dir === 'up' || dir === 'down')) {
      var row = best.closest('[data-row]');
      if (row && row !== current.closest('[data-row]') && row._last && document.body.contains(row._last)) {
        var lr = row._last.getBoundingClientRect();
        if (lr.right > 0 && lr.left < window.innerWidth) best = row._last;
      }
    }
    if (best) { focus(best); return true; }
    return false;
  }

  function first() {
    var s = scope();
    return s.querySelector('.focusable.autofocus:not(.hidden)') ||
      candidates().filter(function (el) { return !el.closest('#menu') || s !== document.body; })[0] ||
      candidates()[0];
  }

  // Back can arrive twice: as key 461 and, if disableBackHistoryAPI is
  // off, as history.back().
  // Keep a spare history entry, treat popstate as Back, and drop duplicates.
  var lastBack = 0;
  function backOnce() { var now = Date.now(), dup = now - lastBack < 600; lastBack = now; return !dup; }
  try { history.pushState({ spare: 1 }, ''); } catch (e) {}
  window.addEventListener('popstate', function () {
    try { history.pushState({ spare: 1 }, ''); } catch (e) {}
    if (!backOnce()) return;
    var el = document.activeElement;
    if (isInput(el)) { el.blur(); return; }
    for (var i = handlers.length - 1; i >= 0; i--) if (handlers[i](K.BACK)) return;
  });

  function onKey(e) {
    var key = e.keyCode;
    if (key === K.BACK && !backOnce()) { e.preventDefault(); return; }
    var typing = isInput(document.activeElement);
    if (typing) {
      if (key === K.ENTER) { document.activeElement.dispatchEvent(new CustomEvent('submit-input')); e.preventDefault(); return; }
      if (key === K.UP || key === K.DOWN || key === K.BACK || key === K.ESC) { document.activeElement.blur(); }
      else return; // let the input handle characters, backspace, caret moves
      if (key === K.BACK || key === K.ESC) { e.preventDefault(); return; }
    }
    for (var i = handlers.length - 1; i >= 0; i--) {
      if (handlers[i](key, e)) { e.preventDefault(); return; }
    }
    var dir = { 37: 'left', 38: 'up', 39: 'right', 40: 'down' }[key];
    if (dir) { moves++; move(dir); e.preventDefault(); return; }
    if (key === K.ENTER && current) {
      e.preventDefault();
      if (isInput(current)) current.focus();
      else current.click();
    }
  }

  document.addEventListener('keydown', onKey, true);
  document.addEventListener('mouseover', function (e) {
    var el = e.target.closest && e.target.closest('.focusable');
    if (el && scope().contains(el) && el !== current) focus(el);
  });

  window.Nav = {
    K: K,
    focus: focus,
    move: move,
    first: function () { focus(first()); },
    get current() { return current; },
    get moves() { return moves; },
    pushScope: function (el) { scopes.push(el); },
    popScope: function (el) { var i = scopes.lastIndexOf(el); if (i >= 0) scopes.splice(i, 1); },
    pushHandler: function (fn) { handlers.push(fn); },
    popHandler: function (fn) { var i = handlers.lastIndexOf(fn); if (i >= 0) handlers.splice(i, 1); },
    isBack: function (key) { return key === K.BACK || key === K.ESC || key === K.BACKSPACE; }
  };
})();
