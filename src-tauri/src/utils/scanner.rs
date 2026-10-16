// use std::path::PathBuf;
use walkdir::WalkDir;

fn is_audio_file(path: &std::path::Path) -> bool {
    match infer::get_from_path(path) {
        Ok(Some(file_type)) => file_type.mime_type().starts_with("audio/"),
        _ => false,
    }
}

pub fn get_audio_files(dir: &str) -> Vec<String> {
    WalkDir::new(dir)
        .into_iter()
        .filter_map(|item| item.ok())
        .filter(|item| item.path().is_file() && is_audio_file(item.path()))
        .map(|item| item.path().to_path_buf())
        .filter_map(|item| item.to_str().map(|i| i.to_string()))
        .collect()
}
