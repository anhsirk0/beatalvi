type t =
  | @as("lemon") Lemon
  | @as("lemon-dark") LemonDark
  | @as("bubblegum") Bubblegum
  | @as("bubblegum-dark") BubblegumDark
  | @as("ocean") Ocean
  | @as("ocean-dark") OceanDark
  | @as("orchid") Orchid
  | @as("orchid-dark") OrchidDark
  | @as("forest") Forest
  | @as("forest-dark") ForestDark
  | @as("coral") Coral
  | @as("coral-dark") CoralDark
  | @as("sunflower") Sunflower
  | @as("sunflower-dark") SunflowerDark
  | @as("cherry") Cherry
  | @as("cherry-dark") CherryDark
  | @as("sky") Sky
  | @as("sky-dark") SkyDark
  | @as("mango") Mango
  | @as("mango-dark") MangoDark

let defaultTheme = Lemon
let lightThemes = [Lemon, Bubblegum, Ocean, Orchid, Forest, Coral, Sunflower, Cherry, Sky, Mango]
let darkThemes = [
  LemonDark,
  BubblegumDark,
  OceanDark,
  OrchidDark,
  ForestDark,
  CoralDark,
  SunflowerDark,
  CherryDark,
  SkyDark,
  MangoDark,
]

// let fromString = s =>
//   switch s {
//   | "lemon" => Lemon
//   | "lemon-dark" => LemonDark
//   | _ => defaultTheme
//   }

external toString: t => string = "%identity"

let isDark = theme => darkThemes->Array.some(t => t == theme)

let toggleTheme = theme =>
  switch theme {
  | LemonDark => Lemon
  | BubblegumDark => Bubblegum
  | OceanDark => Ocean
  | OrchidDark => Orchid
  | ForestDark => Forest
  | CoralDark => Coral
  | SunflowerDark => Sunflower
  | CherryDark => Cherry
  | SkyDark => Sky
  | MangoDark => Mango
  | Lemon => LemonDark
  | Bubblegum => BubblegumDark
  | Ocean => OceanDark
  | Orchid => OrchidDark
  | Forest => ForestDark
  | Coral => CoralDark
  | Sunflower => SunflowerDark
  | Cherry => CherryDark
  | Sky => SkyDark
  | Mango => MangoDark
  }

let rotate = theme => (theme->isDark ? darkThemes : lightThemes)->Util.Arr.rotate(theme)

let setTheme = theme => {
  "html"->Util.Dom.querySelectAndThen(Util.Dom.setAttribute(_, "data-theme", theme->toString))
  "beatalviTheme"->Dom.Storage.setItem(theme->toString, Dom.Storage.localStorage)
}
