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

class plugin_lcm {

  # Hiera lookups
  $lcm_network_metadata     = hiera_hash('network_metadata')
  $lcm_network_scheme       = hiera_hash('network_scheme')
  $lcm_my_uid               = hiera('uid')
  $lcm_hiera_values         = hiera_hash('fuel-plugin-lcm', {})
  $neutron_config           = hiera_hash('neutron_config')
  $mgmt_cidr                = hiera('management_network_range')
  $mgmt_cidr_array          = split($mgmt_cidr, '\/')
  $mgmt_net_mask            = $mgmt_cidr_array[1]

  # Copy paste from: modules/osnailyfacter/modular/openstack-network/networks.pp
  $floating_net             = try_get_value($neutron_config, 'default_floating_net', 'net04_ext')
  $nets                     = $neutron_config['predefined_networks']
  $public_cidr              = try_get_value($nets, "${floating_net}/L3/subnet")

  # Plugin defaults
  $lcm_metadata             = $lcm_hiera_values['metadata']
  $lcm_namespace_name       = $lcm_metadata['lcm_namespace_name']
  $lcm_ka_auth_type         = $lcm_metadata['keepalived']['auth_type']
  $lcm_ka_garp_master_delay = $lcm_metadata['keepalived']['garp_master_delay']
  $lcm_ka_master_priority   = $lcm_metadata['keepalived']['master_priority']
  $lcm_ka_instance_name     = $lcm_metadata['keepalived']['instance_name']
  $lcm_ka_cidr              = $lcm_metadata['keepalived']['cidr']
  $puppetmaster_port        = $lcm_metadata['ports']['puppetmaster']
  $perconadb_port           = $lcm_metadata['ports']['perconadb']
  $foreman_web_port         = $lcm_metadata['ports']['foreman_web']
  $foreman_proxy_port       = $lcm_metadata['ports']['foreman_proxy']
  $foreman_redirect_port    = $lcm_metadata['ports']['foreman_redirect']
  $multicheck_port          = $lcm_metadata['ports']['multicheck']
  $galeracheck_port         = $lcm_metadata['ports']['galeracheck']
  $haproxy_stats_port       = $lcm_metadata['ports']['haproxy_stats']
  $lcm_middleware_port      = pick($lcm_hiera_values['middleware_port'], $lcm_metadata['ports']['middleware'])
  $puppetmaster_location    = $lcm_metadata['haproxy_check']['puppetmaster']
  $foreman_web_location     = $lcm_metadata['haproxy_check']['foreman_web']
  $foreman_proxy_location   = $lcm_metadata['haproxy_check']['foreman_proxy']
  $foreman_cert_dir         = $lcm_metadata['foreman_cert_dir']

  # Plugin specific options
  $lcm_hapub_enabled        = pick($lcm_hiera_values['public_vip_enabled'], false)
  $lcm_pub_veth_name        = regsubst($lcm_namespace_name,'^(..).*','\1pub')
  $lcm_mgmt_veth_name       = regsubst($lcm_namespace_name,'^(..).*','\1mgmt')
  $lcm_virtual_router_id    = pick($lcm_hiera_values['keepalived_vrid'], '50')
  $lcm_ka_auth_pass         = pick($lcm_hiera_values['keepalived_psk'],'lcmKA50s')
  $lcm_my_mgmt_ip           = $lcm_network_metadata['nodes']["node-${lcm_my_uid}"]['network_roles']['lcm_mgmt']
  $lcm_nodes_hash           = get_nodes_hash_by_roles($lcm_network_metadata, ['lcm'])
  $lcm_primary_hash         = get_nodes_hash_by_roles($lcm_network_metadata, ['primary-lcm'])
  $lcm_all_hash             = get_nodes_hash_by_roles($lcm_network_metadata, ['lcm','primary-lcm'])
  $lcm_nodes_ips            = values(get_node_to_ipaddr_map_by_network_role($lcm_all_hash, 'lcm_mgmt'))
  $lcm_nodes_names          = keys(get_node_to_ipaddr_map_by_network_role($lcm_all_hash, 'lcm_mgmt'))
  $lcm_nodes_keys           = keys($lcm_nodes_hash)
  $lcm_primary_key          = keys($lcm_primary_hash)
  $lcm_primary_uid          = $lcm_primary_hash[$lcm_primary_key[0]]['uid']
  $lcm_primary_ip           = values(get_node_to_ipaddr_map_by_network_role($lcm_primary_hash, 'lcm_mgmt'))
  $lcm_primary_name         = keys(get_node_to_ipaddr_map_by_network_role($lcm_primary_hash, 'lcm_mgmt'))
  $lcm_vip                  = $lcm_network_metadata['vips']['lcm']['ipaddr']
  $lcm_public_vip           = $lcm_network_metadata['vips']['lcmpub']['ipaddr']
  $lcm_public_iface         = $lcm_network_scheme['roles']['lcm_pub']
  $lcm_public_gateway       = $lcm_network_scheme['endpoints'][$lcm_public_iface]['gateway']
  $lcm_mgmt_iface           = $lcm_network_scheme['roles']['lcm_mgmt']
  $lcm_apache_ports         = [ $foreman_web_port, $puppetmaster_port, $lcm_middleware_port ]
  $lcm_service_ports        = union(
    $lcm_apache_ports,
    [
      $perconadb_port,
      $foreman_proxy_port,
      $galeracheck_port,
      $multicheck_port,
    ]
  )
}
