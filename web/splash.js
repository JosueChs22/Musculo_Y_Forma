// Quita el splash (#gmyf-splash) cuando Flutter pinta su primer frame.
// Respaldo para navegadores sin soporte de CSS :has().
(function () {
  'use strict';
  var observer = null;

  function removeSplash() {
    var el = document.getElementById('gmyf-splash');
    if (el && el.parentNode) el.parentNode.removeChild(el);
    if (observer) { observer.disconnect(); observer = null; }
    window.removeEventListener('flutter-first-frame', removeSplash);
  }

  function flutterPresent() {
    return document.querySelector('flutter-view, flt-glass-pane') !== null;
  }

  window.addEventListener('flutter-first-frame', removeSplash);

  if (flutterPresent()) { removeSplash(); return; }

  if ('MutationObserver' in window && document.body) {
    observer = new MutationObserver(function () {
      if (flutterPresent()) removeSplash();
    });
    observer.observe(document.body, { childList: true, subtree: true });
  }
})();
