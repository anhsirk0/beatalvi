type handle

type align = [#start | #center | #end]
type behavior = [#smooth | #auto]
type location = {
  index: int,
  align?: align,
  behavior?: behavior,
  offset?: float,
}
@send external scrollToIndex: (handle, location) => unit = "scrollToIndex"

type api = {
  scrollToIndex: int => unit,
  jumpToIndex: int => unit,
}

@module("react-virtuoso") @react.component
external make: (
  ~style: ReactDOM.style=?,
  ~data: array<'a>,
  ~itemContent: (int, 'a) => React.element,
  ~id: string=?,
  ~scrollerRef: Nullable.t<Dom.element> => unit=?,
  ~className: string=?,
  ~ref: React.ref<Nullable.t<handle>>=?,
) => React.element = "Virtuoso"

module Grid = {
  @module("react-virtuoso") @react.component
  external make: (
    ~style: ReactDOM.style=?,
    ~data: array<'a>,
    ~itemContent: (int, 'a) => React.element,
    ~columns: int=?,
    ~totalCount: int,
    ~useWindowScroll: bool=?,
    ~scrollerRef: Nullable.t<Dom.element> => unit=?,
    ~id: string=?,
    ~className: string=?,
    ~itemClassName: string=?,
    ~listClassName: string=?,
  ) => React.element = "VirtuosoGrid"
}
