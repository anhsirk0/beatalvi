type view = All | One(Shape.Album.t)

module Empty = {
  @react.component
  let make = () => {
    <div
      className="center flex-col gap-8 rounded-box size-full grow outline-dashed outline-2 outline-accent-content"
    >
      <Icon.musicNote className="size-32" />
      <p className="r-text-4xl font-bold text-center"> {"Your library is empty"->React.string} </p>

      <p className="text-80 r-text-lg text-center">
        {"By default Beatalvi scans "->React.string}
        <span className="nb-outline nb-active rounded-box px-2 font-medium">
          {"~/Music"->React.string}
        </span>
        <br />
      </p>
      <div className="p-4 nb-outline rounded-box">
        <p className="text-80 r-text">
          {"Feature for adding user defined directory will be added in future release."->React.string}
        </p>
        <p className="text-80 r-text">
          {"You can link your music folder to "->React.string}
          <span className="nb-outline nb-active rounded-box px-2 font-medium mr-1">
            {"~/Music"->React.string}
          </span>
          {" by running this command."->React.string}
        </p>
        <div className="mockup-code w-full mt-4">
          <pre>
            <code className="r-text-lg">
              {"ln -s /path/to/your/music ~/Music"->React.string}
            </code>
          </pre>
        </div>
      </div>
    </div>
  }
}

@react.component
let make = () => {
  let (view, setView) = React.useState(_ => All)
  let tracks = Hook.useFetch({fn: Invoke.getTop10Tracks})
  let albums = Hook.useFetch({fn: Invoke.getTop10Albums})

  let onPlay = (id, ~index) => {
    switch albums {
    | Success(albums) =>
      Invoke.playTracksByAlbumsFromAlbumId({
        albumIds: albums->Array.map(a => a.id),
        albumId: id,
        index,
      })->ignore
    | _ => ignore()
    }
  }

  switch view {
  | All =>
    <div className="size-full flex flex-col p-4 px-8 2xl:p-8 r-gap min-w-0 overflow-y-auto min-h-0">
      {switch (tracks, albums) {
      | (Success(tracks), Success(albums)) =>
        tracks->Array.length > 0
          ? <React.Fragment>
              <HomeTopTracks tracks />
              <HomeTopAlbums onPlay albums setAlbum={a => setView(_ => One(a))} />
            </React.Fragment>
          : <Empty />
      | _ => React.null
      }}
    </div>
  | One(album) => <AlbumView album onBack={() => setView(_ => All)} onPlay />
  }
}
