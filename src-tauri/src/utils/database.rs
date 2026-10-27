use rusqlite::{Connection, Result, params, params_from_iter};
extern crate dirs;
use crate::models::{
    AlbumGroup, AlbumInfo, AlbumTrack, Artist, ArtistAlbum, ArtistStats, BasicAlbum, BasicTrack,
    IdMtime, NameIdMap, Stats, Track, TrackInfo, TrackItem, TracksMetaMap,
};
use crate::utils::config;

/* ─────────────────────────── DB Initialize ─────────────────────────── */
const CREATE_ALBUMS: &str = "
CREATE TABLE IF NOT EXISTS albums (id INTEGER PRIMARY KEY,
                    name TEXT NOT NULL UNIQUE,
                    year INT,
                    loved INT NOT NULL DEFAULT 0,
                    popularity INT NOT NULL DEFAULT 0,
                    mtime INT NOT NULL);
";
const CREATE_ARTISTS: &str = "
CREATE TABLE IF NOT EXISTS artists (id INTEGER PRIMARY KEY, name TEXT NOT NULL UNIQUE);
";
const CREATE_TRACKS: &str = "
CREATE TABLE IF NOT EXISTS tracks (id INTEGER PRIMARY KEY,
                    name TEXT NOT NULL,
                    uri TEXT NOT NULL,
                    duration INT,
                    album_id INT NOT NULL,
                    year INT,
                    popularity INT NOT NULL DEFAULT 0,
                    mtime INT NOT NULL);
";
const CREATE_ALBUM_ARTISTS: &str = "
CREATE TABLE IF NOT EXISTS album_artists (album_id INT NOT NULL, artist_id INT NOT NULL);
";
const CREATE_TRACK_ARTISTS: &str = "
CREATE TABLE IF NOT EXISTS track_artists (track_id INT NOT NULL, artist_id INT NOT NULL);
";

const CREATE_INDEX_ALBUM_ARTISTS: &str = "
CREATE INDEX IF NOT EXISTS idx_aa ON album_artists(album_id);
";

const CREATE_INDEX_TRACK_ARTISTS: &str = "
CREATE INDEX IF NOT EXISTS idx_ta ON track_artists(track_id);
";

const INSERT_INTO_ALBUMS: &str = "
INSERT INTO albums (name, year, mtime) VALUES (?1, ?2, ?3);
";

const INSERT_INTO_ARTISTS: &str = "
INSERT INTO artists (name) VALUES (?1);
";

const INSERT_INTO_TRACKS: &str = "
INSERT INTO tracks (name, uri, duration, year, mtime, album_id) VALUES (?1, ?2, ?3, ?4, ?5, ?6);
";

const INSERT_INTO_ALBUM_ARTISTS: &str = "
INSERT INTO album_artists (album_id, artist_id) VALUES (?1, ?2);
";

const INSERT_INTO_TRACK_ARTISTS: &str = "
INSERT INTO track_artists (track_id, artist_id) VALUES (?1, ?2);
";

pub fn initialize() -> Result<()> {
    let conn = Connection::open(config::get_db_path())?;
    let sql = format!(
        "{}{}{}{}{}{}{}",
        CREATE_ALBUMS,
        CREATE_ARTISTS,
        CREATE_ALBUM_ARTISTS,
        CREATE_TRACKS,
        CREATE_TRACK_ARTISTS,
        CREATE_INDEX_ALBUM_ARTISTS,
        CREATE_INDEX_TRACK_ARTISTS
    );

    conn.execute_batch(&sql)?;
    Ok(())
}
fn make_query_ids(n: usize) -> String {
    (1..=n)
        .map(|num| format!("?{}", num))
        .collect::<Vec<String>>()
        .join(", ")
}

/* ───────────────────────────── DB Inserts ───────────────────────────── */
pub fn add_album(conn: &Connection, album: AlbumInfo) -> Result<i64> {
    conn.execute(
        INSERT_INTO_ALBUMS,
        params![album.name, album.year, album.mtime],
    )?;
    Ok(conn.last_insert_rowid())
}

pub fn add_artist(conn: &Connection, name: &str) -> Result<i64> {
    conn.execute(INSERT_INTO_ARTISTS, params![name])?;
    Ok(conn.last_insert_rowid())
}

