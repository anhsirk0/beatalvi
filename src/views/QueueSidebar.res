@react.component
let make = () => {
  let data = Hook.useFetch({fn: Invoke.getPlayingAlbumGroups})

  <div className="flex flex-col overflow-y-auto w-120 min-h-0 gap-4 2xl:gap-8 grow">
    {switch data {
    | Loading => <div className="loading loading-spinner"></div>
    | Failed => React.null
    | Success(groups) =>
      groups->Array.length > 0
        ? groups
          ->Array.mapWithIndex((group, i) =>
            <Delay key={group.id->Float.toString} timeout={i * 20}>
              <AlbumGroupItem group />
            </Delay>
          )
          ->React.array
        : <p className="font-fraunces r-text-2xl font-light text-center italic mt-[100%]">
            {"The night is quiet."->React.string}
            <br />
            {"Play something"->React.string}
          </p>
    }}
  </div>
}
