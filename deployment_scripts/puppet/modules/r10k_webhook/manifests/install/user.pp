# == Class: r10k_webhook::install::user
#
# === Authors
#
# Scott Brimhall <sbrimhall@mirantis.com>,  Serhii Levchenko <slevchenko@mirantis.com>
#
# === Copyright
#
# Copyright 2016 Mirantis Inc, unless otherwise noted.
#
class r10k_webhook::install::user (
  $user         = $::r10k_webhook::user,
  $group        = $::r10k_webhook::user,
) inherits ::r10k_webhook::install {

  # Validate parameters
  validate_string($user)
  validate_string($group)

  group { $group:
    ensure => 'present',
  }

  # Setup r10k_webhook user if it doesn't exist already
  if ! defined(User[$user]) {
    user { $user:
      ensure     => 'present',
      shell      => '/bin/bash',
      home       => "/home/${user}",
      groups     => $group,
      managehome => true,
    }
  }
}