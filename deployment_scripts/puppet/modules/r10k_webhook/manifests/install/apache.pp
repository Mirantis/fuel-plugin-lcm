# == Class: r10k_webhook::install::apache
#
# === Authors
#
# Scott Brimhall <sbrimhall@mirantis.com>, Serhii Levchenko <slevchenko@mirantis.com>
#
# === Copyright
#
# Copyright 2016 Mirantis Inc, unless otherwise noted.
#
class r10k_webhook::install::apache {

  # Install Apache and mod_passenger
  if $::osfamily == 'RedHat' and $::operatingsystemrelease =~ /^7/ {
    class { '::apache':
      require       => Package['foreman-release'],
      purge_configs => false,
    }
  }
  else {
    class { '::apache':
      purge_configs => false,
    }
  }
  class { '::apache::mod::passenger': }
}