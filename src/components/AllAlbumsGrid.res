@get @return(nullable)
external firstElementChild: Dom.element => option<Dom.element> = "firstElementChild"

@react.component
let make = (~albums: array<Shape.Album.t>) => {
  let (scroller, setScroller) = React.useState(_ => None)
  let lenisRef = React.useRef(Nullable.null)

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

  React.useEffect(() => {
    switch scroller {
    | Some(wrapper) =>
      switch wrapper->firstElementChild {
      | Some(content) =>
        let lenis = Lenis.make({
          wrapper,
          content,
          autoRaf: true,
          allowNestedScroll: true,
          duration: 1.,
          lerp: 0.8,
          smoothWheel: true,
          wheelMultiplier: 4.,
        })
        Some(() => lenis->Lenis.destroy)
      | None => None
      }
    | None => None
    }
  }, [scroller])

  let scrollerRef = React.useCallback0(el =>
    switch el->Nullable.toOption {
    | Some(el) => setScroller(_ => Some(el))
    | None => ()
    }
  )

  <React.Fragment>
    <button onClick=onStartPlay id="play-all" className="hidden"></button>
    <Virtuoso.Grid
      totalCount={albums->Array.length}
      listClassName="main-grid mt-8"
      id="album-grid"
      data=albums
      itemContent={(i, album) => <AlbumItem key={album.id->Float.toString} album onPlay ids />}
      scrollerRef
    />
  </React.Fragment>
}
