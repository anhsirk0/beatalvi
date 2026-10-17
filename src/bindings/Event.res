type t<'a> = {
  event: string,
  id: float,
  payload: 'a,
}

type callback<'a> = t<'a> => unit
@module("@tauri-apps/api/event")
external listen: (string, callback<'a>) => promise<unit => unit> = "listen"

type track = Shape.Track.t
let listenPlay = (fn: track => unit) => listen("play", d => fn(d.payload))
let listenPause = (fn: unit => unit) => listen("pause", _ => fn())
let listenToggle = (fn: bool => unit) => listen("toggle", d => fn(d.payload))
let listenFinished = (fn: unit => unit) => listen("finished", _ => fn())
let listenStart = (fn: track => unit) => listen("start", d => fn(d.payload))
let listenNext = (fn: track => unit) => listen("next", d => fn(d.payload))
let listenPrevious = (fn: track => unit) => listen("previous", d => fn(d.payload))
let listenPosition = (fn: int => unit) => listen("position", d => fn(d.payload))
let listenQueueToggle = (fn: string => unit) => listen("queue_toggle", d => fn(d.payload))
// let listenTrackState = (fn: Shape.Track.state => unit) => listen("track_state", d => fn(d.payload))

// let useListen = eventFn => {
//   React.useEffect0(() => {
//     let unlisten = eventFn()
//     Some(() => unlisten->Promise.then(async fn => fn())->ignore)
//   })
// }

let useListen = (event, fn) => {
  React.useEffect0(() => {
    let unlisten = event(fn)
    Some(() => unlisten->Promise.then(async fn => fn())->ignore)
  })
}
