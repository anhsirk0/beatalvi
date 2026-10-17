type t

module K = ReactEvent.Keyboard

let useKeys = () => {
  let updateConfig = Store.Config.useShallow(s => s.updateConfig)

  (evt: K.t) => {
    evt->K.preventDefault

    let key = evt->K.key
    let isCtrl = evt->K.ctrlKey
    let digit = key->Int.fromString

    // let isModifier = [K.ctrlKey, K.metaKey]->Array.some(fn => evt->fn)

    if key == " " {
      Invoke.toggle()->ignore
    } else if key == "d" {
      updateConfig(SetTheme(Store.Config.getTheme()->Theme.toggleTheme))
    } else if key == "Backspace" {
      "#close-btn"->Util.Dom.querySelectAndThen(Util.Dom.click)
    } else if key == "n" {
      Invoke.playNext()->ignore
    } else if key == "p" {
      Invoke.playPrevious()->ignore
    } else if key == "ArrowLeft" || key == "h" {
      Invoke.rewind10Seconds()->ignore
    } else if key == "ArrowRight" || key == "l" {
      Invoke.seek10Seconds()->ignore
    } else if isCtrl && digit->Option.isSome {
      switch digit {
      | Some(i) =>
        `#side-item-${(i - 1)->Int.toString}`->Util.Dom.querySelectAndThen(Util.Dom.click)
      | None => ignore()
      }
    }
  }
}
