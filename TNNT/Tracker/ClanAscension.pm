#!/usr/bin/env perl

#=============================================================================
# Tracker for clan ascensions. It uses data from player-scoring trackers,
# so this should be run after these.
#
# The clan ascension scoring uses the values from player ascension scoring,
# but limits it only to the best ascension per combo.
#=============================================================================

package TNNT::Tracker::ClanAscension;

use Moo;
use TNNT::ScoringEntry;



#=============================================================================
#=== ATTRIBUTES ==============================================================
#=============================================================================

has name => (
  is => 'ro',
  default => 'clan-ascension',
);

# clan tracking information

has clantrk => (
  is => 'rwp',
  default => sub { {} },
);



#=============================================================================
#=== METHODS =================================================================
#=============================================================================

sub add_game
{
  my (
    $self,
    $game,
  ) = @_;

  #--- only ascended games

  return if !$game->is_ascended();

  #--- initialize

  my $player_name = $game->player()->name();
  my $clan = $game->player()->clan();

  #--- following section only run when the player is a clan member

  if($clan) {
    my $clan_name = $clan->name();
    if(!exists $self->clantrk()->{$clan_name}) {
      $self->clantrk()->{$clan_name} = {};
    }
    my $clan_trk = $self->clantrk()->{$clan_name};
    my $combo = join('-',
      $game->role(),
      $game->race(),
      $game->gender0(),
      $game->align0()
    );

  #--- only following types of entries are counted for ascension score
  #--- for clan scoring purposes

    my @filter = ('ascension', 'conduct', 'speedrun', 'streak');

  #--- create new scoring entry

    my $se = new TNNT::ScoringEntry(
      trophy => $self->name(),
      games => [ $game ],
      when => $game->endtime,
      points => $game->sum_score(@filter),
      data => { combo => $combo },
    );

    #--- the clan already has the game of the same character combo

    if(
      exists $clan_trk->{$combo}
      && $clan_trk->{$combo} < $game->sum_score(@filter)
    ) {
      $clan->remove_and_add('combo', $combo, $se);
      $clan_trk->{$combo} = $game->sum_score(@filter);
    }

  #--- new unique combo game for the clan

    elsif(!exists $clan_trk->{$combo}) {
      $clan->add_score($se);
      $clan_trk->{$combo} = $game->sum_score(@filter);
      $clan->unique_ascs($clan->unique_ascs() + 1);
    }
  }

  #--- finish

  return $self;
}



sub finish
{
}



#=============================================================================

1;
