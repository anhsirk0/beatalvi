module Kbd = {
  @react.component
  let make = (~k) =>
    <kbd className="kbd kbd-lg 2xl:kbd-xl nb-shadow nb-box"> {k->React.string} </kbd>
}

module Item = {
  @react.component
  let make = (~title, ~children) => {
    <div className="flex py-2 2xl:py-4 px-1 items-center border-b border-accent">
      <p className="r-text-lg grow"> {title->React.string} </p>
      {children}
    </div>
  }
}

@react.component
let make = () => {
  <div className="grid grid-cols-1 xl:grid-cols-2 gap-8 2xl:gap-16 overflow-y-auto min-h-0">
    <div className="flex flex-col">
      <p className="r-text-xl font-semibold"> {"Playback"->React.string} </p>
      <Item title="Play / pause">
        <Kbd k="Space" />
      </Item>
      <Item title="Next track">
        <Kbd k="n" />
      </Item>
      <Item title="Previous track">
        <Kbd k="p" />
      </Item>
      <Item title="Skip forward 10 seconds">
        <Kbd k="🡆" />
        <p className="px-2 text-2xl 2xl:text-3xl text-60"> {"or"->React.string} </p>
        <Kbd k="l︎" />
      </Item>
      <Item title="Skip backward 10 seconds">
        <Kbd k="🡄" />
        <p className="px-2 text-2xl 2xl:text-3xl text-60"> {"or"->React.string} </p>
        <Kbd k="h︎" />
      </Item>
      <Item title="Start playback / play all">
        <Kbd k="s" />
      </Item>
      <Item title="Add track to queue">
        <Kbd k="middle click" />
      </Item>
      <Item title="Open playing albums sidebar">
        <Kbd k="q" />
      </Item>
    </div>
    <div className="grid grid-cols-1 gap-8 2xl:gap-16">
      <div className="flex flex-col">
        <p className="r-text-xl font-semibold"> {"Navigation"->React.string} </p>
        <Item title="Search / focus search input">
          <Kbd k="/" />
        </Item>
        <Item title="Sidebar item (s)">
          <Kbd k="ctrl" />
          <p className="px-2 text-2xl 2xl:text-3xl"> {"+"->React.string} </p>
          <Kbd k="1-9" />
        </Item>
        <Item title="Back / close">
          <Kbd k="Backspace" />
          <p className="px-2 text-2xl 2xl:text-3xl text-60"> {"or"->React.string} </p>
          <Kbd k="Escape︎" />
        </Item>
        <Item title="Settings">
          <Kbd k="," />
        </Item>
      </div>
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
        <Item title="Toggle dark mode">
          <Kbd k="d" />
        </Item>
        <Item title="Show this list">
          <Kbd k="?" />
        </Item>
      </div>
    </div>
  </div>
}
