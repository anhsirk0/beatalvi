open ReactEvent

module CloseBtn = {
  @react.component
  let make = (~onClick) => {
    <button
      id="close-btn" onClick className="btn r-btn btn-square btn-ghost nb-ghost bg-base-100 -mt-2"
    >
      <Icon.x className="r-icon" weight=Bold />
    </button>
  }
}

@react.component
let make = (~title=?, ~onClose, ~children, ~classes="") => {
  let className = `modal-box nb-box nb-active flex flex-col max-h-[96vh] min-w-[36vw] ${classes}`

  let onClick = _ => onClose()

  React.useEffect0(() => {
    ".modal-open form"->Util.Dom.querySelectAndThen(Util.Dom.focus)
    None
  })

  <div
    onContextMenu=Mouse.stopPropagation
    onWheel=Wheel.stopPropagation
    onClick
    className="modal modal-open modal-bottom sm:modal-middle"
  >
    <div className onClick=Mouse.stopPropagation>
      {title->Util.renderSome(title =>
        <div className="flex flex-row items-center justify-between mb-2 xl:mb-4 -mt-1">
          {title}
          <CloseBtn onClick />
        </div>
      )}
      {children}
    </div>
  </div>
}
