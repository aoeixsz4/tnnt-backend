#!/usr/bin/env perl

#=============================================================================
# Tracker for the "Most Conducts in one Ascensions" trophy (both individual
# players and clans).
#=============================================================================

package TNNT::Tracker::MostCond;

use Moo;
use TNNT::ScoringEntry;



#=============================================================================
#=== ATTRIBUTES ==============================================================
#=============================================================================

has name => (
  is => 'ro',
  default => 'mostcond',
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

has maxcond => (
  is => 'rwp',
  default => sub { 0 },
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

  if($game->conducts() > $self->maxcond()) {

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

  #--- set player, game and clan

    $self->_set_game($game);
    $self->_set_player($game->player());
    $self->_set_clan($clan);

  #--- add scoring entry to new holder

    my $se_player = new TNNT::ScoringEntry(
      trophy => $self->name(),
      games  => [ $game ],
      data   => { nconds => scalar($game->conducts()) },
      when   => $game->endtime(),
    );

    my $se_clan = new TNNT::ScoringEntry(
      trophy => 'clan-' . $self->name(),
      games  => [ $game ],
      data   => { nconds => scalar($game->conducts()) },
      when   => $game->endtime(),
    );

    $game->player()->add_score($se_player);
    $game->add_score($se_player);
    $clan->add_score($se_clan) if $clan;

  #--- store new max value

    $self->_set_maxcond(scalar($game->conducts()));

  }

}



sub finish
{
}



#=============================================================================

1;
