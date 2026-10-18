type view = Appearance | Keybindings | About

@react.component
let make = () => {
  let (view, setView) = React.useState(_ => Appearance)

  let makeTab = tab => {
    let isActive = tab == view
    let cls = isActive ? "nb-box nb-active bg-primary text-primary-content" : ""
    <div
      tabIndex=0
      role="button"
      onClick={_ => setView(_ => tab)}
      className={`p-4 2xl:p-8 py-2 2xl:py-4 r-text-lg font-medium cursor-pointer ${cls}`}
    >
      {tab->String.make->React.string}
    </div>
  }

  <div className="size-full flex flex-col p-8 py-4 2xl:py-8 r-gap min-h-0">
    <p className="r-text-4xl font-bold"> {"Settings"->React.string} </p>

    <div className="flex flex-col xl:flex-row gap-8 mt-4 min-h-0">
      <div className="flex flex-row xl:flex-col xl:min-w-64 p-2 r-gap overflow-x-auto">
        {Appearance->makeTab}
        {Keybindings->makeTab}
        {About->makeTab}
      </div>
      <div className="flex flex-col grow px-2 r-gap min-h-0 overflow-y-auto h-full">
        {switch view {
        | Appearance => <SettingsAppearance />
        | Keybindings => <SettingsKeybinding />
        | About => <SettingsAbout />
        }}
      </div>
    </div>
  </div>
}
