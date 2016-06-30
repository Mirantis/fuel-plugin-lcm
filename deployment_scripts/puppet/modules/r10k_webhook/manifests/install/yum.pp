# == Class: r10k_webhook::install::yum
#
# === Authors
#
# Scott Brimhall <sbrimhall@mirantis.com>, Serhii Levchenko <slevchenko@mirantis.com>
#
# === Copyright
#
# Copyright 2016 Mirantis Inc, unless otherwise noted.
#
class r10k_webhook::install::yum {

  # Since there isn't an upstream passenger package for centos 7, install foreman repo
  case $::operatingsystem {
    'CentOS': {
      case $::operatingsystemrelease {
        /^7/: {
          if ! defined(Package['foreman-release']) {
            package { 'foreman-release':
            ensure   => 'present',
            provider => 'rpm',
            source   => 'http://yum.theforeman.org/releases/latest/el7/x86_64/foreman-release.rpm'
            }
          }
        }
        default: {
          notify {'This is not a CentOS 7 box. Not installing foreman-release for mod_passenger':}
        }
      }
    }
    default: {
      notify {'This is not a CentOS 7 system, not installing foreman-release for mod_passenger':}
    }
  }
}
