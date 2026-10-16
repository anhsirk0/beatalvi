type objectUrl

module Bytes = {
  type t = array<int>

  let toImageUrl: t => objectUrl = %raw("function(bytes) {
    const blob = new Blob([new Uint8Array(bytes)], { type: 'image/jpg' });
    return URL.createObjectURL(blob);
}")

  let toOpusUrl: t => objectUrl = %raw("function(bytes) {
    const blob = new Blob([new Uint8Array(bytes)], { type: 'audio/opus' });
    return URL.createObjectURL(blob);
}")

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
  type item = {
    name: string,
    album: string,
    artist: string,
  }
  type t = {
    ...item,
    id: float,
    uri: string,
    duration: int,
  }

  type state = {
    track: t,
    isPlaying: bool,
    position: int,
  }

  let totalDuration = arr =>
    arr->Array.map(t => t.duration)->Array.reduce(0, (acc, num) => acc + num)
}

module Album = {
  type item = {
    id: float,
    name: string,
    year: int,
    artist: string,
  }
}
