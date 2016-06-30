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

class plugin_lcm::tasks::database {

  $network_metadata          = hiera_hash('network_metadata')
  $lcm_hiera_values          = hiera_hash('fuel-plugin-lcm')

  $lcm_nodes_array           = get_nodes_hash_by_roles($network_metadata, ['primary-lcm', 'lcm'])
  $lcm_nodes_ips             = values(get_node_to_ipaddr_map_by_network_role($lcm_nodes_array, 'lcm_mgmt'))

  $perconadb_root_password   = $lcm_hiera_values['perconadb_root_password']
  $perconadb_status_password = $lcm_hiera_values['perconadb_check_password']

  if roles_include('primary-lcm') {
    $galera_master_fqdn = $::fqdn
  }
  else {
    $galera_master_fqdn = false
  }

  ################################################################################
  validate_string($perconadb_root_password)
  validate_string($perconadb_status_password)
  validate_array($lcm_nodes_ips)

  class { '::galera':
    galera_servers      => $lcm_nodes_ips,
    galera_master       => $galera_master_fqdn,
    local_ip            => $::ipaddress_br_mgmt,
    bind_address        => $::ipaddress_br_mgmt,
    wsrep_sst_method    => 'xtrabackup-v2',
    root_password       => $perconadb_root_password,
    configure_repo      => false,
    status_password     => $perconadb_status_password,
    validate_connection => false,
  }
}
