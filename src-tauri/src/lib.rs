pub mod models;
mod utils;
extern crate rand;
use clap::Parser;
use itertools::Itertools;
use models::{
    AlbumGroup, Artist, ArtistAlbum, ArtistStats, BasicAlbum, BasicTrack, CoverSize, PlaylistItem,
    PlaylistWithTracks, Stats, Track, TrackState, UserPlaylist,
};
use rand::prelude::SliceRandom;
use rusqlite::OptionalExtension;
use tauri::{AppHandle, Emitter, Manager, State, Webview};
use tokio::task;
use utils::args::Args;
use utils::config;
use utils::database;
use utils::event;
use utils::importer;
use utils::playlist_database;
use utils::scanner;
use utils::state::AppState;

#[tauri::command]
fn get_app_version(app_handle: AppHandle) -> String {
    app_handle.package_info().version.to_string()
}

#[tauri::command]
async fn load_music() -> (usize, usize, usize) {
    task::spawn_blocking(move || {
        let files = scanner::get_audio_files(config::get_music_dir().to_str().unwrap());
        let data;
        if database::tracks_is_empty().unwrap() {
            data = importer::import_all(files).unwrap_or((0, 0, 0));
        } else {
            data = importer::import_and_update(files).unwrap_or((0, 0, 0));
        }
        let _ = importer::generate_cover_art_cache();
        data
    })
    .await
    .unwrap()
}

#[tauri::command]
async fn generate_cover_art_cache() {
    task::spawn_blocking(move || {
        if let Err(e) = importer::generate_cover_art_cache() {
            eprintln!("Failed to generate album covers: {}", e);
        }
    })
    .await
    .unwrap()
}

#[tauri::command]
fn get_stats() -> Stats {
    database::get_stats().unwrap()
}

#[tauri::command]
fn get_all_tracks_grouped_by_album() -> Vec<Track> {
    database::get_all_tracks_grouped_by_album().unwrap_or(Vec::new())
}

#[tauri::command]
fn get_tracks_by_uris(uris: Vec<String>) -> Vec<Track> {
    database::get_tracks_by_uris(uris).unwrap_or(Vec::new())
}

#[tauri::command]
fn get_top_10_tracks() -> Vec<Track> {
    database::get_top_10_tracks().unwrap_or(Vec::new())
}

#[tauri::command]
fn get_top_10_albums() -> Vec<BasicAlbum> {
    database::get_top_n_albums(10).unwrap_or(Vec::new())
}

#[tauri::command]
fn get_top_64_albums() -> Vec<BasicAlbum> {
    database::get_top_n_albums(64).unwrap_or(Vec::new())
}

#[tauri::command]
fn get_random_64_albums() -> Vec<BasicAlbum> {
    database::get_random_n_albums(64).unwrap_or(Vec::new())
}

#[tauri::command]
fn get_recent_64_albums() -> Vec<BasicAlbum> {
    database::get_recent_n_albums(64).unwrap_or(Vec::new())
}

#[tauri::command]
fn get_all_albums() -> Vec<BasicAlbum> {
    database::get_all_albums().unwrap_or(Vec::new())
}

#[tauri::command]
fn get_loved_albums() -> Vec<BasicAlbum> {
    database::get_loved_albums().unwrap()
}

#[tauri::command]
fn get_tracks_by_albums(album_ids: Vec<i64>) -> Vec<Track> {
    database::get_tracks_by_albums(album_ids).unwrap()
}

#[tauri::command]
fn get_related_tracks(track_id: i64, track_uri: String, artist_names: Vec<String>) -> Vec<Track> {
    let mut tracks = database::get_other_tracks_of_same_album(track_id).unwrap_or(Vec::new());
    for artist in artist_names {
        tracks.extend(database::get_top_20_tracks_by_artist_name(&artist).unwrap_or(Vec::new()));
    }
    let playlist_tracks =
        playlist_database::get_other_tracks_in_playlist(&track_uri).unwrap_or(Vec::new());
    tracks.extend(playlist_tracks);
    tracks.sort_by(Track::cmp_by_popularity);
    tracks
        .iter()
        .unique_by(|t| &t.uri)
        .filter(|t| t.id != track_id)
        .cloned()
        .collect()
}

