@react.component
let make = (~album: Shape.Album.t, ~ids, ~onPlay, ~width="w-full") => {
  let isActive = Store.Player.useShallow(s =>
    s.data.track->Option.map(t => t.album) == Some(album.name)
  )
  let id = `album-${album.id->Float.toString}`
  let _ = Hook.useFetch({
    fn: () => Invoke.getAlbumCoverArt({album: album.name, isSmall: false}),
    onSuccess: Shape.Bytes.setCover(_, id),
  })

  let onPlayClick = evt => {
    evt->ReactEvent.Mouse.stopPropagation
    evt->ReactEvent.Mouse.preventDefault
    onPlay(album.id, ~index=0)
  }

  let border = isActive ? "nb-active" : ""

  <Route.Link
    to=Album(album.id, ids) className={`flex flex-col animate-fade cursor-pointer ${width}`}
  >
    <div
      className={`${width} aspect-square bg-primary/40 rounded-box flex shrink-0 overflow-hidden relative isolate group nb active:nb-plain ${border}`}
    >
      <img alt="" id className="object-cover h-full z-10" />
      <div className="center p-4 absolute inset-0 animate-fade">
        <p className="text-9xl text-center text-base-content font-serif">
          {Constant.logo->React.string}
        </p>
      </div>
      <div
        className="flex items-center transitional translate-y-14 group-hover:translate-y-0 h-14 w-full z-20 absolute -bottom-0 p-2"
      >
        <button
          onClick=onPlayClick
          className="btn btn-ghost btn-square bg-primary text-primary-content hover:nb-plain"
        >
          <Icon.play className="r-icon-lg" weight=Fill />
        </button>
      </div>
    </div>
    <p className="r-text pl-1 pt-2 font-medium truncate"> {album.name->React.string} </p>
    <p className="r-text-sm pl-1 text-80 truncate"> {album.artist->React.string} </p>
  </Route.Link>
}
