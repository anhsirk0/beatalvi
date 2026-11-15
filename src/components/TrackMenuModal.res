@react.component
let make = (~track: Shape.Track.t, ~onClose) => {
  <Modal
    title={<p className="r-text-2xl font-semibold"> {track.name->React.string} </p>}
    onClose
    classes="min-w-[40vw]"
  >
    <div className="divider divider-accent -mt-1"></div>
    <div className="center">
      <div className="text-7xl"> {"TrackMenu"->React.string} </div>
    </div>
  </Modal>
}
