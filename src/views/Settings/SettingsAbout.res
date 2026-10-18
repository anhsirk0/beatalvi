module Item = {
  @react.component
  let make = (~title, ~info) => {
    <div className="flex py-1 2xl:py-4 items-center border-b border-accent">
      <p className="r-text-lg text-80 grow"> {title->React.string} </p>
      <p className="r-text-lg font-medium"> {info->React.string} </p>
    </div>
  }
}

@react.component
let make = () => {
  <div className="flex flex-col 2xl:gap-8 max-w-[80%] lg:max-w-[60%] 2xl:max-w-[50%] self-center">
    <div className="center flex-col width-fit">
      <p className="text-4xl xl:text-5xl 2xl:text-6xl font-fraunces font-bold">
        {"Beatalvi"->React.string}
      </p>
      <div className="divider divider-accent 2xl:text-3xl font-bold">
        {"ਬੀਟਾਲਵੀ"->React.string}
      </div>
      <div className="r-text-lg text-60 text-center">
        {"A music player for the files you own."->React.string}
      </div>
    </div>

    <div className="flex-col w-full">
      <Item title="Version" info="0.0.0" />
      <Item title="Made By" info="Anhsirk0" />
    </div>

    <div className="nb-box nb-active bg-base-100 p-4 flex flex-col r-gap">
      <p className="text-80 r-text"> {"ABOUT THE NAME"->React.string} </p>
      <p className="text-3xl font-semibold">
        {"Beat"->React.string}
        <span className="px-2 text-60"> {"+"->React.string} </span>
        {"Batalvi"->React.string}
        <span className="px-2 text-60"> {"="->React.string} </span>
        <span className="font-fraunces"> {"Beatalvi"->React.string} </span>
      </p>
      <p className="r-text text-pretty">
        {"The name is a tribute to "->React.string}
        <span className="font-semibold"> {"Shiv Kumar Batalvi"->React.string} </span>
        {" (1936 - 1973), the Punjabi poet most known for his romantic poetry, noted for its heightened passion, pathos, separation and lover's agony."->React.string}
      </p>
      <div className="p-4 bg-primary/10 flex gap-4 rounded-box mt-4">
        <div
          className="center text-2xl 2xl:text-4xl w-8 2xl:w-14 aspect-square bg-primary text-primary-content font-baloo font-semibold shrink-0 nb-box"
        >
          {Constant.logo->React.string}
        </div>
        <p className="r-text text-pretty">
          {"The logo is ਬ, the first letter of Batalvi in Gurmukhi, the script Punjabi is written in."->React.string}
        </p>
      </div>
    </div>
  </div>
}
