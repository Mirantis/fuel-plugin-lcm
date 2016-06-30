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

class plugin_lcm::tasks::haproxy {

  include '::plugin_lcm'

  $bind               = '0.0.0.0'

  $puppet_port        = $::plugin_lcm::puppetmaster_port
  $perconadb_port     = $::plugin_lcm::perconadb_port
  $foreman_web_port   = $::plugin_lcm::foreman_web_port
  $foreman_redirect   = $::plugin_lcm::foreman_redirect_port
  $foreman_proxy_port = $::plugin_lcm::foreman_proxy_port
  $multicheck_port    = $::plugin_lcm::multicheck_port
  $middleware_port    = $::plugin_lcm::lcm_middleware_port
  $galeracheck_port   = $::plugin_lcm::galeracheck_port
  $lcm_my_mgmt_ip     = $::plugin_lcm::lcm_my_mgmt_ip
  $puppet_location    = $::plugin_lcm::puppetmaster_location
  $frm_web_location   = $::plugin_lcm::foreman_web_location
  $frm_proxy_location = $::plugin_lcm::foreman_proxy_location
  $lcm_namespace_name = $::plugin_lcm::lcm_namespace_name
  $lcm_nodes_names    = $::plugin_lcm::lcm_nodes_names
  $lcm_nodes_ips      = $::plugin_lcm::lcm_nodes_ips
  $lcm_hiera_values   = $::plugin_lcm::lcm_hiera_values
  $primary_ip         = $::plugin_lcm::lcm_primary_ip
  $primary_name       = $::plugin_lcm::lcm_primary_name
  $lcm_nodes_hash     = $::plugin_lcm::lcm_nodes_hash
  $stats_port         = $::plugin_lcm::haproxy_stats_port
  $lcm_public_vip     = $::plugin_lcm::lcm_public_vip

  $haproxy_listen_hash = {
    'stats' => {
      order   => '000',
      bind    => array_to_hash(["${bind}:${stats_port}"]),
      mode    => 'http',
      options => {
        'stats'              => 'enable',
        'stats uri'          => '/stats',
        'stats refresh'      => '5s',
        'stats show-node'    => '',
        'stats show-legends' => '',
        'stats hide-version' => '',
      },
    },
    'puppet' => {
      order   => '010',
      bind    => array_to_hash(["${bind}:${puppet_port}"]),
      options => {
        'balance'   => 'source',
        'hash-type' => 'consistent',
        'option'    => [
          'tcplog',
          'tcpka',
          "httpchk ${puppet_location}",
          ],
      },
    },
    'perconadb' => {
      order   => '020',
      bind    => array_to_hash(["${bind}:${perconadb_port}"]),
      options => {
        'balance'        => 'source',
        'hash-type'      => 'consistent',
        'timeout server' => '28801s',
        'timeout client' => '28801s',
        'option'         => [
          'tcplog',
          'tcpka',
          'httpchk',
          ],
      },
    },
    'foreman_web' => {
      order   => '030',
      bind    => array_to_hash(["${bind}:${foreman_web_port}"]),
      options => {
        'balance'   => 'source',
        'hash-type' => 'consistent',
        'option'    => [
          'tcplog',
          'tcpka',
          "httpchk ${frm_web_location}",
          ],
      },
    },
    'foreman_redirect' => {
      order   => '035',
      mode    => 'http',
      bind    => array_to_hash(["${bind}:${foreman_redirect}"]),
      options => {
          'redirect' => "location https://${lcm_public_vip}"
      },
    },
    'foreman_proxy' => {
      order   => '040',
      bind    => array_to_hash(["${bind}:${foreman_proxy_port}"]),
      options => {
        'balance'   => 'source',
        'hash-type' => 'consistent',
        'option'    => [
          'tcplog',
          'tcpka',
          "httpchk ${frm_proxy_location}",
          ],
      },
    },
    'middleware' => {
      order   => '050',
      mode    => 'http',
      bind    => array_to_hash(["${bind}:${middleware_port}"]),
      options => {
        'balance' => 'roundrobin',
        'option' => [
          'httplog',
          'httpclose',
          'httpchk GET /diagnostic/puppetmasters HTTP/1.0\r\nUser-Agent:\ haproxy-check\r\nAccept:\ */*\r\n',
          ],
      },
    },
  }

