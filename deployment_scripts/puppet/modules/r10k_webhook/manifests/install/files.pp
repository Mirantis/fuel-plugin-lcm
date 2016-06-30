# == Class: r10k_webhook::install::files
#
# === Authors
#
# Scott Brimhall <sbrimhall@mirantis.com>, Serhii Levchenko <slevchenko@mirantis.com>
#
# === Copyright
#
# Copyright 2015 Mirantis Inc, unless otherwise noted.
#
class r10k_webhook::install::files (
  $app_dir             = $::r10k_webhook::app_dir,
  $user                = $::r10k_webhook::user,
  $mode                = $::r10k_webhook::mode,
  $puppetmasters       = $::r10k_webhook::puppetmasters,
  $webhook_auth_user   = $::r10k_webhook::webhook_auth_user,
  $domain              = $::r10k_webhook::domain,
) inherits ::r10k_webhook::install {


  # Setup app directory and docroot

  file { $app_dir:
    ensure => 'directory',
    owner  => $user,
    group  => $user,
    mode   => $mode,
  }

  file { 'tmpdir':
    ensure => 'directory',
    path   => "${app_dir}/tmp",
    owner  => $user,
    group  => $user,
    mode   => $mode,
  }

  file { 'public':
    ensure => 'directory',
    path   => "${app_dir}/public",
    owner  => $user,
    group  => $user,
    mode   => $mode,
  }

  file { 'homedir':
    ensure => 'directory',
    path   => "/home/${user}",
    owner  => $user,
    group  => $user,
    mode   => $mode,
  }


  # Ensure passenger restart file exists
  file { 'restart-txt':
    ensure  => 'present',
    path    => "${app_dir}/tmp/restart.txt",
    owner   => $user,
    group   => $user,
    mode    => '0644',
    content => '',
  }

  file { 'config.ru':
    ensure  => 'file',
    path    => "${app_dir}/config.ru",
    owner   => $user,
    group   => $user,
    mode    => '0644',
    content => template('r10k_webhook/config.ru.erb'),
    notify  => Exec['restart-app'],
  }
}
