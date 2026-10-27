type t

@val external window: t = "window"

module History = {
  type t

  @val @scope("window") external history: t = "history"
  @send external back: t => unit = "back"
}
