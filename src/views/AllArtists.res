module ArtistItem = {
  @react.component
  let make = (~artist: Shape.Artist.t) => {
    let id = `artist-${artist.id->Float.toString}`

    let _ = Hook.useFetch({
      fn: () => Invoke.getArtistCoverArt({artistId: artist.id}),
      onSuccess: Shape.Bytes.setCover(_, id),
    })

    <Route.Link
      to=Artist(artist.id, artist.name) className="flex flex-col animate-fade cursor-pointer"
    >
      <div
        className="aspect-square bg-primary/40 rounded-full flex shrink-0 overflow-hidden relative isolate group nb active:nb-plain"
      >
        <img alt="" id className="object-cover h-full z-10" />
        <div className="center p-4 absolute inset-0 animate-fade">
          <Icon.userCircle className="size-24" weight=Thin />
        </div>
      </div>
      <p className="r-text text-center truncate"> {artist.name->React.string} </p>
    </Route.Link>
  }
}

module ArtistsGrid = {
  @react.component
  let make = (~artists: array<Shape.Artist.t>) => {
    <Lenis options=Lenis.options className="[&>div]:main-grid overflow-y-auto min-h-0">
      {artists
      ->Array.mapWithIndex((artist, i) =>
        <Delay key={artist.id->Float.toString} timeout={i * 20}>
          <ArtistItem artist />
        </Delay>
      )
      ->React.array}
    </Lenis>
  }
}

@react.component
let make = () => {
  let artists = Hook.useFetch({fn: Invoke.getAllArtists})

  switch artists {
  | Loading | Failed => React.null
  | Success(artists) => <ArtistsGrid artists />
  }
}
