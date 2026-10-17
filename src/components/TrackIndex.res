@react.component
let make = (~uri, ~idx) => {
  let (qIdx, isPlaying) = Store.Player.useShallow(s => (
    s.data.queue->Array.findIndex(u => u == uri),
    s.data.track->Option.filter(t => t.uri == uri)->Option.isSome,
  ))

  qIdx >= 0
    ? <p
        className={`r-text-lg font-medium text-primary-content/80 bg-primary nb-box h-4/5 aspect-square center`}
      >
        {(qIdx + 1)->Util.padInt->React.string}
      </p>
    : <p
        className={`r-text-lg font-medium ${isPlaying
            ? "text-primary-content/80"
            : "text-80"} aspect-square h-4/5 center`}
      >
        {(idx + 1)->Util.padInt->React.string}
      </p>
}
