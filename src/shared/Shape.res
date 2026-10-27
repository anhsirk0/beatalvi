type objectUrl

module Bytes = {
  type t = array<int>

  let toImageUrl: t => objectUrl = %raw("function(bytes) {
    const blob = new Blob([new Uint8Array(bytes)], { type: 'image/jpg' });
    return URL.createObjectURL(blob);
}")

  let setImageSrc: (objectUrl, string) => unit = %raw("function(url, id) {
    document.getElementById(id).src = url;
}")

  let setCover = (data: Nullable.t<t>, id) => {
    switch data->Nullable.toOption {
    | Some(bytes) =>
      if bytes->Array.length > 0 {
        bytes->toImageUrl->setImageSrc(id)
      }
    | None => ignore()
    }
  }
  // let revokeObjectUrl = %todo
}

module Stats = {
  type t = {
    tracks: int,
    albums: int,
    artists: int,
    // playlists: int,
  }
}

module Track = {
  type basic = {
    name: string,
    album: string,
    artist: string,
  }
  type t = {
    ...basic,
    id: float,
    uri: string,
    duration: int,
  }

  type item = {
    name: string,
    uri: string,
    duration: int,
  }

  type state = {
    track: Nullable.t<t>,
    isPlaying: bool,
    position: int,
    queue: array<string>,
  }

  let eq = (one, other) => one.id == other.id
  let ne = (one, other) => one.id != other.id
  let filterQuery = (track: t, query) =>
    track.name->Util.Str.contains(query) ||
    track.artist->Util.Str.contains(query) ||
    track.album->Util.Str.contains(query)

  let hasOne = (arr, item) => arr->Array.some(eq(item, _))
  let addOne = (arr, item) => arr->hasOne(item) ? arr : arr->Array.concat([item])
  let removeOne = (arr, item) => arr->hasOne(item) ? arr->Array.filter(ne(item, _)) : arr

  let totalDuration = (arr: array<t>) =>
    arr->Array.map(t => t.duration)->Array.reduce(0, (acc, num) => acc + num)
}

module Album = {
  type t = {
    id: float,
    name: string,
    year: int,
    artist: string,
  }
  type item = {
    id: float,
    name: string,
    year: int,
    mtime: int,
  }

  type group = {
    id: float,
    name: string,
    year: int,
    mtime: int,
    artists: string,
    tracks: array<Track.item>,
  }

  // let toString = (album: t) => `${album.id->Float.toString}%%%${album.name}`
}

module Artist = {
  type t = {id: float, name: string}

  type stats = {
    id: float,
    name: string,
    albumCount: int,
    trackCount: int,
  }
}

module Playlist = {
  type kind = Regular | Smart
  // type data = Regular(array<string>) | Smart(string)
  // type t = {
  //   id: float,
  //   name: string,
  //   data: data,
  // }

  type playlist = {
    id: float,
    name: string,
    mtime: int,
    smartEnabled: bool,
    smartSql: string,
  }

  type t = {
    playlist: playlist,
    tracks: array<string>,
  }
}

module Rule = {
  type numericColumn = Popularity | Year
  type stringColumn = Track | Album | Artist
  type column = Numeric(numericColumn) | String(stringColumn)
  type value = Numeric(int) | String(string)
  type numericOp =
    | @as("is greater than") GreaterThan
    | @as("is less than") LessThan
    | @as("is equal to") EqualTo
    | @as("is not equal to") NotEqualTo
  type stringOp =
    | @as("contains") Contains
    | @as("does not contain") NotContains
    | @as("is equal to") EqualTo
    | @as("is not equal to") NotEqualTo

  external numericOpToString: numericOp => string = "%identity"
  external stringOpToString: stringOp => string = "%identity"

  type t =
    | String({column: stringColumn, operation: stringOp, value: string})
    | Numeric({column: numericColumn, operation: numericOp, value: int})

  let initial = String({column: Track, operation: Contains, value: "test"})
  // type t = {
  //   column: column,
  // operation: operation,
  // }
}

module SmartPlaylist = {
  type match = All | Any
  type orderCols = Track | Album | Artist | Year | Popularity
  type order = Random | Asc(orderCols) | Desc(orderCols)

  type t = {
    match: match,
    order: order,
    limit: int,
    rules: array<Rule.t>,
  }
  let initialState = {
    match: All,
    order: Asc(Track),
    limit: 50,
    rules: [],
  }

  type action =
    // | AddRule(Rule.t)
    | NewRule
    | RemoveRule(int)
    | UpdateRule(int, Rule.t)
    | SetMatch(match)
    | SetOrder(order)
    | SetLimit(int)
  type dispatch = action => unit

  let reducer = (state, action) => {
    switch action {
    | SetMatch(match) => {...state, match}
    | SetOrder(order) => {...state, order}
    | SetLimit(limit) => {...state, limit}
    // | AddRule(rule) => {...state, rules: state.rules->Array.concat([rule])}
    | NewRule => {...state, rules: state.rules->Array.concat([Rule.initial])}
    | RemoveRule(index) => {
        ...state,
        rules: state.rules->Array.filterWithIndex((_, i) => i != index),
      }
    | UpdateRule(index, rule) => {
        ...state,
        rules: state.rules->Array.mapWithIndex((r, i) => i == index ? rule : r),
      }
    }
  }

  let useReducer = (~data=initialState) => React.useReducer(reducer, data)
}
