type t =
  | Home
  | CurrentTrack // need better name
  | Album(float, string)
  | PopularAlbums
  | RandomAlbums
  | LovedAlbums
  | RecentAlbums
  | AllAlbums
  | AllArtists
  | Artist(float, string)
  | Playlist(float)
  | Playlists
  | NewPlaylist(Shape.Playlist.kind)
  | EditPlaylist(float)
  | Settings
  | NotFound

let sidebar = [
  Home,
  PopularAlbums,
  RandomAlbums,
  LovedAlbums,
  RecentAlbums,
  AllAlbums,
  AllArtists,
  Playlists,
]

let useRoute: unit => t = () => {
  let url = RescriptReactRouter.useUrl()
  let toFloat = id => id->Float.fromString->Option.getOr(0.)
  switch (url.path, url.search) {
  | (list{}, _) => Home
  | (list{"album", id}, params) => Album(id->toFloat, params)
  | (list{"popular-albums"}, _) => PopularAlbums
  | (list{"random-albums"}, _) => RandomAlbums
  | (list{"loved-albums"}, _) => LovedAlbums
  | (list{"recent-albums"}, _) => RecentAlbums
  | (list{"all-albums"}, _) => AllAlbums
  | (list{"all-artists"}, _) => AllArtists
  // Setting name here is error prone but okay
  | (list{"artist", id, name}, _) => Artist(id->toFloat, name)
  | (list{"playlists"}, _) => Playlists
  | (list{"playlist", id}, _) => Playlist(id->toFloat)
  | (list{"new-playlist", "regular"}, _) => NewPlaylist(Regular)
  | (list{"new-playlist", "smart"}, _) => NewPlaylist(Smart)
  | (list{"edit-playlist", id}, _) => EditPlaylist(id->toFloat)
  | (list{"settings"}, _) => Settings
  | (list{"current-track"}, _) => CurrentTrack
  | _ => NotFound
  }
}

let toIcon = route =>
  switch route {
  | Home => Icon.house
  | PopularAlbums => Icon.trendUp
  | RandomAlbums => Icon.shuffle
  | LovedAlbums => Icon.heart
  | RecentAlbums => Icon.clockCounterClockwise
  | Album(_) | AllAlbums => Icon.cassetteTape
  | Artist(_) | AllArtists => Icon.userSquare
  | Playlists | Playlist(_) | NewPlaylist(_) | EditPlaylist(_) => Icon.playlist
  | Settings => Icon.sliders
  | CurrentTrack => Icon.musicNote
  | NotFound => Icon.empty
  }

let toTitle = route =>
  switch route {
  | Home => "Home"
  | Album(_) => "Album"
  | PopularAlbums => "Popular Albums"
  | RandomAlbums => "Random Albums"
  | LovedAlbums => "Loved Albums"
  | RecentAlbums => "Recent Albums"
  | AllAlbums => "All Albums"
  | AllArtists => "All Artists"
  | Artist(_) => "Artist"
  | Playlist(_) => "Playlist"
  | Playlists => "Playlists"
  | NewPlaylist(Regular) => "New Regular Playlist"
  | NewPlaylist(Smart) => "New Smart Playlist"
  | EditPlaylist(_) => "Edit Playlist"
  | Settings => "Settings"
  | CurrentTrack => "Current track"
  | NotFound => "Not Found"
  }

let toPath = route =>
  switch route {
  | Home => "/"
  | Album(id, ids) => `/album/${id->Float.toString}?ids=${ids}`
  | PopularAlbums => "/popular-albums"
  | RandomAlbums => "/random-albums"
  | LovedAlbums => "/loved-albums"
  | RecentAlbums => "/recent-albums"
  | AllAlbums => "/all-albums"
  | AllArtists => "/all-artists"
  | Artist(id, name) => `/artist/${id->Float.toString}/${name}`
  | Playlists => "/playlists"
  | Playlist(id) => `/playlist/${id->Float.toString}`
  | NewPlaylist(Regular) => "/new-playlist/regular"
  | NewPlaylist(Smart) => "/new-playlist/smart"
  | EditPlaylist(id) => `/edit-playlist/${id->Float.toString}`
  | Settings => "/settings"
  | CurrentTrack => "/current-track"
  | NotFound => "/not-found"
  }

module Mouse = ReactEvent.Mouse
module Link = {
  @react.component
  let make = (~to, ~className, ~children, ~id=?, ~onClick=?, ~replace=false) => {
    let path = to->toPath
    let onClick = evt => {
      evt->ReactEvent.Mouse.preventDefault
      switch onClick {
      | Some(fn) => fn(evt)
      | None => ignore()
      }
      replace ? RescriptReactRouter.replace(path) : RescriptReactRouter.push(path)
    }

    <a onContextMenu=Mouse.preventDefault ?id href=path className onClick> {children} </a>
  }
}

let goBack = () => Window.History.history->Window.History.back
