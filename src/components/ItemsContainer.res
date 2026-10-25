@react.component
let make = (~title, ~subtitle, ~classes, ~children) => {
  <div className={`h-full flex flex-col nb-box nb-outline ${classes}`}>
    <div className="flex flex-row gap-4 p-4 border-b-2 border-b-accent">
      <p className="font-medium uppercase"> {title->React.string} </p>
      <div className="grow"></div>
      <p className="text-80"> {subtitle->React.string} </p>
    </div>
    {children}
  </div>
}
