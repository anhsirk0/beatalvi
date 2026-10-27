@react.component
let make = (~kind: Shape.Playlist.kind) => {
  <div className="size-full p-4 2xl:p-8 gap-4 grid grid-cols-14 min-h-0 overflow-y-auto">
    <div id="tools" className="col-span-14 xl:col-span-4 flex flex-col gap-4 h-fit xl:h-full">
      <NewPlaylistTabs kind />
    </div>
    {switch kind {
    | Regular => <NewPlaylistRegular />
    | Smart => <NewPlaylistSmart />
    }}
  </div>
}
