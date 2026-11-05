module Cover = {
  @react.component
  let make = (~id, ~album) => {
    let _ = Hook.useFetch({
      fn: () => Invoke.getAlbumCoverArt({album, size: Large}),
      onSuccess: Shape.Bytes.setCover(_, id),
    })

    <img alt="" id className="object-cover w-full z-10" />
  }
}

module Content = {
  @react.component
  let make = (~track: Shape.Track.t) => {
    let id = `current-track-${track.id->Float.toString}`

    <div
      className="size-full grid grid-cols-12 p-4 px-8 2xl:p-8 r-gap min-w-0 overflow-y-auto min-h-0"
    >
      <div className="col-span-12 xl:col-span-7 center">
        <div
          className="aspect-square bg-primary/40 rounded-box flex shrink-0 overflow-hidden nb-outline relative isolate nb nb-active w-full max-w-[800px]"
        >
          <Cover id album=track.album key=track.album />
          <div className="center size-full p-4 absolute inset-0 animate-fade size-full">
            <p className="text-9xl scale-200 font-bold text-center text-80 font-serif">
              {Constant.logo->React.string}
            </p>
          </div>
        </div>
      </div>
      <div className="col-span-12 xl:col-span-5 flex flex-col r-gap">
        <CurrentTrackSidepanel track />
      </div>
    </div>
  }
}

@react.component
let make = () => {
  let track = Store.Player.useShallow(s => s.data.track)

  React.useEffect(() => {
    if track == None {
      RescriptReactRouter.replace(Route.toPath(Home))
    }
    None
  }, [track])

  track->Util.renderSome(track => <Content track />)
}
