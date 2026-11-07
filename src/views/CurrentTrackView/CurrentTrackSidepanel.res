module TrackList = {
  @react.component
  let make = (~tracks: array<Shape.Track.t>, ~scrollToIdx=?) => {
    let containerRef = React.useRef(Nullable.null)
    let scrollerRef = Lenis.useScroller()

    let onTrackPlay = idx =>
      Invoke.playManyFromIndex({uris: tracks->Array.map(t => t.uri), index: idx})->ignore

    React.useEffect0(() => {
      let id = setTimeout(() => {
        switch containerRef.current->Nullable.toOption {
        | Some(flex) =>
          switch scrollToIdx {
          | Some(idx) => flex->Virtuoso.scrollToIndex({index: idx})
          | None => ignore()
          }
        | None => ignore()
        }
      }, 400)
      Some(() => clearTimeout(id))
    })

    <Virtuoso
      ref=containerRef
      className="flex flex-col min-h-0 gap-4 2xl:gap-8 grow min-w-0 [&>div]:px-2"
      style={{display: "flex", flexDirection: "column", height: "100%", flexGrow: "1"}}
      data=tracks
      itemContent={(idx, track) =>
        <TrackItem track idx key=track.uri onClick={_ => onTrackPlay(idx)} cls="mt-1 mb-3 px-2" />}
      scrollerRef
    />
  }
}

module Playing = {
  @react.component
  let make = (~track: Shape.Track.t) => {
    let tracks = Hook.useFetch({fn: Invoke.getPlayingTracks})

    switch tracks {
    | Loading | Failed => React.null
    | Success(tracks) =>
      <TrackList tracks scrollToIdx=?{tracks->Array.findIndexOpt(t => t.uri == track.uri)} />
    }
  }
}

module Related = {
  @react.component
  let make = (~track: Shape.Track.t) => {
    let tracks = Hook.useFetch({
      fn: () =>
        Invoke.getRelatedTracks({
          trackId: track.id,
          trackUri: track.uri,
          artistNames: track.artist->String.split(",")->Array.map(String.trim),
        }),
    })

    switch tracks {
    | Loading | Failed => React.null
    | Success(tracks) => <TrackList tracks />
    }
  }
}

type view = | @as("Up next") UpNext | Related

@react.component
let make = (~track) => {
  let (view, setView) = React.useState(_ => UpNext)

  let makeTab = tab => {
    let cls =
      tab == view
        ? "border-b-base-content border-b-3 font-medium"
        : "text-40 border-b-base-content/40"

    <div
      onClick={_ => setView(_ => tab)}
      role="tab"
      className={`px-4 py-2 text-center r-text cursor-pointer ${cls} border-b-2`}
    >
      {tab->String.make->React.string}
    </div>
  }

  <React.Fragment>
    <div role="tablist" className="flex flex-row">
      {makeTab(UpNext)}
      {makeTab(Related)}
      <div className="grow border-b-base-content/40 border-b-2"></div>
    </div>
    {switch view {
    | UpNext => <Playing track />
    | Related => <Related track />
    }}
  </React.Fragment>
}
