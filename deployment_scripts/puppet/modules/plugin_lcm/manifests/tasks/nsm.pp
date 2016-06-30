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

class plugin_lcm::tasks::nsm {

  include '::plugin_lcm'

  $lcm_namespace_name = $::plugin_lcm::lcm_namespace_name
  $lcm_pub_veth_name  = $::plugin_lcm::lcm_pub_veth_name
  $lcm_mgmt_veth_name = $::plugin_lcm::lcm_mgmt_veth_name
  $lcm_mgmt_iface     = $::plugin_lcm::lcm_mgmt_iface
  $lcm_my_mgmt_ip     = $::plugin_lcm::lcm_my_mgmt_ip
  $lcm_pub_iface      = $::plugin_lcm::lcm_public_iface
  $lcm_ka_cidr        = $::plugin_lcm::lcm_ka_cidr
  $lcm_hapub_enabled  = $::plugin_lcm::lcm_hapub_enabled
  $mgmt_cidr          = $::plugin_lcm::mgmt_cidr
  $lcm_nodes_ips      = $::plugin_lcm::lcm_nodes_ips
  $puppetmaster_port  = $::plugin_lcm::puppetmaster_port
  $perconadb_port     = $::plugin_lcm::perconadb_port
  $foreman_web_port   = $::plugin_lcm::foreman_web_port
  $foreman_proxy_port = $::plugin_lcm::foreman_proxy_port
  $foreman_redirect   = $::plugin_lcm::foreman_redirect_port
  $middleware_port    = $::plugin_lcm::lcm_middleware_port
  $multicheck_port    = $::plugin_lcm::multicheck_port
  $galeracheck_port   = $::plugin_lcm::galeracheck_port
  $stats_port         = $::plugin_lcm::haproxy_stats_port
  $ka_ip              = get_ka_addr_from_mgmt($lcm_my_mgmt_ip,$mgmt_cidr,$lcm_ka_cidr)

  # Resources defaults
  File {
    ensure => present,
    mode   => '0755',
    owner  => 'root',
    group  => 'root',
  }

  # Resources
  file { '/etc/init.d/nsm':
    source => 'puppet:///modules/plugin_lcm/nsm.init',
  }

  file {
    [
      '/etc/nsm.d',
      '/etc/iptables',
    ]:
    ensure => 'directory',
  }

  file { "/etc/nsm.d/${lcm_namespace_name}.nsm":
    content => template("plugin_lcm/${lcm_namespace_name}.nsm.erb"),
  }

  file { '/usr/sbin/nsm':
    source => 'puppet:///modules/plugin_lcm/nsm.bin',
  }

  file { "/etc/iptables/${lcm_namespace_name}.nsm.rules.v4":
    mode    => '0600',
    content => template("plugin_lcm/${lcm_namespace_name}.nsm.rules.v4.erb"),
    notify  => Exec["${lcm_namespace_name}-nsm-iptables-apply"],
  }

  exec { "${lcm_namespace_name}-nsm-iptables-apply":
    command     => "/bin/ip netns exec ${lcm_namespace_name} iptables-restore < /etc/iptables/${lcm_namespace_name}.nsm.rules.v4",
    refreshonly => true,
  }

  service { 'nsm':
    ensure     => running,
    enable     => true,
    name       => 'nsm',
    hasstatus  => true,
    hasrestart => true,
    subscribe  => File["/etc/nsm.d/${lcm_namespace_name}.nsm"],
  }

  # Order
  File['/etc/init.d/nsm'] -> Service['nsm']
  Service['nsm'] -> Exec["${lcm_namespace_name}-nsm-iptables-apply"]

}
