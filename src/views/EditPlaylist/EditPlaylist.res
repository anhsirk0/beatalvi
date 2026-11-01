module Main = {
  @react.component
  let make = (~data: Shape.Playlist.t) => {
    let all = Hook.useFetch({fn: Invoke.getAllPlaylists})
    let playlists = switch all {
    | Loading | Failed => []
    | Success(playlists) => playlists
    }

    let info: Shape.Playlist.playlist = switch data {
    | Regular({playlist}) => playlist
    | Smart(data) => {id: data.id, name: data.name, isSmart: true}
    }
    let (isOpen, setIsOpen) = React.useState(_ => false)
    let onClick = _ => setIsOpen(_ => true)

    <div className="size-full p-4 2xl:p-8 gap-4 grid grid-cols-14 min-h-0 overflow-y-auto">
      <div id="tools" className="col-span-14 xl:col-span-4 flex flex-col gap-4 h-fit xl:h-full">
        {isOpen
          ? <DeletePlaylistModal id=info.id name=info.name onClose={() => setIsOpen(_ => false)} />
          : React.null}
        <div className="w-full join mb-4">
          <div className="join-item font-medium grow px-4 py-3 text-xl nb-outline border-r-0">
            {info.name->React.string}
          </div>
          <button
            onClick
            className="join-item btn xl:btn-lg 2xl:btn-xl btn-square btn-error nb-ghost rounded-l-none"
          >
            <Icon.trash className="r-icon-lg" weight=Fill />
          </button>
        </div>
      </div>
      {switch data {
      | Regular(data) => <NewPlaylistRegular data playlists />
      | Smart(data) => <NewPlaylistSmart data playlists />
      }}
    </div>
  }
}

@react.component
let make = (~id) => {
  let playlist = Hook.useFetch({fn: () => Invoke.findPlaylistById({id: id})})

  switch playlist {
  | Loading | Failed => React.null
  | Success(Value(data)) => <Main data={data->Shape.Playlist.fromData} />
  | Success(_) => React.null
  }
}
