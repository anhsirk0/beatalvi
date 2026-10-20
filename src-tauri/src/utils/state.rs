use crate::models::{AlbumGroup, Track, TrackItem, TrackState};
use crate::utils::database;
use crate::utils::event;
use crate::utils::player::Player;
use crate::utils::playlist::Playlist;
use gstreamer as gst;
use gstreamer::prelude::ElementExt;
use std::collections::VecDeque;
use std::sync::{Arc, Mutex};
use std::thread;
use tauri::{AppHandle, Emitter};

pub struct AppState {
    pub player: Arc<Mutex<Player>>,
    pub queue: Arc<Mutex<VecDeque<String>>>,
    pub playlist: Arc<Mutex<Playlist>>,
    pub app_handle: AppHandle,
}

impl AppState {
    pub fn new(app_handle: AppHandle) -> Self {
        let player = Arc::new(Mutex::new(Player::new().unwrap()));
        let queue = Arc::new(Mutex::new(VecDeque::new()));
        let playlist = Arc::new(Mutex::new(Playlist::new()));

        Self {
            player,
            playlist,
            app_handle,
            queue,
        }
    }

    pub fn spawn_event_listener(&self) {
        let player = Arc::clone(&self.player);
        let playlist = Arc::clone(&self.playlist);
        let queue = Arc::clone(&self.queue);
        let app_handle = self.app_handle.clone();

        thread::spawn(move || {
            let playbin = {
                let p = player.lock().unwrap();
                p.playbin.clone()
            };

            if let Some(bus) = playbin.bus() {
                for msg in bus.iter_timed(gst::ClockTime::NONE) {
                    match msg.view() {
                        gst::MessageView::Eos(..) => {
                            println!("\n Track finished");
                            player.lock().unwrap().stop().unwrap();
                            if let Some(uri) = player.lock().unwrap().get_current_uri() {
                                database::increment_track_and_album_popularity_by_uri(&uri)
                                    .unwrap();
                            }

                            let track_uri = queue.lock().unwrap().pop_front().or(playlist
                                .lock()
                                .unwrap()
                                .next()
                                .cloned());

                            if let Some(uri) = track_uri {
                                match player.lock().unwrap().play(&uri) {
                                    Ok(_) => {
                                        if let Some(track) = database::find_track_by_uri(&uri) {
                                            app_handle.emit(event::NEXT, &track).unwrap();
                                        }
                                        println!("Now playing: {}", uri);
                                    }
                                    Err(e) => {
                                        eprintln!("Failed to play next: {}", e);
                                        app_handle
                                            .emit(event::PLAYBACK_ERROR, e.to_string())
                                            .unwrap();
                                    }
                                }
                            } else {
                                app_handle.emit(event::FINISHED, true).unwrap();
                                println!("Playist & Queue empty - stopping");
                                player.lock().unwrap().stop().unwrap();
                                app_handle.emit(event::EMPTY, true).unwrap();
                            }
                        }
                        gst::MessageView::Error(err) => {
                            eprintln!(" Error: {}", err.error());
                        }
                        _ => {}
                    }
                }
            }
        });
    }

    // pub fn queue_track(&self, uri: &str) {
    //     self.queue.lock().unwrap().push_back(uri.to_string());
    // }

    pub fn queue_toggle_track(&self, uri: &str) {
        let mut queue = self.queue.lock().unwrap();
        if let Some(pos) = queue.iter().position(|s| uri == s) {
            queue.remove(pos);
        } else {
            queue.push_back(uri.to_string());
        }
    }

    pub fn start_playback(&self) {
        if let Some(track_uri) = self.playlist.lock().unwrap().next() {
            match self.player.lock().unwrap().play(&track_uri) {
                Ok(_) => {
                    if let Some(track) = database::find_track_by_uri(&track_uri) {
                        self.app_handle.emit(event::START, &track).unwrap();
                        println!("Playing: {}", track_uri);
                    }
                }
                Err(e) => eprintln!("Failed to play: {}", e),
            }
        } else {
            println!("Queue is empty");
        }
    }

    pub fn play_next(&self) -> Result<(), String> {
        let mut player = self.player.lock().unwrap();
        let track_uri = match self.queue.lock().unwrap().pop_front() {
            Some(uri) => Some(uri),
            None => self.playlist.lock().unwrap().next().cloned(),
        };
        if let Some(uri) = track_uri {
            match player.play(&uri) {
                Ok(_) => {
                    if let Some(track) = database::find_track_by_uri(&uri) {
                        self.app_handle
                            .emit(event::NEXT, &track)
                            .map_err(|e| e.to_string())?;
                        println!("Playing next: {}", uri);
                        Ok(())
                    } else {
                        Err("Track metadata not found".to_string())
                    }
                }
                Err(e) => {
                    eprintln!("Failed to play next: {}", e);
                    Err(format!("Failed to play next: {}", e))
                }
            }
        } else {
            println!("Queue empty");
            player.stop().map_err(|e| e.to_string())?;
            self.app_handle
                .emit(event::EMPTY, true)
                .map_err(|e| e.to_string())?;
            Err("No more tracks in queue".to_string())
        }
    }

    pub fn skip_to_next(&self) -> Result<(), String> {
        self.player
            .lock()
            .unwrap()
            .stop()
            .map_err(|e| e.to_string())?;
        self.play_next()
    }

    pub fn peek_next(&self) -> Option<String> {
        self.queue
            .lock()
            .unwrap()
            .front()
            .or(self.playlist.lock().unwrap().peek_next())
            .cloned()
    }

    /// Play the previous track
    pub fn play_previous(&self) -> Result<(), String> {
        let mut player = self.player.lock().unwrap();

        if let Some(uri) = self.playlist.lock().unwrap().previous().cloned() {
            match player.play(&uri) {
                Ok(_) => {
                    if let Some(track) = database::find_track_by_uri(&uri) {
                        self.app_handle
                            .emit(event::PREVIOUS, &track)
                            .map_err(|e| e.to_string())?;
                        println!("Playing previous: {}", uri);
                        Ok(())
                    } else {
                        Err("Track metadata not found".to_string())
                    }
                }
                Err(e) => {
                    eprintln!("Failed to play previous: {}", e);
                    Err(format!("Failed to play previous: {}", e))
                }
            }
        } else {
            println!("No previous tracks");
            Err("No previous tracks".to_string())
        }
    }

    /// Peek at the previous track without playing
    pub fn peek_previous(&self) -> Option<String> {
        self.playlist.lock().unwrap().peek_previous().cloned()
    }

    pub fn skip_to_previous(&self) -> Result<(), String> {
        self.player
            .lock()
            .unwrap()
            .stop()
            .map_err(|e| e.to_string())?;
        self.play_previous()
    }

    pub fn get_track_state(&self) -> TrackState {
        let track = self
            .player
            .lock()
            .unwrap()
            .get_current_uri()
            .and_then(|uri| database::find_track_by_uri(&uri));
        let is_playing = self.player.lock().unwrap().is_playing().unwrap_or(false);
        let position = self.player.lock().unwrap().get_position().unwrap_or(0);
        let queue = self.queue.lock().unwrap().clone();
        TrackState {
            track,
            is_playing,
            position,
            queue,
        }
    }

    pub fn get_playing_album_groups(&self) -> Vec<AlbumGroup> {
        if self.playlist.lock().unwrap().remaining().is_empty() {
            return Vec::new();
        }
        let uris = self.playlist.lock().unwrap().all().clone();
        let tracks = database::get_tracks_by_uris(uris).unwrap();
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
}
