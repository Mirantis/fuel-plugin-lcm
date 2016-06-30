#    Copyright 2016 Mirantis, Inc.
#
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.

class plugin_lcm::tasks::foreman {

  include '::plugin_lcm'
  include '::foreman::params'

  $lcm_apache_ports       = $::plugin_lcm::lcm_apache_ports
  $perconadb_port         = $::plugin_lcm::perconadb_port
  $foreman_proxy          = $::plugin_lcm::foreman_proxy_port
  $puppetmaster_port      = $::plugin_lcm::puppetmaster_port
  $lcm_hiera_values       = $::plugin_lcm::lcm_hiera_values
  $lcm_network_metadata   = hiera_hash('network_metadata')

  $downcase_fqdn          = downcase($::fqdn)
  $puppetmaster_vip_name  = downcase("puppet.${::domain}")
  $db_pass                = $lcm_hiera_values['foreman_db_password']

  $foreman_user           = $lcm_hiera_values['foreman_user']
  $foreman_password       = $lcm_hiera_values['foreman_password']
  $oauth_consumer_key     = pick($lcm_hiera_values['oauth_consumer_key'], cache_data('foreman_cache_data', 'oauth_consumer_key', random_password(32)))
  $oauth_consumer_secret  = pick($lcm_hiera_values['oauth_consumer_secret'], cache_data('foreman_cache_data', 'oauth_consumer_secret', random_password(32)))

  $foreman_base_url       = pick($lcm_hiera_values['foreman_base_url'], "https://${downcase_fqdn}")
  $foreman_cert_dir       = $::plugin_lcm::foreman_cert_dir

  $oauth_effective_user   = $lcm_hiera_values['oauth_effective_user']

  $tftp                   = $lcm_hiera_values['tftp']
  $dhcp                   = $lcm_hiera_values['dhcp']
  $dns                    = $lcm_hiera_values['dns']
  $bmc                    = $lcm_hiera_values['bmc']
  $db_host                = $lcm_network_metadata['vips']['lcm']['ipaddr']

  $tmp_dir                = fqdn_rand_string(10, 'ABCDEFabcdx351')
  $firewall_foreman_proxy = suffix($::plugin_lcm::lcm_nodes_ips, ":${foreman_proxy}")

  # We have to remove next packages from the catalog
  # because of conflict with percona packages
  Package<|
  (title == 'mysql_client') or
  (title == 'mysql-server')
  |> {
    ensure => absent,
  }

  File<| title == 'mysql-config-file' |> {
    ensure => absent,
    path   => "/tmp/${tmp_dir}",
  }

  File<|
  (title == '/etc/apache2/sites-enabled') or
  (title == '/etc/apache2/sites-available')
  |> {
    purge => false,
  }

  Mysql::Db<| title == 'foreman' |> {
    host => '%',
  }

  tidy { '/etc/apache2':
    recurse => true,
    matches => '000-default.conf',
    require => Package['httpd'],
    notify  => Service['httpd'],
  }

  apache::listen { $lcm_apache_ports: }

  $common_foreman_hash = {
    '::foreman' => {
      custom_repo             => true,
      db_type                 => 'mysql',
      db_host                 => $db_host,
      db_port                 => $perconadb_port,
      db_password             => $db_pass,
      admin_username          => $foreman_user,
      admin_password          => $foreman_password,
      oauth_map_users         => true,
      oauth_consumer_key      => $oauth_consumer_key,
      oauth_consumer_secret   => $oauth_consumer_secret,
      passenger_prestart      => true,
      passenger_min_instances => '1',
      passenger_start_timeout => '600',
      puppetrun               => true,
      logging_level           => 'debug',
    },
  }

  $own_ssl_certificate         = $lcm_hiera_values['own_ssl_certificate']

