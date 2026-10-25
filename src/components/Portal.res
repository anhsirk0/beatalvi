@react.component
let make = (~children, ~id) => {
  switch ReactDOM.querySelector(`#${id}`) {
  | Some(root) => ReactDOM.createPortal(children, root)
  | None => React.null
  }
}