pub fn add_track(conn: &Connection, track: &TrackInfo, uri: &str, album_id: i64) -> Result<i64> {
    conn.execute(
        INSERT_INTO_TRACKS,
        params![
            track.name,
            uri,
            track.duration,
            track.year,
            track.mtime,
            album_id
        ],
    )?;
    Ok(conn.last_insert_rowid())
}

pub fn add_album_artist(conn: &Connection, album_id: &i64, artist_id: i64) -> Result<i64> {
    conn.execute(INSERT_INTO_ALBUM_ARTISTS, params![album_id, artist_id])?;
    Ok(conn.last_insert_rowid())
}

pub fn add_track_artist(conn: &Connection, track_id: i64, artist_id: i64) -> Result<i64> {
    conn.execute(INSERT_INTO_TRACK_ARTISTS, params![track_id, artist_id])?;
    Ok(conn.last_insert_rowid())
}

/* ───────────────────────────── DB Fetchs ───────────────────────────── */
pub fn tracks_is_empty() -> Result<bool> {
    let conn = Connection::open(config::get_db_path())?;
    let count: i32 = conn.query_row("SELECT COUNT(1) FROM tracks LIMIT 1", [], |row| row.get(0))?;
    Ok(count == 0)
}

pub fn get_tracks_meta_map(conn: &Connection) -> Result<TracksMetaMap> {
    let mut stmt = conn.prepare("SELECT id, uri, mtime FROM tracks")?;
    let tracks = stmt
        .query_map([], |row| {
            Ok((
                row.get::<_, String>(1)?,
                IdMtime {
                    id: row.get(0)?,
                    mtime: row.get(2)?,
                },
            ))
        })?
        .collect::<Result<TracksMetaMap>>()?;

    Ok(tracks)
}

pub fn get_albums_id_map() -> Result<NameIdMap> {
    let conn = Connection::open(config::get_db_path())?;
    let mut stmt = conn.prepare("SELECT id, name FROM albums")?;
    let albums = stmt
        .query_map([], |row| Ok((row.get::<_, String>(1)?, row.get(0)?)))?
        .collect::<Result<NameIdMap>>()?;
    Ok(albums)
}

pub fn get_artists_id_map() -> Result<NameIdMap> {
    let conn = Connection::open(config::get_db_path())?;
    let mut stmt = conn.prepare("SELECT id, name FROM artists")?;
    let artists = stmt
        .query_map([], |row| Ok((row.get::<_, String>(1)?, row.get(0)?)))?
        .collect::<Result<NameIdMap>>()?;
    Ok(artists)
}

pub fn find_track_by_uri(uri: &str) -> Option<Track> {
    let conn = Connection::open(config::get_db_path()).expect("Failed to open db");
    conn.query_one(
        "SELECT 
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
             WHERE t.uri = ?1
             GROUP BY t.id, t.name, t.uri, t.duration, t.popularity, a.name",
        params![uri],
        |row| {
            Ok(Track {
                id: row.get(0)?,
                name: row.get(1)?,
                uri: row.get(2)?,
                duration: row.get(3)?,
                popularity: row.get(4)?,
                album: row.get(5)?,
                artist: row.get(6)?,
            })
        },
    )
    .ok()
}

pub fn find_basic_track_by_uri(uri: &str) -> Option<BasicTrack> {
    let conn = Connection::open(config::get_db_path()).expect("Failed to open db");
    conn.query_one(
        "SELECT 
               t.name AS track_name,
               a.name AS album_name,
             GROUP_CONCAT(ar.name, ', ') AS artists
             FROM tracks t
             JOIN albums a ON t.album_id = a.id
             LEFT JOIN track_artists ta ON t.id = ta.track_id
             LEFT JOIN artists ar ON ta.artist_id = ar.id
             WHERE t.uri = ?1
             GROUP BY t.id, t.name, a.name;",
        params![uri],
        |row| {
            Ok(BasicTrack {
                name: row.get(0)?,
                album: row.get(1)?,
                artist: row.get(2)?,
            })
        },
    )
    .ok()
}

pub fn find_track_uri_by_id(id: i64) -> Option<String> {
    let conn = Connection::open(config::get_db_path()).expect("Failed to open db");
    conn.query_one("SELECT uri FROM tracks WHERE id = ?1", params![id], |row| {
        Ok(row.get(0)?)
    })
    .ok()
}

