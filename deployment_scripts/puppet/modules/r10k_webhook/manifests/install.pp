# == Class: r10k_webhook::install
#
# === Authors
#
# Scott Brimhall <sbrimhall@mirantis.com>, Serhii Levchenko <slevchenko@mirantis.com>
#
# === Copyright
#
# Copyright 2016 Mirantis Inc, unless otherwise noted.
#
class r10k_webhook::install (
  $app_dir         = $::r10k_webhook::app_dir,
  $group           = $::r10k_webhook::group,
  $user            = $::r10k_webhook::user,
  $mode            = $::r10k_webhook::mode,
  $puppetmasters   = $::r10k_webhook::puppetmasters,
) inherits ::r10k_webhook {

  include ::r10k_webhook::install::user
  include ::r10k_webhook::install::ruby
  include ::r10k_webhook::install::files
  include ::r10k_webhook::install::yum
  include ::r10k_webhook::install::apache

  Class['::r10k_webhook::install::user'] ->
  Class['::r10k_webhook::install::ruby'] ->
  Class['::r10k_webhook::install::files'] ->
  Class['::r10k_webhook::install::yum'] ->
  Class['::r10k_webhook::install::apache']

  file { 'gemfile_lock':
    path  => "${app_dir}/Gemfile.lock",
    owner => $user,
    group => $user,
    mode  => '0644',
  }

}
