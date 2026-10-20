type fn<'a, 'b> = 'a => promise<'b>

@module("@tauri-apps/api/core")
external invoke: (string, 'a) => promise<'b> = "invoke"

let make = name => invoke(name, _)

type albums = array<Shape.Album.t>
type tracks = array<Shape.Track.t>

type coverArt = Nullable.t<Shape.Bytes.t>

let reloadApp: fn<unit, unit> = make("reload_app")
let reloadWindow: fn<unit, unit> = make("reload_window")
let loadMusic: fn<unit, string> = make("load_music")
let regenerateCoverArtCache: fn<unit, unit> = make("regenerate_cover_art_cache")
let getStats: fn<unit, Shape.Stats.t> = make("get_stats")
let getTop10Tracks: fn<unit, tracks> = make("get_top_10_tracks")
let getTop10Albums: fn<unit, albums> = make("get_top_10_albums")
let getTop100Albums: fn<unit, albums> = make("get_top_100_albums")
let getRandom100Albums: fn<unit, albums> = make("get_random_100_albums")
let getLovedAlbums: fn<unit, albums> = make("get_loved_albums")
let getRecent100Albums: fn<unit, albums> = make("get_recent_100_albums")
let getAllAlbums: fn<unit, albums> = make("get_all_albums")
type getTracksByAlbumsArgs = {albumIds: array<float>}
let getTracksByAlbums: fn<getTracksByAlbumsArgs, tracks> = make("get_tracks_by_albums")
let getAllArtists: fn<unit, array<Shape.Artist.t>> = make("get_all_artists")
type getTrackCoverArtArgs = {album: string, trackUri: string}
let getTrackCoverArt: fn<getTrackCoverArtArgs, coverArt> = make("get_track_cover_art")
type getAlbumCoverArtArgs = {album: string}
let getAlbumCoverArt: fn<getAlbumCoverArtArgs, coverArt> = make("get_album_cover_art")
type getArtistCoverArtArgs = {artistId: float}
let getArtistCoverArt: fn<getArtistCoverArtArgs, coverArt> = make("get_artist_cover_art")
type getArtistStatsArgs = {artistId: float}
let getArtistStats: fn<getArtistStatsArgs, Shape.Artist.stats> = make("get_artist_stats")
type getAlbumsByArtistIdArgs = {artistId: float}
let getAlbumsByArtistId: fn<getAlbumsByArtistIdArgs, array<Shape.Album.item>> = make(
  "get_albums_by_artist_id",
)
type searchTracksGroupedArgs = {query: string}
let searchTracksGrouped: fn<searchTracksGroupedArgs, array<Shape.Album.group>> = make(
  "search_tracks_grouped",
)
let getPlayingAlbumGroups: fn<unit, array<Shape.Album.group>> = make("get_playing_album_groups")

type playArgs = {trackUri: string}
let play: fn<playArgs, unit> = make("play")
let stop: fn<unit, unit> = make("stop")
let pause: fn<unit, unit> = make("pause")
let toggle: fn<unit, unit> = make("toggle")

type playManyArgs = {uris: array<string>}
let playMany: fn<playManyArgs, unit> = make("play_many")

let getPosition: fn<unit, Nullable.t<int>> = make("get_position")

type seekArgs = {seconds: int}
let seek: fn<seekArgs, unit> = make("seek")
let seek10Seconds: fn<unit, unit> = make("seek_10_seconds")
let rewind10Seconds: fn<unit, unit> = make("rewind_10_seconds")

let playNext: fn<unit, unit> = make("play_next")
let peekNext: fn<unit, Nullable.t<Shape.Track.basic>> = make("peek_next")
let playPrevious: fn<unit, unit> = make("play_previous")
let peekPrevious: fn<unit, Nullable.t<Shape.Track.basic>> = make("peek_previous")

type playTracksByAlbumsArgs = {albumIds: array<float>}
let playTracksByAlbums: fn<playTracksByAlbumsArgs, unit> = make("play_tracks_by_albums")

type playManyFromIndexArgs = {uris: array<string>, index: int}
let playManyFromIndex: fn<playManyFromIndexArgs, unit> = make("play_many_from_index")

type playTracksByAlbumsFromAlbumIdArgs = {albumIds: array<float>, albumId: float, index: int}
let playTracksByAlbumsFromAlbumId: fn<playTracksByAlbumsFromAlbumIdArgs, unit> = make(
  "play_tracks_by_albums_from_album_id",
)
type queueToggleTrackArgs = {uri: string}
let queueToggleTrack: fn<queueToggleTrackArgs, unit> = make("queue_toggle_track")
let getTrackState: fn<unit, Shape.Track.state> = make("get_track_state")
let getVolume: fn<unit, int> = make("get_volume")
type setVolumeArgs = {volume: int}
let setVolume: fn<setVolumeArgs, unit> = make("set_volume")
type isAlbumLovedArgs = {albumId: float}
let isAlbumLoved: fn<isAlbumLovedArgs, bool> = make("is_album_loved")
type setAlbumLovedByIdArgs = {albumId: float, loved: bool}
let setAlbumLovedById: fn<setAlbumLovedByIdArgs, unit> = make("set_album_loved_by_id")
