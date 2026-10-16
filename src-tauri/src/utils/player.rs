use gstreamer as gst;
use gstreamer::prelude::*;
use std::error::Error;

pub struct Player {
    pub playbin: gst::Element,
    pub current_uri: Option<String>,
}

impl Player {
    pub fn new() -> Result<Self, Box<dyn Error>> {
        gst::init()?;
        let playbin = gst::ElementFactory::make("playbin")
            .build()
            .map_err(|_| "Failed to create playbin")?;

        Ok(Player {
            playbin,
            current_uri: None,
        })
    }

    pub fn get_state(&self) -> Result<gst::State, Box<dyn Error>> {
        match self.playbin.state(gst::ClockTime::NONE) {
            (_, state, _) => Ok(state),
        }
    }

    pub fn get_current_uri(&self) -> Option<String> {
        // self.playbin.property::<Option<String>>("uri")
        self.current_uri.clone()
    }

    pub fn play(&mut self, uri: &str) -> Result<(), Box<dyn Error>> {
        self.playbin.set_property("uri", &uri);
        self.current_uri = Some(uri.to_string());
        self.playbin.set_state(gst::State::Playing)?;
        Ok(())
    }

    pub fn pause(&self) -> Result<(), Box<dyn Error>> {
        self.playbin.set_state(gst::State::Paused)?;
        Ok(())
    }

    pub fn resume(&self) -> Result<(), Box<dyn Error>> {
        self.playbin.set_state(gst::State::Playing)?;
        Ok(())
    }
    pub fn is_playing(&self) -> Result<bool, Box<dyn Error>> {
        Ok(self.get_state()? == gst::State::Playing)
    }
    pub fn is_stopped(&self) -> Result<bool, Box<dyn Error>> {
        Ok(self.get_state()? == gst::State::Null)
    }
    pub fn toggle(&self) -> Result<(), Box<dyn Error>> {
        match self.get_state() {
            Ok(gstreamer::State::Playing) => self.pause(),
            Ok(gstreamer::State::Paused) => self.resume(),
            _ => Ok(()),
        }
    }

    pub fn stop(&self) -> Result<(), Box<dyn Error>> {
        self.playbin.set_state(gst::State::Null)?;
        Ok(())
    }

    pub fn get_position(&self) -> Option<u64> {
        self.playbin
            .query_position::<gst::ClockTime>()
            .map(|p| p.seconds())
    }

    pub fn seek(&self, seconds: u64) -> Result<u64, Box<dyn Error>> {
        let position = gst::ClockTime::from_seconds(seconds);
        self.playbin.seek_simple(gst::SeekFlags::FLUSH, position)?;
        Ok(seconds)
    }

    pub fn seek_10_seconds(&self) -> Result<u64, Box<dyn Error>> {
        if let Some(pos) = self.get_position() {
            Ok(self.seek(pos + 10)?)
        } else {
            Ok(0)
        }
    }

    pub fn rewind_10_seconds(&self) -> Result<u64, Box<dyn Error>> {
        if let Some(pos) = self.get_position() {
            Ok(self.seek(pos - 10)?)
        } else {
            Ok(0)
        }
    }

    // pub fn set_volume(&self, vol: f64) -> Result<(), Box<dyn Error>> {
    //     self.playbin.set_property("volume", vol);
    //     Ok(())
    // }
}
