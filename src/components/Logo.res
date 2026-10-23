@react.component
let make = (~classes="border-b-2 border-accent") => {
  <div className={`center gap-4 ${Constant.headerHeight} ${classes}`}>
    <div className="flex gap-2 items-center">
      <div
        className="center text-xl 2xl:text-3xl size-8 2xl:size-10 rounded-box bg-primary text-primary-content font-baloo font-semibold"
      >
        {Constant.logo->React.string}
      </div>
      <p className="text-2xl 2xl:text-3xl font-fraunces font-bold text-neutral-content">
        {"Beatalvi"->React.string}
      </p>
    </div>
  </div>
}
