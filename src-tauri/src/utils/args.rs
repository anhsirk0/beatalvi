use clap::Parser;

#[derive(Parser)]
pub struct Args {
    /// Play/pause track
    #[arg(short, long)]
    pub toggle: bool,

    /// Skip to next track
    #[arg(short, long)]
    pub next: bool,

    /// Rewind to previous track
    #[arg(short, long)]
    pub previous: bool,

    /// Queue toggle track by track id
    #[arg(short, long)]
    pub queue: Option<i64>,

    /// Seek n seconds forwards
    #[arg(short, long)]
    pub seek: Option<u64>,

    /// Rewind n seconds
    #[arg(short, long)]
    pub rewind: Option<u64>,

    /// Toggle dark mode
    #[arg(short, long)]
    pub dark_toggle: bool,

    /// Set accent color (if exists)
    #[arg(short, long)]
    pub accent: Option<String>,
}
