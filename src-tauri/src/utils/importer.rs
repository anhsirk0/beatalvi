use crate::models::{AlbumInfo, CoverSize, NameIdMap};
use crate::utils::config;
use crate::utils::database;
use crate::utils::reader;
use rayon::prelude::*;
use rusqlite::{Connection, Result};
use std::{
    collections::HashMap,
    error::Error,
    fs::File,
    io::Write,
    path::{Path, PathBuf},
};
use url::Url;

fn add_artists_if_not_exits(
    conn: &Connection,
    artist: &String,
    artists_map: &mut NameIdMap,
) -> Result<Vec<i64>, Box<dyn Error>> {
    let artists = artist.split(",");
    let mut artist_ids = vec![];

    for name in artists.map(|s| s.trim().to_string()) {
        if let Some(id) = artists_map.get(&name) {
            artist_ids.push(id.clone());
        } else {
            let artist_id = database::add_artist(&conn, &name)?;
            artists_map.insert(name, artist_id);
            artist_ids.push(artist_id);
        }
    }

    Ok(artist_ids)
}

fn add_albums_if_not_exits(
    conn: &Connection,
    info: AlbumInfo,
    albums_map: &mut NameIdMap,
) -> Result<(), Box<dyn Error>> {
    let name = info.name.clone();
    if !albums_map.contains_key(&name) {
        let album_id = database::add_album(conn, info)?;
        albums_map.insert(name, album_id);
    }
    Ok(())
}

fn delete_tracks_and_related_stuff(conn: &Connection, ids: &[i64]) -> Result<()> {
    let _ = database::delete_many_tracks(&conn, &ids)?;
    let album_ids = database::find_albums_without_tracks(&conn)?;
    let _ = database::delete_many_albums(&conn, &album_ids)?;
    let _ = database::delete_many_album_artist_ids(&conn, &album_ids)?;
    let artist_ids = database::find_artists_without_tracks(&conn)?;
    let _ = database::delete_many_artists(&conn, &artist_ids)?;
    let _ = database::delete_many_track_artist_ids(&conn, &ids)?;
    Ok(())
}

fn get_album_cover_art_path(album: &str, cover_size: &CoverSize) -> PathBuf {
    config::get_cache_dir().join(cover_size.name(album))
}

pub fn get_new_or_updated_tracks_files(
    conn: &Connection,
    files: Vec<String>,
) -> Result<Vec<String>, Box<dyn Error>> {
    let tracks_meta_map = database::get_tracks_meta_map(&conn)?;
    let filtered = files.iter().filter(|&f| {
        let path = PathBuf::from(f);
        let meta = reader::get_track_meta(&path).expect("Failed: get_track_meta");
        let uri = meta.uri.clone();

        if let Some(db_track_meta) = tracks_meta_map.get(&uri) {
            db_track_meta.mtime != meta.mtime
        } else {
            true
        }
    });

    Ok(filtered.cloned().collect())
}

// import everything (for new db)
pub fn import_all(files: Vec<String>) -> Result<(usize, usize, usize), Box<dyn Error>> {
    let mut tracks_count: usize = 0;
    let conn = Connection::open(config::get_db_path())?;
    let info_map = reader::get_info_map(files)?;
    let mut albums_map: HashMap<String, i64> = HashMap::new();
    let mut artists_map: HashMap<String, i64> = HashMap::new();

    for entry in info_map.iter() {
        let uri = entry.key().clone();
        let info = entry.value();

        add_albums_if_not_exits(
            &conn,
            AlbumInfo {
                name: info.album.clone(),
                year: info.year,
                mtime: info.mtime,
            },
            &mut albums_map,
        )?;

        let artist_ids = add_artists_if_not_exits(&conn, &info.artist, &mut artists_map)?;

        if let Some(album_id) = albums_map.get(&info.album) {
            let track_id = database::add_track(&conn, info, &uri, *album_id)?;
            tracks_count = tracks_count + 1;
            for id in artist_ids {
                let _ = database::add_track_artist(&conn, track_id, id)?;
                let _ = database::add_album_artist(&conn, album_id, id)?;
            }
        }
    }

    Ok((tracks_count, albums_map.len(), artists_map.len()))
}

