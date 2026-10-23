module Item = {
  @react.component
  let make = (~route: Route.t, ~active: Route.t, ~idx) => {
    let isSelected = route == active
    let (title, icon) = (route->Route.toTitle, route->Route.toIcon)

    let bg = isSelected ? "bg-primary text-primary-content" : "hover:bg-primary/20"
    let className = `flex flex-row p-2 2xl:py-3 px-4 gap-3 ${bg} rounded-box relative isolate overflow-hidden items-center cursor-pointer shrink-0 transitional duration-300`
    let iconClassname = isSelected
      ? "r-icon text-primary-content"
      : "r-icon text-neutral-content/80"
    <Route.Link to=route className id={`side-item-${idx->Int.toString}`}>
      {React.createElement(icon, {className: iconClassname, weight: Bold})}
      <span className="truncate grow r-title font-medium"> {title->React.string} </span>
    </Route.Link>
  }
}

@react.component
let make = (~active) => {
  let (track, queue) = Store.Player.useShallow(s => (s.data.track, s.data.queue))

  <div
    className={`${Constant.sidebarWidth} flex flex-col gap-1 2xl:gap-2 h-full bg-neutral text-neutral-content`}
  >
    {switch track {
    | Some(track) => <PlayerControls key={track.uri ++ queue->Array.length->Int.toString} />
    | None => <Logo />
    }}
    <div className="flex flex-col r-gap p-4 overflow-y-auto">
      {Route.all
      ->Array.mapWithIndex((route, idx) => <Item route key={route->Route.toTitle} active idx />)
      ->React.array}
    </div>
    {switch track {
    | Some(_) => <Logo classes="mt-auto" />
    | None => React.null
    }}
  </div>
}
