@react.component
let make = (~track: Shape.Track.t) => {
  let (position, update) = Store.Player.useShallow(s => (s.data.position, s.update))
  let id = `playing-track-${track.id->Float.toString}`
  let onChange = evt => {
    switch evt->Util.Dom.targetValue->Int.fromString {
    | Some(seconds) => Invoke.seek({seconds: seconds})->ignore
    | None => ignore()
    }
  }

  let _ = Hook.useFetch({
    fn: () => Invoke.getTrackCoverArt({album: track.album, trackUri: track.uri}),
    onSuccess: Shape.Bytes.setCover(_, id),
  })

  Event.useListen(Event.listenPosition, pos => update(SetPosition(pos)))

  React.useEffect0(() => {
    let intervalId = setInterval(() => {
      if Store.Player.isPlaying() {
        Invoke.getPosition()
        ->Promise.then(
          async pos =>
            switch pos->Nullable.toOption {
            | Some(p) => update(SetPosition(p))
            | None => ignore()
            },
        )
        ->ignore
      }
    }, 1000)
    Some(() => clearInterval(intervalId))
  })

  <React.Fragment>
    <div className="flex r-gap shrink-0 min-w-72 2xl:min-w-88">
      <div
        className="size-12 lg:size-12 2xl:size-14 bg-primary/40 rounded-box flex shrink-0 overflow-hidden nb-outline relative isolate"
      >
        <img alt="" key=id id className="object-cover h-full z-10" />
        <div className="center p-4 absolute inset-0 animate-fade">
          <p className="text-4xl text-center text-accent font-serif">
            {Constant.logo->React.string}
          </p>
        </div>
      </div>
      <div className="flex flex-col">
        <div className="font-semibold r-text truncate"> {track.name->React.string} </div>
        <div className="r-text-sm text-80 truncate"> {track.artist->React.string} </div>
      </div>
    </div>
    <div className="flex items-center r-gap grow">
      <p className="r-text font-medium text-right min-w-16 2xl:min-w-24">
        {position->Util.durationToString->React.string}
      </p>
      <input
        key=id
        type_="range"
        min="0"
        max={track.duration->Int.toString}
        value={position->Int.toString}
        onChange
        className="range range-xs range-primary outline-2 outline-primary-content grow transitional [--range-thumb:var(--color-primary)] bg-base-100"
      />
      <p className="r-text font-medium text-left min-16 2xl:min-w-24">
        {track.duration->Util.durationToString->React.string}
      </p>
    </div>
  </React.Fragment>
}
