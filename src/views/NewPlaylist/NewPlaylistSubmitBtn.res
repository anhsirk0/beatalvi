@react.component
let make = (~onSubmit, ~name: option<string>=?) => {
  let (value, setValue) = React.useState(_ => name->Option.getOr(""))

  let onChange = evt => {
    evt->ReactEvent.Form.stopPropagation
    setValue(_ => evt->Util.Dom.targetValue)
  }

  <div className="flex flex-col gap-4 mt-auto">
    <p className="r-text-sm uppercase text-80 -mb-1"> {"Playlist name"->React.string} </p>
    <label
      className="input input-xl bg-base-100 outline-none nb-box active:nb-active has-focus:nb-active w-full mb-4"
    >
      <InputBase value onChange type_="text" className="grow" placeholder=" Playlist" />
    </label>
    <button onClick={_ => onSubmit(value)} className="btn xl:btn-lg 3xl:btn-xl btn-primary">
      {(name->Option.isNone ? "Create playlist" : "Save playlist")->React.string}
    </button>
    <button id="close-btn" onClick={_ => Route.goBack()} className="btn xl:btn-lg 3xl:btn-xl">
      {"Cancel"->React.string}
    </button>
  </div>
}
