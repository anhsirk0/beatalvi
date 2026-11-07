module LoveBtn = {
  @react.component
  let make = (~albumId) => {
    let (isLoved, setIsLoved) = React.useState(_ => false)

    let loved = Hook.useFetch({
      fn: () => Invoke.isAlbumLoved({albumId: albumId}),
      onSuccess: l => setIsLoved(_ => l),
    })
    let onClick = _ => Invoke.setAlbumLovedById({albumId, loved: !isLoved})->ignore

    Event.useListen(Event.listenAlbumLoved, ((id, l)) => {
      if id == albumId {
        setIsLoved(_ => l)
      }
    })

    switch loved {
    | Loading | Failed => React.null
    | Success(_) =>
      <div
        role="button"
        tabIndex=0
        className="cursor-pointer active:scale-110 transitional outline-none mb-1"
        onClick
      >
        {isLoved
          ? <Icon.heart
              weight=Fill className="size-10 stroke-primary-content stroke-4 text-error"
            />
          : <Icon.heart className="size-10" />}
      </div>
    }
  }
}

module Content = {
  @react.component
  let make = (~album: Shape.Album.t, ~onPlay) => {
    let id = `album-${album.id->Float.toString}`
    let hasManyArtists = album.artist->String.includes(", ")
    let _ = Hook.useFetch({
      fn: () => Invoke.getAlbumCoverArt({album: album.name, size: Shape.CoverSize.Medium}),
      onSuccess: Shape.Bytes.setCover(_, id),
    })
    let tracks = Hook.useFetch({fn: () => Invoke.getTracksByAlbums({albumIds: [album.id]})})

    let (trackCount, trackDuration) = switch tracks {
    | Success(tracks) => (tracks->Array.length, tracks->Shape.Track.totalDuration)
    | _ => (0, 0)
    }

    let onTrackPlay = index => onPlay(album.id, ~index)
    let onPlayClick = _ => onPlay(album.id, ~index=0)

    <div className="flex flex-col p-8 size-full gap-4 overflow-y-auto min-h-0 relative">
      <button
        id="close-btn"
        onClick={_ => Route.goBack()}
        className="btn bg-base-100 btn-ghost r-btn nb-box active:nb-box absolute top-4 right-4 2xl:top-8 2xl:right-8"
      >
        <Icon.arrowLeft className="r-icon" weight=Bold />
        {"Go back"->React.string}
      </button>
      <div className="flex gap-4 2xl:gap-8">
        <div
          className="size-40 2xl:size-48 aspect-square bg-primary/40 rounded-box flex shrink-0 overflow-hidden relative isolate group nb nb-active"
        >
          <img alt="" id className="object-cover h-full z-10" />
          <div className="center p-4 absolute inset-0 animate-fade">
            <p className="text-6xl 2xl:text-8xl text-center text-base-content font-serif">
              {Constant.logo->React.string}
            </p>
          </div>
        </div>
        <div className="flex flex-col">
          <p className="r-text-3xl pl-1 font-semibold truncate"> {album.name->React.string} </p>
          <p className="r-text-lg pl-1 text-80 truncate"> {album.artist->React.string} </p>
          {switch tracks {
          | Loading | Failed => React.null
          | Success(_) =>
            <p className="r-text pl-1 text-60">
              {`${trackCount->Int.toString} song${trackCount == 1 ? "" : "s"}`->React.string}
              <span className="px-4"> {Constant.sep->React.string} </span>
              {trackDuration->Util.durationToTimeString->React.string}
              <span className="px-4"> {Constant.sep->React.string} </span>
              {album.year->Int.toString->React.string}
            </p>
          }}
          <div className="flex r-gap items-center mt-auto">
            <button id="play-all" onClick=onPlayClick className="btn 3xl:btn-xl btn-primary w-40">
              <Icon.play className="r-icon-lg pr-2" weight=Fill />
              <span className="font-medium"> {" Play"->React.string} </span>
            </button>
            <LoveBtn albumId=album.id />
          </div>
        </div>
      </div>
      {switch tracks {
      | Loading | Failed => React.null
      | Success(tracks) =>
        <React.Fragment>
          // <p className="r-text text-80 border-b-2 border-accent"> {"Songs"->React.string} </p>
          <div className="grid grid-cols-2 gap-4 w-full px-1 pt-2">
            {tracks
            ->Array.mapWithIndex((track, idx) =>
              <AlbumTrackItem
                idx track key=track.uri onPlay={() => onTrackPlay(idx)} showArtist=hasManyArtists
              />
            )
            ->React.array}
          </div>
        </React.Fragment>
      }}
    </div>
  }
}

@react.component
let make = (~id, ~searchParams) => {
  let album = Hook.useFetch({fn: () => Invoke.findAlbumById({id: id})})

  let onPlay = (id, ~index) => {
    let params = Domapi.URLSearchParams.make(searchParams)
    let albumIds =
      params
      ->Domapi.URLSearchParams.get("ids")
      ->Option.map(ids => ids->String.split(",")->Array.filterMap(Float.fromString))
      ->Option.getOr([id])

    Invoke.playTracksByAlbumsFromAlbumId({
      albumIds,
      albumId: id,
      shuffle: false,
      index,
    })->ignore
  }

  switch album {
  | Loading | Failed => React.null
  | Success(Value(album)) => <Content album onPlay />
  | Success(_) => React.null
  }
}
