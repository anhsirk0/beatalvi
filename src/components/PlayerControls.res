let tipClasses = "r-text font-medium px-4 py-2 bg-primary text-primary-content whitespace-nowrap nb-box"

module PreviousBtn = {
  @react.component
  let make = () => {
    let onClick = _ => Invoke.playPrevious()->ignore

    let previousTrack = Hook.useFetch({
      fn: () => Invoke.peekPrevious()->Promise.then(async n => n->Nullable.toOption),
    })
    let disabled = switch previousTrack {
    | Success(Some(_)) => false
    | _ => true
    }

    let btn =
      <button disabled onClick className="btn btn-ghost btn-square btn-lg hover:bg-base-200/10">
        <Icon.skipBack className="size-8 text-neutral-content" weight=Fill />
      </button>

    switch previousTrack {
    | Success(Some(info)) =>
      <Tippy
        render={attrs =>
          <p {...attrs} className=tipClasses>
            {info.name->React.string}
            <span className="text-primary-content/60"> {` ${Constant.sep} `->React.string} </span>
            {info.artist->React.string}
          </p>}
      >
        {btn}
      </Tippy>
    | _ => btn
    }
  }
}

module NextBtn = {
  @react.component
  let make = () => {
    let onClick = _ => Invoke.playNext()->ignore

    let nextTrack = Hook.useFetch({
      fn: () => Invoke.peekNext()->Promise.then(async n => n->Nullable.toOption),
    })
    let disabled = switch nextTrack {
    | Success(Some(_)) => false
    | _ => true
    }

    let btn =
      <button disabled onClick className="btn btn-ghost btn-square btn-lg hover:bg-base-200/10">
        <Icon.skipForward className="size-8 text-neutral-content" weight=Fill />
      </button>

    switch nextTrack {
    | Success(Some(info)) =>
      <Tippy
        render={attrs =>
          <p {...attrs} className=tipClasses>
            {info.name->React.string}
            <span className="text-primary-content/60"> {` ${Constant.sep} `->React.string} </span>
            {info.artist->React.string}
          </p>}
      >
        {btn}
      </Tippy>
    | _ => btn
    }
  }
}

@react.component
let make = () => {
  let (state, update) = Store.Player.useShallow(s => (s.data.state, s.update))
  let onToggle = _ => Invoke.toggle()->ignore

  Event.useListen(Event.listenToggle, playing => update(SetState(playing ? Playing : Paused)))


  <div
    className={`${Constant.headerHeight} flex border-b-2 border-accent center w-full center gap-4`}
  >
    <PreviousBtn />
    <button
      onClick=onToggle className="btn btn-ghost btn-square btn-lg bg-primary text-primary-content"
    >
      {state == Playing
        ? <Icon.pause className="size-8" weight=Fill />
        : <Icon.play className="size-8" weight=Fill />}
    </button>
    <NextBtn />
  </div>
}
