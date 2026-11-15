module QueueBtn = {
  @react.component
  let make = (~uri, ~onClose) => {
    let isQueued = Store.Player.useShallow(s => s.data.queue->Array.some(u => u == uri))
    let onClick = _ => {
      Invoke.queueToggleTrack({uri: uri})->ignore
      onClose()
    }

    <button onClick className="btn btn-ghost bg-base-100 nb-box active:nb-box r-btn-lg">
      {(isQueued ? "Remove from queue" : "Add to queue")->React.string}
    </button>
  }
}

module Btn = {
  @react.component
  let make = (~playlist: Shape.Playlist.playlist, ~uri: string, ~forAdd=false, ~onClose) => {
    let onClick = _ => {
      let fn = forAdd ? Invoke.appendTrackToPlaylist : Invoke.removeTrackFromPlaylist
      fn({id: playlist.id, uri})
      ->Promise.catch(async _e => -1)
      ->Promise.then(async ids => {
        let (action, actioned) = forAdd ? ("add to", "added to") : ("remove from", "removed from")
        ids > 0
          ? Toast.success(`Song ${actioned} ${playlist.name}.`)
          : Toast.error(`Failed to ${action} ${playlist.name}.`)
      })
      ->ignore
      onClose()
    }

    <button onClick className="btn btn-ghost bg-base-100 nb-box active:nb-box r-btn-lg">
      {(forAdd ? "Add to" : "Remove from ")->React.string}
      <Icon.playlist className="r-icon" />
      <span className="font-medium"> {playlist.name->React.string} </span>
    </button>
  }
}

type playlistData = {
  toAdd: array<Shape.Playlist.playlist>,
  toRemove: array<Shape.Playlist.playlist>,
}

@react.component
let make = (~track: Shape.Track.t, ~onClose) => {
  let playlists = Store.Player.useShallow(s => s.data.playlists->Array.filter(p => !p.isSmart))
  let (data, setData) = React.useState(_ => {toAdd: [], toRemove: []})

  let _ = Hook.useFetch({
    fn: () => Invoke.getPlaylistsForTrack({uri: track.uri}),
    onSuccess: trackPlaylists => {
      let filterFn = (p: Shape.Playlist.playlist) => trackPlaylists->Array.some(tp => tp.id == p.id)
      let toRemove = playlists->Array.filter(filterFn)
      let toAdd = playlists->Array.filter(p => !filterFn(p))
      setData(_ => {
        toAdd,
        toRemove,
      })
    },
  })

  <Modal
    title={<p className="r-text-2xl"> {track.name->React.string} </p>}
    onClose
    classes="min-w-24 transitional"
  >
    <div className="divider divider-accent -mt-1"></div>
    <SettingsAbout.Item title="Album" info=track.album />
    <SettingsAbout.Item title="Artist" info=track.artist />
    <div className="mt-4 flex r-gap flex-col">
      <QueueBtn uri=track.uri onClose />
      {data.toAdd
      ->Array.map(p => <Btn key=p.name playlist=p uri=track.uri forAdd=true onClose />)
      ->React.array}
      {data.toRemove
      ->Array.map(p => <Btn key=p.name playlist=p uri=track.uri onClose />)
      ->React.array}
    </div>
  </Modal>
}
