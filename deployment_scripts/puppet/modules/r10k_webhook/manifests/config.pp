# == Class: r10k_webhook::config
#
# === Authors
#
# Scott Brimhall <sbrimhall@mirantis.com>, Serhii Levchenko <slevchenko@mirantis.com>
#
# === Copyright
#
# Copyright 2016 Mirantis Inc, unless otherwise noted.
#
class r10k_webhook::config (
  $vhost             = $::r10k_webhook::vhost,
  $app_dir           = $::r10k_webhook::app_dir,
  $user              = $::r10k_webhook::user,
  $mode              = $::r10k_webhook::mode,
  $foreman_user      = $::r10k_webhook::foreman_user,
  $foreman_password  = $::r10k_webhook::foreman_password,
  $foreman_api_call  = $::r10k_webhook::foreman_api_call,

) inherits ::r10k_webhook {

  include ::plugin_lcm

  $lcm_nodes       = $::plugin_lcm::lcm_all_hash
  $middleware_port = $::plugin_lcm::lcm_middleware_port
  $puppetmasters   = filter_hash(values($lcm_nodes), 'fqdn')

  exec { 'restart-app':
    command     => "/usr/bin/touch \"${app_dir}/tmp/restart.txt\"",
    path        => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin',
    refreshonly => true,
    subscribe   => File[['app-config', 'app']],
  }

  file { 'app-config':
    path    => "${app_dir}/config.yaml",
    owner   => $user,
    group   => $user,
    mode    => '0644',
    content => template('r10k_webhook/config.yaml.erb'),
    notify  => Exec['restart-app'],
  }->

  file { 'app':
    path    => "${app_dir}/r10k_webhook.rb",
    owner   => $user,
    group   => $user,
    mode    => '0644',
    content => template('r10k_webhook/r10k_webhook.rb.erb'),
    notify  => Exec['restart-app'],
  }->

  file { 'app-sudo':
    path    => '/etc/sudoers.d/r10k-webhook',
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('r10k_webhook/sudo_r10k_webhook.erb'),
    notify  => Exec['restart-app'],
  }->

  apache::vhost { 'r10k-middleware':
    ensure         => 'present',
    servername     => $vhost,
    docroot        => "${app_dir}/public",
    docroot_group  => $user,
    docroot_owner  => $user,
    manage_docroot => false,
    directories    => [
      { path              => "${app_dir}/public",
        passenger_enabled => 'on',
      },
    ],
    port           => $middleware_port,
  }

  apache::listen { $::plugin_lcm::lcm_apache_ports: }

}
