@react.component
let make = () => {
  let route = Route.useRoute()
  let theme = Store.Config.useShallow(s => s.config.theme)
  let update = Store.Player.useShallow(s => s.update)
  let handleKeys = Keybindings.useKeys()

  let state = Hook.useFetch({fn: Invoke.loadMusic})
  let _ = Hook.useFetch({
    fn: Invoke.getTrackState,
    onSuccess: data => {
      switch data->Nullable.toOption {
      | Some(data) => {
          update(SetTrack(data.track))
          update(SetState(data.isPlaying ? Playing : Paused))
          update(SetPosition(data.position))
        }
      | None => ignore()
      }
    },
  })

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
    <div className="size-full flex flex-row min-h-0">
      <Sidebar active=route />
      {switch state {
      | Failed => <p className="text-7xl font-bold"> {"Todo: Error"->React.string} </p>
      | Loading => <Loading />
      | Success(_) => 
        <div className="flex flex-col size-full min-h-0 min-w-0">
          <Header />
          {switch route {
          | Home => <Home />
          | PopularAlbums => <PopularAlbums />
          | Settings => <Settings />
          | _ => <ErrorPage />
          }}
        </div>
      }}
    </div>
  </React.Fragment>
}
