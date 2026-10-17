type invokeFn<'a, 'b> = 'a => promise<'b>

@module("@tauri-apps/api/core")
external invoke: (string, 'a) => promise<'b> = "invoke"

let makeInvoke = name => invoke(name, _)

let loadMusic: invokeFn<unit, string> = makeInvoke("load_music")
let getStats: invokeFn<unit, Shape.Stats.t> = makeInvoke("get_stats")
let getTop10Tracks: invokeFn<unit, array<Shape.Track.t>> = makeInvoke("get_top_10_tracks")
let getTop10Albums: invokeFn<unit, array<Shape.Album.item>> = makeInvoke("get_top_10_albums")
let getTop100Albums: invokeFn<unit, array<Shape.Album.item>> = makeInvoke("get_top_100_albums")
type getTracksByAlbumsArgs = {albumIds: array<float>}
let getTracksByAlbums: invokeFn<getTracksByAlbumsArgs, array<Shape.Track.t>> = makeInvoke(
  "get_tracks_by_albums",
)
type getTrackCoverArtArgs = {album: string, trackUri: string}
let getTrackCoverArt: invokeFn<getTrackCoverArtArgs, Shape.Bytes.t> = makeInvoke(
  "get_track_cover_art",
)
type getAlbumCoverArtArgs = {album: string}
let getAlbumCoverArt: invokeFn<getAlbumCoverArtArgs, Shape.Bytes.t> = makeInvoke(
  "get_album_cover_art",
)

type playArgs = {trackUri: string}
let play: invokeFn<playArgs, unit> = makeInvoke("play")

type switchArgs = {trackUri: string}
let switchTrack: invokeFn<switchArgs, unit> = makeInvoke("switch")

let stop: invokeFn<unit, unit> = makeInvoke("stop")
let pause: invokeFn<unit, unit> = makeInvoke("pause")
let toggle: invokeFn<unit, unit> = makeInvoke("toggle")

type playManyArgs = {uris: array<string>}
let playMany: invokeFn<playManyArgs, unit> = makeInvoke("play_many")

let getPosition: invokeFn<unit, Nullable.t<int>> = makeInvoke("get_position")

type seekArgs = {seconds: int}
let seek: invokeFn<seekArgs, unit> = makeInvoke("seek")
let seek10Seconds: invokeFn<unit, unit> = makeInvoke("seek_10_seconds")
let rewind10Seconds: invokeFn<unit, unit> = makeInvoke("rewind_10_seconds")

let playNext: invokeFn<unit, unit> = makeInvoke("play_next")
let peekNext: invokeFn<unit, Nullable.t<Shape.Track.item>> = makeInvoke("peek_next")
let playPrevious: invokeFn<unit, unit> = makeInvoke("play_previous")
let peekPrevious: invokeFn<unit, Nullable.t<Shape.Track.item>> = makeInvoke("peek_previous")

type playTracksByAlbumsArgs = {albumIds: array<float>}
let playTracksByAlbums: invokeFn<playTracksByAlbumsArgs, unit> = makeInvoke("play_tracks_by_albums")

type playManyFromIndexArgs = {uris: array<string>, index: int}
let playManyFromIndex: invokeFn<playManyFromIndexArgs, unit> = makeInvoke("play_many_from_index")

let getTrackState: invokeFn<unit, Nullable.t<Shape.Track.state>> = makeInvoke("get_track_state")

type playTracksByAlbumsFromAlbumIdArgs = {albumIds: array<float>, albumId: float, index: int}
let playTracksByAlbumsFromAlbumId: invokeFn<playTracksByAlbumsFromAlbumIdArgs, unit> = makeInvoke(
  "play_tracks_by_albums_from_album_id",
)

type queueToggleTrackArgs = {uri: string}
let queueToggleTrack: invokeFn<queueToggleTrackArgs, unit> = makeInvoke("queue_toggle_track")
