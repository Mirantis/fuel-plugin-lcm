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

class plugin_lcm::tasks::r10k_deploy {

  $r10k_config    = hiera_hash('fuel-plugin-lcm')
  $r10k_conf_path = '/etc/r10k.yaml'
  $private_repo   = $r10k_config['private_repo']
  $r10k_user      = pick($r10k_config['user'], 'puppetr10k')
  $r10k_group     = pick($r10k_config['group'], $r10k_user)
  $remote_repo    = $r10k_config['remote_repo']


  if $private_repo {

    $repo_link  = split($remote_repo, ':')
    $repo_proto = $repo_link[0]
    $repo_host  = inline_template('<%= @repo_link[1].gsub(/^\/\//, "") %>')
    $repo_port  = inline_template('<%= @repo_link[2].gsub(/\/.*/, "") %>')

    notify {"Remote_repo parsed: proto: ${repo_proto} host: ${repo_host} port: ${repo_port}" :}

    $private_config = {
      repo_host => $repo_host,
      repo_port => $repo_port,
      username  => $r10k_user,
      key_path  => '/root/.ssh/repo_key.pem',
      r10k_key  => $r10k_config['r10k_key']['content'],
    }

    class { '::r10k':
      private_config => $private_config,
    }

    class { '::r10k::config':
      private_config => $private_config,
      remote_repo    => $remote_repo,
    }

  }
  else {
    class { '::r10k':}

    class { '::r10k::config':
      remote_repo => $remote_repo,
    }
  }
}