pub fn import_and_update(files: Vec<String>) -> Result<(usize, usize, usize), Box<dyn Error>> {
    let mut tracks_count: usize = 0;
    let conn = Connection::open(config::get_db_path())?;
    let tracks_meta_map = database::get_tracks_meta_map(&conn)?;
    let mut albums_map = database::get_albums_id_map()?;
    let mut artists_map = database::get_artists_id_map()?;

    let new_or_updated_files = get_new_or_updated_tracks_files(&conn, files.clone())?;
    let info_map = reader::get_info_map(new_or_updated_files)?;

    for entry in info_map.iter() {
        let uri = entry.key().clone();
        let info = entry.value();

        add_albums_if_not_exits(
            &conn,
            AlbumInfo {
                name: info.album.clone(),
                year: info.year,
                mtime: info.mtime,
            },
            &mut albums_map,
        )?;

        let artist_ids = add_artists_if_not_exits(&conn, &info.artist, &mut artists_map)?;

        // Check meta from db to compare mtime
        if let Some(db_track_meta) = tracks_meta_map.get(&uri) {
            if let Some(album_id) = albums_map.get(&info.album) {
                let _ = database::update_track_by_id(&conn, db_track_meta.id, info, *album_id)?;
                let _ = database::delete_track_artists_by_track_id(&conn, db_track_meta.id)?;
                for id in artist_ids {
                    let _ = database::add_track_artist(&conn, db_track_meta.id, id)?;
                    let _ = database::add_album_artist(&conn, album_id, id)?;
                }
            }
        } else {
            if let Some(album_id) = albums_map.get(&info.album) {
                let track_id = database::add_track(&conn, info, &uri, *album_id)?;
                tracks_count = tracks_count + 1;
                for id in artist_ids {
                    let _ = database::add_track_artist(&conn, track_id, id)?;
                    let _ = database::add_album_artist(&conn, album_id, id)?;
                }
            }
        }
    }

    // Delete deleted track stuff
    let _ = remove_deleted_tracks(files, &conn)?;

    Ok((tracks_count, albums_map.len(), artists_map.len()))
}

pub fn remove_deleted_tracks(
    files: Vec<String>,
    conn: &Connection,
) -> Result<usize, Box<dyn Error>> {
    let tracks_meta_map = database::get_tracks_meta_map(&conn)?;
    let map: HashMap<String, bool> = files
        .into_iter()
        .map(|f| {
            let uri = Url::from_file_path(f).unwrap().to_string();
            (uri, true)
        })
        .collect();

    let removed_ids: Vec<i64> = tracks_meta_map
        .iter()
        .filter(|(key, _)| !map.contains_key(*key))
        .map(|(_key, value)| value.id)
        .collect();

    if removed_ids.len() > 0 {
        delete_tracks_and_related_stuff(&conn, &removed_ids)?;
    }
    Ok(removed_ids.len())
}

fn store_album_cover_from_uri(
    track_uri: &str,
    album_path: &Path,
    cover_size: &CoverSize,
) -> Result<Vec<u8>, Box<dyn Error>> {
    let uri = Url::parse(&track_uri).unwrap();
    let track_path = uri.to_file_path().expect("Failed to get path from uri");
    match reader::get_cover_art_bytes_from_path(&track_path, cover_size) {
        Ok(buf) => {
            let mut out_file = File::create(&album_path).unwrap();
            out_file.write_all(&buf).unwrap();
            Ok(buf)
        }
        Err(e) => Err(e)?,
    }
}

pub fn get_and_set_cover_art(
    album: &str,
    track_uri: &str,
    cover_size: &CoverSize,
) -> Result<Vec<u8>, Box<dyn Error>> {
    let path = get_album_cover_art_path(album, &cover_size);
    if path.exists() {
        Ok(std::fs::read(&path).expect("Failed to read"))
    } else {
        let buf = store_album_cover_from_uri(&track_uri, &path, cover_size)?;
        Ok(buf)
    }
}

pub fn get_cover_art(album: &str, cover_size: &CoverSize) -> Result<Vec<u8>, Box<dyn Error>> {
    let path = get_album_cover_art_path(album, cover_size);
    Ok(std::fs::read(&path)?)
}

pub fn generate_cover_art_cache() -> Result<(), Box<dyn Error>> {
    let album_tracks = database::get_one_track_per_album()?;
    let sizes: Vec<CoverSize> = vec![CoverSize::Small, CoverSize::Medium, CoverSize::Large];

    album_tracks.par_iter().for_each(|item| {
        sizes.par_iter().for_each(|size| {
            let path = config::get_cache_dir().join(size.name(&item.album_name));
            if !path.exists() {
                if let Err(e) = store_album_cover_from_uri(&item.track_uri, &path, size) {
                    eprintln!("Failed to store album cover: {}", e);
                }
            }
        });
        // let cover_name_sm = format!("{}_sm.jpg", slugify(&item.album_name));
        // let path = config::get_cache_dir().join(cover_name_sm);
        // if !path.exists() {
        //     if let Err(e) = store_album_cover_from_uri(&item.track_uri, &path, true) {
        //         eprintln!("Failed to store sm album cover: {}", e);
        //     }
        // }
    });

    Ok(())
}
