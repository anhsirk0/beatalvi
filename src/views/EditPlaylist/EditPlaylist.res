module Main = {
  @react.component
  let make = (~data: Shape.Playlist.t) => {
    let kind: Shape.Playlist.kind = data.playlist.smartEnabled ? Smart : Regular
    let (isOpen, setIsOpen) = React.useState(_ => false)
    let onClick = _ => setIsOpen(_ => true)

    <div className="size-full p-4 2xl:p-8 gap-4 grid grid-cols-14 min-h-0 overflow-y-auto">
      <div id="tools" className="col-span-14 xl:col-span-4 flex flex-col gap-4 h-fit xl:h-full">
        {isOpen
          ? <DeletePlaylistModal
              id=data.playlist.id name=data.playlist.name onClose={() => setIsOpen(_ => false)}
            />
          : React.null}
        <div className="w-full join mb-4">
          <div className="join-item font-medium grow px-4 py-3 text-xl nb-outline border-r-0">
            {data.playlist.name->React.string}
          </div>
          <button
            onClick
            className="join-item btn xl:btn-lg 2xl:btn-xl btn-square btn-error nb-ghost rounded-l-none"
          >
            <Icon.trash className="r-icon-lg" weight=Fill />
          </button>
        </div>
      </div>
      {switch kind {
      | Regular => <NewPlaylistRegular data />
      | Smart => <div className="text-7xl"> {"Smart"->React.string} </div>
      }}
    </div>
  }
}

@react.component
let make = (~id) => {
  let playlist = Hook.useFetch({fn: () => Invoke.findPlaylistById({id: id})})

  switch playlist {
  | Loading | Failed => React.null
  | Success(Value(data)) => <Main data />
  | Success(_) => React.null
  }
}
