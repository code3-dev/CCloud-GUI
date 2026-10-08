# CCloud for LG webOS TV

A webOS TV app for CCloud. Flutter does not target webOS, so this is a small web app (plain HTML, CSS and JavaScript, no build step) that talks to the same API as the desktop app and has the same sections: Movies, Series, Search, Favorites, Countries and Settings, plus a Home screen built from the API's `first` rows. The interface is in Persian and laid out right to left, like the desktop app.

| Desktop (`lib/src/repositories`) | TV (`app/js/api.js`) |
| --- | --- |
| `BaseRepository` (main server, then the helper servers) | `call()` tries the same three servers in the same order |
| `MovieRepository`, `SeriesRepository` | `Api.movies`, `Api.series` (genre and sort filters) |
| `CountriesRepository` | `Api.countries`, `Api.posters({country})` |
| `GenreRepository`, `SearchRepository`, `SeasonsRepository` | `Api.genres`, `Api.search`, `Api.seasons` |
| `StorageUtils` (favorites) | `app/js/store.js`: favorites, watch positions and the preferred quality, in localStorage |

The TV plays MP4 and MKV files directly with its own media player. The player is built for the remote:
- The app resumes where you stopped.
- **Yellow** changes the quality.
- Audio and subtitle buttons appear when a file has several tracks.
- Series have a next-episode button.

Live TV is not included, because the TVGarden channel list that the desktop app uses currently returns 404.

## Files

```
webos/app/
  appinfo.json   app id com.pira.ccloud; the version follows pubspec.yaml in CI
  index.html     layout and Content-Security-Policy
  css/app.css
  js/nav.js      remote-control (spatial) navigation
  js/api.js      CCloud API client
  js/store.js    favorites, positions, preferences
  js/player.js   video player
  js/app.js      screens and routing
```

## Build and run

```bash
npm install -g @webos-tools/cli
ares-package webos/app -o webos/dist          # creates com.pira.ccloud_<version>_all.ipk
ares-install --device tv webos/dist/*.ipk
ares-launch --device tv com.pira.ccloud
```

You can also open `webos/app` in the [webOS TV simulator](https://webostv.developer.lge.com/develop/tools/simulator-introduction), or with `ares-launch -s <version> webos/app`. Debug on a TV with `ares-inspect --device tv com.pira.ccloud`.

See [assets/WEBOS_INSTALL.md](../assets/WEBOS_INSTALL.md) for how to set up the TV.
