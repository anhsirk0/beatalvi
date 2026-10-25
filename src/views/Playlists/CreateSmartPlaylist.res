@react.component
let make = (~onCancel) => {
  <React.Fragment>
    <ItemsContainer
      title="Rules" classes="col-span-14 xl:col-span-10 min-h-[65vh]" subtitle="3 rules"
    >
      <p className="text-3xl"> {"Rules"->React.string} </p>
    </ItemsContainer>
  </React.Fragment>
}
