type view = All | One(Shape.Album.t)

@react.component
let make = (~albums: array<Shape.Album.t>) => {
  let (view, setView) = React.useState(_ => All)

  let onPlay = (id, ~index) => {
    Invoke.playTracksByAlbumsFromAlbumId({
      albumIds: albums->Array.map(a => a.id),
      albumId: id,
      index,
    })->ignore
  }

  let onStartPlay = _ =>
    switch albums[0] {
    | Some(a) => onPlay(a.id, ~index=0)
    | None => ignore()
    }

  switch view {
  | One(album) => <AlbumView album onBack={() => setView(_ => All)} onPlay />
  | All =>
    <React.Fragment>
      <button onClick=onStartPlay id="play-all" className="hidden"></button>
      <div
        className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 xl:grid-cols-6 2xl:grid-cols-7 gap-8 w-full p-8 overflow-y-auto"
      >
        {albums
        ->Array.mapWithIndex((album, i) =>
          <Delay key={album.id->Float.toString} timeout={i * 20}>
            <AlbumItem album onClick={() => setView(_ => One(album))} onPlay />
          </Delay>
        )
        ->React.array}
      </div>
    </React.Fragment>
  }
}
