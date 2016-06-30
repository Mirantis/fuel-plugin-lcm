# == Class: r10k
#
# Install r10k
#
# === Parameters
#
# * [*ensure*]
#   Version of r10k to install. Accepts any ensure state that is valid for the
#   Package type.
#   Default: present
# * [*private_config*]
#   Configuration options hash to access a private repo over ssh.
#   Hash:
#    {
#      repo_host => 'String',
#      repo_port => 'String',
#      username  => 'String',
#      key_path  => '/path/to/id_rsa',
#      r10k_key  => 'String',
#    }
#   Default: ''
# * [*user*]
#   User account for r10k to work under. For security reasons r10k operates under root by default
#   Default: root
# * [*group*]
#   Group account for r10k to work under. For security reasons r10k operates under root by default
#   Default: root
# * [*mode*]
#   Permissions mode for r10k related files.
#   Default: 0644


class r10k (
  $ensure         = 'present',
  $private_config = '',
  $user           = 'root',
  $group          = 'root',
  $mode           = '0644',
){

  package { 'git':
    ensure => $ensure,
  }->

  package { 'ruby-faraday':
    ensure => '0.9.2-1',
  }->

  package {
    [
      'ruby-r10k', 'ruby-log4r', 'ruby-backports', 'ruby-colored', 'ruby-cri',
      'ruby-faraday-middleware', 'ruby-minitar', 'ruby-multi-json', 'ruby-multipart-post', 'ruby-net-ssh',
      'ruby-puppet-forge', 'ruby-rack', 'ruby-rack-protection', 'ruby-rack-test', 'ruby-semantic-puppet',
      'ruby-sinatra', 'ruby-sinatra-config-file', 'ruby-sinatra-contrib', 'ruby-tilt'
    ]:
      ensure => $ensure,
  }

  file { '/var/cache/r10k':
    ensure => directory,
    owner  => $user,
    group  => $group,
    mode   => $mode,
  }

  if is_hash($private_config) {
    file { $private_config['key_path']:
      ensure  => file,
      owner   => $user,
      group   => $group,
      mode    => '0600',
      path    => $private_config['key_path'],
      content => $private_config['r10k_key'],
      require => File['/var/cache/r10k'],
    }
  }
}
