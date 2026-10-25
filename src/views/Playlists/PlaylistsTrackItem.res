@react.component
let make = (~track: Shape.Track.t, ~index, ~isSelected, ~onToggle, ~forSelected=false) => {
  let activeContainer = isSelected ? "nb-active" : ""
  let activeIndex = forSelected
    ? "text-primary bg-primary-content"
    : isSelected
    ? "bg-primary text-primary-content"
    : ""
  <div
    role="button"
    onClick={_ => onToggle(track)}
    className={`flex flex-row nb-box cursor-pointer nb ${activeContainer} mb-4 animate-slide-up active:nb-plain overflow-hidden bg-base-100`}
  >
    <div className={`p-4 center min-w-[6rem] border-r-2 border-accent ${activeIndex}`}>
      <p className="font-serif text-4xl"> {index->Util.padInt->React.string} </p>
    </div>
    <div className="flex flex-col p-4 py-2 min-w-0 grow">
      <div className="flex flex-row gap-2 items-center w-full">
        <p className="r-text-xl font-medium truncate"> {track.name->React.string} </p>
      </div>
      <div className={`flex flex-row gap-2 text-80 items-center w-full`}>
        <Icon.userCircle className="size-5" />
        <p className="r-text-sm truncate"> {track.artist->React.string} </p>
        <Icon.vinylRecord className="size-5 ml-2" />
        <p className="r-text-sm truncate"> {track.album->React.string} </p>
      </div>
    </div>
  </div>
}
