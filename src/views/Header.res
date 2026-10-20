type modal = Keybindings | Search | Nope

@react.component
let make = () => {
  let (modal, setModal) = React.useState(_ => Nope)

  let track = Store.Player.useShallow(s => s.data.track)
  let popoverId = "settings-menu"

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
      <button
        id="search-modal"
        onClick={_ => setModal(_ => Search)}
        className="btn bg-base-100 btn-square btn-ghost r-btn nb-box active:nb-box"
      >
        <Icon.magnifyingGlass className="r-icon" />
      </button>
      <button onClick={_ => setModal(_ => Keybindings)} id="keybindings-modal" className="hidden">
      </button>
      <Popover.Btn target=popoverId anchor="settings-btn">
        <button className="btn bg-base-100 btn-square btn-ghost r-btn nb-box active:nb-plain">
          <Icon.sliders className="r-icon" />
        </button>
      </Popover.Btn>
      <Popover.Menu id=popoverId anchor="settings-btn">
        <div
          className="dropdown dropdown-end p-4 w-80 mt-4 bg-base-100 nb-box nb-active flex flex-col"
        >
          <VolumeSlider />
          <div className="divider divider-accent"></div>
          <ThemeSwitcher />
          <div className="divider divider-accent"></div>
          <Route.Link
            onClick={_ => Popover.close(popoverId)}
            to=Settings
            className="btn btn-lg btn-ghost nb-box active:nb-box"
          >
            {"More Settings"->React.string}
            <Icon.arrowRight className="ml-auto r-icon" weight=Bold />
          </Route.Link>
        </div>
      </Popover.Menu>
    </div>
    {switch modal {
    | Keybindings =>
      <Modal
        title={<p className="text-4xl font-bold"> {"Keybindings"->React.string} </p>}
        onClose={() => setModal(_ => Nope)}
        classes="min-w-[60vw]"
      >
        <div className="divider divider-accent -mt-1"></div>
        <SettingsKeybinding />
      </Modal>
    | Search => <SearchModal onClose={() => setModal(_ => Nope)} />
    | Nope => React.null
    }}
  </div>
}
