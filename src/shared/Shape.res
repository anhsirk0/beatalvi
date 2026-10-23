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
