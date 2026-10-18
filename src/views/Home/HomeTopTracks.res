@react.component
let make = () => {
  let tracks = Hook.useFetch({fn: Invoke.getTop10Tracks})
  let onPlayAll = _ => {
    switch tracks {
    | Success(tracks) => Invoke.playMany({uris: tracks->Array.map(t => t.uri)})->ignore
    | _ => ignore()
    }
  }

  let onTrackClick = idx => {
    switch tracks {
    | Success(tracks) =>
      Invoke.playManyFromIndex({uris: tracks->Array.map(t => t.uri), index: idx})->ignore
    | _ => ignore()
    }
  }

  switch tracks {
  | Loading => React.null
  | Failed => React.null
  | Success(tracks) =>
    <div className="flex flex-col w-full min-w-0">
      <div className="flex justify-between">
        <p className="r-text-2xl font-serif"> {"Top Tracks"->React.string} </p>
        <button
          id="play-all"
          onClick=onPlayAll
          className="btn btn-ghost bg-base-100 nb-box active:nb-box r-btn"
        >
          <Icon.play className="r-icon" />
          {"Play all"->React.string}
        </button>
      </div>
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4 w-full py-4 px-1">
        {tracks
        ->Array.mapWithIndex((track, idx) =>
          <TrackItem idx track key=track.uri onClick={() => onTrackClick(idx)} />
        )
        ->React.array}
      </div>
    </div>
  }
}
