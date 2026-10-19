@react.component
let make = (~artist: Shape.Artist.t, ~onBack) => {
  let id = `artist-${artist.id->Float.toString}`
  let _ = Hook.useFetch({
    fn: () => Invoke.getArtistCoverArt({artistId: artist.id}),
    onSuccess: Shape.Bytes.setCover(_, id),
  })
  let stats = Hook.useFetch({fn: () => Invoke.getArtistStats({artistId: artist.id})})
  let albums = Hook.useFetch({fn: () => Invoke.getAlbumsByArtistId({artistId: artist.id})})

  let onPlay = (id, ~index) => {
    switch albums {
    | Loading | Failed => ignore()
    | Success(albums) =>
      Invoke.playTracksByAlbumsFromAlbumId({
        albumIds: albums->Array.map(a => a.id),
        albumId: id,
        index,
      })->ignore
    }
  }

  let onStartPlay = _ =>
    switch albums {
    | Loading | Failed => ignore()
    | Success(albums) =>
      switch albums[0] {
      | Some(a) => onPlay(a.id, ~index=0)
      | None => ignore()
      }
    }

  <div className="flex flex-col p-8 size-full gap-4 overflow-y-auto min-h-0 relative">
    <button
      id="close-btn"
      onClick={_ => onBack()}
      className="btn bg-base-100 btn-ghost r-btn nb-box active:nb-box absolute top-4 right-4 2xl:top-8 2xl:right-8"
    >
      <Icon.arrowLeft className="r-icon" weight=Bold />
      {"Go back"->React.string}
    </button>
    <div className="flex gap-4 2xl:gap-8">
      <div
        className="w-40 2xl:w-48 aspect-square bg-primary/40 rounded-full flex shrink-0 overflow-hidden relative isolate group nb-outline"
      >
        <img id className="object-cover h-full z-10" />
        <div className="center p-4 absolute inset-0">
          <Icon.userCircle className="size-24" weight=Thin />
        </div>
      </div>
      <div className="flex flex-col gap-2 py-2">
        <p className="text-3xl 2xl:text-5xl pl-1 font-semibold truncate">
          {artist.name->React.string}
        </p>
        {switch stats {
        | Loading | Failed => React.null
        | Success({trackCount, albumCount}) =>
          <p className="text-lg 2xl:text-2xl pl-1 text-60">
            {`${trackCount->Int.toString} track${trackCount == 1 ? "" : "s"}`->React.string}
            <span className="px-4"> {Constant.sep->React.string} </span>
            {`${albumCount->Int.toString} album${albumCount == 1 ? "" : "s"}`->React.string}
          </p>
        }}
        <button
          onClick=onStartPlay
          id="play-all"
          className="btn xl:btn-lg 2xl:btn-xl btn-primary w-40 mt-auto"
        >
          <Icon.play className="r-icon pr-2" weight=Fill />
          <span className="font-medium"> {" Play"->React.string} </span>
        </button>
      </div>
    </div>
    {switch albums {
    | Loading | Failed => React.null
    | Success(albums) =>
      <div className="grid grid-cols-2 gap-4 w-full px-1 pt-2 border-t-2 border-accent">
        {albums
        ->Array.map(album =>
          <ArtistAlbumItem album artistId=artist.id key={album.id->Float.toString} onPlay />
        )
        ->React.array}
      </div>
    }}
  </div>
}
