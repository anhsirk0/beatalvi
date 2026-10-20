@react.component
let make = () => {
  let (isOpen, toggleOpen, _) = Hook.useToggle()
  let route = Route.useRoute()
  let (theme, volume) = Store.Config.useShallow(s => (s.config.theme, s.config.volume))
  let update = Store.Player.useShallow(s => s.update)
  let handleKeys = Keybindings.useKeys()

  let state = Hook.useFetch({fn: Invoke.loadMusic})
  let _ = Hook.useFetch({
    fn: Invoke.getTrackState,
    onSuccess: data => {
      switch data.track->Nullable.toOption {
      | Some(track) => {
          update(SetTrack(track))
          update(SetState(data.isPlaying ? Playing : Paused))
          update(SetPosition(data.position))
        }
      | None => ignore()
      }
      update(SetQueue(data.queue))
    },
  })

  let _ = Hook.useFetch({fn: () => Invoke.setVolume({volume: volume})})

  let setTrack = track => {
    update(SetState(Playing))
    update(SetTrack(track))
    update(SetPosition(0))
  }

  React.useEffect1(() => {
    theme->Theme.setTheme
    None
  }, [theme])

  Event.useListen(Event.listenPlay, setTrack)
  Event.useListen(Event.listenStart, setTrack)
  Event.useListen(Event.listenNext, track => {
    setTrack(track)
    update(QueueRemove(track.uri))
  })
  Event.useListen(Event.listenPrevious, setTrack)
  Event.useListen(Event.listenQueueToggle, uri => update(QueueToggle(uri)))

  Event.useListen(Event.listenFinished, _ => {
    update(SetState(Stopped))
    update(RemoveTrack)
    update(SetPosition(0))
  })

  React.useEffect0(() => {
    Document.addKeyListener("keydown", handleKeys)
    Some(() => Document.removeKeyListener("keydown", handleKeys))
  })

  <React.Fragment>
    <Toast.Toaster />
    <div className="drawer drawer-end size-full">
      <input
        checked=isOpen readOnly=true id="queue-drawer" type_="checkbox" className="drawer-toggle"
      />
      <div className="drawer-content size-full flex flex-row min-h-0">
        <Sidebar active=route />
        {switch state {
        | Failed => <p className="text-7xl font-bold"> {"Todo: Error"->React.string} </p>
        | Loading => <Loading />
        | Success(_) =>
          <div className="flex flex-col size-full min-h-0 min-w-0">
            <Header toggleOpen />
            {switch route {
            | Home => <Home />
            | PopularAlbums => <PopularAlbums />
            | RandomAlbums => <RandomAlbums />
            | LovedAlbums => <LovedAlbums />
            | RecentAlbums => <RecentAlbums />
            | AllAlbums => <AllAlbums />
            | AllArtists => <AllArtists />
            | Settings => <Settings />
            | _ => <ErrorPage />
            }}
          </div>
        }}
      </div>
      <div className="drawer-side">
        <label
          id="close-btn"
          onClick={_ =>
            if isOpen {
              toggleOpen()
            }}
          ariaLabel="close sidebar"
          className="drawer-overlay"
        >
        </label>
        <div className="bg-base-200 min-h-full r-gap p-4">
          <p className="text-60 r-text uppercase"> {"Playing Albums"->React.string} </p>
          {isOpen ? <QueueSidebar /> : React.null}
        </div>
      </div>
    </div>
  </React.Fragment>
}
