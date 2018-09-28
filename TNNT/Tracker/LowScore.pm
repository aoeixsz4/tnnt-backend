#!/usr/bin/env perl

#=============================================================================
# Tracker for the "Lowest Score" trophy (both individual players and clans).
#=============================================================================

package TNNT::Tracker::LowScore;

use Moo;
use TNNT::ScoringEntry;



#=============================================================================
#=== ATTRIBUTES ==============================================================
#=============================================================================

has name => (
  is => 'ro',
  default => 'lowscore',
);

has player => (
  is => 'rwp',
);

has clan => (
  is => 'rwp',
);

has game => (
  is => 'rwp',
);

has lowest_score => (
  is => 'rwp',
);



#=============================================================================
#=== METHODS =================================================================
#=============================================================================

sub add_game
{
  my ($self, $game) = @_;
  my $player = $game->player();
  my $clan = $player->clan();

  #--- count only ascending games

  return if !$game->is_ascended();

  #--- current game has the most conducts so far

  if(
    !defined $self->lowest_score()
    || $game->points() < $self->lowest_score()
  ) {

  #--- remove scoring entry from previous holder (if any)

    if($self->player()) {
      $self->player()->remove_score($self->name());
    }
    if($self->game()) {
      $self->game()->remove_score($self->name());
    }
    if($self->clan()) {
      $self->clan()->remove_score('clan-' . $self->name());
    }

  #--- set player and game

    $self->_set_game($game);
    $self->_set_player($game->player());
    $self->_set_clan($clan);

  #--- add scoring entry to new holder

    my $se_player = new TNNT::ScoringEntry(
      trophy => $self->name(),
      games  => [ $game ],
      data   => { score => $game->points() },
      when   => $game->endtime(),
    );

    my $se_clan = new TNNT::ScoringEntry(
      trophy => 'clan-' . $self->name(),
      games  => [ $game ],
      data   => { score => $game->points() },
      when   => $game->endtime(),
    );

    $game->player()->add_score($se_player);
    $game->add_score($se_player);
    $clan->add_score($se_clan) if $clan;

  #--- store new max value

    $self->_set_lowest_score($game->points());

  }

}


sub finish
{
}



#=============================================================================

1;
