@react.component
let make = () => {
  let albums = Hook.useFetch({fn: Invoke.getTop50Albums})

  switch albums {
  | Loading => React.null
  | Failed => React.null
  | Success(albums) => <AllAlbumsGrid albums />
  }
}
