module TrackItem = {
  @react.component
  let make = (~track: Shape.Track.item, ~idx) => {
    let currentTrack = Store.Player.useShallow(s => s.data.track)
    let isPlaying = Some(track.uri) == currentTrack->Option.map(t => t.uri)
    let bg = isPlaying ? "bg-primary text-primary-content nb-active" : "bg-base-100"

    let onClick = _ => Invoke.play({trackUri: track.uri})->ignore

    let onMouseDown = evt => {
      "#search-input"->Util.Dom.querySelectAndThen(Util.Dom.blur)
      if evt->ReactEvent.Mouse.button == 1 {
        evt->ReactEvent.Mouse.preventDefault
        Invoke.queueToggleTrack({uri: track.uri})->ignore
      }
    }

    <div
      role="button"
      onClick
      onMouseDown
      className={`flex flex-row items-center cursor-pointer px-4 nb nb-box active:nb-plain gap-4 border-2 ${bg} shrink-0`}
    >
      <TrackIndex uri=track.uri idx />
      <p className="r-text-lg font-medium grow truncate py-2"> {track.name->React.string} </p>
      <p className="text-lg"> {track.duration->Util.durationToString->React.string} </p>
    </div>
  }
}

@react.component
let make = (~group: Shape.Album.group) => {
  let id = `group-${group.id->Float.toString}`
  let _ = Hook.useFetch({
    fn: () => Invoke.getAlbumCoverArt({album: group.name}),
    onSuccess: Shape.Bytes.setCover(_, id),
  })

  <div className="animate-slide-up flex flex-col r-gap px-1">
    <div className="flex gap-4 r-gap">
      <div
        className="w-16 2xl:w-20 aspect-square bg-primary/40 rounded-box flex shrink-0 overflow-hidden relative isolate group nb-outline"
      >
        <img id className="object-cover h-full z-10" />
        <div className="center p-4 absolute inset-0">
          <p className="text-4xl 2xl:text-6xl text-center text-base-content font-serif">
            {"?"->React.string}
          </p>
        </div>
      </div>
      <div className="flex flex-col 2xl:gap-1">
        <p className="r-text-xl pl-1 font-medium truncate"> {group.name->React.string} </p>
        <p className="r-text-lg pl-1 text-80"> {group.artists->React.string} </p>
      </div>
    </div>
    {group.tracks
    ->Array.mapWithIndex((track, idx) => <TrackItem track idx key=track.uri />)
    ->React.array}
  </div>
}
