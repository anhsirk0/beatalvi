module Config = {
  type t = {
    theme: Theme.t,
  }

  type action = SetTheme(Theme.t)

  let reducer = (_config, action) =>
    switch action {
    | SetTheme(theme) => {theme: theme}
    }

  let defaultOptions = {
    theme: Lemon,
  }
  module StoreData = {
    type state = {
      config: t,
      updateConfig: action => unit,
    }
  }
  module Store = Zustand.MakeStore(StoreData)

  let store = Store.create(Store.persist(set => {
      config: defaultOptions,
      updateConfig: action => set(state => {...state, config: state.config->reducer(action)}),
    }, {name: "beatalvi-config"}))

  let use = _ => store->Store.use(state => state)
  let useShallow = selector => store->Store.use(Store.useShallow(selector))

  let getTheme = () => (store->Store.getState).config.theme
}

module Player = {
  type state = Playing | Paused | Stopped
  type t = {
    track: option<Shape.Track.t>,
    state: state,
    position: int,
  }

  type action =
    | SetState(state)
    | SetTrack(Shape.Track.t)
    | SetPosition(int)
    | RemoveTrack

  let reducer = (data, action) =>
    switch action {
    | SetState(state) => {...data, state}
    | SetTrack(track) => {...data, track: Some(track)}
    | SetPosition(position) => {...data, position}
    | RemoveTrack => {...data, track: None}
    }

  module StoreData = {
    type state = {data: t, update: action => unit}
  }
  module Store = Zustand.MakeStore(StoreData)

  let store = Store.create(set => {
    data: {
      track: None,
      state: Stopped,
      position: 0,
    },
    update: action => set(prev => {...prev, data: prev.data->reducer(action)}),
  })

  let use = _ => store->Store.use(state => state)
  let useShallow = selector => store->Store.use(Store.useShallow(selector))

  let isPlaying = () => (store->Store.getState).data.state == Playing
  let getPosition = () => (store->Store.getState).data.position
}
