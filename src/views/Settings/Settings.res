@react.component
let make = () => {
  <div className="size-full flex flex-col p-8 r-gap min-h-0 overflow-y-auto">
    <p className="r-text-2xl font-semibold"> {"Settings"->React.string} </p>
    <SettingsAppearance />
  </div>
}
