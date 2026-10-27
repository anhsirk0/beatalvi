module Rule = Shape.Rule

module SelectColumn = {
  @react.component
  let make = (~value: Rule.column, ~onChange=?) => {
    let value = switch value {
    | Numeric(col) => col->String.make
    | String(col) => col->String.make
    }
    <select value className="select select-xl nb-outline w-full">
      <option> {Rule.Track->String.make->React.string} </option>
      <option> {Rule.Album->String.make->React.string} </option>
      <option> {Rule.Artist->String.make->React.string} </option>
      <option> {Rule.Popularity->String.make->React.string} </option>
      <option> {Rule.Year->String.make->React.string} </option>
    </select>
  }
}

@react.component
let make = (~rule: Shape.Rule.t, ~dispatch: Shape.SmartPlaylist.dispatch, ~index) => {
  let label = index == 1 ? "WHERE" : "AND"
  //   let onColumnChange = (val: Rule.column) => dispatch(UpdateRule(index - 1,
  // switch val {
  // | Numeric(col) =>
  // }
  // ))

  <div
    role="button"
    className="flex flex-row nb-box cursor-pointer nb-active animate-slide-up overflow-hidden bg-base-100"
  >
    <div
      className="p-4 center min-w-[6rem] border-r-2 border-accent text-primary bg-primary-content"
    >
      <p className="font-serif text-4xl"> {index->Util.padInt->React.string} </p>
    </div>
    <div className="flex flex-col p-4 gap-4 min-w-0 grow">
      <div className="flex justify-between">
        <p className="r-text uppercase text-60"> {label->React.string} </p>
        <button className="btn r-btn btn-square btn-ghost">
          <Icon.x className="r-icon" />
        </button>
      </div>
      <div className="grid grid-cols-14 gap-4">
        <div className="col-span-14 lg:col-span-7 2xl:col-span-4">
          {switch rule {
          | Numeric({column}) => <SelectColumn value=Numeric(column) />
          | String({column}) => <SelectColumn value=String(column) />
          }}
        </div>
        <div className="col-span-12 lg:col-span-7 2xl:col-span-5">
          <select defaultValue="Pick a color" className="select select-xl nb-outline w-full">
            <option disabled=true> {"Pick a color"->React.string} </option>
            <option> {"Crimson"->React.string} </option>
            <option> {"Amber"->React.string} </option>
            <option> {"Velvet"->React.string} </option>
          </select>
        </div>
        <div className="col-span-12 lg:col-span-7 2xl:col-span-5">
          <select defaultValue="Pick a color" className="select select-xl nb-outline w-full">
            <option disabled=true> {"Pick a color"->React.string} </option>
            <option> {"Crimson"->React.string} </option>
            <option> {"Amber"->React.string} </option>
            <option> {"Velvet"->React.string} </option>
          </select>
        </div>
      </div>
    </div>
  </div>
}
