module AlbumItem = {
  @react.component
  let make = (~album: Shape.Album.item) => {
    let id = `album-${album.id->Float.toString}`
    let _ = Hook.useFetch({
      fn: () => Invoke.getAlbumCoverArt({album: album.name}),
      onSuccess: bytes => {
        if bytes->Array.length > 0 {
          bytes->Shape.Bytes.toImageUrl->Util.Dom.setImageSrc(id)
        }
      },
    })

    let onClick = _ => {
      Invoke.playTracksByAlbums({albumIds: [album.id]})->ignore
    }

    <div onClick className="flex flex-col animate-slide-left cursor-pointer">
      <div
        className="size-40 lg:size-48 2xl:size-48 bg-base-content/30 rounded-box flex shrink-0 overflow-hidden nb relative isolate"
      >
        <img id className="object-cover h-full z-10" />
        <div className="center p-4 absolute inset-0">
          <p className="text-9xl text-center text-base-content font-serif"> {"?"->React.string} </p>
        </div>
      </div>
      <p className="r-text pl-1 pt-2 font-medium truncate w-48"> {album.name->React.string} </p>
      <p className="r-text-sm pl-1 text-80 truncate"> {album.artist->React.string} </p>
    </div>
  }
}

@react.component
let make = () => {
  let albums = Hook.useFetch({fn: Invoke.getTop10Albums})
  let onPlayAll = _ => {
    switch albums {
    | Success(albums) => Invoke.playTracksByAlbums({albumIds: albums->Array.map(a => a.id)})->ignore
    | _ => ignore()
    }
  }

  switch albums {
  | Loading | Failed => React.null
  | Success(albums) =>
    <div className="flex flex-col w-full min-w-0">
      <div className="flex justify-between">
        <p className="r-text-2xl font-serif"> {"Top Albums"->React.string} </p>
        <button onClick=onPlayAll className="btn btn-ghost bg-base-100 nb-box active:nb-box">
          {"Play all"->React.string}
        </button>
      </div>
      <div className="flex flex-row overflow-x-auto gap-4 w-full pt-4 px-1">
        {albums
        ->Array.map(album => <AlbumItem album key={album.id->Float.toString} />)
        ->React.array}
      </div>
    </div>
  }
}
