module Content = {
  @react.component
  let make = (~playlist: Shape.Playlist.playlist, ~tracks) => {
    let (trackCount, trackDuration) = (tracks->Array.length, tracks->Shape.Track.totalDuration)

    let onPlay = (~shuffle) =>
      Invoke.playMany({uris: tracks->Array.map(t => t.uri), shuffle})->ignore
    let onStartPlay = _ => onPlay(~shuffle=false)
    let onStartRandomPlay = _ => onPlay(~shuffle=true)
    let onTrackPlay = idx =>
      Invoke.playManyFromIndex({uris: tracks->Array.map(t => t.uri), index: idx})->ignore

    <React.Fragment>
      <div className="flex gap-4 items-end pb-4">
        <div className="flex flex-col">
          <p className="text-3xl 2xl:text-5xl pl-1 font-semibold truncate">
            {playlist.name->React.string}
          </p>
          <p className="r-text pl-2 text-60">
            {`${trackCount->Int.toString} track${trackCount == 1 ? "" : "s"}`->React.string}
            <span className="px-4"> {Constant.sep->React.string} </span>
            {trackDuration->Util.durationToTimeString->React.string}
          </p>
        </div>
        <button
          onClick=onStartPlay
          id="play-all"
          className="btn xl:btn-lg 2xl:btn-xl btn-primary w-40 ml-4 mb-1"
        >
          <Icon.play className="r-icon-lg pr-2" weight=Fill />
          <span className="font-medium"> {" Play"->React.string} </span>
        </button>
        <button onClick=onStartRandomPlay id="play-all" className="btn r-btn-lg btn-square mb-1">
          <Icon.shuffle className="r-icon-lg" weight=Bold />
        </button>
        <Route.Link
          to=EditPlaylist(playlist.id) className="btn xl:btn-lg 2xl:btn-xl btn-square mb-1"
        >
          <Icon.pencilSimple className="r-icon-lg" />
        </Route.Link>
      </div>
      {tracks->Array.length > 0
        ? <div className="grid grid-cols-2 gap-4 w-full px-1 pt-4 border-t-2 border-accent">
            {tracks
            ->Array.mapWithIndex((track, idx) =>
              <TrackItem idx track key=track.uri onClick={() => onTrackPlay(idx)} />
            )
            ->React.array}
          </div>
        : <div className="center r-gap flex-col border-t-2 border-accent">
            <p className="font-instrument r-text-3xl font-light text-center italic mt-[20%]">
              {"No song fits these words yet."->React.string}
            </p>
            <p className="r-text-lg text-center text-60">
              {"Loosen a rule or two to let more music in."->React.string}
            </p>
          </div>}
    </React.Fragment>
  }
}

module Main = {
  @react.component
  let make = (~playlist: Shape.Playlist.t) => {
    let tracks = Hook.useFetch({
      fn: () => {
        switch playlist {
        | Regular({tracks}) => Invoke.getTracksByUris({uris: tracks})
        | Smart(data) => Invoke.getSmartPlaylistTracks({query: data.smartSql})
        }
      },
    })
    let info: Shape.Playlist.playlist = switch playlist {
    | Regular({playlist}) => playlist
    | Smart(data) => {id: data.id, name: data.name, isSmart: true}
    }

    <Lenis
      options=Lenis.options
      className="flex flex-col p-8 size-full gap-4 overflow-y-auto min-h-0 relative"
    >
      <Route.Link
        id="close-btn"
        to=Playlists
        className="btn bg-base-100 btn-ghost r-btn nb-box active:nb-box absolute top-4 right-4 2xl:top-8 2xl:right-8"
        replace=true
      >
        <Icon.arrowLeft className="r-icon" weight=Bold />
        {"Go back"->React.string}
      </Route.Link>
      {switch tracks {
      | Loading | Failed => React.null
      | Success(tracks) => <Content playlist=info tracks />
      }}
    </Lenis>
  }
}

@react.component
let make = (~id) => {
  let playlist = Hook.useFetch({fn: () => Invoke.findPlaylistById({id: id})})

  switch playlist {
  | Loading | Failed => React.null
  | Success(Value(playlist)) => <Main playlist={playlist->Shape.Playlist.fromData} />
  | Success(_) => React.null
  }
}
