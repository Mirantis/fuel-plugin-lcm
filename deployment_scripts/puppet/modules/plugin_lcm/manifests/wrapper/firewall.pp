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

define plugin_lcm::wrapper::firewall (
  $split  = split($name, ':')
) {

  $source = $split[0]
  $port   = $split[1]
  $proto  = $split[2]

  if $proto == '' {
    $proto_selector = 'tcp'
  } else {
    $proto_selector = $proto
  }

  firewall { "880 Incoming ${proto_selector} call to ${port} from ${source}":
    proto  => $proto_selector,
    source => $source,
    dport  => $port,
    action => 'accept',
  }

}
