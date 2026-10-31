type t

module K = ReactEvent.Keyboard

let useKeys = () => {
  let updateConfig = Store.Config.useShallow(s => s.update)

  (evt: K.t) => {
    let key = evt->K.key

    if key != "Tab" || key != "Enter" || key != "Escape" {
      evt->K.preventDefault
    }

    let isCtrl = evt->K.ctrlKey
    let digit = key->Int.fromString

    // let isModifier = [K.ctrlKey, K.metaKey]->Array.some(fn => evt->fn)

    if key == " " {
      Invoke.toggle()->ignore
    } else if key == "Backspace" || key == "Escape" {
      "#close-btn"->Util.Dom.querySelectAndThen(Util.Dom.click)
    } else if key == "?" {
      "#keybindings-modal"->Util.Dom.querySelectAndThen(Util.Dom.click)
    } else if key == "/" {
      "#search-modal"->Util.Dom.querySelectAndThen(Util.Dom.click)
      setTimeout(() => "#search-input"->Util.Dom.querySelectAndThen(Util.Dom.focus), 200)->ignore
    } else if key == ";" {
      Route.Settings->Route.toPath->RescriptReactRouter.push
    } else if key == "," {
      switch Store.Config.getTheme()->Theme.rotateBackward {
      | Some(theme) => updateConfig(SetTheme(theme))
      | None => ignore()
      }
    } else if key == "." {
      switch Store.Config.getTheme()->Theme.rotate {
      | Some(theme) => updateConfig(SetTheme(theme))
      | None => ignore()
      }
    } else if key == "d" {
      updateConfig(SetTheme(Store.Config.getTheme()->Theme.toggleTheme))
    } else if key == "n" {
      Invoke.playNext()->ignore
    } else if key == "p" {
      Invoke.playPrevious()->ignore
    } else if key == "q" {
      "#queue-sidebar"->Util.Dom.querySelectAndThen(Util.Dom.click)
    } else if key == "s" {
      "#play-all"->Util.Dom.querySelectAndThen(Util.Dom.click)
    } else if key == "ArrowLeft" || key == "h" {
      Invoke.rewind10Seconds()->ignore
    } else if key == "ArrowRight" || key == "l" {
      Invoke.seek10Seconds()->ignore
    } else if key == "ArrowUp" || key == "j" {
      // Todo: show a toast
      Invoke.setVolume({volume: Store.Config.getVolume() + 5})->ignore
    } else if key == "ArrowDown" || key == "k" {
      // Todo: show a toast
      Invoke.setVolume({volume: Store.Config.getVolume() - 5})->ignore
    } else if isCtrl && key == "r" {
      Invoke.reloadWindow()->ignore
    } else if isCtrl && digit->Option.isSome {
      switch digit {
      | Some(i) => {
          let id = (i == 0 ? 9 : i - 1)->Int.toString
          `#side-item-${id}`->Util.Dom.querySelectAndThen(Util.Dom.click)
        }
      | None => ignore()
      }
    }
  }
}
