module Item = {
  @react.component
  let make = (~group: Shape.Album.group, ~idx) => {
    let currentTrack = Store.Player.useShallow(s => s.data.track)

    let hasTrack = switch currentTrack {
    | Some(track) => group.tracks->Array.some(t => t.uri == track.uri)
    | None => false
    }

    <Delay timeout={idx * 20}>
      <AlbumGroupItem group closed={!hasTrack} showTrackCount=true />
    </Delay>
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

  <React.Fragment>
    // <UpNext />
    <p className="text-60 r-text uppercase"> {"Playing Albums"->React.string} </p>
    <div className="flex flex-col overflow-y-auto min-h-0 gap-4 2xl:gap-8 grow">
      {switch playings {
      | Loading => <div className="loading loading-spinner"></div>
      | Failed => React.null
      | Success(groups) =>
        groups->Array.length > 0
          ? groups
            ->Array.mapWithIndex((group, idx) => <Item group idx key={idx->Int.toString} />)
            ->React.array
          : <p className="font-fraunces r-text-2xl font-light text-center italic mt-[100%]">
              {"The night is quiet."->React.string}
              <br />
              {"Play something"->React.string}
            </p>
      }}
    </div>
  </React.Fragment>
}
