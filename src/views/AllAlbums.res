@react.component
let make = () => {
  let albums = Hook.useFetch({fn: Invoke.getAllAlbums})

  switch albums {
  | Loading => React.null
  | Failed => React.null
  | Success(albums) => <AllAlbumsGrid albums />
  }
}
