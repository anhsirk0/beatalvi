type t

type options = {
  autoRaf?: bool,
  autoToggle?: bool,
  anchors?: bool,
  smoothWheel?: bool,
  wheelMultiplier?: float,
  allowNestedScroll?: bool,
  naiveDimensions?: bool,
  stopInertiaOnNavigate?: bool,
  lerp?: float,
  duration?: float,
  prevent?: Dom.element => bool,
  wrapper?: Dom.element,
  content?: Dom.element,
}

module Component = {
  @module("lenis/react") @react.component
  external make: (
    ~root: bool=?,
    ~className: string=?,
    ~options: options=?,
    ~children: React.element,
  ) => React.element = "ReactLenis"
}

type useLenisFn = t => unit
@module("lenis/react")
external useLenis: useLenisFn => unit = "useLenis"

let prevent = el => {
  open Util.Dom
  !(el->Classlist.classlist->Classlist.contains("overflow-y-auto"))
}

let options = {
  autoRaf: true,
  allowNestedScroll: true,
  smoothWheel: true,
  duration: 1.,
  lerp: 0.8,
  wheelMultiplier: 4.,
}

@module("lenis") @new external make: options => t = "default"

@send external destroy: t => unit = "destroy"
@send external resize: t => unit = "resize"
@send external start: t => unit = "start"
@send external stop: t => unit = "stop"

@send external scrollTo: (t, float) => unit = "scrollTo"
// @send external scrollToWithOptions: (t, float, scrollToOptions) => unit = "scrollTo"
