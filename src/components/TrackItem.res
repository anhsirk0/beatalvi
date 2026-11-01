module Cover = {
  @react.component
  let make = (~track: Shape.Track.t) => {
    let id = `song-${track.id->Float.toString}`
    let _ = Hook.useFetch({
      fn: () => Invoke.getTrackCoverArt({album: track.album, trackUri: track.uri}),
      onSuccess: Shape.Bytes.setCover(_, id),
    })

    <div
      className="size-12 2xl:size-14 bg-base-content/30 rounded-box flex shrink-0 overflow-hidden nb-outline relative isolate"
    >
      <img alt="" key=id id className="object-cover h-full z-10" />
      <div className="center p-4 absolute inset-0 animate-fade">
        <p className="text-4xl text-center text-base-content font-serif">
          {Constant.logo->React.string}
        </p>
      </div>
    </div>
  }
}

@react.component
let make = (~track: Shape.Track.t, ~idx, ~onClick) => {
  let currentTrack = Store.Player.useShallow(s => s.data.track)
  let isPlaying = Some(track.id) == currentTrack->Option.map(t => t.id)
  let bg = isPlaying ? "bg-primary text-primary-content nb-active" : "bg-base-100"

  let onMouseDown = evt => {
    if evt->ReactEvent.Mouse.button == 1 {
      evt->ReactEvent.Mouse.preventDefault
      Invoke.queueToggleTrack({uri: track.uri})->ignore
    }
  }

  <div
    role="button"
    onClick={_ => onClick()}
    onMouseDown
    className={`flex flex-row items-center cursor-pointer p-4 py-2 nb nb-box active:nb-plain gap-4 border-2 ${bg} animate-slide-up`}
  >
    <TrackIndex uri=track.uri idx />
    <Cover track />
    <div className="flex flex-col grow h-full">
      <p className="r-text-lg font-medium line-clamp-1"> {track.name->React.string} </p>
      <p className={`r-text line-clamp-1 ${isPlaying ? "text-primary-content/90" : "text-80"}`}>
        {track.artist->React.string}
      </p>
    </div>
    <p className="text-lg"> {track.duration->Util.durationToString->React.string} </p>
  </div>
}
