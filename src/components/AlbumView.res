module TrackItem = {
  @react.component
  let make = (~track: Shape.Track.t, ~idx) => {
    let currentTrack = Store.Player.useShallow(s => s.data.track)
    let isPlaying = Some(track.id) == currentTrack->Option.map(t => t.id)
    let bg = isPlaying ? "bg-primary text-primary-content nb-active" : "bg-base-100"

    <div
      role="button"
      className={`flex flex-row items-center cursor-pointer p-4 py-2 nb nb-box active:nb-plain gap-4 border-2 ${bg}`}
    >
      <p className={`r-text-lg font-medium ${isPlaying ? "text-primary-content/80" : "text-80"}`}>
        {(idx + 1)->Util.padInt->React.string}
      </p>
      <div className="flex flex-col grow h-full">
        <p className="r-text-lg font-medium truncate"> {track.name->React.string} </p>
      </div>
      <p className="text-lg"> {track.duration->Util.durationToString->React.string} </p>
    </div>
  }
}

@react.component
let make = (~album: Shape.Album.item) => {
  let id = `album-${album.id->Float.toString}`
  let _ = Hook.useFetch({
    fn: () => Invoke.getAlbumCoverArt({album: album.name}),
    onSuccess: bytes => {
      if bytes->Array.length > 0 {
        bytes->Shape.Bytes.toImageUrl->Util.Dom.setImageSrc(id)
      }
    },
  })
  let tracks = Hook.useFetch({
    fn: () => Invoke.getTracksByAlbums({albumIds: [album.id]}),
  })

  let (trackCount, trackDuration) = switch tracks {
  | Success(tracks) => (tracks->Array.length, tracks->Shape.Track.totalDuration)
  | _ => (0, 0)
  }

  <div className="flex flex-col p-4 2xl:p-8 size-full gap-8">
    <div className="flex gap-8">
      <div
        className="w-64 aspect-square bg-base-content/40 rounded-box flex shrink-0 overflow-hidden relative isolate group nb nb-active"
      >
        <img id className="object-cover h-full z-10" />
        <div className="center p-4 absolute inset-0">
          <p className="text-9xl text-center text-base-content font-serif"> {"?"->React.string} </p>
        </div>
      </div>
      <div className="flex flex-col gap-4">
        <p className="text-7xl pl-1 pt-2 font-bold truncate"> {album.name->React.string} </p>
        <p className="text-4xl pl-1 text-80 truncate">
          <span className="font-medium"> {album.artist->React.string} </span>
          {switch tracks {
          | Loading | Failed => React.null
          | Success(_) =>
            <React.Fragment>
              <span className="px-4"> {Constant.sep->React.string} </span>
              <span className="text-60">
                {`${trackCount->Int.toString} track${trackCount == 1 ? "" : "s"}`->React.string}
              </span>
              <span className="px-4"> {Constant.sep->React.string} </span>
              <span className="text-60">
                {trackDuration->Util.durationToString->React.string}
              </span>
            </React.Fragment>
          }}
        </p>
        <button className="btn btn-xl btn-primary w-40 mt-auto">
          <Icon.play className="r-icon pr-2" weight=Fill />
          {" Play"->React.string}
        </button>
      </div>
    </div>
    {switch tracks {
    | Loading | Failed => React.null
    | Success(tracks) =>
      <React.Fragment>
        <p className="r-text text-80 border-b-2 border-accent py-2 mt-4">
          {"Tracks"->React.string}
        </p>
        <div className="grid grid-cols-2 gap-4 w-full px-1">
          {tracks
          ->Array.mapWithIndex((track, idx) => <TrackItem idx track key=track.uri />)
          ->React.array}
        </div>
      </React.Fragment>
    }}
  </div>
}
