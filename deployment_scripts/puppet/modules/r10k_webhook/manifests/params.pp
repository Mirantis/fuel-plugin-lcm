# == Class: r10k_webhook::params
#
# This class sets up a sinatra app that listens for environments
# and modules to deploy to Puppetmasters via r10k
#
# === Parameters
#
# $vhost
#   The fqdn to use for the apache vhost.
#   Defaults to: ${::fqdn}.
#
# $app_dir
#   The directory to deploy the app into.
#   Defaults to /home/<current_user>/app.
#
# $user
#   The user for the app.
#   Defaults to 'r10kwebhook'.
#
# $mode
#   The docroot mode.
#   Defaults to '0755'.
#
# $webhook_key_owner
#   Real username authorized key-pair was generated for.
#   Defaults to 'root'.
#
# $puppetmasters
#   A hash of puppetmasters to deploy to.
#   Defaults to: ['puppet'].
#
# === Authors
#
# Scott Brimhall <sbrimhall@mirantis.com>, Serhii Levchenko <slevchenko@mirantis.com>
#
# === Copyright
#
# Copyright 2016 Mirantis Inc, unless otherwise noted.
#
class r10k_webhook::params {

  $vhost             = $::fqdn
  $domain            = $::domain
  $user              = 'r10kwebhook'
  $app_dir           = "/home/${user}/app"
  $mode              = '0755'
  $port              = '9292'
  $puppetmasters     = ['puppet']

}
