# == Class: r10k_webhook
#
# This class sets up a sinatra app that listens for environments
# and modules to r10k_webhook to Puppetmasters via r10k
#
# === Parameters
#
# $vhost
#   The fqdn to use for the apache vhost.  Defaults to ${::fqdn}.
#
# $app_dir
#   The directory to deploy the app into. Defaults to /home/r10k_webhook/app.
#
# $group
#   The group for the app. Defaults to 'r10kwbebhook'.
#
# $user
#   The user for the app. Defaults to 'r10kwebhook'.
#
# $mode
#   The docroot mode. Defaults to '0755'.
#
# $port
#   The port the app will listen on. Defaults to 9292.
#
# === Examples
#
#  $config = hiera('r10k_webhook::config')
#
#  class { 'r10k_webhook':
#    app_dir       => $config[app_dir],
#    group         => $config[group],
#    user          => $config[user],
#    mode          => $config[mode],
#  }
#
# === Authors
#
# Scott Brimhall <sbrimhall@mirantis.com>, Serhii Levchenko <slevchenko@mirantis.com>
#
# === Copyright
#
# Copyright 2016 Mirantis Inc, unless otherwise noted.
#
class r10k_webhook (
  $network_metadata      = pick($network_metadata, {}),
  $vhost                 = $::r10k_webhook::params::vhost,
  $domain                = $::r10k_webhook::params::domain,
  $app_dir               = $::r10k_webhook::params::app_dir,
  $group                 = $::r10k_webhook::params::group,
  $user                  = $::r10k_webhook::params::user,
  $mode                  = $::r10k_webhook::params::mode,
  $port                  = $::r10k_webhook::params::port,
  $foreman_user          = $::r10k_webhook::foreman_user,
  $foreman_password      = $::r10k_webhook::foreman_password,
  $foreman_api_call      = $::r10k_webhook::foreman_api_call,
) inherits ::r10k_webhook::params {

  # Validate parameters
  validate_hash($network_metadata)
  validate_string($app_dir)
  validate_string($group)
  validate_string($user)
  validate_string($mode)
  validate_string($port)
  validate_string($foreman_user)
  validate_string($foreman_password)
  validate_string($foreman_api_call)

  # Call private classes to install and configure the app
  include ::r10k_webhook::install
  include ::r10k_webhook::config

  # Order them the way we want

  Class['::r10k_webhook::install'] ->
  Class['::r10k_webhook::config']
}
