module Card = {
  @react.component
  let make = (~theme: Theme.t, ~current, ~onChange) => {
    let isActive = current == theme
    let cls = isActive ? "nb-active" : ""

    let component =
      <div
        className={`aspect-square nb-box overflow-hidden ${cls} center cursor-pointer`}
        onClick={_ => onChange(theme)}
        tabIndex=0
      >
        <div className="rounded-full size-10 translate-x-4 translate-y-4 bg-primary"></div>
      </div>

    React.cloneElement(component, {"data-theme": theme->Theme.toString})
  }
}

@react.component
let make = () => {
  let (current, isDark, updateConfig) = Store.Config.useShallow(s => (
    s.config.theme,
    s.config.theme->Theme.isDark,
    s.update,
  ))
  let onChange = theme => updateConfig(SetTheme(theme))

  <div className="flex flex-col">
    <div className="flex justify-between">
      <p className="text-80 r-text"> {"THEME"->React.string} </p>
      <div className="font-medium r-text"> {current->Theme.toString->React.string} </div>
    </div>
    <div className="grid grid-cols-5 gap-4 mt-2">
      {(isDark ? Theme.darkThemes : Theme.lightThemes)
      ->Array.map(theme => <Card theme current onChange key={theme->Theme.toString} />)
      ->React.array}
    </div>
  </div>
}
