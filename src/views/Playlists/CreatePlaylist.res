@react.component
let make = (~onCancel) => {
  let (view, setView) = React.useState(_ => Shape.Playlist.Regular)
  let (tracks, setTracks) = React.useState(_ => [])
  let _tracksData = Hook.useFetch({
    fn: Invoke.getAllTracksGroupedByAlbum,
    onSuccess: all => setTracks(_ => all),
  })

  let makeTab = tab => {
    let isActive = tab == view
    <button
      onClick={_ => setView(_ => tab)}
      className={`join-item btn xl:btn-lg 2xl:btn-xl flex-1 ${isActive ? "btn-primary" : ""}`}
    >
      {switch tab {
      | Regular => <Icon.listBullets className="r-icon mr-2" />
      | Smart => <Icon.slidersHorizontal className="r-icon mr-2" />
      }}

      {tab->String.make->React.string}
    </button>
  }

  <div className="size-full p-4 2xl:p-8 gap-4 grid grid-cols-14 min-h-0 overflow-y-auto">
    <div id="tools" className="col-span-14 xl:col-span-4 flex flex-col gap-4 h-fit xl:h-full">
      <div className="w-full join isolate mb-4 mt-1 last:z-10">
        {Regular->makeTab}
        {Smart->makeTab}
      </div>
    </div>
    {switch view {
    | Regular => <CreateRegularPlaylist tracks onCancel />
    | Smart => <CreateSmartPlaylist onCancel />
    }}
  </div>
}
