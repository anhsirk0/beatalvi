@react.component
let make = () => {
  let albums = Hook.useFetch({fn: Invoke.getRecent100Albums})

  switch albums {
  | Loading => React.null
  | Failed => React.null
  | Success(albums) => <AllAlbumsGrid albums />
  }
}
