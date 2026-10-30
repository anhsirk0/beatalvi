pub struct Playlist {
    pub tracks: Vec<String>,
    pub current_index: Option<usize>,
}

impl Playlist {
    pub fn new() -> Self {
        Playlist {
            tracks: Vec::new(),
            current_index: None,
        }
    }

    /// Add track to end of playlist
    // pub fn add(&mut self, uri: String) {
    //     self.tracks.push(uri);
    // }

    /// Add multiple tracks
    pub fn add_many(&mut self, uris: Vec<String>) {
        self.tracks.extend(uris);
    }

    /// Get current track URI
    pub fn current(&self) -> Option<&String> {
        self.current_index.and_then(|i| self.tracks.get(i))
    }

    /// Move to next track
    pub fn next(&mut self) -> Option<&String> {
        match self.current_index {
            None if !self.tracks.is_empty() => {
                self.current_index = Some(0);
                self.current()
            }
            Some(i) if i + 1 < self.tracks.len() => {
                self.current_index = Some(i + 1);
                self.current()
            }
            _ => {
                self.current_index = None;
                None
            }
        }
    }

    /// Move to previous track
    pub fn previous(&mut self) -> Option<&String> {
        match self.current_index {
            Some(i) if i > 0 => {
                self.current_index = Some(i - 1);
                self.current()
            }
            _ => None,
        }
    }

    /// Peek at next track without advancing
    pub fn peek_next(&self) -> Option<&String> {
        self.current_index.and_then(|i| self.tracks.get(i + 1))
    }

    /// Peek at previous track
    pub fn peek_previous(&self) -> Option<&String> {
        self.current_index
            .and_then(|i| i.checked_sub(1))
            .and_then(|i| self.tracks.get(i))
    }

    /// Get current index
    // pub fn current_index(&self) -> Option<usize> {
    //     self.current_index
    // }

    /// Get all tracks
    pub fn all(&self) -> &Vec<String> {
        &self.tracks
    }

    /// Get remaining tracks (current + ahead)
    pub fn remaining(&self) -> Vec<String> {
        self.current_index
            .map(|i| self.tracks[i..].to_vec())
            .unwrap_or_default()
    }

    /// Get played tracks (before current)
    // pub fn history(&self) -> Vec<String> {
    //     self.current_index
    //         .map(|i| self.tracks[..i].to_vec())
    //         .unwrap_or_default()
    // }

    /// Jump to specific index
    pub fn jump_to(&mut self, index: usize) -> Result<Option<&String>, String> {
        if index < self.tracks.len() {
            self.current_index = Some(index);
            Ok(self.current())
        } else {
            Err(format!("Index {} out of bounds", index))
        }
    }

    /// Remove track at index
    // pub fn remove(&mut self, index: usize) -> Option<String> {
    //     if index < self.tracks.len() {
    //         let removed = self.tracks.remove(index);

    //         // Adjust current_index if needed
    //         if let Some(current) = self.current_index {
    //             if current == index && current >= self.tracks.len() && !self.tracks.is_empty() {
    //                 self.current_index = Some(self.tracks.len() - 1);
    //             } else if current > index {
    //                 self.current_index = Some(current - 1);
    //             }
    //         }

    //         Some(removed)
    //     } else {
    //         None
    //     }
    // }

    pub fn add_many_and_jump_to_index(
        &mut self,
        uris: Vec<String>,
        index: usize,
    ) -> Result<Option<&String>, String> {
        self.clear();
        self.add_many(uris);
        if index > 0 {
            Ok(self.jump_to(index - 1)?)
        } else {
            let first = self.tracks.first();
            Ok(first)
        }
    }

    pub fn clear(&mut self) {
        self.tracks.clear();
        self.current_index = None;
    }

    // pub fn len(&self) -> usize {
    //     self.tracks.len()
    // }

    // pub fn is_empty(&self) -> bool {
    //     self.tracks.is_empty()
    // }
}
