module Kbd = {
  @react.component
  let make = (~k) =>
    <kbd className="kbd kbd-lg 2xl:kbd-xl nb-shadow nb-box"> {k->React.string} </kbd>
}

module Item = {
  @react.component
  let make = (~title, ~children) => {
    <div className="flex py-2 px-1 items-center border-b border-accent">
      <p className="r-text grow"> {title->React.string} </p>
      {children}
    </div>
  }
}

module CliArgs = {
  @react.component
  let make = () => {
    <div className="flex flex-col">
      <p className="r-text-xl font-semibold"> {"Command line args"->React.string} </p>
      <Item title="Play / pause">
        <Kbd k="--toggle" />
      </Item>
      <Item title="Next song">
        <Kbd k="--next" />
      </Item>
      <Item title="Previous song">
        <Kbd k="--previous" />
      </Item>
      <Item title="Queue song by song id">
        <Kbd k="--queue <INT>" />
      </Item>
      <Item title="Seek forwards [n] seconds">
        <Kbd k="--seek <INT>" />
      </Item>
      <Item title="Rewind [n] seconds">
        <Kbd k="--rewind <INT>" />
      </Item>
      <Item title="Toggle dark mode">
        <Kbd k="--dark-toggle" />
      </Item>
    </div>
  }
}

module Navigation = {
  @react.component
  let make = () => {
    <div className="flex flex-col">
      <p className="r-text-xl font-semibold"> {"Navigation"->React.string} </p>
      <Item title="Search / focus search input">
        <Kbd k="/" />
      </Item>
      <Item title="Sidebar item [n]">
        <Kbd k="ctrl" />
        <p className="px-2 text-2xl 2xl:text-3xl"> {"+"->React.string} </p>
        <Kbd k="1-0" />
      </Item>
      <Item title="Back / close">
        <Kbd k="Backspace" />
        <p className="px-2 text-2xl 2xl:text-3xl text-60"> {"or"->React.string} </p>
        <Kbd k="Escape︎" />
      </Item>
      <Item title="Settings">
        <Kbd k=";" />
      </Item>
    </div>
  }
}

@react.component
let make = (~showCli=false) => {
  <div className="grid grid-cols-1 xl:grid-cols-2 gap-8 2xl:gap-16 overflow-y-auto min-h-0">
    <div className="grid grid-cols-1 gap-8">
      <div className="flex flex-col">
        <p className="r-text-xl font-semibold"> {"Playback"->React.string} </p>
        <Item title="Play / pause">
          <Kbd k="Space" />
        </Item>
        <Item title="Next song">
          <Kbd k="n" />
        </Item>
        <Item title="Previous song">
          <Kbd k="p" />
        </Item>
        <Item title="Seek 10 seconds">
          <Kbd k="🡆" />
          <p className="px-2 text-2xl 2xl:text-3xl text-60"> {"or"->React.string} </p>
          <Kbd k="l︎" />
        </Item>
        <Item title="Rewind 10 seconds">
          <Kbd k="🡄" />
          <p className="px-2 text-2xl 2xl:text-3xl text-60"> {"or"->React.string} </p>
          <Kbd k="h︎" />
        </Item>
        <Item title="Volume + 5">
          <Kbd k="🡅" />
          <p className="px-2 text-2xl 2xl:text-3xl text-60"> {"or"->React.string} </p>
          <Kbd k="j︎" />
        </Item>
        <Item title="Volume - 5">
          <Kbd k="🡇" />
          <p className="px-2 text-2xl 2xl:text-3xl text-60"> {"or"->React.string} </p>
          <Kbd k="k︎" />
        </Item>
        <Item title="Start playback / play all">
          <Kbd k="s" />
        </Item>
        <Item title="Add song to queue">
          <Kbd k="middle click" />
        </Item>
        <Item title="Open playing albums sidebar">
          <Kbd k="q" />
        </Item>
      </div>
      {showCli ? <Navigation /> : React.null}
    </div>
    <div className="grid grid-cols-1 gap-8">
      <div className="flex flex-col">
        <p className="r-text-xl font-semibold"> {"App"->React.string} </p>
        <Item title="Reload window">
          <Kbd k="ctrl" />
          <p className="px-2 text-3xl"> {"+"->React.string} </p>
          <Kbd k="r" />
        </Item>
        <Item title="Rotate theme">
          <Kbd k="." />
        </Item>
        <Item title="Rotate theme backward">
          <Kbd k="," />
        </Item>
        <Item title="Toggle dark mode">
          <Kbd k="d" />
        </Item>
        <Item title="Show this list">
          <Kbd k="?" />
        </Item>
      </div>
      {showCli ? <CliArgs /> : <Navigation />}
    </div>
  </div>
}