#[tauri::command]
fn get_all_artists() -> Vec<Artist> {
    database::get_all_artists().unwrap()
}

#[tauri::command]
fn find_album_by_id(id: i64) -> Option<BasicAlbum> {
    database::find_album_by_id(id)
}

#[tauri::command]
async fn get_track_cover_art(album: String, track_uri: String) -> Option<Vec<u8>> {
    tokio::task::spawn_blocking(move || {
        importer::get_and_set_cover_art(&album, &track_uri, &CoverSize::Small).ok()
    })
    .await
    .unwrap()
}

#[tauri::command]
async fn get_album_cover_art(album: String, size: String) -> Option<Vec<u8>> {
    tokio::task::spawn_blocking(move || {
        importer::get_cover_art(&album, &CoverSize::from_string(&size)).ok()
    })
    .await
    .unwrap()
}

#[tauri::command]
async fn get_artist_cover_art(artist_id: i64) -> Option<Vec<u8>> {
    tokio::task::spawn_blocking(move || {
        if let Ok(Some(album)) = database::get_random_album_name_by_artist_id(artist_id) {
            importer::get_cover_art(&album, &CoverSize::Medium).ok()
        } else {
            None
        }
    })
    .await
    .unwrap()
}

#[tauri::command]
fn get_artist_stats(artist_id: i64) -> Option<ArtistStats> {
    match database::get_artist_stats(artist_id) {
        Ok(stats) => stats,
        Err(e) => {
            eprintln!("{:?}", e);
            None
        }
    }
}

#[tauri::command]
fn get_albums_by_artist_id(artist_id: i64) -> Vec<ArtistAlbum> {
    database::get_albums_by_artist_id(artist_id).unwrap()
}

#[tauri::command]
fn search_tracks_grouped(query: String) -> Vec<AlbumGroup> {
    database::search_tracks_grouped(&query).unwrap_or(Vec::new())
}

#[tauri::command]
fn get_playing_album_groups(state: State<AppState>) -> Vec<AlbumGroup> {
    state.get_playing_album_groups()
}

#[tauri::command]
fn get_playing_tracks(state: State<AppState>) -> Vec<Track> {
    state.get_playing_tracks()
}

#[tauri::command]
fn get_queued_tracks(state: State<AppState>) -> Vec<Track> {
    state.get_queued_tracks()
}

#[tauri::command]
fn get_queued_album_groups(state: State<AppState>) -> Vec<AlbumGroup> {
    state.get_queued_album_groups()
}

#[tauri::command]
fn play(track_uri: String, app_handle: AppHandle, state: State<AppState>) {
    let mut player = state.player.lock().unwrap();
    if !player.is_stopped().unwrap() {
        player.stop().unwrap();
        std::thread::sleep(std::time::Duration::from_millis(200));
    }
    player.play(&track_uri).unwrap();
    let track = database::find_track_by_uri(&track_uri).unwrap();
    app_handle.emit(event::PLAY, track).unwrap();
}

#[tauri::command]
fn pause(app_handle: AppHandle, state: State<AppState>) {
    state.player.lock().unwrap().pause().unwrap();
    app_handle.emit(event::PAUSE, true).unwrap();
}

#[tauri::command]
fn get_position(state: State<AppState>) -> Option<u64> {
    state.player.lock().unwrap().get_position()
}

#[tauri::command]
fn toggle(app_handle: AppHandle, state: State<AppState>) {
    let player = state.player.lock().unwrap();
    player.toggle().unwrap();
    let is_playing = player.is_playing().unwrap();
    app_handle.emit(event::TOGGLE, is_playing).unwrap();
}

#[tauri::command]
fn stop(app_handle: AppHandle, state: State<AppState>) {
    state.player.lock().unwrap().stop().unwrap();
    app_handle.emit(event::STOP, true).unwrap();
}

