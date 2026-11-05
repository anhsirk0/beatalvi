module Btn = {
  @react.component
  let make = (~children, ~target: string, ~anchor: string) => {
    React.cloneElement(children, {"popoverTarget": target, "style": {"anchorName": `--${anchor}`}})
  }
}

module Menu = {
  @react.component
  let make = (~children, ~id: string, ~anchor: string) => {
    React.cloneElement(
      children,
      {"id": id, "popover": "auto", "style": {"positionAnchor": `--${anchor}`}},
    )
  }
}

@send external hidePopover: Dom.element => unit = "hidePopover"

let close = id => `#${id}`->Domapi.querySelectAndThen(hidePopover)
