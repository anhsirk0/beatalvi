@react.component
let make = () => {
  let albums = Hook.useFetch({fn: Invoke.getLovedAlbums})

  switch albums {
  | Loading => React.null
  | Failed => React.null
  | Success(albums) =>
    albums->Array.length > 0
      ? <AllAlbumsGrid albums />
      : <div className="center r-gap flex-col">
          <p className="font-fraunces font-light r-text-3xl text-center italic mt-[25%]">
            {"Your heart hasn't chosen an album yet."->React.string}
          </p>
          <p className="r-text-lg text-center text-60">
            {"Tap "->React.string}
            <Icon.heart className="r-icon inline mb-1" weight=Fill />
            {" on any album and it will wait for you here."->React.string}
          </p>
        </div>
  }
}
