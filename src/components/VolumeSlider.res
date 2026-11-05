@react.component
let make = () => {
  let (volume, updateConfig) = Store.Config.useShallow(s => (s.config.volume, s.update))
  let setVolume = vol => updateConfig(SetVolume(vol))

  let onChange = evt => {
    switch evt->Domapi.targetValue->Int.fromString {
    | Some(vol) => Invoke.setVolume({volume: vol})->ignore
    | None => ignore()
    }
  }

  Event.useListen(Event.listenVolume, setVolume)

  <div className="flex flex-col">
    <div className="flex justify-between">
      <p className="text-80 r-text"> {"VOLUME"->React.string} </p>
      <div className="font-medium r-text"> {`${volume->Int.toString}%`->React.string} </div>
    </div>
    <div className="flex r-gap items-center">
      <Icon.speakerSimpleHigh className="r-icon" />
      <input
        type_="range"
        min="0"
        max="100"
        value={volume->Int.toString}
        onChange
        className="range range-xs grow"
      />
    </div>
  </div>
}
