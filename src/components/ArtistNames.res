@react.component
let make = (~artists, ~onNavigate=ignore, ~className) => {
  let (collected, setCollected) = React.useState(_ => [])
  let _ = Hook.useFetch({
    fn: () =>
      Invoke.getArtistIdsByNames({
        names: artists
        ->String.split(",")
        ->Array.map(String.trim)
        ->Array.toSorted((a, b) => a->String.localeCompare(b)),
      }),
    onSuccess: ids => {
      let data = []
      ids->Dict.forEachWithKey((id, name) => data->Array.push((id, name)))
      setCollected(_ => data)
    },
  })

  <p className>
    {collected
    ->Array.mapWithIndex(((id, name), idx) => {
      <React.Fragment>
        <Route.Link
          to=Artist(id, name) onClick={_ => onNavigate()} className="inline hover:underline"
        >
          {name->React.string}
        </Route.Link>
        {idx != collected->Array.length - 1 ? <span> {", "->React.string} </span> : React.null}
      </React.Fragment>
    })
    ->React.array}
  </p>
}
