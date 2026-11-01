type view = All | One(Shape.Album.t)

@react.component
let make = (~albums: array<Shape.Album.t>) => {
  let (view, setView) = React.useState(_ => All)

  let onPlay = (id, ~index) => {
    Invoke.playTracksByAlbumsFromAlbumId({
      albumIds: albums->Array.map(a => a.id),
      albumId: id,
      shuffle: false,
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
    <Lenis options=Lenis.options className="[&>div]:main-grid overflow-y-auto min-h-0">
      <button onClick=onStartPlay id="play-all" className="hidden"></button>
      {albums
      ->Array.mapWithIndex((album, i) =>
        <Delay key={album.id->Float.toString} timeout={i * 20}>
          <AlbumItem album onClick={() => setView(_ => One(album))} onPlay />
        </Delay>
      )
      ->React.array}
    </Lenis>
  }
}
