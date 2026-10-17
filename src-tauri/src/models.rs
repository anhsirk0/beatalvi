use serde::Serialize;
use std::collections::HashMap;

pub struct Album {
    pub id: i64,
    pub name: String,
    pub year: i32,
    pub popularity: i32,
    pub mtime: i64,
    pub loved: bool,
}
pub struct Artist {
    pub id: i64,
    pub name: String,
}

#[derive(Serialize, Clone, Debug)]
#[serde(rename_all = "camelCase")]
pub struct Track {
    pub id: i64,
    pub name: String,
    pub uri: String,
    pub duration: i64,
    pub album: String,
    pub artist: String,
    pub popularity: i32,
}

#[derive(Serialize, Clone)]
#[serde(rename_all = "camelCase")]
pub struct BasicTrack {
    pub name: String,
    pub album: String,
    pub artist: String,
}

#[derive(Serialize, Clone)]
#[serde(rename_all = "camelCase")]
pub struct BasicAlbum {
    pub id: i64,
    pub name: String,
    pub year: i64,
    pub artist: String,
}

pub struct UriMtime {
    pub uri: String,
    pub mtime: i64,
}

pub struct IdMtime {
    pub id: i64,
    pub mtime: i64,
}

pub type TracksMetaMap = HashMap<String, IdMtime>;
pub type NameIdMap = HashMap<String, i64>;

pub struct TrackInfo {
    pub name: String,
    pub duration: i64,
    pub album: String,
    pub artist: String,
    pub year: i32,
    pub mtime: i64,
}

pub struct AlbumInfo {
    pub name: String,
    pub year: i32,
    pub mtime: i64,
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
pub struct Stats {
    pub tracks: i32,
    pub albums: i32,
    pub artists: i32,
}

#[derive(Serialize, Clone)]
#[serde(rename_all = "camelCase")]
pub struct TrackState {
    pub track: Track,
    pub is_playing: bool,
    pub position: u64,
}

pub enum Event {
    Play,
    Pause,
    Toggle,
    Stop,
    Position,
}
