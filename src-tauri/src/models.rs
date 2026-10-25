use serde::Serialize;
use std::cmp::Ordering;
use std::collections::{HashMap, VecDeque};

pub struct Album {
    pub id: i64,
    pub name: String,
    pub year: i32,
    pub popularity: i32,
    pub mtime: i64,
    pub loved: bool,
}

#[derive(Serialize, Clone, Debug)]
#[serde(rename_all = "camelCase")]
pub struct Artist {
    pub id: i64,
    pub name: String,
}

#[derive(Serialize, Clone, Debug)]
#[serde(rename_all = "camelCase")]
pub struct ArtistStats {
    pub id: i64,
    pub name: String,
    pub album_count: i64,
    pub track_count: i64,
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
pub struct TrackItem {
    pub name: String,
    pub uri: String,
    pub duration: i64,
}
#[derive(Serialize, Clone)]
pub struct AlbumGroup {
    pub id: i64,
    pub name: String,
    pub artists: String,
    pub tracks: Vec<TrackItem>,
}

#[derive(Serialize, Clone)]
#[serde(rename_all = "camelCase")]
pub struct BasicAlbum {
    pub id: i64,
    pub name: String,
    pub year: i64,
    pub artist: String,
}

#[derive(Serialize, Clone)]
#[serde(rename_all = "camelCase")]
pub struct ArtistAlbum {
    pub id: i64,
    pub name: String,
    pub year: i64,
    pub mtime: i64,
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
    pub track: Option<Track>,
    pub is_playing: bool,
    pub position: u64,
    pub queue: VecDeque<String>,
}

pub struct AlbumTrack {
    pub track_uri: String,
    pub album_id: i64,
    pub album_name: String,
}

#[derive(Serialize, Clone)]
#[serde(rename_all = "camelCase")]
pub struct UserPlaylist {
    pub id: i64,
    pub name: String,
    pub mtime: i64,
    pub smart_enabled: bool,
    pub smart_sql: String,
}

#[derive(Serialize, Clone)]
#[serde(rename_all = "camelCase")]
pub struct PlaylistWithTracks {
    pub playlist: UserPlaylist,
    pub tracks: Vec<String>,
}

// pub struct SmartPlaylist {
//     pub playlist: UserPlaylist,
//     pub tracks_uris: Vec<String>,
// }

impl AlbumGroup {
    // Sort by match priority: tracks first, then album, then artists
    pub fn cmp_by_query(query: &str, a: &Self, b: &Self) -> Ordering {
        let query_lower = query.to_lowercase();

        // Count track matches: starts_with gets priority (weight 2), contains gets (weight 1)
        let order = |name: &str| {
            if name.to_lowercase().starts_with(&query_lower) {
                2
            } else if name.to_lowercase().contains(&query_lower) {
                1
            } else {
                0
            }
        };
        let a_track_score: i32 = a.tracks.iter().map(|t| order(&t.name)).sum();
        let b_track_score: i32 = b.tracks.iter().map(|t| order(&t.name)).sum();

        if a_track_score != b_track_score {
            return b_track_score.cmp(&a_track_score); // Descending
        }

        // Album match (starts_with first, then contains)
        let a_album_match = order(&a.name);
        let b_album_match = order(&b.name);

        if a_album_match != b_album_match {
            return b_album_match.cmp(&a_album_match); // Descending
        }

        // Artist match (starts_with first, then contains)
        order(&b.artists).cmp(&order(&a.artists)) // Descending
    }
}
