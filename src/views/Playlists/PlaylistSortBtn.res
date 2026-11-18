let popoverId = "sort-menu"
let anchor = "sort-btn"

module Item = {
  @react.component
  let make = (~sort, ~active, ~name) => {
    let (sortMap, updateConfig) = Store.Config.useShallow(s => (s.config.sortMap, s.update))

    let label = sort->Shape.Sort.toString
    let className = sort == active ? "btn r-btn btn-primary" : "btn r-btn btn-ghost"
    let onClick = _ => {
      let newSortMap = sortMap->Dict.copy
      newSortMap->Dict.set(name, sort)
      updateConfig(SetSortMap(newSortMap))
      Popover.close(popoverId)
    }

    <button onClick className> {label->React.string} </button>
  }
}

@react.component
let make = (~name) => {
  let active = Store.Config.useShallow(s =>
    s.config.sortMap->Dict.get(name)->Option.getOr(Shape.Sort.default)
  )

  <React.Fragment>
    <Popover.Btn target=popoverId anchor>
      <button className="btn r-btn-lg btn-square btn-ghost bg-base-100 active:nb-plain mb-1">
        <Icon.funnel className="r-icon-lg" />
      </button>
    </Popover.Btn>
    <Popover.Menu id=popoverId anchor>
      <div className="dropdown p-4 w-64 mt-4 bg-base-100 nb-box nb-active flex flex-col gap-2">
        {Shape.Sort.all
        ->Array.mapWithIndex((sort, idx) => <Item sort active name key={idx->Int.toString} />)
        ->React.array}
      </div>
    </Popover.Menu>
  </React.Fragment>
}
