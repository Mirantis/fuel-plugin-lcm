# == Class: r10k::config
#
# Set up the root r10k config file (/etc/r10k.yaml).
#
# === Parameters
# * [*private_config*]
#   Configuration options hash to access a private repo over ssh.
#   Hash:
#    {
#      repo_host => 'String',
#      repo_port => 'String',
#      username  => 'String',
#      key_path  => '/path/to/id_rsa,
#      r10k_key  => 'String',
#    }
#   Default: ''
# * [*remote_repo*]
#   Direct ssh link for a control repo.
#   Default: ''
# * [*cachedir*]
#   Path to r10k cache directory.
#   Default: /var/cache/r10k
# * [*postrun*]
#   An array of strings that specifies an arbitrary command to be run after
#   environment deployment, where first element is 'cmd'.
#   Default: []
# * [*path*]
#   The path at which the r10k config is written.
#   Default: /etc/r10k.yaml
# * [*user*]
#   User account for r10k to work under. For security reasons r10k operates under root by default
#   Default: root
# * [*group*]
#   Group account for r10k to work under. For security reasons r10k operates under root by default
#   Default: root
# * [*mode*]
#   Permissions mode for r10k related files.
#   Default: 0644

class r10k::config (
  $private_config = '',
  $remote_repo    = '',
  $cachedir       = '/var/cache/r10k',
  $postrun        = [],
  $path           = '/etc/puppetlabs/r10k/r10k.yaml',
  $user           = 'root',
  $group          = 'root',
  $mode           = '0644',
){

  file { [ '/etc/puppetlabs', '/etc/puppetlabs/r10k' ]:
    ensure => 'directory',
  }->

  file { $path:
    ensure  => 'file',
    recurse => true,
    owner   => $user,
    group   => $group,
    mode    => $mode,
    content => template('r10k/r10k.yaml.erb'),
  }

  if is_hash($private_config) {
    file { '/root/.ssh/config':
      ensure  => 'file',
      recurse => true,
      owner   => $user,
      group   => $group,
      mode    => '0600',
      content => template('r10k/ssh_config.erb'),
    }
  }
}