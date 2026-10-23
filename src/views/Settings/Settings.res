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

  <div className="size-full flex flex-col xl:flex-row p-8 py-4 2xl:py-8 gap-4 2xl:gap-8 min-h-0">
    <div className="flex flex-row xl:min-w-64 xl:flex-col p-2 r-gap overflow-x-auto shrink">
      <p className="r-text-4xl font-bold xl:mb-4 mr-auto"> {"Settings"->React.string} </p>
      {Appearance->makeTab}
      {Keybindings->makeTab}
      {About->makeTab}
    </div>
    <div className="flex flex-col grow p-2 xl:pt-4 r-gap min-h-0 overflow-y-auto size-full">
      {switch view {
      | Appearance => <SettingsAppearance />
      | Keybindings => <SettingsKeybinding />
      | About => <SettingsAbout />
      }}
    </div>
  </div>
}
