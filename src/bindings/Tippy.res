type t

@module("@tippyjs/react/headless") @react.component
external make: (
  ~children: React.element,
  ~render: JsxDOM.domProps => React.element,
) => React.element = "default"
