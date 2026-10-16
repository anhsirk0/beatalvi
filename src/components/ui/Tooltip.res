@react.component
let make = (~title: string, ~className="", ~children) => {
  let component = <div className={`tooltip ${className}`}> {children} </div>
  React.cloneElement(component, {"data-tip": title})
}
