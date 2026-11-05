module Rule = Shape.Rule
module SP = Shape.SmartPlaylist

module SelectColumn = {
  @react.component
  let make = (~value, ~onChange) => {
    let onChange = evt => evt->Domapi.targetValue->Rule.columnFromString->onChange
    let makeOption = col => {
      let value = col->Rule.columnToString
      <option value> {value->React.string} </option>
    }

    <select
      onChange value={value->Rule.columnToString} className="select select-xl nb-outline w-full"
    >
      {makeOption(Text(Track))}
      {makeOption(Text(Album))}
      {makeOption(Text(Artist))}
      {makeOption(Numeric(Popularity))}
      {makeOption(Numeric(Year))}
    </select>
  }
}

module SelectOperation = {
  @react.component
  let make = (~value, ~onChange, ~column: Rule.column) => {
    let onChange = evt => evt->Domapi.targetValue->Rule.operationFromString(column)->onChange
    let makeOption = op => {
      let value = op->Rule.operationToString
      <option key=value value> {value->React.string} </option>
    }

    <select
      onChange value={value->Rule.operationToString} className="select select-xl nb-outline w-full"
    >
      {switch column {
      | Text(_) => Rule.textOps->Array.map(o => makeOption(Text(o)))
      | Numeric(_) => Rule.numericOps->Array.map(o => makeOption(Numeric(o)))
      }->React.array}
    </select>
  }
}

@react.component
let make = (~rule: Rule.t, ~dispatch: SP.dispatch, ~index, ~match: SP.match) => {
  let label = index == 1 ? "WHERE" : match == All ? "AND" : "OR"
  let value = switch rule {
  | Text({value}) => value
  | Numeric({value}) => value->Int.toString
  }

  let onChange = evt => {
    evt->ReactEvent.Form.stopPropagation
    let val = evt->Domapi.targetValue
    dispatch(
      UpdateRule(
        index - 1,
        switch rule {
        | Text(data) => Text({...data, value: val})
        | Numeric(data) => Numeric({...data, value: val->Int.fromString->Option.getOr(0)})
        },
      ),
    )
  }

  let onColumnChange = column => dispatch(UpdateRule(index - 1, column->Rule.onColumnChange(rule)))
  let onOperationChange = operation =>
    dispatch(UpdateRule(index - 1, operation->Rule.onOperationChange(rule)))

  <div className="flex flex-row nb-box nb-active animate-slide-up overflow-hidden bg-base-100">
    <div
      className="p-4 center min-w-[6rem] border-r-2 border-accent text-primary bg-primary-content"
    >
      <p className="font-serif text-4xl"> {index->Util.padInt->React.string} </p>
    </div>
    <div className="flex flex-col p-4 gap-4 min-w-0 grow">
      <div className="flex justify-between">
        <p className="r-text uppercase text-60"> {label->React.string} </p>
        <button
          onClick={_ => dispatch(RemoveRule(index - 1))} className="btn r-btn btn-square btn-ghost"
        >
          <Icon.x className="r-icon" />
        </button>
      </div>
      <div className="grid grid-cols-14 gap-4">
        <div className="col-span-14 lg:col-span-7 2xl:col-span-4">
          <SelectColumn value={rule->Rule.getColumn} onChange=onColumnChange />
        </div>
        <div className="col-span-12 lg:col-span-7 2xl:col-span-5">
          <SelectOperation
            value={rule->Rule.getOperation} column={rule->Rule.getColumn} onChange=onOperationChange
          />
        </div>
        <div className="col-span-12 lg:col-span-7 2xl:col-span-5">
          <label
            className="input input-xl bg-base-100 outline-none nb-box active:nb-active has-focus:nb-active w-full mb-4"
          >
            {switch rule {
            | Text(_) => <InputBase value onChange type_="text" className="grow" />
            | Numeric(_) => <InputBase value onChange type_="number" className="grow" />
            }}
          </label>
        </div>
      </div>
    </div>
  </div>
}
