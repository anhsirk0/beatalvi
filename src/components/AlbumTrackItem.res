@react.component
let make = (~track: Shape.Track.t, ~idx, ~onPlay, ~artist=?) => {
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
    onClick={_ => onPlay()}
    onMouseDown
    className={`flex flex-row items-center cursor-pointer p-4 py-0 nb nb-box active:nb-plain gap-4 border-2 ${bg}`}
  >
    <TrackIndex uri=track.uri idx />
    <p className="r-text-lg font-medium grow truncate py-2"> {track.name->React.string} </p>
    {artist->Util.renderSome(artist => {
      <p className={`r-text font-medium ${isPlaying ? "text-primary-content/90" : "text-80"}`}>
        {artist->React.string}
      </p>
    })}
    <p className="text-lg"> {track.duration->Util.durationToString->React.string} </p>
  </div>
}
