module AlbumItem = {
  @react.component
  let make = (~album: Shape.Album.item, ~onClick, ~onPlayFromHere) => {
    let isActive = Store.Player.useShallow(s =>
      s.data.track->Option.map(t => t.album) == Some(album.name)
    )
    let id = `album-${album.id->Float.toString}`
    let _ = Hook.useFetch({
      fn: () => Invoke.getAlbumCoverArt({album: album.name}),
      onSuccess: bytes => {
        if bytes->Array.length > 0 {
          bytes->Shape.Bytes.toImageUrl->Util.Dom.setImageSrc(id)
        }
      },
    })

    let onPlayClick = evt => {
      evt->ReactEvent.Mouse.stopPropagation
      onPlayFromHere()
    }

    let border = isActive ? "nb-primary" : ""

    <div onClick={_ => onClick()} className="flex flex-col animate-fade cursor-pointer">
      <div
        role="button"
        className={`w-full aspect-square bg-base-content/40 rounded-box flex shrink-0 overflow-hidden relative isolate group nb active:nb-plain ${border}`}
      >
        <img id className="object-cover h-full z-10" />
        <div className="center p-4 absolute inset-0">
          <p className="text-9xl text-center text-base-content font-serif"> {"?"->React.string} </p>
        </div>
        <div
          className="flex items-center transitional translate-y-14 group-hover:translate-y-0 h-14 w-full z-20 absolute -bottom-0 p-2"
        >
          <button
            onClick=onPlayClick className="btn btn-ghost btn-square bg-primary text-primary-content"
          >
            <Icon.play className="r-icon" weight=Fill />
          </button>
          <div className="grow"></div>
          // <button
          //   onClick=onPlayFromHereClick
          //   className="btn btn-ghost btn-square bg-primary text-primary-content"
          // >
          //   <Icon.arrowRight className="r-icon" weight=Bold />
          // </button>
        </div>
      </div>
      <p className="r-text pl-1 pt-2 font-medium truncate"> {album.name->React.string} </p>
      <p className="r-text-sm pl-1 text-80 truncate"> {album.artist->React.string} </p>
    </div>
  }
}

type view = AllAlbums | Album(Shape.Album.item)
@react.component
let make = () => {
  let (view, setView) = React.useState(_ => AllAlbums)
  let albums = Hook.useFetch({
    fn: Invoke.getTop100Albums,
    // onSuccess: all =>
    //   switch all[4] {
    //   | Some(album) => setView(_ => Album(album))
    //   | None => ignore()
    //   },
  })
  let onPlayFromHere = id => {
    switch albums {
    | Success(albums) =>
      Invoke.playTracksByAlbumsFromAlbumId({
        albumIds: albums->Array.map(a => a.id),
        albumId: id,
      })->ignore
    | _ => ignore()
    }
  }

  switch view {
  | Album(album) => <AlbumView album />
  | AllAlbums =>
    switch albums {
    | Loading => React.null
    | Failed => React.null
    | Success(albums) =>
      <div
        className="grid grid-cols-1 md:grid-cols-3 lg:grid-cols-4 xl:grid-cols-6 2xl:grid-cols-7 gap-8 w-full p-8 overflow-y-auto"
      >
        {albums
        ->Array.mapWithIndex((album, i) =>
          <Delay key={album.id->Float.toString} timeout={i * 20}>
            <AlbumItem
              album
              key={album.id->Float.toString}
              onClick={() => setView(_ => Album(album))}
              onPlayFromHere={() => onPlayFromHere(album.id)}
            />
          </Delay>
        )
        ->React.array}
      </div>
    }
  }
}
