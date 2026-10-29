type t =
  | Home
  | PopularAlbums
  | RandomAlbums
  | LovedAlbums
  | RecentAlbums
  | AllAlbums
  | AllArtists
  | Playlist(float)
  | Playlists
  | NewPlaylist(Shape.Playlist.kind)
  | EditPlaylist(float)
  | Settings
  | NotFound
// Todo: add routes for Album/Artist etc
// | Album(float)

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
  switch url.path {
  | list{} => Home
  | list{"popular-albums"} => PopularAlbums
  | list{"random-albums"} => RandomAlbums
  | list{"loved-albums"} => LovedAlbums
  | list{"recent-albums"} => RecentAlbums
  | list{"all-albums"} => AllAlbums
  | list{"all-artists"} => AllArtists
  | list{"playlists"} => Playlists
  | list{"playlist", id} => Playlist(id->Float.fromString->Option.getOr(0.))
  | list{"new-playlist", "regular"} => NewPlaylist(Regular)
  | list{"new-playlist", "smart"} => NewPlaylist(Smart)
  | list{"edit-playlist", id} => EditPlaylist(id->Float.fromString->Option.getOr(0.))
  | list{"settings"} => Settings
  // | list{"album", id} => Album(id)
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
  | AllAlbums => Icon.cassetteTape
  | AllArtists => Icon.userSquare
  | Playlists | Playlist(_) | NewPlaylist(_) | EditPlaylist(_) => Icon.playlist
  | Settings => Icon.sliders
  | NotFound => Icon.empty
  }

let toTitle = route =>
  switch route {
  | Home => "Home"
  | PopularAlbums => "Popular Albums"
  | RandomAlbums => "Random Albums"
  | LovedAlbums => "Loved Albums"
  | RecentAlbums => "Recent Albums"
  | AllAlbums => "All Albums"
  | AllArtists => "All Artists"
  | Playlist(_) => "Playlist"
  | Playlists => "Playlists"
  | NewPlaylist(Regular) => "New Regular Playlist"
  | NewPlaylist(Smart) => "New Smart Playlist"
  | EditPlaylist(_) => "Edit Playlist"
  | Settings => "Settings"
  | NotFound => "Not Found"
  }

let toPath = route =>
  switch route {
  | Home => "/"
  | PopularAlbums => "/popular-albums"
  | RandomAlbums => "/random-albums"
  | LovedAlbums => "/loved-albums"
  | RecentAlbums => "/recent-albums"
  | AllAlbums => "/all-albums"
  | AllArtists => "/all-artists"
  | Playlists => "/playlists"
  | Playlist(id) => `/playlist/${id->Float.toString}`
  | NewPlaylist(Regular) => "/new-playlist/regular"
  | NewPlaylist(Smart) => "/new-playlist/smart"
  | EditPlaylist(id) => `/edit-playlist/${id->Float.toString}`
  | Settings => "/settings"
  | NotFound => "/not-found"
  }

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
      if replace {
        RescriptReactRouter.replace(path)
      } else {
        RescriptReactRouter.push(path)
      }
    }
    <a ?id href=path className onClick> {children} </a>
  }
}

// let fromPlaylist = (item: Shape.Playlist.playlist) =>

let goBack = () => Window.History.history->Window.History.back
