use std::{fs, path::PathBuf};

const NAME: &str = "beatalvi";

fn get_config_dir() -> PathBuf {
    dirs::config_dir().expect("config dir not found").join(NAME)
}
pub fn get_cache_dir() -> PathBuf {
    dirs::cache_dir().expect("cache dir not found").join(NAME)
}

pub fn get_db_path() -> PathBuf {
    // get_config_dir().join("beatalvi.db")
    get_config_dir().join("beatalvi-dev.db")
}

pub fn get_playlist_db_path() -> PathBuf {
    get_config_dir().join("playlists.db")
}

pub fn get_music_dir() -> PathBuf {
    dirs::home_dir()
        .expect("failed to get home dir")
        // .join("Music")
        .join("test")
}

pub fn create_config_dir_if_not_exists() -> PathBuf {
    let path = get_config_dir();
    fs::create_dir_all(&path).expect("failed to create config directory");
    path
}

pub fn create_cache_dir_if_not_exists() -> PathBuf {
    let path = get_cache_dir();
    fs::create_dir_all(&path).expect("failed to create cache directory");
    path
}
