module Config = {
  type t = {
    theme: Theme.t,
    volume: int,
  }

  type action = SetTheme(Theme.t) | SetVolume(int)

  let reducer = (config, action) =>
    switch action {
    | SetTheme(theme) => {...config, theme}
    | SetVolume(volume) => {...config, volume}
    }

  let defaultOptions = {
    theme: Lemon,
    volume: 100,
  }
  module StoreData = {
    type state = {
      config: t,
      update: action => unit,
    }
  }
  module Store = Zustand.MakeStore(StoreData)

  let store = Store.create(Store.persist(set => {
      config: defaultOptions,
      update: action => set(state => {...state, config: state.config->reducer(action)}),
    }, {name: "beatalvi-user-config"}))

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
    queue: array<string>, // array of uris
  }

  type action =
    | SetState(state)
    | SetTrack(Shape.Track.t)
    | RemoveTrack
    | SetPosition(int)
    | SetQueue(array<string>)
    | QueueToggle(string)
    | QueueRemove(string)

  let reducer = (data, action) =>
    switch action {
    | SetState(state) => {...data, state}
    | SetTrack(track) => {...data, track: Some(track)}
    | RemoveTrack => {...data, track: None}
    | SetPosition(position) => {...data, position}
    | SetQueue(queue) => {...data, queue}
    | QueueToggle(uri) => {...data, queue: data.queue->Util.Arr.toggle(uri)}
    | QueueRemove(uri) => {...data, queue: data.queue->Array.filter(u => u != uri)}
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
      queue: [],
    },
    update: action => set(prev => {...prev, data: prev.data->reducer(action)}),
  })

  let use = _ => store->Store.use(state => state)
  let useShallow = selector => store->Store.use(Store.useShallow(selector))

  let isPlaying = () => (store->Store.getState).data.state == Playing
  let getPosition = () => (store->Store.getState).data.position
}
