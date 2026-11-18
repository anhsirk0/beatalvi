type objectUrl

module Bytes = {
  type t = array<int>

  let toImageUrl: t => objectUrl = %raw("function(bytes) {
    const blob = new Blob([new Uint8Array(bytes)], { type: 'image/jpg' });
    return URL.createObjectURL(blob);
}")

  let setImageSrc: (objectUrl, string) => unit = %raw("function(url, id) {
    let el = document.getElementById(id);
    if (el) el.src = url;
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

module Rule = {
  type numericColumn = Popularity | Year
  type textColumn = Track | Album | Artist
  type column = Numeric(numericColumn) | Text(textColumn)

  type numericOp =
    | @as("is greater than") GreaterThan
    | @as("is less than") LessThan
    | @as("is equal to") EqualTo
    | @as("is not equal to") NotEqualTo
  let numericOps = [EqualTo, NotEqualTo, GreaterThan, LessThan]
  type textOp =
    | @as("contains") Contains
    | @as("does not contain") NotContains
    | @as("is equal to") EqualTo
    | @as("is not equal to") NotEqualTo
  let textOps = [EqualTo, NotEqualTo, Contains, NotContains]

  type operation =
    | Numeric(numericOp)
    | Text(textOp)

  type textRule = {column: textColumn, operation: textOp, value: string}
  type numericRule = {column: numericColumn, operation: numericOp, value: int}

  type t = Numeric(numericRule) | Text(textRule)

  external numericOpToString: numericOp => string = "%identity"
  external textOpToString: textOp => string = "%identity"
  external numericColToString: numericColumn => string = "%identity"
  external textColToString: textColumn => string = "%identity"

  let columnToString = (col: column) =>
    switch col {
    | Numeric(col) => col->numericColToString
    | Text(col) => col->textColToString
    }
  let columnFromString = (col: string): column =>
    switch col {
    | s if s == Album->textColToString => Text(Album)
    | s if s == Artist->textColToString => Text(Artist)
    | s if s == Popularity->numericColToString => Numeric(Popularity)
    | s if s == Year->numericColToString => Numeric(Year)
    | _ => Text(Track)
    }
  let operationToString = (op: operation) =>
    switch op {
    | Numeric(op) => op->numericOpToString
    | Text(op) => op->textOpToString
    }
  let equalOpFromString = (op: string, col: column): operation => {
    switch (col, op) {
    | (Text(_), s) if s == EqualTo->textOpToString => Text(EqualTo)
    | (Text(_), s) if s == NotEqualTo->textOpToString => Text(NotEqualTo)
    | (Text(_), _) => Text(EqualTo)
    | (Numeric(_), s) if s == EqualTo->textOpToString => Numeric(EqualTo)
    | (Numeric(_), s) if s == NotEqualTo->textOpToString => Numeric(NotEqualTo)
    | (Numeric(_), _) => Numeric(EqualTo)
    }
  }
  let operationFromString = (op: string, col: column): operation =>
    switch op {
    | s if s == GreaterThan->numericOpToString => Numeric(GreaterThan)
    | s if s == LessThan->numericOpToString => Numeric(LessThan)
    | s if s == Contains->textOpToString => Text(Contains)
    | s if s == NotContains->textOpToString => Text(NotContains)
    | s if s == NotContains->textOpToString => Text(NotContains)
    | s => equalOpFromString(s, col)
    }

  let initialText: textRule = {column: Track, operation: Contains, value: ""}
  let initialNumeric: numericRule = {column: Popularity, operation: GreaterThan, value: 50}
  let initialRule = Text(initialText)

  let getColumn = (rule: t): column =>
    switch rule {
    | Text({column}) => Text(column)
    | Numeric({column}) => Numeric(column)
    }
  let getOperation = (rule: t): operation =>
    switch rule {
    | Text({operation}) => Text(operation)
    | Numeric({operation}) => Numeric(operation)
    }

  let onColumnChange = (col: column, rule: t) =>
    switch col {
    | Numeric(column) =>
      switch rule {
      | Text(_) => Numeric({...initialNumeric, column})
      | Numeric(data) => Numeric({...data, column})
      }
    | Text(column) =>
      switch rule {
      | Text(data) => Text({...data, column})
      | Numeric(_) => Text({...initialText, column})
      }
    }

  let onOperationChange = (op: operation, rule: t) =>
    switch op {
    | Numeric(operation) =>
      switch rule {
      | Text(_) => Numeric({...initialNumeric, operation})
      | Numeric(data) => Numeric({...data, operation})
      }
    | Text(operation) =>
      switch rule {
      | Text(data) => Text({...data, operation})
      | Numeric(_) => Text({...initialText, operation})
      }
    }

  let numericColumnToSql = (col: numericColumn) =>
    switch col {
    | Popularity => "t.popularity"
    | Year => "a.year"
    }

  let textColumnToSql = (col: textColumn) =>
    switch col {
    | Track => "t.name"
    | Album => "a.name"
    | Artist => "ar.name"
    }

  let numericOpToSql = (op: numericOp) =>
    switch op {
    | EqualTo => "="
    | NotEqualTo => "!="
    | GreaterThan => ">"
    | LessThan => "<"
    }
  let textOpToSql = (op: textOp) =>
    switch op {
    | EqualTo => "="
    | NotEqualTo => "!="
    | Contains => "LIKE"
    | NotContains => "NOT LIKE"
    }

  let toSql = rule => {
    switch rule {
    | Numeric({column, operation, value}) => {
        let col = numericColumnToSql(column)
        let op = numericOpToSql(operation)
        `${col} ${op} ${Int.toString(value)}`
      }
    | Text({column, operation, value}) => {
        let col = textColumnToSql(column)
        let op = textOpToSql(operation)
        let escapedValue = String.replaceAll(value, "'", "''")
        switch operation {
        | Contains | NotContains => `${col} ${op} '%${escapedValue}%'`
        | EqualTo | NotEqualTo => `${col} ${op} '${escapedValue}'`
        }
      }
    }
  }
}

module SmartPlaylist = {
  type match = All | Any
  type orderCols =
    | @as("Song") Track
    | Album
    | Artist
    | Year
    | Popularity
  type order = Random | Asc(orderCols) | Desc(orderCols)
  let orderCols = [Track, Album, Artist, Year, Popularity]

  type t = {
    match: match,
    order: order,
    limit: int,
    rules: array<Rule.t>,
  }
  let initial = {
    match: All,
    order: Asc(Track),
    limit: 50,
    rules: [],
  }
  @scope("JSON") @val
  external parseInto: string => t = "parse"
  type action =
    | NewRule
    | RemoveRule(int)
    | UpdateRule(int, Rule.t)
    | SetMatch(match)
    | SetOrder(order)
    | SetLimit(int)
  type dispatch = action => unit

  external orderColsToString: orderCols => string = "%identity"
  let orderToString = order =>
    switch order {
    | Random => "Random"
    | Asc(col) => col->orderColsToString ++ " (ascending)"
    | Desc(col) => col->orderColsToString ++ " (descending)"
    }
  let orderColFromString = col =>
    switch col {
    | s if s == Track->orderColsToString => Track
    | s if s == Album->orderColsToString => Album
    | s if s == Artist->orderColsToString => Artist
    | s if s == Year->orderColsToString => Year
    | s if s == Popularity->orderColsToString => Popularity
    | _ => Track
    }

  let orderFromString = ord =>
    if ord == "Random" {
      Random
    } else if ord->String.endsWith("(ascending)") {
      Asc(ord->String.replace(" (ascending)", "")->orderColFromString)
    } else if ord->String.endsWith("(descending)") {
      Desc(ord->String.replace(" (descending)", "")->orderColFromString)
    } else {
      Random
    }

  let reducer = (state, action) => {
    switch action {
    | SetMatch(match) => {...state, match}
    | SetOrder(order) => {...state, order}
    | SetLimit(limit) => {...state, limit}
    | NewRule => {...state, rules: state.rules->Array.concat([Rule.initialRule])}
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

  let useReducer = (~json: option<string>) =>
    React.useReducer(reducer, json->Option.map(parseInto)->Option.getOr(initial))

  let matchToSql = (match: match): string =>
    switch match {
    | All => "AND"
    | Any => "OR"
    }

  let orderColToSql = (col: orderCols): string =>
    switch col {
    | Track => "t.name"
    | Album => "a.name"
    | Artist => "artists"
    | Year => "a.year"
    | Popularity => "t.popularity"
    }

  let orderToSql = (order: order): string =>
    switch order {
    | Random => "ORDER BY RANDOM()"
    | Asc(col) => `ORDER BY ${orderColToSql(col)} ASC`
    | Desc(col) => `ORDER BY ${orderColToSql(col)} DESC`
    }

  let toSql: t => string = data => {
    let matchOp = data.match->matchToSql
    let rulesWhere = data.rules->Array.map(Rule.toSql)->Array.join(` ${matchOp} `)
    let whereClause = rulesWhere === "" ? "" : `WHERE ${rulesWhere}`
    let orderClause = orderToSql(data.order)
    let limitClause = `LIMIT ${Int.toString(data.limit)}`
    `SELECT 
       t.id,
       t.name AS track_name,
       t.uri,
       t.duration,
       t.popularity,
       a.name AS album_name,
     GROUP_CONCAT(ar.name, ', ') AS artists
     FROM tracks t
     JOIN albums a ON t.album_id = a.id
     LEFT JOIN track_artists ta ON t.id = ta.track_id
     LEFT JOIN artists ar ON ta.artist_id = ar.id
     ${whereClause}
     GROUP BY t.id, t.name, t.uri, t.duration, t.popularity, a.name
     ${orderClause}
     ${limitClause}`
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
    isSmart: bool,
  }
  type data = {
    id: float,
    name: string,
    mtime: int,
    smartEnabled: bool,
    smartSql: string,
    smartJson: string,
  }
  type full = {
    @as("playlist") data: data,
    tracks: array<string>,
  }

  type regular = {playlist: playlist, tracks: array<string>}

  type t =
    | Regular(regular)
    | Smart(data)

  let fromData = ({data, tracks}: full) => {
    if data.smartEnabled {
      Smart(data)
    } else {
      Regular({
        playlist: {id: data.id, name: data.name, isSmart: false},
        tracks,
      })
    }
  }
}

module CoverSize = {
  type t = | @as("small") Small | @as("medium") Medium | @as("large") Large
}
