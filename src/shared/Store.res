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
  let getVolume = () => (store->Store.getState).config.volume
}

module Player = {
  type state = Playing | Paused | Stopped
  type t = {
    track: option<Shape.Track.t>,
    state: state,
    position: int,
    queue: array<string>, // array of uris
    playlists: array<Shape.Playlist.playlist>,
  }

  type action =
    | SetState(state)
    | SetTrack(Shape.Track.t)
    | RemoveTrack
    | SetPosition(int)
    | SetQueue(array<string>)
    | SetPlaylists(array<Shape.Playlist.playlist>)
    | QueueToggle(string)
    | QueueRemove(string)

  let reducer = (data, action) =>
    switch action {
    | SetState(state) => {...data, state}
    | SetTrack(track) => {...data, track: Some(track)}
    | RemoveTrack => {...data, track: None}
    | SetPosition(position) => {...data, position}
    | SetQueue(queue) => {...data, queue}
    | SetPlaylists(playlists) => {...data, playlists}
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
      playlists: [],
    },
    update: action => set(prev => {...prev, data: prev.data->reducer(action)}),
  })

  let use = _ => store->Store.use(state => state)
  let useShallow = selector => store->Store.use(Store.useShallow(selector))

  let isStopped = () => (store->Store.getState).data.state == Stopped
  let isPlaying = () => (store->Store.getState).data.state == Playing
  let getPosition = () => (store->Store.getState).data.position
}
