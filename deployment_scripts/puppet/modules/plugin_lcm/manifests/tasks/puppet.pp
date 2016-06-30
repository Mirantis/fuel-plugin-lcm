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

class plugin_lcm::tasks::puppet {

  $lcm_hiera_values      = hiera_hash('fuel-plugin-lcm', {})
  $lcm_metadata          = $lcm_hiera_values['metadata']
  $lcm_network_metadata  = hiera_hash('network_metadata')
  $lcm_vip               = $lcm_network_metadata['vips']['lcm']['ipaddr']
  $lcm_all_hash          = get_nodes_hash_by_roles($lcm_network_metadata, ['lcm','primary-lcm'])

  $puppetmaster_vip_name = downcase("puppet.${::domain}")

  $foreman_web_port      = $lcm_metadata['ports']['foreman_web']
  $puppetmaster_port     = $lcm_metadata['ports']['puppetmaster']
  $puppetagent_port      = $lcm_metadata['ports']['puppetagent']
  $lcm_middleware_port   = pick($lcm_hiera_values['middleware_port'], $lcm_metadata['ports']['middleware'])

  $lcm_apache_ports      = [ $foreman_web_port, $puppetmaster_port, $lcm_middleware_port ]
  $lcm_nodes_ips         = values(get_node_to_ipaddr_map_by_network_role($lcm_all_hash, 'lcm_mgmt'))
  $node_uid              = hiera('uid')
  $node_cert_name        = "node-${node_uid}.${::domain}"

  $firewall_puppet       = suffix($lcm_nodes_ips, ":${puppetagent_port}")

  $own_ssl_certificate   = $lcm_hiera_values['own_ssl_certificate']
  $foreman_cert_dir      = $lcm_metadata['foreman_cert_dir']

  $common_puppet_hash = {
    '::puppet' => {
      listen          => true,
      listen_to       => ["*.${::domain}"],
      puppetmaster    => $puppetmaster_vip_name,
      client_certname => $node_cert_name,
    },
  }

  if roles_include(['lcm', 'primary-lcm']) {

    File<|
    (title == '/etc/apache2/sites-enabled') or
    (title == '/etc/apache2/sites-available') or
    (title == '/etc/apache2/conf.d')
    |> {
      purge => false,
    }

    tidy { '/etc/apache2':
      recurse => true,
      matches => '000-default.conf',
      require => Package['httpd'],
      notify  => Service['httpd'],
    }

    file { '/etc/puppet/files':
      ensure => directory,
      before => Package['puppetmaster-common'],
    }

    file { '/var/lib/puppet/ssl':
      ensure  => directory,
      owner   => 'puppet',
      group   => 'puppet',
      recurse => true,
      before  => Class['::puppet'],
    }

    if ($own_ssl_certificate) and ($lcm_hiera_values['ssl_foreman_ca'] != '') {
      $ssl_foreman_ca_name = $lcm_hiera_values['ssl_foreman_ca'][name]
      $enc_ca_file = "${foreman_cert_dir}/${ssl_foreman_ca_name}" #Use custom ca file
    } else {
      $enc_ca_file = undef
    }

    $class_puppet_hash = deep_merge(
      $common_puppet_hash,
      {
        '::puppet' => {
          auth_template              => 'plugin_lcm/auth.conf.erb',
          server_common_modules_path => false,
          server_foreman_ssl_ca      => $enc_ca_file,
          server                     => true,
          server_environments        => [],
        }
      }
    )
    apache::listen { $lcm_apache_ports: }
  }
  else {
    $class_puppet_hash = $common_puppet_hash
  }

  tweaks::ubuntu_service_override { 'puppetmaster': }

  plugin_lcm::wrapper::firewall { $firewall_puppet: }

  host { $puppetmaster_vip_name:
    comment => 'Puppet Master',
    ip      => $lcm_vip,
  }

  file_line { 'enable_puppet_logs':
    path    => '/etc/default/puppet',
    line    => 'DAEMON_OPTS="--verbose --logdest /var/log/puppet/puppet.log"',
    match   => '^DAEMON_OPTS=',
    notify  => Service['puppet'],
    require => Augeas['puppet::set_start'],
  }

  create_resources('class', $class_puppet_hash)
  include ::plugin_lcm::puppet_master_status
}
