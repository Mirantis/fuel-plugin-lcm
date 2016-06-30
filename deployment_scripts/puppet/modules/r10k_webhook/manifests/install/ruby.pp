# == Class: r10k_webhook::install::ruby
#
# === Authors
#
# Scott Brimhall <sbrimhall@mirantis.com>, Serhii Levchenko <slevchenko@mirantis.com>
#
# === Copyright
#
# Copyright 2016 Mirantis Inc, unless otherwise noted.
#
class r10k_webhook::install::ruby {

  # Make sure ruby is setup and we have rubygems installed
  if defined(Class['::ruby']) {
    include ::ruby
  }

  case $::operatingsystem {
      'CentOS': {
        if ! defined(Package['rubygems']) {
          package { 'rubygems':
          ensure => 'present',
        }
      }
    }
    default: {
      notify {'This is not a CentOS box. Not installing rubygems ':}
    }
  }

}
