module Content = {
  @react.component
  let make = (~playlists: array<Shape.Playlist.playlist>) => {
    playlists->Array.length > 0
      ? <div
          className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 xl:grid-cols-6 2xl:grid-cols-7 3xl:grid-cols-8 gap-8 w-full p-8 overflow-y-auto min-h-0"
        >
          {playlists
          ->Array.mapWithIndex((playlist, i) =>
            <Delay key={playlist.id->Float.toString} timeout={i * 20}>
              <PlaylistItem playlist />
            </Delay>
          )
          ->React.array}
          <Route.Link
            to=NewPlaylist(Regular) className="flex flex-col animate-fade cursor-pointer p-1"
          >
            <div
              className="aspect-square bg-base-200 rounded-box center flex-col shrink-0 overflow-hidden relative isolate group outline-dashed outline-base-content/60 p-4"
            >
              <Icon.plus className="size-12 text-60" />
              <p className="r-text text-center text-60 truncate">
                {"New playlist"->React.string}
              </p>
            </div>
          </Route.Link>
        </div>
      : <div className="center r-gap flex-col size-full">
          <p className="font-fraunces font-light r-text-3xl text-center italic">
            {"Every collection begins with a single song."->React.string}
          </p>
          <p className="r-text-lg text-center text-60">
            {"Gather the songs you love in your first playlist."->React.string}
          </p>
          <Route.Link to=NewPlaylist(Regular) className="btn btn-lg 2xl:btn-xl btn-primary mt-4">
            <Icon.plus className="r-icon" weight=Bold />
            {"New playlist"->React.string}
          </Route.Link>
        </div>
  }
}

@react.component
let make = () => {
  let update = Store.Player.useShallow(s => s.update)
  let data = Hook.useFetch({
    fn: Invoke.getAllPlaylists,
    onSuccess: playlists => update(SetPlaylists(playlists)),
  })
  switch data {
  | Loading | Failed => React.null
  | Success(playlists) => <Content playlists />
  }
}