  if ($own_ssl_certificate and
  $lcm_hiera_values['ssl_foreman_cert_private_key'] != '' and
  $lcm_hiera_values['ssl_foreman_cert'] != '' and
  $lcm_hiera_values['ssl_foreman_ca'] != '')  {

    $ssl_foreman_private_key      = $lcm_hiera_values['ssl_foreman_cert_private_key'][content]
    $ssl_foreman_private_key_name = $lcm_hiera_values['ssl_foreman_cert_private_key'][name]
    $ssl_foreman_cert             = $lcm_hiera_values['ssl_foreman_cert'][content]
    $ssl_foreman_cert_name        = $lcm_hiera_values['ssl_foreman_cert'][name]
    $ssl_foreman_ca               = $lcm_hiera_values['ssl_foreman_ca'][content]
    $ssl_foreman_ca_name          = $lcm_hiera_values['ssl_foreman_ca'][name]
    $ssl_crl_exists               = $lcm_hiera_values['ssl_crl_location']
    if is_hash($ssl_crl_exists) {
      $ssl_crl_location             = $lcm_hiera_values['ssl_crl_location'][content]
      $ssl_crl_location_name        = $lcm_hiera_values['ssl_crl_location'][name]
    }


    if ($ssl_foreman_private_key != '') and ($ssl_foreman_cert != '') {
      file { $foreman_cert_dir:
        ensure => 'directory',
        owner  => 'foreman',
        group  => 'puppet',
        mode   => '0750',
      }

      File <|
      (title == $ssl_foreman_private_key_name) or
      (title == $ssl_foreman_cert_name) or
      (title == $ssl_crl_location_name) or
      (title == $ssl_foreman_ca_name)
      |> {
        ensure  => 'file',
        owner   => 'foreman',
        group   => 'puppet',
        mode    => '640',
        require => File[$foreman_cert_dir],
      }
      file { $ssl_foreman_private_key_name:
        path    => "${foreman_cert_dir}/${ssl_foreman_private_key_name}",
        content => $ssl_foreman_private_key,
      }
      file { $ssl_foreman_cert_name:
        path    => "${foreman_cert_dir}/${ssl_foreman_cert_name}",
        content => $ssl_foreman_cert,
      }
      file { $ssl_foreman_ca_name:
        path    => "${foreman_cert_dir}/${ssl_foreman_ca_name}",
        content => $ssl_foreman_ca,
      }
    }

    $ssl_ca_file = "${foreman_cert_dir}/${ssl_foreman_ca_name}" #Use custom ca file
    if is_hash($ssl_crl_exists) {
      file { $ssl_crl_location_name:
        path    => "${foreman_cert_dir}/${ssl_crl_location_name}",
        content => $ssl_crl_location,
      }
      $foreman_hash = deep_merge($common_foreman_hash,
        {
          '::foreman' => {
            server_ssl_key  => "${foreman_cert_dir}/${ssl_foreman_private_key_name}",
            server_ssl_cert => "${foreman_cert_dir}/${ssl_foreman_cert_name}",
            server_ssl_crl  => "${foreman_cert_dir}/${ssl_crl_location_name}",
          }
        }
      )
    } else {
      $foreman_hash = deep_merge($common_foreman_hash,
        {
          '::foreman' => {
            server_ssl_key  => "${foreman_cert_dir}/${ssl_foreman_private_key_name}",
            server_ssl_cert => "${foreman_cert_dir}/${ssl_foreman_cert_name}",
          }
        }
      )
    } #end of is_hash
  } else {
    $foreman_hash = $common_foreman_hash
    $ssl_ca_file = $::foreman::params::server_ssl_ca #Use default puppet ca file
    notice('Configuring default puppet CA path for the deploy: /var/lib/puppet/ssl/ca/')
  }

  create_resources('class', $foreman_hash)

  class { '::foreman_proxy':
    custom_repo           => true,
    plugin_version        => absent,
    puppet_url            => "https://${puppetmaster_vip_name}:${puppetmaster_port}",
    tftp                  => $tftp,
    dhcp                  => $dhcp,
    dns                   => $dns,
    bmc                   => $bmc,
    foreman_base_url      => $foreman_base_url,
    oauth_consumer_key    => $oauth_consumer_key,
    oauth_consumer_secret => $oauth_consumer_secret,
    registered_name       => $downcase_fqdn,
    registered_proxy_url  => "https://${downcase_fqdn}:${foreman_proxy}",
    oauth_effective_user  => $oauth_effective_user,
    trusted_hosts         => [],
    log_level             => 'DEBUG',
  }

  plugin_lcm::wrapper::firewall { $firewall_foreman_proxy: }

  Foreman_user {
    admin            => false,
    foreman_user     => $foreman_user,
    foreman_password => $foreman_password,
    foreman_base_url => "https://${downcase_fqdn}",
    ca_file          => $ssl_ca_file,
    require          => Class['::foreman'],
    before           => Class['::foreman_proxy'],
  }

  foreman_user { 'status':
    password  => 'status',
    firstname => 'status',
    lastname  => 'status',
    auth_name => 'Internal',
    mail      => 'status@server.com',
    role_name => 'Viewer',
  }

  foreman_user { 'deploy_user':
    password  => 'deploy_passwd',
    firstname => 'deploy',
    lastname  => 'deploy',
    auth_name => 'Internal',
    mail      => 'deploy@server.com',
    role_name => 'Manager',
  }

  exec { 'modify_value_data_type':
    command => '/usr/bin/mysql --defaults-extra-file=/root/.my.cnf -e "ALTER TABLE foreman.fact_values MODIFY value LONGTEXT;"',
    onlyif  => '/usr/bin/mysql --defaults-extra-file=/root/.my.cnf -e "DESCRIBE foreman.fact_values;"|/bin/grep -w value|/bin/grep -qw text',
    require => Class['::foreman'],
  }
}
