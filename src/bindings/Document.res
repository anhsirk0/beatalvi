type t
@val external document: t = "document"
@val @scope("document") external body: Dom.element = "body"

@set external setTitle: (t, string) => unit = "title"

@scope("document")
external createElement: string => Dom.element = "createElement"

@send external appendChild: (Dom.element, Dom.element) => Dom.element = "appendChild"
@send external removeChild: (Dom.element, Dom.element) => unit = "removeChild"

@scope("document")
external addKeyListener: (string, ReactEvent.Keyboard.t => unit) => unit = "addEventListener"

@scope("document")
external removeKeyListener: (string, ReactEvent.Keyboard.t => unit) => unit = "removeEventListener"
