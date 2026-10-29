use crate::models::{PlaylistItem, PlaylistWithTracks, Track, UserPlaylist};
use crate::utils::config;
use rusqlite::{Connection, Result, params};
use std::time::{SystemTime, UNIX_EPOCH};

/* ─────────────────────────── DB Initialize ─────────────────────────── */
const CREATE_PLAYLISTS: &str = "
CREATE TABLE IF NOT EXISTS playlists (id INTEGER PRIMARY KEY,
                    name TEXT NOT NULL UNIQUE,
                        smart_enabled INT NOT NULL DEFAULT 0,
                        smart_sql TEXT,
                        smart_json TEXT,
                        mtime BIGINT NOT NULL);
";
const INSERT_INTO_PLAYLISTS: &str = "
INSERT INTO playlists (name, smart_enabled, smart_sql, smart_json, mtime) VALUES (?1, ?2, ?3, ?4, ?5);";

const CREATE_TRACKS: &str = "
CREATE TABLE IF NOT EXISTS tracks (playlist_id INT NOT NULL,
                    uri TEXT NOT NULL);
";
const INSERT_INTO_TRACKS: &str = "INSERT INTO tracks (playlist_id, uri) VALUES (?1, ?2);";

pub fn initialize() -> Result<()> {
    let conn = Connection::open(config::get_playlist_db_path())?;
    let sql = format!("{}{}", CREATE_PLAYLISTS, CREATE_TRACKS);

    conn.execute_batch(&sql)?;
    Ok(())
}

pub fn create_playlist_with_track_uris(name: &str, uris: Vec<String>) -> Result<i64> {
    let mut conn = Connection::open(config::get_playlist_db_path())?;
    let mtime = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap()
        .as_millis() as i64;
    let tx = conn.transaction()?;
    tx.execute(INSERT_INTO_PLAYLISTS, params![name, "0", "", "", mtime])?;
    let playlist_id: i64 = tx.last_insert_rowid();
    for uri in uris {
        tx.execute(INSERT_INTO_TRACKS, params![&playlist_id, uri])?;
    }
    tx.commit()?;
    Ok(playlist_id)
}

pub fn create_smart_playlist(name: &str, sql: String, json: String) -> Result<i64> {
    let conn = Connection::open(config::get_playlist_db_path())?;
    let mtime = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap()
        .as_millis() as i64;
    conn.execute(INSERT_INTO_PLAYLISTS, params![name, "1", sql, json, mtime])?;
    Ok(conn.last_insert_rowid())
}

pub fn update_smart_playlist(id: i64, name: &str, sql: String, json: String) -> Result<i64> {
    let conn = Connection::open(config::get_playlist_db_path())?;
    let mtime = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap()
        .as_millis() as i64;
    conn.execute(
        "UPDATE playlists SET name = ?1, smart_sql = ?2, smart_json = ?3, mtime = ?4 WHERE id = ?5",
        params![name, sql, json, mtime, id],
    )?;
    Ok(id)
}

pub fn update_playlist_with_track_uris(id: i64, name: &str, uris: Vec<String>) -> Result<i64> {
    let mut conn = Connection::open(config::get_playlist_db_path())?;
    let mtime = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap()
        .as_millis() as i64;
    let tx = conn.transaction()?;
    tx.execute(
        "UPDATE playlists SET name = ?1, mtime = ?2 WHERE id = ?3",
        params![name, mtime, id],
    )?;
    // Delete existing tracks
    tx.execute("DELETE FROM tracks WHERE playlist_id = ?1", params![id])?;

    // Insert new tracks
    {
        let mut stmt = tx.prepare("INSERT INTO tracks (playlist_id, uri) VALUES (?1, ?2)")?;

        for track_uri in uris {
            stmt.execute(params![id, track_uri])?;
        }
    }
    tx.commit()?;
    Ok(id)
}

pub fn delete_playlist_by_id(id: i64) -> Result<i64> {
    let mut conn = Connection::open(config::get_playlist_db_path())?;
    let tx = conn.transaction()?;
    tx.execute("DELETE FROM tracks WHERE playlist_id = ?1", params![id])?;
    tx.execute("DELETE FROM playlists WHERE id = ?1", params![id])?;
    tx.commit()?;
    Ok(id)
}

pub fn get_all_playlists() -> Result<Vec<PlaylistItem>> {
    let conn = Connection::open(config::get_playlist_db_path())?;
    let mut stmt = conn.prepare("SELECT id, name, smart_enabled FROM playlists")?;
    let playlists = stmt
        .query_map([], |row| {
            Ok(PlaylistItem {
                id: row.get(0)?,
                name: row.get(1)?,
                is_smart: row.get::<_, i32>(2)? != 0,
            })
        })?
        .collect::<Result<Vec<PlaylistItem>, _>>()?;

    Ok(playlists)
}

pub fn get_playlists_with_tracks() -> Result<Vec<PlaylistWithTracks>> {
    let conn = Connection::open(config::get_playlist_db_path())?;
    let mut stmt = conn
        .prepare("SELECT id, name, smart_enabled, smart_sql, smart_json, mtime FROM playlists")?;

    let playlists = stmt.query_map([], |row| {
        Ok(UserPlaylist {
            id: row.get(0)?,
            name: row.get(1)?,
            smart_enabled: row.get::<_, i32>(2)? != 0,
            smart_sql: row.get(3)?,
            smart_json: row.get(4)?,
            mtime: row.get(5)?,
        })
    })?;

    let mut result = Vec::new();

    for playlist_result in playlists {
        let playlist = playlist_result?;
        let mut track_stmt = conn.prepare("SELECT uri FROM tracks WHERE playlist_id = ?1")?;

        let tracks: Vec<String> = track_stmt
            .query_map([playlist.id], |row| row.get(0))?
            .collect::<Result<Vec<_>, _>>()?;

        result.push(PlaylistWithTracks { playlist, tracks });
    }

    Ok(result)
}

pub fn find_playlist_with_tracks_by_id(id: i64) -> Result<PlaylistWithTracks> {
    let conn = Connection::open(config::get_playlist_db_path())?;
    let mut stmt = conn.prepare(
        "SELECT id, name, smart_enabled, smart_sql, smart_json, mtime FROM playlists WHERE id = ?1",
    )?;

    let playlist = stmt.query_row([id], |row| {
        Ok(UserPlaylist {
            id: row.get(0)?,
            name: row.get(1)?,
            smart_enabled: row.get::<_, i32>(2)? != 0,
            smart_sql: row.get(3)?,
            smart_json: row.get(4)?,
            mtime: row.get(5)?,
        })
    })?;

    let mut track_stmt = conn.prepare("SELECT uri FROM tracks WHERE playlist_id = ?1")?;
    let tracks: Vec<String> = track_stmt
        .query_map([playlist.id], |row| row.get(0))?
        .collect::<Result<Vec<_>, _>>()?;

    Ok(PlaylistWithTracks { playlist, tracks })
}

pub fn get_smart_playlist_tracks(query: String) -> Result<Vec<Track>> {
    let conn = Connection::open(config::get_db_path())?;
    let mut stmt = conn.prepare(&query)?;
    let tracks = stmt
        .query_map([], |row| {
            Ok(Track {
                id: row.get(0)?,
                name: row.get(1)?,
                uri: row.get(2)?,
                duration: row.get(3)?,
                popularity: row.get(4)?,
                album: row.get(5)?,
                artist: row.get(6)?,
            })
        })?
        .collect::<Result<Vec<Track>, _>>()?;
    Ok(tracks)
}
