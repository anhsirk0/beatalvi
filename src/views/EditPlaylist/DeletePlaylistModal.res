@react.component
let make = (~id, ~name, ~onClose) => {
  let onDelete = _ => {
    Invoke.deletePlaylistById({id: id})
    ->Promise.catch(async _e => -1.)
    ->Promise.then(async id => {
      id > 0. ? Toast.success("Playlist deleted.") : Toast.error("Failed to delete playlist.")
    })
    ->ignore
    onClose()
    RescriptReactRouter.replace(Route.toPath(Playlists))
  }

  <Modal
    title={<p className="r-text-2xl font-semibold"> {"Confirm deletion"->React.string} </p>}
    onClose
    classes="min-w-[30vw]"
  >
    <div className="divider divider-accent -mt-1"></div>
    <p className="r-text-xl">
      {`Are you sure you want to delete '${name}' playlist?`->React.string}
    </p>
    <div className="modal-action">
      <button onClick=onDelete className="btn r-btn-lg btn-error">
        {"Yes, delete"->React.string}
      </button>
      <button onClick={_ => onClose()} className="btn r-btn-lg">
        {"No, cancel"->React.string}
      </button>
    </div>
  </Modal>
}
