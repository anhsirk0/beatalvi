type t

module K = ReactEvent.Keyboard

let useKeys = () => {
  let updateConfig = Store.Config.useShallow(s => s.updateConfig)

  (evt: K.t) => {
    // let isModifier = [K.ctrlKey, K.metaKey]->Array.some(fn => evt->fn)
    evt->K.preventDefault
    let key = K.key(evt)

    if key == " " {
      Invoke.toggle()->ignore
    } else if key == "d" {
      updateConfig(SetTheme(Store.Config.getTheme()->Theme.toggleTheme))
    } else if key == "n" {
      Invoke.playNext()->ignore
    } else if key == "p" {
      Invoke.playPrevious()->ignore
    } else if key == "ArrowLeft" || key == "h" {
      Invoke.rewind10Seconds()->ignore
    } else if key == "ArrowRight" || key == "l" {
      Invoke.seek10Seconds()->ignore
    }
  }
}
