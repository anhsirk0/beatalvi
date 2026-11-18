module Content = {
  @react.component
  let make = (~query, ~onNavigate) => {
    let data = Hook.useFetch({
      fn: () => Invoke.searchTracksGrouped({query: query}),
    })

    <div className="flex flex-col gap-4 2xl:gap-8 overflow-y-auto min-h-0 max-h-[60vh] grow">
      {switch data {
      | Loading => <div className="loading loading-spinner"></div>
      | Failed => React.null
      | Success(groups) =>
        groups->Array.length > 0
          ? groups
            ->Array.mapWithIndex((group, i) =>
              <Delay key={group.id->Float.toString} timeout={i * 10}>
                <AlbumGroupItem onNavigate group idx=i />
              </Delay>
            )
            ->React.array
          : <div className="center grow">
              <p className="font-fraunces font-light r-text-3xl italic">
                {"Not every word finds its tune."->React.string}
              </p>
            </div>
      }}
    </div>
  }
}

@react.component
let make = (~onClose) => {
  let (value, setValue) = React.useState(_ => "")

  let onChange = evt => {
    evt->ReactEvent.Form.stopPropagation
    setValue(_ => evt->Domapi.targetValue)
  }

  let query = Hook.useDebounce(value, 500)

  <Modal onClose classes="min-w-[50vw] min-h-[60vh] transitional">
    <button onClick={_ => onClose()} id="close-btn" className="hidden"></button>
    <label
      className="input input-xl bg-base-200 outline-none nb-box active:nb-active has-focus:nb-active w-full mb-4"
    >
      <Icon.magnifyingGlass className="r-icon" />
      <InputBase id="search-input" value onChange type_="text" className="grow" />
    </label>
    {query->String.length > 2
      ? <Content onNavigate=onClose query key=query />
      : <div className="center grow">
          <p className="r-text-xl text-80">
            {"Search for songs, albums and artists"->React.string}
          </p>
        </div>}
  </Modal>
}
