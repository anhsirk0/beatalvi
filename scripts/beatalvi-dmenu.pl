#!/usr/bin/env perl
use warnings;

my $db    = "$ENV{HOME}/.config/beatalvi/beatalvi.db";
my $query = q{select tracks.id, tracks.name, artists.name from tracks
              join track_artists on track_artists.track_id = tracks.id
              join artists on track_artists.artist_id = artists.id
              order by popularity desc;};

my @all = split "\n", `echo "$query" | sqlite3 $db`;

# collect songs in @songs (no duplicates)
my %seen  = ();
my @songs = grep { !$seen{ substr $_, 0, 5 }++ } @all;

my @names = ();
my %ids   = ();    # { "name" => id }

# refactoring song names and populating @names and %ids
foreach my $song (@songs) {

    # cleanup names
    s/\|/+/, s/\|/ -  / for $song;
    my @temp = split( '\+', $song );
    $ids{ $temp[1] } = $temp[0];
    push( @names, $temp[1] );
}

my $joined_names = join "\n", @names;
my $prompt       = "Beatalvi »";
chomp( my $var = `echo "$joined_names" | dmenu -p "$prompt" -l 30 -i` );

exit unless ($var);
my ( $song, $artist ) = split "-", $var;
system(qq{notify-send "=> $song" "$artist"; beatalvi --queue $ids{$var}});

