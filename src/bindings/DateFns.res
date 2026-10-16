type t
@module("date-fns") external format: (t, string) => string = "format"
// @module("date-fns") external isThisMinute: tt => bool = "isThisMinute"
@module("date-fns") external isToday: t => bool = "isToday"
@module("date-fns") external isYesterday: t => bool = "isYesterday"
@module("date-fns") external isThisWeek: t => bool = "isThisWeek"

let toRelative = date => {
  let fmt = if date->isToday {
    "hh:mm aa"
  } else if date->isYesterday {
    "hh:mm aa, 'Yesterday'"
  } else if date->isThisWeek {
    "hh:mm aa, EEEE"
  } else {
    "hh:mm aa, dd-MM-yyyy"
  }
  date->format(fmt)
}

let toStr = date => date->format("hh:mm aa, dd-MM-yyyy")
