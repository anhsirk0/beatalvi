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

module Scroll = {
  type behavior =
    | @as("smooth") Smooth
    | @as("auto") Auto
  type block =
    | @as("start") Start
    | @as("center") Center
    | @as("end") End
    | @as("nearest") Nearest
  type intoViewOpts = {behavior?: behavior, block?: block, inline?: block}
  @send external intoView: (Dom.element, intoViewOpts) => unit = "scrollIntoView"
}

module Classlist = {
  type t
  @get external classlist: Dom.element => t = "classList"
  @send external contains: (t, string) => bool = "contains"
}

module URLSearchParams = {
  type t
  @new external make: string => t = "URLSearchParams"
  %%private(@send external get_: (t, string) => Nullable.t<string> = "get")
  let get = (params, key) => params->get_(key)->Nullable.toOption
}

@get @return(nullable)
external firstElementChild: Dom.element => option<Dom.element> = "firstElementChild"
