#!/usr/bin/perl -w

use strict;
use Getopt::Long;

# args
my $help;
my $by_recent;
my $by_artist;
my $by_album;

my $db          = "$ENV{HOME}/.config/beatalvi/beatalvi.db";
my $rofi_config = "$ENV{HOME}/.config/beatalvi-rofi/config.rasi";

# dont add ';' at the end
my $query = q{select tracks.id, tracks.name, artists.name from tracks
              join track_artists on track_artists.track_id = tracks.id
              join artists on track_artists.artist_id = artists.id
              join albums on tracks.album_id = albums.id
};

# get current playing song and artist
sub get_song_and_artist {
    my ( $song, $artist ) = grep /title|artist/, split "\n", `pactl list`;
    s/.*?\"//, s/\(.*?\)|\"//g, s/\s+$//, chomp for $song, $artist;
    $artist =~ s/ & /, /;
    return ( $song, $artist );
}

# add current song info to rofi menu placeholder
sub update_rofi_placeholder {
    my ($placeholder) = @_;

    # read config
    my $config_content = "";
    open( FH, '<', $rofi_config )
      or die
qq{Unable to open: $rofi_config \nHint: move this directory to '~/.config/beatalvi-rofi'\n};
    while (<FH>) {
        if ( $_ =~ /place/ ) {
            $_ =~ s/\".*\"/\"$placeholder\"/;
        }
        $config_content .= $_;
    }
    close(FH);

    # write config
    open( FH, '>', $rofi_config ) or die "Unable to open\n";
    print FH $config_content;
    close(FH);
}

sub main {
    GetOptions(
        "help|h"     => \$help,
        "recent|r"   => \$by_recent,
        "artist|a=s" => \$by_artist,
        "album|b=s"  => \$by_album,
    ) or die("Error in command line arguments\n");
    print_help_and_exit() if ($help);

    # dont add ';'
    if ( $by_artist && $by_album ) {
        $query .=
qq{where artists.name like '%$by_artist%' and albums.name like '%$by_album%'\n};
    }
    elsif ($by_artist) {
        $query .= qq{where artists.name like '%$by_artist%'\n};   # dont add ';'
    }
    elsif ($by_album) {
        $query .= qq{where albums.name like '%$by_album%'\n};     # dont add ';'
    }

    # make sure to add ';' at the end
    if ($by_recent) {
        $query .= q{order by albums.mtime desc;};
    }
    else {
        $query .= q{order by tracks.popularity desc;};
    }

    my @all = split "\n", `echo "$query" | sqlite3 $db`;

    # collect songs in @songs (no duplicates)
    my %seen  = ();
    my @songs = grep { !$seen{ substr $_, 0, 4 }++ } @all;

    my @names = ("Play next");
    my %ids   = ();              # { "name" => id }

    # refactoring song names and populating @names and %ids
    foreach my $song (@songs) {

        # s/Ft.*\|/|/g, s/\(.*?\)//g, s/\|/+/, s/\|/ -  / for $song;
        s/\|/+/, s/\|/ -  / for $song;
        my @temp = split( '\+', $song );
        $ids{ $temp[1] } = $temp[0];
        push( @names, $temp[1] );
    }

    my $total = scalar %ids;

    # update rofi placeholder
    my ( $song, $artist ) = get_song_and_artist();
    my $placeholder = "\t" x 2 . "  $song - $artist";
    update_rofi_placeholder($placeholder);

    my $joined_names = join "\n", @names;
    my $rofi_args = "-p 'Add song to Queue ($total):' -i -theme $rofi_config";
    chomp( my $var = `echo "$joined_names" | rofi -dmenu $rofi_args` );

    # restore rofi placeholder , this is optional
    update_rofi_placeholder("");

    exit unless ($var);
    if ( $var eq "Play next" ) {
        system('notify-send "Next"; beatalvi --next');
    }
    else {
        my ( $song, $artist ) = split "-", $var;
        system(
            qq{notify-send "=> $song" "$artist"; beatalvi --queue $ids{$var}});
    }
}

sub print_help_and_exit {
    my $help_text = qq{usage: ./launcher.pl [options]\n
    -h, --help \t\t\t show help message
    -r, --recent \t\t sort by recently added
    -a, --artist=STR \t\t list by artist name
    -b, --album=STR \t\t list by album name

examples:
    ./launcher.pl --recent
    ./launcher.pl -a 'Arjan Dhillon'
    ./launcher.pl -b 'A for Arjan'
    ./launcher.pl -a 'Arjan Dhillon' -b 'shikhar' -r
};

    print $help_text;
    exit;
}

main()