  $haproxy_balancermember_hash = {
    'puppet' => {
      order   => '010',
      ports   => $puppet_port,
      options => "check port ${multicheck_port} inter 2s rise 3 fall 3",
    },
    'perconadb' => {
      order          => '020',
      ports          => $perconadb_port,
      options        => "check port ${galeracheck_port} inter 20s fastinter 2s downinter 2s rise 3 fall 3",
      define_backups => True,
    },
    'foreman_web' => {
      order   => '030',
      ports   => $foreman_web_port,
      options => "check port ${multicheck_port} inter 5s fastinter 2s downinter 2s rise 3 fall 3",
    },
    'foreman_proxy' => {
      order   => '040',
      ports   => $foreman_proxy_port,
      options => "check port ${multicheck_port} inter 2s rise 3 fall 3",
    },
    'middleware' => {
      order   => '050',
      ports   => $middleware_port,
      options => 'check inter 2s rise 3 fall 3',
    },
  }

  Haproxy::Listen {
    mode        => 'tcp',
    use_include => true,
    notify      => Service['haproxy'],
  }

  Haproxy::Balancermember {
    listening_service => $name,
    server_names      => $lcm_nodes_names,
    ipaddresses       => $lcm_nodes_ips,
    use_include       => true,
    notify            => Service['haproxy'],
  }

  File {
    require => Package['haproxy'],
  }

  file {
    [
      '/etc/haproxy/conf.d',
      '/etc/nsm',
      "/etc/nsm/${lcm_namespace_name}",
    ]:
      ensure => 'directory',
  }

  file { '/etc/init.d/haproxy':
    content => template('plugin_lcm/haproxy.init.erb'),
    notify  => Service['haproxy'],
  }

  file { "/etc/nsm/${lcm_namespace_name}/haproxy.stop":
    source => 'puppet:///modules/plugin_lcm/haproxy.stop',
  }

  file { "/etc/nsm/${lcm_namespace_name}/haproxy.start":
    source => 'puppet:///modules/plugin_lcm/haproxy.start',
  }

  file { '/usr/local/bin/multicheck':
    content => template('plugin_lcm/multicheck.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0750',
  }

  file { '/etc/xinetd.d/multicheck':
    content => template('plugin_lcm/multicheck.xinet.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    notify  => Service['xinetd'],
  }

  service { 'xinetd' :
    ensure => 'running',
    enable => true,
  }

  concat::fragment { 'haproxy-include':
    target  => '/etc/haproxy/haproxy.cfg',
    order   => '99',
    content => "\ninclude conf.d/*.cfg\n",
  }

  class { '::haproxy':
    global_options   => {
      'log'     => '/dev/log local0',
      'chroot'  => '/var/lib/haproxy',
      'maxconn' => '65535',
      'user'    => 'haproxy',
      'group'   => 'haproxy',
      'daemon'  => true,
      'stats'   => [
        'socket /var/lib/haproxy/stats mode 660 level admin',
        'timeout 5s',
      ],
    },
    defaults_options => {
      'log'     => 'global',
      'option'  => [
        'redispatch',
        'http-server-close',
        'splice-auto',
        'dontlognull',
      ],
      'retries' => '3',
      'timeout' => [
        'http-request 20s',
        'queue 1m',
        'connect 3s',
        'client 5m',
        'server 5m',
        'check 2s',
      ],
      'maxconn' => '65535',
    }
  }

  create_resources('haproxy::listen', $haproxy_listen_hash)
  create_resources('haproxy::balancermember', $haproxy_balancermember_hash)

  # Accepting incoming haproxy calls
  firewall { '800 Incoming haproxy calls':
    proto  => 'tcp',
    source => $::plugin_lcm::lcm_vip,
    dport  => $::plugin_lcm::lcm_service_ports,
    action => 'accept',
  }

  firewall { '810 Incoming haproxy calls':
    proto  => 'tcp',
    source => $::plugin_lcm::lcm_ka_cidr,
    dport  => $::plugin_lcm::lcm_service_ports,
    action => 'accept',
  }

}
