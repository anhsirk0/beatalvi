let useToggle = (~init: bool=false) => {
  let (isOpen, setIsOpen) = React.useState(_ => init)
  let toggleOpen = () => setIsOpen(val => !val)
  (isOpen, toggleOpen, setIsOpen)
}
let useDebounce = (value, delay) => {
  let (debounced, setDebounced) = React.useState(_ => value)
  React.useEffect2(() => {
    let id = setTimeout(() => setDebounced(_ => value), delay)
    Some(() => clearTimeout(id))
  }, (value, delay))

  debounced
}

type fetchOption<'a, 'b> = {
  fn: unit => promise<'a>,
  onSuccess?: 'b => unit,
}
type fetchResult<'a> = Loading | Failed | Success('a)
let useFetch = (opts: fetchOption<'a, 'b>) => {
  let (state, setState) = React.useState(_ => Loading)
  let hasRun = React.useRef(false)

  React.useEffect0(() => {
    if !hasRun.current {
      hasRun.current = true
      try {
        opts.fn()
        ->Promise.then(async data => {
          setState(_ => Success(data))
          switch opts.onSuccess {
          | Some(onSuccess) => onSuccess(data)
          | None => ignore()
          }
        })
        ->ignore
      } catch {
      | _ => setState(_ => Failed)
      }
    }
    None
  })

  state
}
