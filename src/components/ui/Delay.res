@react.component
let make = (~timeout: int, ~children) => {
  let (show, setShow) = React.useState(() => false)

  React.useEffect0(() => {
    let timeoutId = setTimeout(() => setShow(_ => true), timeout)
    Some(() => clearTimeout(timeoutId))
  })

  show ? children : React.null
}
