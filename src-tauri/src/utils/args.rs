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
}
