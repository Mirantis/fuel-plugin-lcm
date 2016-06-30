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

class plugin_lcm::tasks::keepalived {

  include '::plugin_lcm'

  # We do not want our template to use scope lookups
  $lcm_namespace_name = $::plugin_lcm::lcm_namespace_name
  $lcm_pub_veth_name  = $::plugin_lcm::lcm_pub_veth_name
  $lcm_mgmt_veth_name = $::plugin_lcm::lcm_mgmt_veth_name
  $lcm_hapub_enabled  = $::plugin_lcm::lcm_hapub_enabled
  $lcm_ka_vrid        = $::plugin_lcm::lcm_virtual_router_id
  $lcm_ka_auth_pass   = $::plugin_lcm::lcm_ka_auth_pass
  $lcm_ka_auth_type   = $::plugin_lcm::lcm_ka_auth_type
  $lcm_ka_garp_delay  = $::plugin_lcm::lcm_ka_garp_master_delay
  $lcm_vrrp_priority  = $::plugin_lcm::lcm_ka_master_priority
  $lcm_instance       = $::plugin_lcm::lcm_ka_instance_name
  $lcm_mgmt_vip       = $::plugin_lcm::lcm_vip
  $lcm_mgmt_cidr      = $::plugin_lcm::mgmt_cidr
  $lcm_pub_vip        = $::plugin_lcm::lcm_public_vip
  $lcm_nodes_hash     = $::plugin_lcm::lcm_nodes_hash
  $lcm_my_uid         = $::plugin_lcm::lcm_my_uid
  $lcm_primary_uid    = $::plugin_lcm::lcm_primary_uid
  $lcm_pub_cidr       = $::plugin_lcm::public_cidr
  $lcm_pub_gate       = $::plugin_lcm::lcm_public_gateway
  $lcm_mgmt_ns_name   = "${lcm_mgmt_veth_name}-ns"
  $lcm_pub_ns_name    = "${lcm_pub_veth_name}-ns"

  if ($lcm_my_uid == $lcm_primary_uid) {
    $lcm_ka_state    = 'MASTER'
    $lcm_ka_priority = $lcm_vrrp_priority
  }
  else {
    $lcm_ka_state    = 'BACKUP'
    $lcm_ka_priority = get_priority_by_uid($lcm_nodes_hash,$lcm_my_uid)
  }

  if $lcm_hapub_enabled {
    $lcm_ka_va = [
      {
        ip  => $lcm_mgmt_vip,
        dev => $lcm_mgmt_ns_name,
      },
      {
        ip  => $lcm_pub_vip,
        dev => $lcm_pub_ns_name,
      }
    ]
    $lcm_ka_vr = [
      {
        src => $lcm_mgmt_vip,
        to  => $lcm_mgmt_cidr,
        dev => $lcm_mgmt_ns_name,
      },
      {
        to    => $lcm_pub_cidr,
        dev   => $lcm_pub_ns_name,
        scope => 'link',
      },
      {
        src => $lcm_pub_vip,
        to  => '0.0.0.0/0',
        via => $lcm_pub_gate,
      }
    ]
  }
  else {
    $lcm_ka_va = [
      {
        ip  => $lcm_mgmt_vip,
        dev => $lcm_mgmt_ns_name,
      }
    ]
    $lcm_ka_vr = [
      {
        src => $lcm_mgmt_vip,
        to  => $lcm_mgmt_cidr,
        dev => $lcm_mgmt_ns_name,
      }
    ]
  }

  # Resource defaults
  File {
    ensure => present,
    mode   => '0755',
    owner  => 'root',
    group  => 'root',
  }

  class { '::keepalived':
    service_manage => false,
  }

  class { '::keepalived::global_defs':
    ensure    => present,
    router_id => $lcm_instance,
  }

  keepalived::vrrp::instance { $lcm_instance:
    interface         => $lcm_mgmt_ns_name,
    state             => $lcm_ka_state,
    virtual_router_id => $lcm_ka_vrid,
    priority          => $lcm_ka_priority,
    auth_type         => $lcm_ka_auth_type,
    auth_pass         => $lcm_ka_auth_pass,
    garp_master_delay => $lcm_ka_garp_delay,
    virtual_ipaddress => $lcm_ka_va,
    virtual_routes    => $lcm_ka_vr,
    track_script      => 'check_bucket',
  }

  keepalived::vrrp::script { 'check_bucket':
    script   => '/etc/keepalived/bucket.check',
    interval => '2',
    fall     => '2',
    rise     => '2',
  }

  file { '/etc/init.d/keepalived':
    content => template('plugin_lcm/keepalived.init.erb'),
    notify  => Exec['replace_keepalived_config'],
  }

  file {
    [
      '/etc/nsm',
      "/etc/nsm/${lcm_namespace_name}",
    ]:
      ensure => 'directory',
  }

  file { '/etc/keepalived/bucketchecks':
    ensure => 'directory',
    mode   => '0700',
  }

  file { '/etc/keepalived/bucket.check':
    source => 'puppet:///modules/plugin_lcm/bucket.check',
  }

  file { "/etc/nsm/${lcm_namespace_name}/keepalived.stop":
    source => 'puppet:///modules/plugin_lcm/keepalived.stop',
  }

  file { "/etc/nsm/${lcm_namespace_name}/keepalived.start":
    source => 'puppet:///modules/plugin_lcm/keepalived.start',
  }

  exec { 'replace_keepalived_config':
    command     => '/etc/init.d/keepalived restart',
    refreshonly => true,
  }

  service { 'keepalived':
    ensure     => running,
    name       => 'keepalived',
    enable     => true,
    hasstatus  => true,
    hasrestart => true,
    subscribe  => Keepalived::Vrrp::Instance[$lcm_instance],
  }

  File['/etc/init.d/keepalived'] -> Service['keepalived']

}
