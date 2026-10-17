type t =
  | Home
  | PopularAlbums
  | RandomAlbums
  | LovedAlbums
  | RecentAlbums
  | AllAlbums
  | AllArtists
  | Playlists
  | Settings
  | NotFound

let all = [
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
  | list{"settings"} => Settings
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
  | Playlists => Icon.playlist
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
  | Playlists => "Playlists"
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
  | Settings => "/settings"
  | NotFound => "/not-found"
  }

module Link = {
  @react.component
  let make = (~to, ~className, ~children, ~id=?) => {
    let path = to->toPath
    let onClick = evt => {
      evt->ReactEvent.Mouse.preventDefault
      RescriptReactRouter.push(path)
    }
    <a ?id href=path className onClick> {children} </a>
  }
}
