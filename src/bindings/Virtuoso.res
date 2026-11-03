@module("react-virtuoso") @react.component
external make: (
  ~style: ReactDOM.style=?,
  ~data: array<'a>,
  ~itemContent: (int, 'a) => React.element,
  ~id: string=?,
  ~className: string=?,
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
    ~itemClassName: string=?,
    ~listClassName: string=?,
  ) => React.element = "VirtuosoGrid"
}
