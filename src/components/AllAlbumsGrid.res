@react.component
let make = (~albums: array<Shape.Album.t>) => {
  let scrollerRef = Lenis.useScroller()

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

  let ids = albums->Array.map(a => a.id->Float.toString)->Array.join(",")

  <React.Fragment>
    <button onClick=onStartPlay id="play-all" className="hidden"></button>
    <Virtuoso.Grid
      totalCount={albums->Array.length}
      listClassName="main-grid my-7"
      itemClassName="pt-1"
      data=albums
      itemContent={(_, album) => <AlbumItem key={album.id->Float.toString} album onPlay ids />}
      scrollerRef
    />
  </React.Fragment>
}
