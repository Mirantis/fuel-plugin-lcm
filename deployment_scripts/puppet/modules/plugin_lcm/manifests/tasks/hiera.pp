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

class plugin_lcm::tasks::hiera {

  $data_dir            = '/etc/hiera'
  $override_dir        = 'plugins'
  $override_dir_path   = "${data_dir}/${override_dir}"
  $metadata_file       = '/etc/astute.yaml'

  $lcm_hiera_values  = hiera_hash('fuel-plugin-lcm')
  $master_ip         = hiera ('master_ip')
  $env_id            = hiera ('deployment_id')
  $keystone_user     = $lcm_hiera_values['configdb_user']
  $keystone_password = $lcm_hiera_values['configdb_pass']
  $keystone_tenant   = $lcm_hiera_values['metadata']['configdb']['tenant']
  $keystone_endpoint = "http://${master_ip}:5000"
  $nailgun_endpoint  = "http://${master_ip}:8000"
  $backend           = 'nailgun'

  $data = [
    'override/node/%{::fqdn}',
    'override/class/%{calling_class}',
    'override/module/%{calling_module}',
    'override/plugins',
    'override/common',
    'override/configuration/%{::fqdn}',
    'override/configuration/role',
    'override/configuration/cluster',
    'class/%{calling_class}',
    'module/%{calling_module}',
    'deleted_nodes',
    'nodes',
    'globals%{disable_globals_yaml}',
    'astute',
  ]

  $keystone = {
    endpoint    => $keystone_endpoint,
    api         => 'v2.0',
    credentials => {
      user   => $keystone_user,
      pass   => $keystone_password,
      tenant => $keystone_tenant,
    },
  }

  $nailgun = {
    endpoint => $nailgun_endpoint,
    api      => 'v1',
    env_id   => $env_id,
  }

  $astute_data_file    = '/etc/astute.yaml'
  $hiera_main_config   = '/etc/hiera.yaml'
  $hiera_puppet_config = '/etc/puppet/hiera.yaml'
  $hiera_data_file     = "${data_dir}/astute.yaml"

  File {
    owner => 'root',
    group => 'root',
    mode  => '0644',
  }

  hiera_config { $hiera_main_config :
    ensure             => 'present',
    backends           => $backend,
    data_dir           => $data_dir,
    hierarchy          => $data,
    override_dir       => $override_dir,
    metadata_yaml_file => $metadata_file,
    merge_behavior     => 'deeper',
    additions          => {
      keystone => $keystone,
      nailgun  => $nailgun,
    },
  }

  file { 'hiera_data_dir' :
    ensure => 'directory',
    path   => $data_dir,
  }

  file { 'hiera_data_override_dir' :
    ensure => 'directory',
    path   => $override_dir_path,
  }

  file { 'hiera_config' :
    ensure => 'present',
    path   => $hiera_main_config,
  }

  file { 'hiera_data_astute' :
    ensure => 'symlink',
    path   => $hiera_data_file,
    target => $astute_data_file,
  }

  file { 'hiera_puppet_config' :
    ensure => 'symlink',
    path   => $hiera_puppet_config,
    target => $hiera_main_config,
  }

  file { '/usr/lib/ruby/vendor_ruby/hiera/backend/nailgun_backend.rb' :
    source => 'puppet:///modules/plugin_lcm/nailgun_backend.rb',
  }
}
