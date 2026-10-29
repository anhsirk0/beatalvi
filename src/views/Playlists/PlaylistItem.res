@react.component
let make = (~playlist: Shape.Playlist.playlist) => {
  <Route.Link to=Playlist(playlist.id) className="flex flex-col animate-fade cursor-pointer">
    <div
      className="aspect-square bg-primary/40 rounded-box flex shrink-0 overflow-hidden relative isolate group nb active:nb-plain"
    >
      // <img alt="" className="object-cover h-full z-10" />
      <div className="center p-4 absolute inset-0 animate-fade">
        <Icon.playlist className="size-24" weight=Thin />
      </div>
    </div>
    <p className="r-text text-center truncate"> {playlist.name->React.string} </p>
  </Route.Link>
}
