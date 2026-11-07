module Card = {
  @react.component
  let make = (~theme: Theme.t, ~current, ~onChange) => {
    let isActive = current == theme
    let className = `flex flex-col flex-1 nb-box bg-transparent overflow-hidden h-36 ${isActive
        ? "nb-active"
        : ""}`
    let component =
      <div className onClick={_ => onChange(theme)} tabIndex=0>
        <div className="flex flex-row grow">
          <div className="w-2/5 h-full bg-neutral"></div>
          <div className="w-3/5 h-full bg-base-200 p-4">
            <div className="nb-box bg-primary h-8 w-16"></div>
          </div>
        </div>
        <div className="flex p-4 justify-between border-t-2 border-accent bg-base-100">
          <p className="r-title capitalize font-medium"> {theme->Theme.toString->React.string} </p>
          {isActive ? <Icon.check className="r-icon" weight=Bold /> : React.null}
        </div>
      </div>

    React.cloneElement(component, {"data-theme": theme->Theme.toString})
  }
}

type btnState = Idle | Loading | Done

@react.component
let make = () => {
  let (state, setState) = React.useState(_ => Idle)
  let (current, isDark, showPlaylistsInSidebar, updateConfig) = Store.Config.useShallow(s => (
    s.config.theme,
    s.config.theme->Theme.isDark,
    s.config.showPlaylistsInSidebar,
    s.update,
  ))

  let onChange = theme => updateConfig(SetTheme(theme))
  let onRegenCover = _ => {
    setState(_ => Loading)
    Invoke.regenerateCoverArtCache()
    ->Promise.then(async _ => {
      setTimeout(() => setState(_ => Done), 1000)->ignore
      setTimeout(() => setState(_ => Idle), 8000)->ignore
    })
    ->ignore
  }

  <React.Fragment>
    <p className="xl:mt-4 text-80 uppercase font-medium"> {"Mode"->React.string} </p>
    <ToggleButtons
      first="Light"
      second="Dark"
      active={isDark ? "Dark" : "Light"}
      onChange={_ => onChange(current->Theme.toggleTheme)}
    />
    <p className="mt-4 text-80 uppercase font-medium"> {"Theme"->React.string} </p>
    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-5 gap-8">
      {(isDark ? Theme.darkThemes : Theme.lightThemes)
      ->Array.map(theme => <Card theme current onChange key={theme->Theme.toString} />)
      ->React.array}
    </div>
    <p className="xl:mt-4 text-80 uppercase font-medium">
      {"Show playlists in sidebar"->React.string}
    </p>
    <ToggleButtons
      active={showPlaylistsInSidebar ? "Yes" : "No"}
      onChange={_ => updateConfig(SetShowPlaylistsInSidebar(!showPlaylistsInSidebar))}
    />
    <p className="mt-4 text-80 uppercase font-medium"> {"Cover art"->React.string} </p>
    {switch state {
    | Idle =>
      <button onClick=onRegenCover className="btn r-btn-lg w-96">
        {"Regenerate cover art cache"->React.string}
      </button>
    | Done =>
      <button onClick=onRegenCover className="btn r-btn-lg btn-success w-100">
        {"Cover art cache regenerated"->React.string}
      </button>
    | Loading =>
      <button disabled=true className="btn r-btn-lg w-96">
        <span className="loading loading-spinner"></span>
        {"Generating cover art cache"->React.string}
      </button>
    }}
  </React.Fragment>
}