// pub fn find_artist_id_by_name(name: &str) -> Option<i64> {
//     let conn = Connection::open(config::get_db_path()).expect("Failed to open db");
//     conn.query_row(
//         "SELECT id FROM artists WHERE name = ?1",
//         params![name],
//         |row| Ok(row.get(0)?),
//     )
//     .ok()
// }

/// Album that does not belong to any track
pub fn find_albums_without_tracks(conn: &Connection) -> Result<Vec<i64>> {
    let mut stmt = conn.prepare(
        "SELECT a.id FROM albums a 
         WHERE NOT EXISTS (SELECT 1 FROM tracks t WHERE t.album_id = a.id);",
    )?;
    let album_ids = stmt
        .query_map([], |row| row.get(0))?
        .collect::<Result<Vec<i64>, _>>()?;

    Ok(album_ids)
}

/// Artist that does not belong to any track
pub fn find_artists_without_tracks(conn: &Connection) -> Result<Vec<i64>> {
    let mut stmt = conn.prepare(
        "SELECT ar.id
                 FROM artists ar
                 WHERE ar.id NOT IN (SELECT DISTINCT artist_id FROM track_artists)
                 ORDER BY ar.name ASC",
    )?;
    let artist_ids = stmt
        .query_map([], |row| row.get(0))?
        .collect::<Result<Vec<i64>, _>>()?;

    Ok(artist_ids)
}

pub fn get_stats() -> Result<Stats> {
    let conn = Connection::open(config::get_db_path())?;
    conn.query_row(
        "SELECT 
             (SELECT COUNT(*) FROM tracks) AS track_count,
             (SELECT COUNT(*) FROM albums) AS album_count,
             (SELECT COUNT(*) FROM artists) AS artist_count",
        [],
        |row| {
            Ok(Stats {
                tracks: row.get(0)?,
                albums: row.get(1)?,
                artists: row.get(2)?,
            })
        },
    )
}

pub fn is_album_loved(album_id: i64) -> Result<bool> {
    let conn = Connection::open(config::get_db_path())?;
    let loved = conn.query_row(
        "SELECT loved FROM albums WHERE id = ?",
        params![album_id],
        |row| row.get::<_, i32>(0).map(|v| v != 0),
    )?;
    Ok(loved)
}

