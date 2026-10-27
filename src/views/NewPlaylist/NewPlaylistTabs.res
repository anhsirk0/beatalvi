@react.component
let make = (~kind: Shape.Playlist.kind) => {
  let makeTab = tab => {
    let cls = tab == kind ? "btn-primary" : ""
    <Route.Link
      replace=true
      to=NewPlaylist(tab)
      className={`join-item btn xl:btn-lg 2xl:btn-xl flex-1 ${cls} last:z-10`}
    >
      {switch tab {
      | Regular => <Icon.listBullets className="r-icon mr-2" />
      | Smart => <Icon.slidersHorizontal className="r-icon mr-2" />
      }}
      {tab->String.make->React.string}
    </Route.Link>
  }

  <div className="w-full join isolate mb-4 mt-1">
    {Regular->makeTab}
    {Smart->makeTab}
  </div>
}
