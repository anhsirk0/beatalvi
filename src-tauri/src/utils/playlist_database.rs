use crate::models::{PlaylistItem, PlaylistWithTracks, Track, UserPlaylist};
use crate::utils::config;
use crate::utils::database;
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

fn get_mtime() -> i64 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap()
        .as_millis() as i64
}

pub fn initialize() -> Result<()> {
    let conn = Connection::open(config::get_playlist_db_path())?;
    let sql = format!("{}{}", CREATE_PLAYLISTS, CREATE_TRACKS);

    conn.execute_batch(&sql)?;
    Ok(())
}

pub fn create_playlist_with_track_uris(name: &str, uris: Vec<String>) -> Result<i64> {
    let mut conn = Connection::open(config::get_playlist_db_path())?;
    let mtime = get_mtime();
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
    let mtime = get_mtime();
    conn.execute(INSERT_INTO_PLAYLISTS, params![name, "1", sql, json, mtime])?;
    Ok(conn.last_insert_rowid())
}

pub fn update_smart_playlist(id: i64, name: &str, sql: String, json: String) -> Result<i64> {
    let conn = Connection::open(config::get_playlist_db_path())?;
    let mtime = get_mtime();
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

pub fn get_playlist_track_uris(id: i64, conn: &Connection) -> Result<Vec<String>> {
    let mut track_stmt = conn.prepare("SELECT uri FROM tracks WHERE playlist_id = ?1")?;
    let uris: Vec<String> = track_stmt
        .query_map([id], |row| row.get(0))?
        .collect::<Result<Vec<_>, _>>()?;
    Ok(uris)
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

    let tracks = get_playlist_track_uris(id, &conn)?;

    Ok(PlaylistWithTracks { playlist, tracks })
}

pub fn find_playlist_by_id(id: i64) -> Result<UserPlaylist> {
    let conn = Connection::open(config::get_playlist_db_path())?;
    let mut stmt = conn.prepare(
        "SELECT id, name, smart_enabled, smart_sql, smart_json, mtime FROM playlists WHERE id = ?1",
    )?;

    let playlist = stmt.query_one([id], |row| {
        Ok(UserPlaylist {
            id: row.get(0)?,
            name: row.get(1)?,
            smart_enabled: row.get::<_, i32>(2)? != 0,
            smart_sql: row.get(3)?,
            smart_json: row.get(4)?,
            mtime: row.get(5)?,
        })
    })?;

    Ok(playlist)
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
                year: row.get(5)?,
                mtime: row.get(6)?,
                album: row.get(7)?,
                artist: row.get(8)?,
            })
        })?
        .collect::<Result<Vec<Track>, _>>()?;
    Ok(tracks)
}

pub fn get_playlist_tracks(id: i64) -> Result<Vec<Track>> {
    let conn = Connection::open(config::get_playlist_db_path())?;
    let sql = conn.query_one(
        "SELECT id, smart_enabled, smart_sql  FROM playlists WHERE id = ?1",
        params![id],
        |row| {
            Ok(if row.get::<_, i32>(1)? != 0 {
                Some(row.get::<_, String>(2)?)
            } else {
                None
            })
        },
    )?;

    let tracks = match sql {
        Some(query) => get_smart_playlist_tracks(query)?,
        None => {
            let uris = get_playlist_track_uris(id, &conn)?;
            database::get_tracks_by_uris(uris)?
        }
    };

    Ok(tracks)
}

pub fn get_other_tracks_in_playlist(track_uri: &str) -> Result<Vec<Track>> {
    let conn = Connection::open(config::get_playlist_db_path())?;
    let mut stmt = conn.prepare(
        "SELECT t2.playlist_id, t2.uri
         FROM tracks t1
         JOIN tracks t2 ON t2.playlist_id = t1.playlist_id
         WHERE t1.uri = ?1
           AND t2.uri != ?1
         ORDER BY t2.playlist_id ASC
         LIMIT 10",
    )?;

    let uris = stmt
        .query_map(params![track_uri], |row| Ok(row.get::<_, String>(1)?))?
        .collect::<Result<Vec<_>, _>>()?;

    let tracks = database::get_tracks_by_uris(uris)?;
    Ok(tracks)
}

pub fn get_playlists_for_track(uri: &str) -> Result<Vec<PlaylistItem>> {
    let conn = Connection::open(config::get_playlist_db_path())?;
    let mut stmt = conn.prepare(
        "SELECT DISTINCT p.id, p.name
         FROM playlists p
         JOIN tracks t ON t.playlist_id = p.id
         WHERE t.uri = ?1
         ORDER BY p.name ASC",
    )?;

    let playlists = stmt
        .query_map(params![uri], |row| {
            Ok(PlaylistItem {
                id: row.get(0)?,
                name: row.get(1)?,
                is_smart: false,
            })
        })?
        .collect::<Result<Vec<_>, _>>()?;

    Ok(playlists)
}

pub fn append_track_to_playlist(playlist_id: i64, track_uri: &str) -> Result<bool> {
    let mut conn = Connection::open(config::get_playlist_db_path())?;
    let tx = conn.transaction()?;
    let added = tx.execute(
        "INSERT INTO tracks (playlist_id, uri) VALUES (?1, ?2)",
        params![playlist_id, track_uri],
    )?;
    if added > 0 {
        let mtime = get_mtime();
        tx.execute(
            "UPDATE playlists SET mtime = ?1 WHERE id = ?2",
            params![mtime, playlist_id],
        )?;
    }
    tx.commit()?;

    Ok(added > 0)
}

pub fn remove_track_from_playlist(playlist_id: i64, track_uri: &str) -> Result<bool> {
    let mut conn = Connection::open(config::get_playlist_db_path())?;
    let tx = conn.transaction()?;
    let removed = tx.execute(
        "DELETE FROM tracks
         WHERE rowid = (
             SELECT rowid FROM tracks
             WHERE playlist_id = ?1 AND uri = ?2
             LIMIT 1
         )",
        params![playlist_id, track_uri],
    )?;
    if removed > 0 {
        let mtime = get_mtime();
        tx.execute(
            "UPDATE playlists SET mtime = ?1 WHERE id = ?2",
            params![mtime, playlist_id],
        )?;
    }
    tx.commit()?;
    Ok(removed > 0)
}
