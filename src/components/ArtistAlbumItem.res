@react.component
let make = (~album: Shape.Album.item, ~onPlay) => {
  let id = `album-${album.id->Float.toString}`
  let _ = Hook.useFetch({
    fn: () => Invoke.getAlbumCoverArt({album: album.name}),
    onSuccess: Shape.Bytes.setCover(_, id),
  })
  let tracks = Hook.useFetch({fn: () => Invoke.getTracksByAlbums({albumIds: [album.id]})})
  let (trackCount, trackDuration, hasManyArtists) = switch tracks {
  | Success(tracks) => (
      tracks->Array.length,
      tracks->Shape.Track.totalDuration,
      tracks->Array.map(t => t.artist)->Util.Arr.uniq->Array.length > 1,
    )
  | _ => (0, 0, false)
  }

  let onTrackPlay = index => onPlay(album.id, ~index)

  <div className={trackCount > 1 ? "col-span-2 animate-slide-up" : "col-span-1 animate-slide-up"}>
    <div className="flex gap-4 2xl:gap-8 pt-4">
      <div
        className="w-20 2xl:w-28 aspect-square bg-primary/40 rounded-box flex shrink-0 overflow-hidden relative isolate group nb-outline"
      >
        <img id className="object-cover h-full z-10" />
        <div className="center p-4 absolute inset-0">
          <p className="text-6xl 2xl:text-8xl text-center text-base-content font-serif">
            {"?"->React.string}
          </p>
        </div>
      </div>
      <div className="flex flex-col 2xl:gap-1">
        <p className="text-2xl 2xl:text-4xl pl-1 font-medium truncate">
          {album.name->React.string}
        </p>
        {trackCount > 0
          ? <p className="text-lg 2xl:text-2xl pl-1 text-80">
              {`${trackCount->Int.toString} track${trackCount == 1 ? "" : "s"}`->React.string}
              <span className="px-4"> {Constant.sep->React.string} </span>
              {trackDuration->Util.durationToTimeString->React.string}
            </p>
          : React.null}
        <p className="text-lg 2xl:text-2xl pl-1 text-80">
          {album.year->Int.toString->React.string}
        </p>
      </div>
    </div>
    {switch tracks {
    | Loading | Failed => React.null
    | Success(tracks) =>
      <div
        className={`grid ${trackCount > 1 ? "grid-cols-2" : "grid-cols-1"} gap-4 w-full px-1 pt-4`}
      >
        {tracks
        ->Array.mapWithIndex((track, idx) =>
          <AlbumTrackItem
            idx track key=track.uri onPlay={() => onTrackPlay(idx)} showArtist=hasManyArtists
          />
        )
        ->React.array}
      </div>
    }}
  </div>
}
