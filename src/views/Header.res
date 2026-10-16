@react.component
let make = () => {
  let track = Store.Player.useShallow(s => s.data.track)

  <div
    className={`${Constant.headerHeight} border-b-2 border-accent px-8 w-full flex items-center r-gap`}
  >
    {switch track {
    | Some(track) => <TrackInfoAndProgress track key=track.uri />
    | None =>
      <Delay timeout={100}>
        <Stats />
      </Delay>
    }}
    <div className="flex justify-end r-gap ml-auto shrink-0 min-w-40">
      <button className="btn bg-base-100 btn-square btn-ghost r-btn nb-box active:nb-box">
        <Icon.magnifyingGlass className="r-icon" />
      </button>
      <Route.Link
        to=Settings className="btn bg-base-100 btn-square btn-ghost r-btn nb-box active:nb-box"
      >
        <Icon.sliders className="r-icon" />
      </Route.Link>
    </div>
  </div>
}
