module Item = {
  @react.component
  let make = (~title, ~count, ~hideBorder=false) => {
    let label = count == 1 ? title : title ++ "s"
    let border = hideBorder ? "pl-1" : "border-l-2 border-accent-content"
    <div className={`flex flex-col px-8 ${border} justify-around`}>
      <div className="r-text-xl font-bold"> {count->Int.toString->React.string} </div>
      <div className="r-text-sm uppercase font-medium text-80 -mt-1"> {label->React.string} </div>
    </div>
  }
}

@react.component
let make = () => {
  let data = Hook.useFetch({fn: Invoke.getStats})

  switch data {
  | Loading => React.null
  | Failed => React.null
  | Success(stats) =>
    <div className="flex flex-row items-center ">
      // <Icon.vinylRecord className="size-14" />
      <Item title="Track" count=stats.tracks hideBorder=true />
      <Item title="Album" count=stats.albums />
      <Item title="Artist" count=stats.artists />
      <Item title="Playlist" count=0 />
    </div>
  }
}
