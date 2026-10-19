type view = All | One(Shape.Artist.t)

module ArtistItem = {
  @react.component
  let make = (~artist: Shape.Artist.t, ~onClick) => {
    let id = `artist-${artist.id->Float.toString}`

    let _ = Hook.useFetch({
      fn: () => Invoke.getArtistCoverArt({artistId: artist.id}),
      onSuccess: Shape.Bytes.setCover(_, id),
    })

    <div
      role="button" onClick={_ => onClick()} className="flex flex-col animate-fade cursor-pointer"
    >
      <div
        className="aspect-square bg-primary/40 rounded-full flex shrink-0 overflow-hidden relative isolate group nb active:nb-plain"
      >
        <img id className="object-cover h-full z-10" />
        <div className="center p-4 absolute inset-0">
          <Icon.userCircle className="size-24" weight=Thin />
        </div>
      </div>
      <p className="r-text text-center"> {artist.name->React.string} </p>
    </div>
  }
}

module ArtistsGrid = {
  @react.component
  let make = (~artists: array<Shape.Artist.t>) => {
    let (view, setView) = React.useState(_ => All)

    switch view {
    | One(artist) => <ArtistView artist onBack={() => setView(_ => All)} />
    | All =>
      <div
        className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 xl:grid-cols-6 2xl:grid-cols-7 gap-8 w-full p-8 overflow-y-auto min-h-0"
      >
        {artists
        ->Array.mapWithIndex((artist, i) =>
          <Delay key={artist.id->Float.toString} timeout={i * 20}>
            <ArtistItem artist onClick={() => setView(_ => One(artist))} />
          </Delay>
        )
        ->React.array}
      </div>
    }
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
