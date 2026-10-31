type t

module Options = {
  type t
  external fromObj: {..} => t = "%identity"
}

module Toaster = {
  @react.component @module("react-hot-toast")
  external make: (~position: string=?) => React.element = "Toaster"
}

%%private(
  @module("react-hot-toast") external toast: (string, Options.t) => unit = "toast"
  let makeIcon = (icon: Icon.t) => React.createElement(icon, {className: "size-8"})

  let make = (options, msg) => toast(msg, options)
)

let success = make(
  Options.fromObj({
    "icon": makeIcon(Icon.checkCircle),
    "className": "alert alert-primary",
  }),
  _,
)

let error = make(
  Options.fromObj({
    "icon": makeIcon(Icon.warning),
    "className": "alert alert-error",
  }),
  _,
)

let warn = make(
  Options.fromObj({
    "icon": makeIcon(Icon.warningCircle),
    "className": "alert alert-warning",
  }),
  _,
)
let info = make(
  Options.fromObj({
    "icon": makeIcon(Icon.info),
    "className": "alert alert-info",
  }),
  _,
)

// let success = msg => privateSuccess(make, msg)
// let error = msg => privateError(make, msg)
