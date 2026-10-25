use crate::models::{PlaylistWithTracks, UserPlaylist};
use crate::utils::config;
use rusqlite::{Connection, Result, params, params_from_iter};
use std::time::{SystemTime, UNIX_EPOCH};

/* ─────────────────────────── DB Initialize ─────────────────────────── */
const CREATE_PLAYLISTS: &str = "
CREATE TABLE IF NOT EXISTS playlists (id INTEGER PRIMARY KEY,
                    name TEXT NOT NULL UNIQUE,
                        smart_enabled INT NOT NULL DEFAULT 0,
                        smart_sql TEXT,
                        mtime BIGINT NOT NULL);
";
const INSERT_INTO_PLAYLISTS: &str = "
INSERT INTO playlists (name, smart_enabled, smart_sql, mtime) VALUES (?1, ?2, ?3, ?4);";

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
    tx.execute(INSERT_INTO_PLAYLISTS, params![name, "0", "", mtime])?;
    let playlist_id: i64 = tx.last_insert_rowid();
    for uri in uris {
        tx.execute(INSERT_INTO_TRACKS, params![&playlist_id, uri])?;
    }
    tx.commit()?;
    Ok(playlist_id)
}

pub fn get_playlists_with_tracks() -> Result<Vec<PlaylistWithTracks>> {
    let conn = Connection::open(config::get_playlist_db_path())?;
    let mut stmt =
        conn.prepare("SELECT id, name, smart_enabled, smart_sql, mtime FROM playlists")?;

    let playlists = stmt.query_map([], |row| {
        Ok(UserPlaylist {
            id: row.get(0)?,
            name: row.get(1)?,
            smart_enabled: row.get::<_, i32>(2)? != 0,
            smart_sql: row.get(3)?,
            mtime: row.get(4)?,
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
