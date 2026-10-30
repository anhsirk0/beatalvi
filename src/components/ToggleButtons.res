@react.component
let make = (~first="Yes", ~second="No", ~active, ~onChange) => {
  let onClick = opt =>
    if opt != active {
      onChange(opt)
    }

  let makeBtn = opt => {
    let className =
      opt == active
        ? "btn r-btn-lg btn-primary"
        : "btn r-btn-lg nb-outline active:nb-outline active:nb-plain btn-ghost"
    <button onClick={_ => onClick(opt)} className> {opt->React.string} </button>
  }

  <div className="flex r-gap">
    {makeBtn(first)}
    {makeBtn(second)}
  </div>
}
