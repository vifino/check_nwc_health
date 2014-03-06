package Classes::CiscoIOS::Component::TemperatureSubsystem;
our @ISA = qw(GLPlugin::Item);
use strict;

sub init {
  my $self = shift;
  my $tempcnt = 0;
  $self->get_snmp_tables('CISCO-ENVMON-MIB', [
      ['temperatures', 'ciscoEnvMonTemperatureStatusTable', 'Classes::CiscoIOS::Component::TemperatureSubsystem::Temperature'],
  ]);
  foreach (@{$self->{temperatures}}) {
    $_->{ciscoEnvMonTemperatureStatusIndex} = $tempcnt++ if (! exists $_->{ciscoEnvMonTemperatureStatusIndex});
  }
}

sub check {
  my $self = shift;
  $self->add_info('checking temperatures');
  $self->blacklist('t', '');
  if (scalar (@{$self->{temperatures}}) == 0) {
  } else {
    foreach (@{$self->{temperatures}}) {
      $_->check();
    }
  }
}


package Classes::CiscoIOS::Component::TemperatureSubsystem::Temperature;
our @ISA = qw(GLPlugin::TableItem);
use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    blacklisted => 0,
    info => undef,
    extendedinfo => undef,
  };
  foreach (keys %params) {
    $self->{$_} = $params{$_};
  }
  $self->{ciscoEnvMonTemperatureStatusIndex} ||= 0;
  $self->{ciscoEnvMonTemperatureLastShutdown} ||= 0;
  if ($self->{ciscoEnvMonTemperatureStatusValue}) {
    bless $self, $class;
  } else {
    bless $self, $class.'::Simple';
  }
  return $self;
}

sub check {
  my $self = shift;
  $self->blacklist('t', $self->{ciscoEnvMonTemperatureStatusIndex});
  if ($self->{ciscoEnvMonTemperatureStatusValue} >
      $self->{ciscoEnvMonTemperatureThreshold}) {
    $self->add_info(sprintf 'temperature %d %s is too high (%d of %d max = %s)',
        $self->{ciscoEnvMonTemperatureStatusIndex},
        $self->{ciscoEnvMonTemperatureStatusDescr},
        $self->{ciscoEnvMonTemperatureStatusValue},
        $self->{ciscoEnvMonTemperatureThreshold},
        $self->{ciscoEnvMonTemperatureState});
    if ($self->{ciscoEnvMonTemperatureState} eq 'warning') {
      $self->add_warning();
    } elsif ($self->{ciscoEnvMonTemperatureState} eq 'critical') {
      $self->add_critical();
    }
  } else {
    $self->add_info(sprintf 'temperature %d %s is %d (of %d max = normal)',
        $self->{ciscoEnvMonTemperatureStatusIndex},
        $self->{ciscoEnvMonTemperatureStatusDescr},
        $self->{ciscoEnvMonTemperatureStatusValue},
        $self->{ciscoEnvMonTemperatureThreshold},
        $self->{ciscoEnvMonTemperatureState});
  }
  $self->add_perfdata(
      label => sprintf('temp_%s', $self->{ciscoEnvMonTemperatureStatusIndex}),
      value => $self->{ciscoEnvMonTemperatureStatusValue},
      warning => $self->{ciscoEnvMonTemperatureThreshold},
      critical => undef,
  );
}


package Classes::CiscoIOS::Component::TemperatureSubsystem::Temperature::Simple;
our @ISA = qw(GLPlugin::TableItem);
use strict;

sub check {
  my $self = shift;
  $self->{ciscoEnvMonTemperatureStatusIndex} ||= 0;
  $self->{ciscoEnvMonTemperatureStatusDescr} ||= 0;
  $self->blacklist('t', $self->{ciscoEnvMonTemperatureStatusIndex});
  $self->add_info(sprintf 'temperature %d %s is %s',
      $self->{ciscoEnvMonTemperatureStatusIndex},
      $self->{ciscoEnvMonTemperatureStatusDescr},
      $self->{ciscoEnvMonTemperatureState});
  if ($self->{ciscoEnvMonTemperatureState} ne 'normal') {
    if ($self->{ciscoEnvMonTemperatureState} eq 'warning') {
      $self->add_warning();
    } elsif ($self->{ciscoEnvMonTemperatureState} eq 'critical') {
      $self->add_critical();
    }
  } else {
  }
}
