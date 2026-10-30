module TrackItem = {
  @react.component
  let make = (~track: Shape.Track.item, ~idx) => {
    let currentTrack = Store.Player.useShallow(s => s.data.track)
    let isPlaying = Some(track.uri) == currentTrack->Option.map(t => t.uri)
    let bg = isPlaying ? "bg-primary text-primary-content nb-active" : "bg-base-100"

    let onClick = _ => Invoke.play({trackUri: track.uri})->ignore

    let onMouseDown = evt => {
      "#search-input"->Util.Dom.querySelectAndThen(Util.Dom.blur)
      if evt->ReactEvent.Mouse.button == 1 {
        evt->ReactEvent.Mouse.preventDefault
        Invoke.queueToggleTrack({uri: track.uri})->ignore
      }
    }

    <div
      role="button"
      onClick
      onMouseDown
      className={`flex flex-row items-center cursor-pointer px-4 nb nb-box active:nb-plain gap-4 border-2 ${bg} shrink-0 animate-slide-up`}
    >
      <TrackIndex uri=track.uri idx />
      <p className="r-text-lg font-medium w-full truncate py-2"> {track.name->React.string} </p>
      <p className="text-lg"> {track.duration->Util.durationToString->React.string} </p>
    </div>
  }
}

@react.component
let make = (~group: Shape.Album.group, ~closed=false, ~showTrackCount=false, ~idx) => {
  let (collapsed, toggleCollapsed, setCollapsed) = Hook.useToggle(~init=closed)

  let id = `group-${idx->Int.toString}-${group.id->Float.toString}`
  let _ = Hook.useFetch({
    fn: () => Invoke.getAlbumCoverArt({album: group.name, isSmall: true}),
    onSuccess: Shape.Bytes.setCover(_, id),
  })

  React.useEffect(() => {
    setCollapsed(_ => closed)
    None
  }, [closed])

  <div id={`group-${idx->Int.toString}`} className="animate-slide-up flex flex-col r-gap px-1">
    <div
      onClick={_ => toggleCollapsed()}
      className="flex gap-4 r-gap cursor-pointer hover:bg-primary/10 rounded-box"
    >
      <div
        className="size-12 2xl:size-14 aspect-square bg-primary/40 rounded-box flex shrink-0 overflow-hidden relative isolate group nb-outline"
      >
        <img alt="" id className="object-cover h-full z-10" />
        <div className="center p-4 absolute inset-0 animate-fade">
          <p className="r-text-2xl text-center text-base-content font-serif">
            {Constant.logo->React.string}
          </p>
        </div>
      </div>
      <div className="flex flex-col w-full min-w-0">
        <p className="r-text-lg pl-1 -mt-1 font-medium truncate"> {group.name->React.string} </p>
        <p className="r-text pl-1 -mt-1 text-80"> {group.artists->React.string} </p>
      </div>
      <div className="h-full ml-auto flex flex-col items-end">
        {collapsed
          ? <Icon.caretDown className="r-icon" weight=Bold />
          : <Icon.caretUp className="r-icon" weight=Bold />}
        {showTrackCount
          ? <div className="r-text-sm whitespace-nowrap">
              {group.tracks->Array.length->Util.toAmountLabel("Track")->React.string}
            </div>
          : React.null}
      </div>
    </div>
    {!collapsed
      ? group.tracks
        ->Array.mapWithIndex((track, idx) => <TrackItem track idx key=track.uri />)
        ->React.array
      : React.null}
  </div>
}
