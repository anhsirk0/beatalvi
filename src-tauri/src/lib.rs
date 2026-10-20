pub mod models;
mod utils;
use models::{
    AlbumGroup, Artist, ArtistAlbum, ArtistStats, BasicAlbum, BasicTrack, Stats, Track, TrackState,
};
use tauri::{AppHandle, Emitter, Manager, State, Webview};
use tokio::task;
use utils::config;
use utils::database;
use utils::event;
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
async fn regenerate_cover_art_cache() {
    task::spawn_blocking(move || {
        if let Err(e) = importer::regenerate_cover_art_cache() {
            eprintln!("Failed to regenerate album covers: {}", e);
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
fn get_random_100_albums() -> Vec<BasicAlbum> {
    database::get_random_n_albums(100).unwrap()
}

#[tauri::command]
fn get_recent_100_albums() -> Vec<BasicAlbum> {
    database::get_recent_n_albums(100).unwrap()
}

#[tauri::command]
fn get_all_albums() -> Vec<BasicAlbum> {
    database::get_all_albums().unwrap()
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
fn get_all_artists() -> Vec<Artist> {
    database::get_all_artists().unwrap()
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
async fn get_artist_cover_art(artist_id: i64) -> Option<Vec<u8>> {
    tokio::task::spawn_blocking(move || {
        if let Ok(Some(album)) = database::get_random_album_name_by_artist_id(artist_id) {
            importer::get_cover_art(&album).ok()
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
fn queue_toggle_track(uri: String, app_handle: AppHandle, state: State<AppState>) {
    state.queue_toggle_track(&uri);
    app_handle.emit(event::QUEUE_TOGGLE, uri).unwrap();
}

#[tauri::command]
fn play_many(uris: Vec<String>, state: State<AppState>) {
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
    state: State<AppState>,
) {
    let tracks = database::get_track_uris_by_albums(album_ids).unwrap();
    let uris = tracks.iter().map(|(uri, _)| uri.clone()).collect();

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
    if let Ok(seconds) = state.player.lock().unwrap().seek_10_seconds() {
        let _ = app_handle.emit(event::POSITION, seconds);
    }
}

#[tauri::command]
fn rewind_10_seconds(app_handle: AppHandle, state: State<AppState>) {
    if let Ok(seconds) = state.player.lock().unwrap().rewind_10_seconds() {
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
    match state.player.lock().unwrap().set_volume(volume) {
        Ok(_) => {
            let _ = app_handle.emit(event::VOLUME, volume);
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
fn reload_app(app_handle: AppHandle) {
    app_handle.restart()
}

#[tauri::command]
fn reload_window(webview: Webview) {
    webview.eval("location.reload()").ok();
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
            reload_app,
            reload_window,
            load_music,
            regenerate_cover_art_cache,
            get_stats,
            get_top_10_tracks,
            get_top_10_albums,
            get_top_100_albums,
            get_random_100_albums,
            get_loved_albums,
            get_recent_100_albums,
            get_all_albums,
            get_tracks_by_albums,
            get_track_cover_art,
            get_album_cover_art,
            get_artist_cover_art,
            get_all_artists,
            get_artist_stats,
            get_albums_by_artist_id,
            search_tracks_grouped,
            get_playing_album_groups,
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
            set_album_loved_by_id
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
