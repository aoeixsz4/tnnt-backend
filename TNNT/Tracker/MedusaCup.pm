#!/usr/bin/env perl

#=============================================================================
# Tracker for the Medusa Cup clan trophy.
#=============================================================================

package TNNT::Tracker::MedusaCup;

use Moo;
use TNNT::ScoringEntry;



#=============================================================================
#=== ATTRIBUTES ==============================================================
#=============================================================================

has name => (
  is => 'ro',
  default => 'clan-medusacup',
);

has eligible_clans => (
  is => 'ro',
  lazy => 1,
  builder => 1,
);

has topclan => (
  is => 'rwp',
);



#=============================================================================
#=== METHODS =================================================================
#=============================================================================

#-----------------------------------------------------------------------------
# List of clans eligible for the trophy, ie. clans that have no ascensions.
#-----------------------------------------------------------------------------

sub _build_eligible_clans
{
  my ($self) = @_;

  my %eligible_clans;
  TNNT::ClanList->instance()->iter_clans(sub {
    $eligible_clans{$_[0]->name()} = 1;
  });

  return \%eligible_clans;
}


#-----------------------------------------------------------------------------
# Process one game.
#-----------------------------------------------------------------------------

sub add_game
{
  my ($self, $game) = @_;
  my $clans = TNNT::ClanList->instance();
  my $clan = $game->player()->clan();

  #--- only clan games

  return if !$clan;

  #--- only eligible clans

  return if !$self->eligible_clans()->{$clan->name()};

  #--- aux function to find highest-scoring eligible clan
  # FIXME: This doesn't handle ties

  my $get_new_clan = sub {
    my @sorted =
    sort { $b->sum_score('!clan-medusacup') <=> $a->sum_score('!clan-medusacup')}
    map  { $clans->clans()->{$_} }
    grep { $self->eligible_clans()->{$_} }
    keys %{$self->eligible_clans()};

    return $sorted[0];
  };

  #--- if eligible clan has ascended game, make it ineligible

  if(
    $game->is_ascended()
    && $self->eligible_clans()->{$clan->name()}
  ) {
    $self->eligible_clans()->{$clan->name()} = 0;
    if($self->topclan() && $self->topclan()->name() eq $clan->name()) {
      $self->_set_topclan(undef);
      $clan->remove_score($self->name());
    }
  }

  #--- get new clan

  my $new_clan = $get_new_clan->();

  #--- if the leading clan has not changed, do nothing

  if(
    $self->topclan()
    && $self->topclan()->name() eq $new_clan->name()
  ) {
    return $self;
  }

  #--- if there's leader, remove its scoring entry

  if($self->topclan()) {
    $self->topclan()->remove_score($self->name());
  }

  #--- create new scoring entry for the new leader

  # but only if they have non-zero score; this avoids the problem where
  # multiple clans with zero score (at the start of the tournament) get
  # randomly assigned the Medusa Cup

  if(
    $new_clan && $new_clan->sum_score('!clan-medusacup')
  ) {
    $new_clan->add_score(TNNT::ScoringEntry->new(
      trophy => $self->name(),
      when => $game->endtime(),
    ));
  }

  #--- and record current state

  $self->_set_topclan($new_clan);

  #--- finish

  return $self;
}


#-----------------------------------------------------------------------------
# Tracker cleanup.
#-----------------------------------------------------------------------------

sub finish
{
}



#=============================================================================

1;