pub fn get_all_tracks_grouped_by_album() -> Result<Vec<Track>> {
    let conn = Connection::open(config::get_db_path())?;
    let query = "SELECT 
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
             GROUP BY t.id, t.name, t.uri, t.duration, t.popularity, a.name, a.id
             ORDER BY a.name ASC, t.name ASC";

    let mut stmt = conn.prepare(query)?;
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

pub fn get_top_10_tracks() -> Result<Vec<Track>> {
    let conn = Connection::open(config::get_db_path())?;
    let mut stmt = conn.prepare(
        "SELECT 
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
             GROUP BY t.id, t.name, t.uri, t.duration, t.popularity, a.name
             ORDER BY t.popularity DESC
             LIMIT 10",
    )?;
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

pub fn get_tracks_by_uris(uris: Vec<String>) -> Result<Vec<Track>> {
    let conn = Connection::open(config::get_db_path())?;
    let joined_ids = make_query_ids(uris.len());
    let case_parts: Vec<String> = (0..uris.len())
        .map(|i| format!("WHEN t.uri = ? THEN {}", i))
        .collect();
    let cte = format!("CASE {} ELSE {} END", case_parts.join(" "), uris.len());
    let query = format!(
        "SELECT 
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
             WHERE t.uri in ({})
             GROUP BY t.id, t.name, t.uri, t.duration, t.popularity, a.name
             ORDER BY {}",
        joined_ids, cte
    );

    // Bind uris twice: once for WHERE IN, once for CASE WHEN
    let mut params: Vec<&str> = uris.iter().map(|s| s.as_str()).collect();
    params.extend(params.clone());

    let mut stmt = conn.prepare(&query)?;
    let tracks = stmt
        .query_map(params_from_iter(params), |row| {
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

fn albums_query(limit: Option<usize>, order: Option<String>) -> String {
    let order_by = order.unwrap_or("a.popularity DESC".into());
    let limit = limit.map(|n| format!("\nLIMIT {}", n)).unwrap_or("".into());
    format!(
        "SELECT 
          a.id,
          a.name AS album_name,
          a.year,
          a.popularity,
          (SELECT GROUP_CONCAT(ar.name, ', ')
          FROM (
          SELECT DISTINCT aa.artist_id
          FROM album_artists aa
          WHERE aa.album_id = a.id
          ) AS unique_artists
          JOIN artists ar ON unique_artists.artist_id = ar.id
          ) AS artists
        FROM albums a
        ORDER BY {}{}",
        order_by, limit
    )
}

fn n_albums_query(num: usize, order: Option<String>) -> String {
    albums_query(Some(num), order.or(Some("a.popularity DESC".into())))
}

fn top_n_albums_query(num: usize) -> String {
    n_albums_query(num, None)
}
fn random_n_albums_query(num: usize) -> String {
    n_albums_query(num, Some("RANDOM()".into()))
}
fn recent_n_albums_query(num: usize) -> String {
    n_albums_query(num, Some("a.mtime DESC".into()))
}

fn get_albums(sql: &str) -> Result<Vec<BasicAlbum>> {
    let conn = Connection::open(config::get_db_path())?;
    let mut stmt = conn.prepare(sql)?;
    let albums = stmt
        .query_map([], |row| {
            Ok(BasicAlbum {
                id: row.get(0)?,
                name: row.get(1)?,
                year: row.get(2)?,
                artist: row.get(4)?,
            })
        })?
        .collect::<Result<Vec<BasicAlbum>, _>>()?;
    Ok(albums)
}

pub fn get_top_n_albums(num: usize) -> Result<Vec<BasicAlbum>> {
    get_albums(&top_n_albums_query(num))
}

pub fn get_random_n_albums(num: usize) -> Result<Vec<BasicAlbum>> {
    get_albums(&random_n_albums_query(num))
}

pub fn get_recent_n_albums(num: usize) -> Result<Vec<BasicAlbum>> {
    get_albums(&recent_n_albums_query(num))
}

pub fn get_all_albums() -> Result<Vec<BasicAlbum>> {
    get_albums(&albums_query(None, Some("artists ASC".into())))
}

pub fn get_loved_albums() -> Result<Vec<BasicAlbum>> {
    let conn = Connection::open(config::get_db_path())?;
    let mut stmt = conn.prepare(
        "SELECT 
          a.id,
          a.name,
          a.year,
          a.loved,
          a.popularity,
          (SELECT GROUP_CONCAT(ar.name, ', ')
           FROM (
             SELECT DISTINCT aa.artist_id
             FROM album_artists aa
             WHERE aa.album_id = a.id
           ) AS unique_artists
           JOIN artists ar ON unique_artists.artist_id = ar.id
          ) AS artists
        FROM albums a
        WHERE a.loved = 1
        ORDER BY a.popularity DESC",
    )?;

    let albums = stmt
        .query_map([], |row| {
            Ok(BasicAlbum {
                id: row.get(0)?,
                name: row.get(1)?,
                year: row.get(2)?,
                artist: row.get(5)?,
            })
        })?
        .collect::<Result<Vec<_>, _>>()?;

    Ok(albums)
}

pub fn get_track_uris_by_albums(ids: Vec<i64>) -> Result<Vec<(String, i64)>> {
    if ids.is_empty() {
        return Ok(Vec::new());
    }
    let joined_ids = make_query_ids(ids.len());
    let cte_rows = ids
        .iter()
        .enumerate()
        .map(|(idx, id)| format!("SELECT {} AS id, {} AS sort_order", id, idx))
        .collect::<Vec<_>>()
        .join(" UNION ALL ");

    let query = format!(
        r#"
        WITH album_order AS ({})
        SELECT 
          t.uri,
          t.album_id
        FROM albums a
        JOIN tracks t ON a.id = t.album_id
        JOIN album_order ao ON a.id = ao.id
        WHERE a.id IN ({})
        ORDER BY ao.sort_order, t.name;
"#,
        cte_rows, joined_ids
    );

    let conn = Connection::open(config::get_db_path())?;
    let mut stmt = conn.prepare(&query)?;
    let tracks = stmt
        .query_map(params_from_iter(ids), |row| Ok((row.get(0)?, row.get(1)?)))?
        .collect::<Result<Vec<(String, i64)>, _>>()?;
    Ok(tracks)
}

pub fn get_tracks_by_albums(ids: Vec<i64>) -> Result<Vec<Track>> {
    if ids.is_empty() {
        return Ok(Vec::new());
    }
    let joined_ids = make_query_ids(ids.len());
    let cte_rows = ids
        .iter()
        .enumerate()
        .map(|(idx, id)| format!("SELECT {} AS id, {} AS sort_order", id, idx))
        .collect::<Vec<_>>()
        .join(" UNION ALL ");

    let query = format!(
        r#"
        WITH album_order AS ({})
        SELECT 
          a.id AS album_id,
          a.name AS album_name,
          t.id AS track_id,
          t.name AS track_name,
          t.uri,
          t.duration,
          t.popularity,
          (SELECT GROUP_CONCAT(name, ', ')
           FROM (
             SELECT ar.name
             FROM track_artists ta
             JOIN artists ar ON ta.artist_id = ar.id
             WHERE ta.track_id = t.id
             GROUP BY ar.name
           )
          ) AS artists
        FROM albums a
        JOIN tracks t ON a.id = t.album_id
        JOIN album_order ao ON a.id = ao.id
        WHERE a.id IN ({})
        ORDER BY ao.sort_order, t.name;
        "#,
        cte_rows, joined_ids
    );

    let conn = Connection::open(config::get_db_path())?;
    let mut stmt = conn.prepare(&query)?;
    let tracks = stmt
        .query_map(params_from_iter(ids), |row| {
            Ok(Track {
                id: row.get(2)?,
                name: row.get(3)?,
                uri: row.get(4)?,
                duration: row.get(5)?,
                popularity: row.get(6)?,
                album: row.get(1)?,
                artist: row.get(7)?,
            })
        })?
        .collect::<Result<Vec<Track>, _>>()?;
    Ok(tracks)
}

pub fn get_all_artists() -> Result<Vec<Artist>> {
    let conn = Connection::open(config::get_db_path())?;
    let mut stmt = conn.prepare("SELECT a.id, a.name FROM artists a ORDER BY a.name ASC")?;

    let artists = stmt
        .query_map([], |row| {
            Ok(Artist {
                id: row.get(0)?,
                name: row.get(1)?,
            })
        })?
        .collect::<Result<Vec<_>, _>>()?;

    Ok(artists)
}

pub fn get_random_album_name_by_artist_id(artist_id: i64) -> Result<Option<String>> {
    let conn = Connection::open(config::get_db_path())?;
    let mut stmt = conn.prepare(
        "SELECT 
          a.id,
          a.name AS album_name
        FROM albums a
        WHERE a.id IN (
          SELECT DISTINCT aa.album_id
          FROM album_artists aa
          WHERE aa.artist_id = ?
        )
        ORDER BY RANDOM()
        LIMIT 1",
    )?;

    let name = stmt.query_row([artist_id], |row| Ok(row.get(1)?)).ok();
    Ok(name)
}

pub fn get_artist_stats(artist_id: i64) -> Result<Option<ArtistStats>> {
    let conn = Connection::open(config::get_db_path())?;
    let mut stmt = conn.prepare(
        "SELECT 
          ar.id,
          ar.name,
          (SELECT COUNT(DISTINCT aa.album_id)
           FROM album_artists aa
           WHERE aa.artist_id = ar.id
          ) AS album_count,
          (SELECT COUNT(DISTINCT ta.track_id)
           FROM track_artists ta
           WHERE ta.artist_id = ar.id
          ) AS track_count
        FROM artists ar
        WHERE ar.id = ?",
    )?;

    let artist = stmt
        .query_row([artist_id], |row| {
            Ok(ArtistStats {
                id: row.get(0)?,
                name: row.get(1)?,
                album_count: row.get(2)?,
                track_count: row.get(3)?,
            })
        })
        .ok();

    Ok(artist)
}

pub fn get_one_track_per_album() -> Result<Vec<AlbumTrack>> {
    let conn = Connection::open(config::get_db_path())?;
    let mut stmt = conn.prepare(
        "SELECT 
          a.id,
          a.name,
          t.uri
        FROM albums a
        JOIN tracks t ON a.id = t.album_id
        WHERE t.id = (
          SELECT id FROM tracks 
          WHERE album_id = a.id 
          LIMIT 1
        )",
    )?;

    let tracks = stmt
        .query_map([], |row| {
            Ok(AlbumTrack {
                album_id: row.get(0)?,
                album_name: row.get(1)?,
                track_uri: row.get(2)?,
            })
        })?
        .collect::<Result<Vec<_>, _>>()?;

    Ok(tracks)
}

pub fn get_albums_by_artist_id(artist_id: i64) -> Result<Vec<ArtistAlbum>> {
    let conn = Connection::open(config::get_db_path())?;
    let mut stmt = conn.prepare(
        "SELECT DISTINCT
          a.id,
          a.name,
          a.year,
          a.mtime
        FROM albums a
        JOIN album_artists aa ON a.id = aa.album_id
        WHERE aa.artist_id = ?
        ORDER BY a.year DESC, a.mtime DESC",
    )?;

    let albums = stmt
        .query_map([artist_id], |row| {
            Ok(ArtistAlbum {
                id: row.get(0)?,
                name: row.get(1)?,
                year: row.get(2)?,
                mtime: row.get(3)?,
            })
        })?
        .collect::<Result<Vec<_>, _>>()?;

    Ok(albums)
}

pub fn search_tracks_grouped(query: &str) -> Result<Vec<AlbumGroup>> {
    let conn = Connection::open(config::get_db_path())?;
    let search_pattern = format!("%{}%", query);

    let mut stmt = conn.prepare(
        "SELECT a.id, a.name, a.year, a.mtime,
                (SELECT GROUP_CONCAT(ar.name, ', ')
                 FROM (SELECT DISTINCT aa.artist_id FROM album_artists aa WHERE aa.album_id = a.id)
                 JOIN artists ar ON ar.id = artist_id),
                GROUP_CONCAT(t.uri || '|' || t.name || '|' || t.duration, ';;')
        FROM tracks t
        JOIN albums a ON t.album_id = a.id
        WHERE t.name LIKE ?
           OR a.name LIKE ?
           OR EXISTS (SELECT 1 FROM track_artists ta 
                      JOIN artists ar ON ar.id = ta.artist_id 
                      WHERE ta.track_id = t.id AND ar.name LIKE ?)
        GROUP BY a.id, a.name, a.year, a.mtime
        ORDER BY a.year DESC, a.mtime DESC",
    )?;

    let mut results = stmt
        .query_map([&search_pattern, &search_pattern, &search_pattern], |row| {
            let album_name: String = row.get(1)?;
            let tracks_str: String = row.get(5)?;
            let tracks = tracks_str
                .split(";;")
                .map(|pair| {
                    let parts: Vec<&str> = pair.split('|').collect();
                    TrackItem {
                        uri: parts.get(0).unwrap_or(&"").to_string(),
                        name: parts.get(1).unwrap_or(&"").to_string(),
                        duration: parts
                            .get(2)
                            .unwrap_or(&"")
                            .to_string()
                            .parse::<i64>()
                            .unwrap_or(0),
                    }
                })
                .collect();

            Ok(AlbumGroup {
                id: row.get(0)?,
                name: album_name,
                artists: row.get(4)?,
                tracks,
            })
        })?
        .collect::<Result<Vec<_>, _>>()?;

    results.sort_by(|a, b| AlbumGroup::cmp_by_query(query, a, b));
    Ok(results)
}

pub fn get_album_groups_from_uris(uris: Vec<String>) -> Vec<AlbumGroup> {
    let tracks = get_tracks_by_uris(uris).unwrap();
    let mut groups: Vec<AlbumGroup> = Vec::new();
    let mut group_tracks: Vec<Track> = Vec::new();

    for track in tracks {
        if let Some(last_track) = group_tracks.last() {
            if last_track.album == track.album {
                group_tracks.push(track);
            } else {
                groups.push(AlbumGroup {
                    id: last_track.id.clone(), // should be album id, but its fine
                    name: last_track.album.clone(),
                    artists: last_track.artist.clone(),
                    tracks: group_tracks
                        .iter()
                        .map(|t| TrackItem {
                            name: t.name.clone(),
                            uri: t.uri.clone(),
                            duration: t.duration.clone(),
                        })
                        .collect(),
                });
                group_tracks.clear();
                group_tracks.push(track);
            }
        } else {
            group_tracks.push(track);
        }
    }
    if let Some(last_track) = group_tracks.last() {
        groups.push(AlbumGroup {
            id: last_track.id.clone(), // should be album id, but its fine/uniq
            name: last_track.album.clone(),
            artists: last_track.artist.clone(),
            tracks: group_tracks
                .iter()
                .map(|t| TrackItem {
                    name: t.name.clone(),
                    uri: t.uri.clone(),
                    duration: t.duration.clone(),
                })
                .collect(),
        });
        // group_tracks.clear();
    }
    groups
}

/* ───────────────────────────── DB Updates ───────────────────────────── */
pub fn update_track_by_id(
    conn: &Connection,
    id: i64,
    track: &TrackInfo,
    album_id: i64,
) -> Result<()> {
    conn.execute(
        "UPDATE tracks SET name = ?2, duration = ?3, year = ?4, mtime = ?5, album_id = ?6 WHERE id = ?1",
        params![
            id,
            track.name,
            track.duration,
            track.year,
            track.mtime,
            album_id
        ],
    )?;
    Ok(())
}

pub fn increment_track_and_album_popularity_by_uri(uri: &str) -> Result<()> {
    let conn = Connection::open(config::get_db_path())?;
    conn.execute(
        "UPDATE tracks SET popularity = popularity + 1 WHERE uri = ?;",
        params![uri],
    )?;
    conn.execute(
        "UPDATE albums 
         SET popularity = popularity + (
         SELECT CASE 
           WHEN COUNT(*) > 2 THEN ROUND(1.0 / COUNT(*) * 50 + 0.5)
           ELSE ROUND(1.0 / COUNT(*) * 25 + 0.5)
         END
         FROM tracks
         WHERE album_id = albums.id
        )
        WHERE id = (SELECT album_id FROM tracks WHERE uri = ?);",
        params![uri],
    )?;
    Ok(())
}

pub fn set_album_loved_by_id(album_id: i64, loved: bool) -> Result<()> {
    let conn = Connection::open(config::get_db_path())?;
    conn.execute(
        "UPDATE albums SET loved = ? WHERE id = ?",
        params![loved as i64, album_id],
    )?;
    Ok(())
}

/* ───────────────────────────── DB Deletes ───────────────────────────── */
pub fn delete_track_artists_by_track_id(conn: &Connection, track_id: i64) -> Result<()> {
    conn.execute(
        "DELETE FROM track_artists WHERE track_id = ?1",
        params![track_id],
    )?;
    Ok(())
}

fn delete_many(conn: &Connection, kind: &str, col: &str, ids: &[i64]) -> Result<usize> {
    if ids.is_empty() {
        return Ok(0);
    }
    let joined_ids = make_query_ids(ids.len());
    let query = format!("DELETE FROM {} WHERE {} IN ({})", kind, col, joined_ids);
    let mut stmt = conn.prepare(&query)?;
    let deleted = stmt.execute(params_from_iter(ids))?;

    Ok(deleted)
}

fn delete_many_via_id(conn: &Connection, kind: &str, ids: &[i64]) -> Result<usize> {
    delete_many(&conn, kind, "id", ids)
}

pub fn delete_many_track_artist_ids(conn: &Connection, ids: &[i64]) -> Result<usize> {
    delete_many(&conn, "track_artists", "track_id", ids)
}

pub fn delete_many_tracks(conn: &Connection, track_ids: &[i64]) -> Result<usize> {
    delete_many_via_id(&conn, "tracks", track_ids)
}

pub fn delete_many_albums(conn: &Connection, album_ids: &[i64]) -> Result<usize> {
    delete_many_via_id(&conn, "albums", album_ids)
}

pub fn delete_many_album_artist_ids(conn: &Connection, ids: &[i64]) -> Result<usize> {
    delete_many(&conn, "album_artists", "album_id", ids)
}

pub fn delete_many_artists(conn: &Connection, artist_ids: &[i64]) -> Result<usize> {
    delete_many_via_id(&conn, "artists", artist_ids)
}