#[tauri::command]
fn queue_toggle_track(uri: String, state: State<AppState>) {
    state.queue_toggle_track(&uri);
}

fn queue_toggle_track_by_id(id: i64, state: State<AppState>) {
    state.queue_toggle_track_by_id(id);
}

#[tauri::command]
fn play_many(uris: Vec<String>, shuffle: bool, state: State<AppState>) {
    let mut uris = uris;
    if shuffle {
        let mut rng = rand::thread_rng();
        uris.shuffle(&mut rng);
    }

    state.playlist.lock().unwrap().clear();
    state.playlist.lock().unwrap().add_many(uris);

    if !state.player.lock().unwrap().is_stopped().unwrap() {
        let _ = state.player.lock().unwrap().stop();
    }
    std::thread::sleep(std::time::Duration::from_millis(200));
    state.start_playback();
}

#[tauri::command]
fn play_tracks_by_albums(album_ids: Vec<i64>, state: State<AppState>) {
    let uris = database::get_track_uris_by_albums(album_ids)
        .unwrap()
        .iter()
        .map(|(uri, _)| uri.clone())
        .collect();
    state.player.lock().unwrap().stop().unwrap();
    state.playlist.lock().unwrap().clear();
    state.playlist.lock().unwrap().add_many(uris);
    std::thread::sleep(std::time::Duration::from_millis(200));
    state.start_playback();
}

#[tauri::command]
fn play_many_from_index(uris: Vec<String>, index: usize, state: State<AppState>) {
    let _ = state
        .playlist
        .lock()
        .unwrap()
        .add_many_and_jump_to_index(uris, index);
    if !state.player.lock().unwrap().is_stopped().unwrap() {
        let _ = state.player.lock().unwrap().stop();
    }
    std::thread::sleep(std::time::Duration::from_millis(200));
    state.start_playback();
}

#[tauri::command]
fn play_tracks_by_albums_from_album_id(
    album_ids: Vec<i64>,
    album_id: i64,
    index: usize,
    shuffle: bool,
    state: State<AppState>,
) {
    let tracks = database::get_track_uris_by_albums(album_ids).unwrap();
    let mut uris: Vec<String> = tracks.iter().map(|(uri, _)| uri.clone()).collect();

    if shuffle {
        let mut rng = rand::thread_rng();
        uris.shuffle(&mut rng);
    }

    if let Some(idx) = tracks.iter().position(|(_, id)| id == &album_id) {
        state.player.lock().unwrap().stop().unwrap();
        let _ = state
            .playlist
            .lock()
            .unwrap()
            .add_many_and_jump_to_index(uris, idx + index);
        if !state.player.lock().unwrap().is_stopped().unwrap() {
            let _ = state.player.lock().unwrap().stop();
        }
        std::thread::sleep(std::time::Duration::from_millis(200));
        state.start_playback();
    }
}

#[tauri::command]
fn seek(seconds: u64, app_handle: AppHandle, state: State<AppState>) {
    if state.player.lock().unwrap().seek(seconds).is_ok() {
        let _ = app_handle.emit(event::POSITION, seconds);
    }
}

#[tauri::command]
fn seek_10_seconds(app_handle: AppHandle, state: State<AppState>) {
    if let Ok(seconds) = state.player.lock().unwrap().seek_forward(10) {
        let _ = app_handle.emit(event::POSITION, seconds);
    }
}

#[tauri::command]
fn rewind_10_seconds(app_handle: AppHandle, state: State<AppState>) {
    if let Ok(seconds) = state.player.lock().unwrap().rewind(10) {
        let _ = app_handle.emit(event::POSITION, seconds);
    }
}

#[tauri::command]
fn play_next(state: State<AppState>) {
    if state.peek_next().is_some() {
        state.skip_to_next().unwrap();
    }
}

#[tauri::command]
fn peek_next(state: State<AppState>) -> Option<BasicTrack> {
    state
        .peek_next()
        .and_then(|uri| database::find_basic_track_by_uri(&uri))
}

