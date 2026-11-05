%%private(
  let fourItems = arr =>
    arr->Array.length > 3
      ? arr->Array.slice(~start=0, ~end=4)
      : arr->Array.concatMany([arr, arr, arr])->Array.slice(~start=0, ~end=4)
)

module Cover = {
  @react.component
  let make = (~playlistId, ~idx, ~album) => {
    let id = `${playlistId->Float.toString}-cover-${idx->Int.toString}`
    let _ = Hook.useFetch({
      fn: () => Invoke.getAlbumCoverArt({album, size: Shape.CoverSize.Medium}),
      onSuccess: Shape.Bytes.setCover(_, id),
    })

    <img id alt="" className="object-cover h-full" />
  }
}

module CoverGrid = {
  @react.component
  let make = (~id, ~tracks: array<Shape.Track.t>) => {
    <div className="grid grid-cols-2 z-10 h-full bg-accent gap-0.5">
      {tracks
      ->Array.mapWithIndex((track, idx) =>
        <Cover key={idx->Int.toString} album=track.album idx playlistId=id />
      )
      ->React.array}
    </div>
  }
}

@react.component
let make = (~playlist: Shape.Playlist.playlist) => {
  let tracks = Hook.useFetch({
    fn: () => Invoke.getPlaylistsTracksById({id: playlist.id}),
  })
  let onPlayClick = evt => {
    evt->ReactEvent.Mouse.stopPropagation
    evt->ReactEvent.Mouse.preventDefault
    switch tracks {
    | Loading | Failed => ignore()
    | Success(tracks) =>
      Invoke.playMany({uris: tracks->Array.map(t => t.uri), shuffle: false})->ignore
    }
  }

  <Route.Link to=Playlist(playlist.id) className="flex flex-col animate-fade cursor-pointer">
    <div
      className="aspect-square bg-primary/40 rounded-box flex shrink-0 overflow-hidden relative isolate group nb active:nb-plain"
    >
      {switch tracks {
      | Loading | Failed => React.null
      | Success(tracks) => <CoverGrid id=playlist.id tracks={tracks->fourItems} />
      }}
      <div className="center p-4 absolute inset-0 animate-fade">
        <Icon.playlist className="size-24" weight=Thin />
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
    <p className="r-text text-center truncate"> {playlist.name->React.string} </p>
  </Route.Link>
}
