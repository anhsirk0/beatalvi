use crate::models::{TrackInfo, UriMtime};
use crate::utils::config;
use dashmap::DashMap;
use image::ImageError;
use rayon::prelude::*;
use std::{
    error::Error,
    fs::{File, metadata},
    io::{Cursor, Write},
    path::{Path, PathBuf},
    time::UNIX_EPOCH,
};
use symphonia::core::{
    formats::FormatOptions,
    io::MediaSourceStream,
    meta::{Metadata, MetadataOptions, StandardTagKey, Value},
    probe::{Hint, ProbeResult},
};
use url::Url;

fn get_probe_result(path: &Path) -> Result<ProbeResult, Box<dyn Error>> {
    let file = File::open(path)?;

    let mss = MediaSourceStream::new(Box::new(file), Default::default());
    let mut hint = Hint::new();
    if let Some(extension) = path.extension().and_then(|x| x.to_str()) {
        hint.with_extension(extension);
    }

    let probe = symphonia::default::get_probe().format(
        &hint,
        mss,
        &FormatOptions::default(),
        &MetadataOptions::default(),
    )?;
    Ok(probe)
}
pub fn get_cover_art_bytes_from_metadata(data: Metadata) -> Result<Vec<u8>, Box<dyn Error>> {
    if let Some(metadata_rev) = data.current() {
        for visual in metadata_rev.visuals() {
            let buf = resize_image_bytes(&visual.data)?;
            return Ok(buf);
        }
    }
    Err("No cover art found")?
}

pub fn get_cover_art_bytes_from_path(path: &Path) -> Result<Vec<u8>, Box<dyn Error>> {
    let probe = get_probe_result(path)?;
    let mut format = probe.format;
    get_cover_art_bytes_from_metadata(format.metadata())
}

pub fn get_track_meta<P: AsRef<Path>>(path: &P) -> Result<UriMtime, Box<dyn Error>> {
    let uri = Url::from_file_path(path)
        .map_err(|_| "invalid file path")?
        .to_string();

    let mtime = metadata(&path)?
        .modified()?
        .duration_since(UNIX_EPOCH)?
        .as_secs() as i64;

    Ok(UriMtime { uri, mtime })
}

fn get_track_info<P: AsRef<Path>>(path: P) -> Result<TrackInfo, Box<dyn Error>> {
    let path = path.as_ref();

    let mtime = metadata(path)?
        .modified()?
        .duration_since(UNIX_EPOCH)?
        .as_secs() as i64;

    let probe = get_probe_result(path)?;
    let mut format = probe.format;
    let track = format
        .default_track()
        .ok_or("audio file has no default track")?;

    let params = &track.codec_params;

    let duration = match (params.n_frames, params.time_base) {
        (Some(n_frames), Some(time_base)) => {
            let seconds =
                (n_frames as f64 * (time_base.numer as f64 / time_base.denom as f64)) as i64;
            seconds
        }
        _ => 0,
    };

    let mut name = path.file_stem().unwrap().to_string_lossy().to_string();
    let mut album = String::from("Unknown");
    let mut artist = String::from("Unknown");
    let mut year: i32 = 0;

    if let Some(revision) = format.metadata().current() {
        for tag in revision.tags() {
            match tag.std_key {
                Some(StandardTagKey::TrackTitle) => match tag.value.clone() {
                    Value::String(val) => name = val,
                    _ => (),
                },
                Some(StandardTagKey::Album) => match tag.value.clone() {
                    Value::String(val) => album = val,
                    _ => (),
                },
                Some(StandardTagKey::Artist) => match tag.value.clone() {
                    Value::String(val) => artist = val,
                    _ => (),
                },
                Some(StandardTagKey::Date) => match tag.value.clone() {
                    Value::String(val) => year = val.parse::<i32>().unwrap_or(0),
                    Value::Float(val) => year = val as i32,
                    Value::SignedInt(val) => year = val as i32,
                    _ => (),
                },
                _ => {}
            }
        }
    }

    let album_cover_name = format!("{}.jpg", album.clone());
    let album_cover_path = config::get_cache_dir().join(album_cover_name);

    if !(Path::new(&album_cover_path).exists()) {
        let mut out_file = File::create(&album_cover_path)?;
        match get_cover_art_bytes_from_metadata(format.metadata()) {
            Ok(buf) => out_file.write_all(&buf)?,
            Err(e) => eprintln!("Err: {}", e),
        }
    }

    Ok(TrackInfo {
        name,
        duration,
        album,
        artist,
        year,
        mtime,
    })
}

// { uri: TrackInfo } // also set cover art cache
pub fn get_info_map(files: Vec<String>) -> Result<DashMap<String, TrackInfo>, Box<dyn Error>> {
    let info_map = DashMap::new();

    files.par_iter().for_each(|file| {
        let path = PathBuf::from(file);
        let uri = Url::from_file_path(&path)
            .expect("invalid file path")
            .to_string();
        let info = get_track_info(path).expect("Failed to get info");

        info_map.insert(uri, info);
    });
    Ok(info_map)
}

fn resize_image_bytes(input: &[u8]) -> Result<Vec<u8>, ImageError> {
    let img = image::load_from_memory(input)?;
    let mut out = Vec::new();
    img.resize(350, 350, image::imageops::FilterType::Lanczos3)
        .write_to(&mut Cursor::new(&mut out), image::ImageFormat::Jpeg)?;
    Ok(out)
}

// pub fn uri_to_path_str(uri: &str) -> Result<String, Box<dyn Error>> {
//     let path_string = Url::parse(uri)?
//         .to_file_path()
//         .unwrap()
//         .to_string_lossy()
//         .to_string();
//     Ok(path_string)
// }
