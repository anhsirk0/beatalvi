let toCapitalize = str => str->String.charAt(0)->String.toUpperCase ++ str->String.slice(~start=1)

let range = Belt.Array.range(1, _)

let toInitials = name =>
  name
  ->String.split(" ")
  ->Array.map(s => s->String.charAt(0))
  ->Array.map(String.toUpperCase)
  ->Array.join("")

let toAmountText = (count, label) => count == 1 ? label : label ++ "s"
let toAmountLabel = (count, label) => `${count->Int.toString} ${label}${count == 1 ? "" : "s"}`

let renderSome = (data, fn) =>
  switch data {
  | Some(some) => fn(some)
  | None => React.null
  }

let padInt = num => num->Int.toString->String.padStart(2, "0")
let padInt3 = num => num->Int.toString->String.padStart(3, "0")
let durationToString = seconds => {
  let hrs = seconds / 3600
  let mins = (seconds % 3600 / 60)->padInt
  let secs = (seconds % 60)->padInt
  hrs > 0 ? `${hrs->padInt}:${mins}:${secs}` : `${mins}:${secs}`
}

let durationToTimeString = seconds => {
  let hrs = seconds / 3600
  let mins = seconds % 3600 / 60
  let secs = (seconds % 60)->Int.toString
  if hrs > 0 {
    `${hrs->Int.toString} h  ${mins->Int.toString} m`
  } else if mins > 0 {
    `${mins->Int.toString} m  ${secs} s`
  } else {
    `${secs} s`
  }
}

module Str = {
  let isEmpty = str => str->String.length === 0
  let or = (str, str2) => str->isEmpty ? str2 : str
  let isSame = (str, str2) => str->String.toLowerCase == str2->String.toLowerCase
  let contains = (s1, s2) => s1->String.toLowerCase->String.includes(s2->String.toLowerCase)
}

module Arr = {
  let isEmpty = arr => arr->Array.length === 0
  let or = (arr, arr2) => arr->isEmpty ? arr2 : arr
  let uniq = arr => arr->Set.fromArray->Set.toArray
  let toggle = (arr: array<'a>, item: 'a) =>
    arr->Array.some(i => i == item) ? arr->Array.filter(i => i != item) : arr->Array.concat([item])
  let rotate = (arr, item) => {
    switch arr->Array.findIndexOpt(i => i == item) {
    | Some(idx) => arr[mod(idx + 1, arr->Array.length)]
    | None => arr[0]
    }
  }
  // let render = (arr, fn) => arr->Array.map(fn)->React.array
  // let renderOr = (arr, fn, empty) => arr->isEmpty ? empty : arr->Array.map(fn)->React.array
}

module Dom = {
  @set external setValue: (Dom.element, string) => unit = "value"
  @send external focus: Dom.element => unit = "focus"
  @send external click: Dom.element => unit = "click"
  @send external blur: Dom.element => unit = "blur"
  @send external setAttribute: (Dom.element, string, string) => unit = "setAttribute"

  let querySelectAndThen = (selector, action) => {
    switch ReactDOM.querySelector(selector) {
    | Some(el) => el->action
    | None => ()
    }
  }
  let targetValue = evt => ReactEvent.Form.target(evt)["value"]
}
