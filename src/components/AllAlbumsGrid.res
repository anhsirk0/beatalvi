type view = AllAlbums | Album(Shape.Album.item)

@react.component
let make = (~albums: array<Shape.Album.item>) => {
  let (view, setView) = React.useState(_ => AllAlbums)

  let onPlay = (id, ~index) => {
    Invoke.playTracksByAlbumsFromAlbumId({
      albumIds: albums->Array.map(a => a.id),
      albumId: id,
      index,
    })->ignore
  }

  let onStarPlay = _ => {
    switch albums[0] {
    | Some(a) =>
      Invoke.playTracksByAlbumsFromAlbumId({
        albumIds: albums->Array.map(a => a.id),
        albumId: a.id,
        index: 0,
      })->ignore

    | None => ignore()
    }
  }

  switch view {
  | Album(album) => <AlbumView album onBack={() => setView(_ => AllAlbums)} onPlay />
  | AllAlbums =>
    <React.Fragment>
      <button onClick=onStarPlay id="play-all" className="hidden"></button>
      <div
        className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 xl:grid-cols-6 2xl:grid-cols-7 gap-8 w-full p-8 overflow-y-auto"
      >
        {albums
        ->Array.mapWithIndex((album, i) =>
          <Delay key={album.id->Float.toString} timeout={i * 20}>
            <AlbumItem album onClick={() => setView(_ => Album(album))} onPlay />
          </Delay>
        )
        ->React.array}
      </div>
    </React.Fragment>
  }
}
