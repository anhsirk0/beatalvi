module Rule = Shape.Rule
module SP = Shape.SmartPlaylist

module SelectOrder = {
  @react.component
  let make = (~value, ~onChange) => {
    let onChange = evt => evt->Domapi.targetValue->SP.orderFromString->onChange

    let makeOption = ord => {
      let value = ord->SP.orderToString
      <option key=value value> {value->React.string} </option>
    }

    <select onChange value={value->SP.orderToString} className="select select-xl nb-outline w-full">
      {SP.orderCols
      ->Array.flatMap(o => [makeOption(Asc(o)), makeOption(Desc(o))])
      ->React.array}
      {makeOption(Random)}
    </select>
  }
}

@react.component
let make = (~data: option<Shape.Playlist.data>=?, ~playlists: array<Shape.Playlist.playlist>) => {
  let (state, dispatch) = SP.useReducer(~json=data->Option.map(d => d.smartJson))

  let onChange = evt => {
    evt->ReactEvent.Form.stopPropagation
    dispatch(SetLimit(evt->Domapi.targetValue->Int.fromString->Option.getOr(0)))
  }

  let onAddNewRule = _ => {
    if state.rules->Array.length == 50 {
      Toast.error("Max 50 rules are allowed for a smart playlist.")
    } else {
      dispatch(NewRule)
    }
  }

  let subtitle =
    state.rules->Array.length->Util.toAmountLabel("rule") ++
    ` ${Constant.sep} match ` ++
    state.match->String.make->String.toLowerCase

  let onSubmit = name => {
    let success = ref(false)
    if name->String.length < 1 {
      Toast.error("Please enter a name to create a playlist.")
    } else if state.rules->Array.length < 1 {
      Toast.error("Please add atleast one rule to manage the playlist.")
    } else if state.limit < 1 {
      Toast.error("Limit can not be empty.")
    } else {
      let sql = state->SP.toSql
      let json = state->JSON.stringifyAny->Option.getOr("")

      switch data {
      | Some(data) =>
        if data.name == name && data.smartSql == sql {
          Toast.info("No changes were made")
          success := true
        } else if playlists->Array.some(p => p.name == name && p.id != data.id) {
          Toast.error("Playlist with same name already exists.")
        } else {
          Invoke.updateSmartPlaylist({id: data.id, name, sql, json})
          ->Promise.catch(async _e => -1.)
          ->Promise.then(async id => {
            id > 0. ? Toast.success("Playlist updated.") : Toast.error("Failed to update playlist.")
          })
          ->ignore
          success := true
        }
      | None =>
        if playlists->Array.some(p => p.name == name) {
          Toast.error("Playlist with same name already exists.")
        } else {
          Invoke.createSmartPlaylist({name, sql, json})
          ->Promise.catch(async _e => -1.)
          ->Promise.then(async id => {
            id > 0. ? Toast.success("Playlist created.") : Toast.error("Failed to create playlist.")
          })
          ->ignore
          success := true
        }
      }
    }
    if success.contents {
      RescriptReactRouter.replace(Route.toPath(Playlists))
    }
  }

  let makeMatchBtn = m => {
    let cls = m == state.match ? "bg-primary text-primary-content" : ""
    let label = switch m {
    | All => "All rules"
    | Any => "Any rule"
    }
    let onClick = _ => dispatch(SetMatch(m))
    <button
      onClick className={`join-item btn xl:btn-lg 2xl:btn-xl btn-ghost flex-1 last:z-10 ${cls}`}
    >
      {label->React.string}
    </button>
  }

  <React.Fragment>
    <Portal id="tools">
      <div className="p-4 flex flex-col gap-4 bg-base-100 nb-outline rounded-box">
        <p className="r-text-sm uppercase text-80 -mb-1"> {"Songs must match"->React.string} </p>
        <div className="w-full join isolate">
          {makeMatchBtn(All)}
          {makeMatchBtn(Any)}
        </div>
      </div>
      <div className="p-4 flex flex-col gap-4 bg-base-100 nb-outline rounded-box">
        <p className="r-text-sm uppercase text-80 -mb-1"> {"Limit"->React.string} </p>
        <div className="flex gap-4 items-center">
          <label
            className="input input-xl bg-base-100 outline-none nb-box active:nb-active has-focus:nb-active w-36"
          >
            <InputBase value={state.limit->Int.toString} onChange type_="number" />
          </label>
          <p className="r-text grow whitespace-nowrap"> {"songs, sort by"->React.string} </p>
        </div>
        <SelectOrder value=state.order onChange={order => dispatch(SetOrder(order))} />
      </div>
      <div className="grow"></div>
      <NewPlaylistSubmitBtn onSubmit name=?{data->Option.map(d => d.name)} />
    </Portal>
    <ItemsContainer title="Rules" subtitle classes="col-span-14 lg:col-span-10 min-h-[65vh]">
      <div className="flex flex-col gap-4 p-4 grow min-h-0 overflow-y-auto">
        {state.rules
        ->Array.mapWithIndex((rule, idx) =>
          <RuleItem key={idx->Int.toString} rule dispatch match=state.match index={idx + 1} />
        )
        ->React.array}
        <div
          role="button"
          onClick=onAddNewRule
          className="center flex-col gap-2 p-4 py-12 w-full rounded-box outline-dashed outline-base-content/60 cursor-pointer"
        >
          <Icon.plus className="size-12 text-60" />
          <p className="r-text text-center text-60 truncate"> {"Add rule"->React.string} </p>
        </div>
      </div>
    </ItemsContainer>
  </React.Fragment>
}
