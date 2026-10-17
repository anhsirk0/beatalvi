@react.component
let make = (~setAlbum, ~albums: array<Shape.Album.item>, ~onPlay) => {
  let onPlayAll = _ => {
    Invoke.playTracksByAlbums({albumIds: albums->Array.map(a => a.id)})->ignore
  }

  <div className="flex flex-col w-full min-w-0">
    <div className="flex justify-between">
      <p className="r-text-2xl font-serif"> {"Top Albums"->React.string} </p>
      <button onClick=onPlayAll className="btn btn-ghost bg-base-100 nb-box active:nb-box r-btn">
        <Icon.play className="r-icon" />
        {"Play all"->React.string}
      </button>
    </div>
    <div className="flex flex-row overflow-x-auto gap-4 w-full pt-4 px-1">
      {albums
      ->Array.map(album =>
        <PopularAlbums.AlbumItem
          key={album.id->Float.toString} album onClick={_ => setAlbum(album)} onPlay width="w-56"
        />
      )
      ->React.array}
    </div>
  </div>
}
