(function () {
  document.getElementById('year').textContent = new Date().getFullYear();
  var list = document.getElementById('song-list');
  if (!list) return;
  fetch('content/sursaar_content.json', { cache: 'no-cache' })
    .then(function (r) { return r.json(); })
    .then(function (data) {
      var songs = (data.songs || []).slice(0, 24);
      if (!songs.length) { list.innerHTML = '<p class="muted">No songs yet.</p>'; return; }
      list.innerHTML = songs.map(function (s) {
        var chords = (s.originalChords || s.chords || []).slice(0, 6)
          .map(function (c) { return '<i>' + String(c).replace(/[<>&]/g, '') + '</i>'; }).join('');
        var meta = [s.artist, s.key ? 'Key ' + s.key : null, s.capo ? 'Capo ' + s.capo : null, s.difficulty]
          .filter(Boolean).join(' · ');
        return '<a class="song" href="app/#/song/' + encodeURIComponent(s.id) + '"><b>' +
          String(s.title).replace(/[<>&]/g, '') + '</b><small>' + meta.replace(/[<>&]/g, '') +
          '</small><div class="chords">' + chords + '</div></a>';
      }).join('');
    })
    .catch(function () { list.innerHTML = '<p class="muted">Catalogue unavailable right now — open the app to browse songs.</p>'; });
})();