#[tauri::command]
fn play_previous(state: State<AppState>) {
    if state.peek_previous().is_some() {
        state.skip_to_previous().unwrap();
    }
}

#[tauri::command]
fn peek_previous(state: State<AppState>) -> Option<BasicTrack> {
    state
        .peek_previous()
        .and_then(|uri| database::find_basic_track_by_uri(&uri))
}

#[tauri::command]
fn get_track_state(state: State<AppState>) -> TrackState {
    state.get_track_state()
}

#[tauri::command]
fn get_volume(state: State<AppState>) -> i32 {
    state.player.lock().unwrap().get_volume()
}

#[tauri::command]
fn set_volume(volume: i32, app_handle: AppHandle, state: State<AppState>) {
    let vol = ((volume as f64) / 64.).max(0.).min(1.);
    match state.player.lock().unwrap().set_volume(vol) {
        Ok(_) => {
            let _ = app_handle.emit(event::VOLUME, (vol * 64.) as i8);
        }
        Err(e) => eprintln!("{:?}", e),
    }
}

#[tauri::command]
fn is_album_loved(album_id: i64) -> bool {
    database::is_album_loved(album_id).unwrap_or(false)
}

#[tauri::command]
fn set_album_loved_by_id(album_id: i64, loved: bool, app_handle: AppHandle) {
    match database::set_album_loved_by_id(album_id, loved) {
        Ok(_) => {
            let _ = app_handle.emit(event::LOVED, (album_id, loved));
        }
        Err(e) => eprintln!("{:?}", e),
    }
}

#[tauri::command]
fn create_playlist_with_track_uris(name: String, uris: Vec<String>) -> Result<i64, String> {
    playlist_database::create_playlist_with_track_uris(&name, uris)
        .map_err(|_| "failed to create playlist".into())
}

#[tauri::command]
fn create_smart_playlist(name: String, sql: String, json: String) -> Result<i64, String> {
    playlist_database::create_smart_playlist(&name, sql, json).map_err(|e| {
        eprintln!("{}", e);
        "failed to create smart playlist".into()
    })
}

#[tauri::command]
fn update_smart_playlist(id: i64, name: String, sql: String, json: String) -> Result<i64, String> {
    playlist_database::update_smart_playlist(id, &name, sql, json)
        .map_err(|_| "failed to update smart playlist".into())
}

#[tauri::command]
fn update_playlist_with_track_uris(
    id: i64,
    name: String,
    uris: Vec<String>,
) -> Result<i64, String> {
    playlist_database::update_playlist_with_track_uris(id, &name, uris)
        .map_err(|_| "failed to update playlist".into())
}
#[tauri::command]
fn delete_playlist_by_id(id: i64) -> Result<i64, String> {
    playlist_database::delete_playlist_by_id(id).map_err(|_| "failed to delete playlist".into())
}

#[tauri::command]
fn get_all_playlists() -> Vec<PlaylistItem> {
    playlist_database::get_all_playlists().unwrap_or(Vec::new())
}

#[tauri::command]
fn get_playlists_with_tracks() -> Vec<PlaylistWithTracks> {
    playlist_database::get_playlists_with_tracks().unwrap_or(Vec::new())
}

#[tauri::command]
fn get_playlists_tracks_by_id(id: i64) -> Vec<Track> {
    playlist_database::get_playlist_tracks(id).unwrap_or(Vec::new())
}

#[tauri::command]
fn get_smart_playlist_tracks(query: String) -> Vec<Track> {
    playlist_database::get_smart_playlist_tracks(query).unwrap_or(Vec::new())
}

#[tauri::command]
fn find_playlist_by_id(id: i64) -> Option<UserPlaylist> {
    playlist_database::find_playlist_by_id(id)
        .optional()
        .unwrap_or(None)
}

#[tauri::command]
fn find_playlist_with_tracks_by_id(id: i64) -> Option<PlaylistWithTracks> {
    playlist_database::find_playlist_with_tracks_by_id(id)
        .optional()
        .unwrap_or(None)
}

#[tauri::command]
fn reload_app(app_handle: AppHandle) {
    app_handle.restart()
}

