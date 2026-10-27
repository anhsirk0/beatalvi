@react.component
let make = () => {
  let (state, dispatch) = Shape.SmartPlaylist.useReducer()

  let onSubmit = name => Console.log(name)

  <React.Fragment>
    <Portal id="tools">
      <div className="p-4 flex flex-col gap-4 bg-base-100 nb-outline rounded-box">
        <p className="r-text-sm uppercase text-80 -mb-1"> {"Songs must match"->React.string} </p>
        <div className="w-full join isolate">
          <button className="join-item btn xl:btn-lg 2xl:btn-xl btn-ghost flex-1">
            {"All Rules"->React.string}
          </button>
          <button className="join-item btn xl:btn-lg 2xl:btn-xl btn-ghost flex-1 z-10">
            {"Any Rule"->React.string}
          </button>
        </div>
      </div>
      <div className="grow"></div>
      <NewPlaylistSubmitBtn onSubmit />
    </Portal>
    <ItemsContainer
      title="Rules" subtitle="0 rules - match all" classes="col-span-14 lg:col-span-10 min-h-[65vh]"
    >
      <div className="flex flex-col gap-4 p-4 grow min-h-0 overflow-y-auto">
        {state.rules
        ->Array.mapWithIndex((rule, idx) =>
          <RuleItem key={idx->Int.toString} rule dispatch index={idx + 1} />
        )
        ->React.array}
        <div
          role="button"
          onClick={_ => dispatch(NewRule)}
          className="center flex-col gap-2 p-4 py-12 w-full rounded-box outline-dashed outline-base-content/60 cursor-pointer"
        >
          <Icon.plus className="size-12 text-60" />
          <p className="r-text text-center text-60 truncate"> {"Add rule"->React.string} </p>
        </div>
        // <p className="text-center text-5xl"> {"Todo: impl rules"->React.string} </p>
      </div>
    </ItemsContainer>
  </React.Fragment>
}
