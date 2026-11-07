module Item = {
  @react.component
  let make = (~group: Shape.Album.group, ~idx) => {
    let currentTrack = Store.Player.useShallow(s => s.data.track)

    let hasTrack = switch currentTrack {
    | Some(track) => group.tracks->Array.some(t => t.uri == track.uri)
    | None => false
    }

    React.useEffect(() => {
      if hasTrack {
        setTimeout(() => {
          `#group-${idx->Int.toString}`->Domapi.querySelectAndThen(
            Domapi.Scroll.intoView(_, {behavior: Smooth, block: Center}),
          )
        }, 800)->ignore
      }
      None
    }, [hasTrack])

    <AlbumGroupItem group closed={!hasTrack} showTrackCount=true idx cls="mb-4" />
  }
}

// module UpNext = {
//   @react.component
//   let make = () => {
//     let tracks = switch tracks {
//     | Loading | Failed => React.null
//     | Success(tracks) =>
//       tracks->Array.length > 0
//         ? <React.Fragment>
//             <p className="text-60 r-text uppercase"> {"Up next"->React.string} </p>
//             <div className="flex flex-col overflow-y-auto w-120 min-h-0 gap-4 2xl:gap-8 grow">
//               {tracks
//               ->Array.mapWithIndex((track, idx) =>
//                 <TrackItem track idx onClick={_ => ignore()} key=track.uri />
//               )
//               ->React.array}
//             </div>
//           </React.Fragment>
//         : React.null
//     }
//   }
// }

@react.component
let make = () => {
  let playings = Hook.useFetch({fn: Invoke.getPlayingAlbumGroups})
  let scrollerRef = Lenis.useScroller()

  <React.Fragment>
    // <UpNext />
    <p className="text-60 r-text uppercase"> {"Playing Albums"->React.string} </p>
    {switch playings {
    | Loading => <div className="loading loading-spinner"></div>
    | Failed => React.null
    | Success(groups) =>
      groups->Array.length > 0
        ? <Virtuoso
            className="flex flex-col min-h-0 gap-4 2xl:gap-8 grow"
            style={{display: "flex", flexDirection: "column", height: "100%", flexGrow: "1"}}
            data=groups
            itemContent={(idx, group) => <Item group idx key={idx->Int.toString} />}
            scrollerRef
          />
        : <p className="font-fraunces font-light r-text-2xl text-center italic mt-[100%]">
            {"The night is quiet."->React.string}
            <br />
            {"Play something"->React.string}
          </p>
    }}
  </React.Fragment>
}
