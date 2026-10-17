type view = All | Album(Shape.Album.item)

@react.component
let make = () => {
  let (view, setView) = React.useState(_ => All)
  let albums = Hook.useFetch({fn: Invoke.getTop10Albums})

  let onPlay = (id, ~index) => {
    switch albums {
    | Success(albums) =>
      Invoke.playTracksByAlbumsFromAlbumId({
        albumIds: albums->Array.map(a => a.id),
        albumId: id,
        index,
      })->ignore
    | _ => ignore()
    }
  }

  switch view {
  | All =>
    <div className="size-full flex flex-col p-4 px-8 2xl:p-8 r-gap min-w-0 overflow-y-auto min-h-0">
      <HomeTopTracks />
      {switch albums {
      | Loading | Failed => React.null
      | Success(albums) => <HomeTopAlbums onPlay albums setAlbum={a => setView(_ => Album(a))} />
      }}
    </div>
  | Album(album) => <AlbumView album onBack={() => setView(_ => All)} onPlay />
  }
}
