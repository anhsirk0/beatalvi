module ArtistItem = {
  @react.component
  let make = (~artist: Shape.Artist.t) => {
    let id = `artist-${artist.id->Float.toString}`

    let _ = Hook.useFetch({
      fn: () => Invoke.getArtistCoverArt({artistId: artist.id}),
      onSuccess: bytes => {
        if bytes->Array.length > 0 {
          bytes->Shape.Bytes.toImageUrl->Util.Dom.setImageSrc(id)
        }
      },
    })

    <div role="button" className="flex flex-col gap-2 animate-fade cursor-pointer">
      <div
        className="aspect-square bg-primary/40 rounded-full flex shrink-0 overflow-hidden relative isolate group nb active:nb-plain"
      >
        <img id className="object-cover h-full z-10" />
        <div className="center p-4 absolute inset-0">
          <Icon.userCircle className="size-24" weight=Thin />
          // <p className="text-9xl text-center text-base-content font-serif"> {"?"->React.string} </p>
        </div>
      </div>

      <p className="r-text text-center"> {artist.name->React.string} </p>
    </div>
  }
}

@react.component
let make = () => {
  let artists = Hook.useFetch({fn: Invoke.getAllArtists})

  switch artists {
  | Loading | Failed => React.null
  | Success(artists) =>
    <div
      className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 xl:grid-cols-6 2xl:grid-cols-7 gap-8 w-full p-8 overflow-y-auto min-h-0"
    >
      {artists
      ->Array.mapWithIndex((artist, i) =>
        <Delay key={artist.id->Float.toString} timeout={i * 20}>
          <ArtistItem artist />
        </Delay>
      )
      ->React.array}
    </div>
  }
}
