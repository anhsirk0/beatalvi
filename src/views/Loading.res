@react.component
let make = () => {
  <div className="center flex-col h-full min-h-0 w-max mx-auto p-8 gap-8">
    <div className="flex flex-col w-full gap-4">
      <p className="text-5xl font-bold"> {"Scanning Music ..."->React.string} </p>

      <progress className="progress progress-primary border-2 border-accent w-full h-12 nb-shadow">
      </progress>
      <p className="text-xl font-medium text-80">
        {"This may take a while, depending on the size of your library."->React.string}
      </p>
    </div>
    <div className="nb-outline p-4 2xl:p-8 nb-box overflow-y-auto min-h-0">
      <SettingsKeybinding />
    </div>
  </div>
}
