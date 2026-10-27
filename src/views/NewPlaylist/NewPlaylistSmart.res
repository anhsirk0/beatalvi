@react.component
let make = () => {
  let onSubmit = name => Console.log(name)

  <React.Fragment>
    <Portal id="tools">
      <div className="grow"></div>
      <NewPlaylistSubmitBtn onSubmit />
    </Portal>
    <ItemsContainer
      title="Rules" subtitle="3 rules - match all" classes="col-span-14 lg:col-span-10 min-h-[65vh]"
    >
      <div className="center p-4 grow h-full">
        <p className="text-center text-5xl"> {"Todo: impl rules"->React.string} </p>
      </div>
    </ItemsContainer>
  </React.Fragment>
}
