pub mod models;
mod utils;
use models::{BasicAlbum, BasicTrack, Stats, Track, TrackState};
use tauri::{AppHandle, Emitter, Manager, State};
use tokio::task;
use utils::config;
use utils::database;
use utils::importer;
use utils::scanner;
use utils::state::AppState;

#[tauri::command]
async fn load_music() -> (usize, usize, usize) {
    task::spawn_blocking(move || {
        let files = scanner::get_audio_files(config::get_music_dir().to_str().unwrap());
        if database::tracks_is_empty().unwrap() {
            importer::import_all(files).unwrap_or((0, 0, 0))
        } else {
            importer::import_and_update(files).unwrap_or((0, 0, 0))
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
fn get_top_10_tracks() -> Vec<Track> {
    database::get_top_10_tracks().unwrap()
}

#[tauri::command]
fn get_top_10_albums() -> Vec<BasicAlbum> {
    database::get_top_n_albums(10).unwrap()
}

#[tauri::command]
fn get_top_100_albums() -> Vec<BasicAlbum> {
    database::get_top_n_albums(100).unwrap()
}

#[tauri::command]
fn get_tracks_by_albums(album_ids: Vec<i64>) -> Vec<Track> {
    database::get_tracks_by_albums(album_ids).unwrap()
}

#[tauri::command]
async fn get_track_cover_art(album: String, track_uri: String) -> Option<Vec<u8>> {
    tokio::task::spawn_blocking(move || importer::get_and_set_cover_art(&album, &track_uri).ok())
        .await
        .unwrap()
}

#[tauri::command]
async fn get_album_cover_art(album: String) -> Option<Vec<u8>> {
    tokio::task::spawn_blocking(move || importer::get_cover_art(&album).ok())
        .await
        .unwrap()
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
    app_handle.emit("play", track).unwrap();
}

#[tauri::command]
fn pause(app_handle: AppHandle, state: State<AppState>) {
    state.player.lock().unwrap().pause().unwrap();
    app_handle.emit("pause", true).unwrap();
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
    app_handle.emit("toggle", is_playing).unwrap();
}

#[tauri::command]
fn stop(app_handle: AppHandle, state: State<AppState>) {
    state.player.lock().unwrap().stop().unwrap();
    app_handle.emit("stop", true).unwrap();
}

#[tauri::command]
fn queue_one(uri: String, state: State<AppState>) {
    state.queue_track(&uri)
}

#[tauri::command]
fn play_many(uris: Vec<String>, state: State<AppState>) {
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
fn play_tracks_by_albums_from_album_id(album_ids: Vec<i64>, album_id: i64, state: State<AppState>) {
    let tracks = database::get_track_uris_by_albums(album_ids).unwrap();
    let uris = tracks.iter().map(|(uri, _)| uri.clone()).collect();

    if let Some(index) = tracks.iter().position(|(_, id)| id == &album_id) {
        state.player.lock().unwrap().stop().unwrap();
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
}

#[tauri::command]
fn seek(seconds: u64, app_handle: AppHandle, state: State<AppState>) {
    if state.player.lock().unwrap().seek(seconds).is_ok() {
        let _ = app_handle.emit("position", seconds);
    }
}

#[tauri::command]
fn seek_10_seconds(app_handle: AppHandle, state: State<AppState>) {
    if let Ok(seconds) = state.player.lock().unwrap().seek_10_seconds() {
        let _ = app_handle.emit("position", seconds);
    }
}

#[tauri::command]
fn rewind_10_seconds(app_handle: AppHandle, state: State<AppState>) {
    if let Ok(seconds) = state.player.lock().unwrap().rewind_10_seconds() {
        let _ = app_handle.emit("position", seconds);
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
fn get_track_state(state: State<AppState>) -> Option<TrackState> {
    state.get_track_state()
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    let _ = config::create_config_dir_if_not_exists();
    let _ = config::create_cache_dir_if_not_exists();
    let _ = database::initialize().expect("Could not initialize database");
    tauri::Builder::default()
        .setup(|app| {
            let app_handle = app.app_handle();
            let state = AppState::new(app_handle.clone());
            state.spawn_event_listener();
            app.manage(state);
            Ok(())
        })
        .plugin(tauri_plugin_fs::init())
        .plugin(tauri_plugin_opener::init())
        .invoke_handler(tauri::generate_handler![
            load_music,
            get_stats,
            get_top_10_tracks,
            get_top_10_albums,
            get_top_100_albums,
            get_tracks_by_albums,
            get_track_cover_art,
            get_album_cover_art,
            play,
            pause,
            toggle,
            stop,
            queue_one,
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
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
