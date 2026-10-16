@react.component
let make = () => {
  <div className="center size-full p-8">
    <div className="flex flex-col md:w-1/2 gap-4">
      <p className="text-5xl font-bold"> {"Scanning Music ..."->React.string} </p>

      <progress className="progress progress-primary border-2 border-accent w-full h-12 nb-shadow">
      </progress>
      <p className="text-xl font-medium text-80">
        {"This may take a while, depending on the size of your library."->React.string}
      </p>
    </div>
  </div>
}
