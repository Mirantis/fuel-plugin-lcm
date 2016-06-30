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

class plugin_lcm::tasks::r10k_webhook {

  include '::plugin_lcm'

  $network_metadata       = hiera_hash('network_metadata')
  $config                 = hiera_hash('fuel-plugin-lcm')
  $user                   = pick($config[webhook_auth_user], 'r10kwebhook')
  $group                  = $user
  $app_dir                = "/home/${user}/r10k_webhook"
  $foreman_base_url       = pick($config[foreman_base_url], "https://${::fqdn}")
  $foreman_user           = pick($config[foreman_user], 'admin')
  $foreman_password       = pick($config[foreman_password], 'changeme')
  $foreman_api_call       = "${foreman_base_url}/api/smart_proxies/"
  $firewall_middleware_in = suffix($::plugin_lcm::lcm_nodes_ips, ":${::plugin_lcm::lcm_middleware_port}")

  class { '::r10k_webhook':
    network_metadata => $network_metadata,
    user             => $user,
    group            => $group,
    app_dir          => $app_dir,
    foreman_user     => $foreman_user,
    foreman_password => $foreman_password,
    foreman_api_call => $foreman_api_call,
  }

  plugin_lcm::wrapper::firewall { $firewall_middleware_in: }

}
