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

class plugin_lcm::tasks::lcm_update_hosts {

  $lcm_hiera_values  = hiera_hash('fuel-plugin-lcm')
  $foreman_password  = $lcm_hiera_values['foreman_password']
  $foreman_user      = $lcm_hiera_values['foreman_user']
  $foreman_url       = downcase("puppet.${::domain}")
  $roles_array       = hiera_array('roles',[])
  $roles             = join($roles_array,' ')

  $controller    = 'lcm_comp::role::controller'
  $compute       = 'lcm_comp::role::compute'

  File {
    ensure => present,
    mode   => '0755',
    owner  => 'root',
    group  => 'root',
  }

  file { '/usr/sbin/update_hosts':
    content => template('plugin_lcm/update.erb'),
  }

  file { '/etc/init.d/update_hosts':
    source => 'puppet:///modules/plugin_lcm/update.init',
  }

  file { '/etc/default/update_hosts':
    content => 'START=yes',
  }

  service { 'update_hosts':
    ensure     => running,
    enable     => true,
    hasstatus  => true,
    hasrestart => true,
  }

  # Order
  File<||> -> Service['update_hosts']
}