#[tauri::command]
fn reload_window(webview: Webview) {
    webview.eval("location.reload()").ok();
}

fn seek_forward(seconds: u64, app_handle: AppHandle, state: State<AppState>) {
    if let Ok(pos) = state.player.lock().unwrap().seek_forward(seconds) {
        let _ = app_handle.emit(event::POSITION, pos);
    }
}

fn rewind(seconds: u64, app_handle: AppHandle, state: State<AppState>) {
    if let Ok(pos) = state.player.lock().unwrap().rewind(seconds) {
        let _ = app_handle.emit(event::POSITION, pos);
    }
}

fn toggle_dark_mode(app_handle: AppHandle) {
    let _ = app_handle.emit(event::TOGGLE_DARK_MODE, true);
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    let _ = config::create_config_dir_if_not_exists();
    let _ = config::create_cache_dir_if_not_exists();
    let _ = database::initialize().expect("Could not initialize db");
    let _ = playlist_database::initialize().expect("Could not initialize playlist db");
    tauri::Builder::default()
        .setup(|app| {
            let app_handle = app.app_handle();
            let state = AppState::new(app_handle.clone());
            state.spawn_event_listener();
            app.manage(state);
            Ok(())
        })
        .plugin(tauri_plugin_single_instance::init(|app, args_vec, _cwd| {
            match Args::try_parse_from(args_vec) {
                Err(e) => eprintln!("Parse error: {}", e),
                Ok(args) => {
                    if args.toggle {
                        toggle(app.app_handle().clone(), app.state());
                    } else if args.next {
                        play_next(app.state());
                    } else if args.previous {
                        play_previous(app.state());
                    } else if args.dark_toggle {
                        toggle_dark_mode(app.app_handle().clone());
                    } else if let Some(id) = args.queue {
                        queue_toggle_track_by_id(id, app.state());
                    } else if let Some(seconds) = args.seek {
                        seek_forward(seconds, app.app_handle().clone(), app.state());
                    } else if let Some(seconds) = args.rewind {
                        rewind(seconds, app.app_handle().clone(), app.state());
                    }
                }
            }
            // Bring existing window to front
            // if let Some(window) = app.get_webview_window("main") {
            //     let _ = window.set_focus();
            // }
        }))
        .plugin(tauri_plugin_fs::init())
        .plugin(tauri_plugin_opener::init())
        .invoke_handler(tauri::generate_handler![
            get_app_version,
            reload_app,
            reload_window,
            load_music,
            generate_cover_art_cache,
            get_stats,
            get_all_tracks_grouped_by_album,
            get_tracks_by_uris,
            get_top_10_tracks,
            get_top_10_albums,
            get_top_64_albums,
            get_random_64_albums,
            get_loved_albums,
            get_recent_64_albums,
            get_all_albums,
            find_album_by_id,
            get_tracks_by_albums,
            get_related_tracks,
            get_track_cover_art,
            get_album_cover_art,
            get_artist_cover_art,
            get_all_artists,
            get_artist_stats,
            get_albums_by_artist_id,
            search_tracks_grouped,
            get_playing_album_groups,
            get_playing_tracks,
            get_queued_album_groups,
            get_queued_tracks,
            play,
            pause,
            toggle,
            stop,
            queue_toggle_track,
            play_many,
            get_position,
            seek,
            seek_10_seconds,
            rewind_10_seconds,
            play_next,
            peek_next,
            play_previous,
            peek_previous,
            play_tracks_by_albums,
            play_many_from_index,
            play_tracks_by_albums_from_album_id,
            get_track_state,
            get_volume,
            set_volume,
            is_album_loved,
            set_album_loved_by_id,
            create_playlist_with_track_uris,
            create_smart_playlist,
            update_playlist_with_track_uris,
            update_smart_playlist,
            get_all_playlists,
            get_playlists_with_tracks,
            get_smart_playlist_tracks,
            get_playlists_tracks_by_id,
            find_playlist_with_tracks_by_id,
            find_playlist_by_id,
            delete_playlist_by_id
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
