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

module Puppet::Parser::Functions

  newfunction(:get_ka_addr_from_mgmt, :type => :rvalue, :doc => <<-EOS
    Returns keepalived address for node using mgmt one
    EOS
  ) do |args|

    mgmt_ip, mgmt_cidr, ka_cidr = args
    require 'ipaddr'

    mgmt_net_a, mgmt_net_m = mgmt_cidr.split('/')
    ka_net_a, ka_net_m = ka_cidr.split('/')

    return IPAddr.new(
      IPAddr.new(mgmt_ip).to_i -
      IPAddr.new(mgmt_net_a).to_i +
      IPAddr.new(ka_net_a).to_i, Socket::AF_INET
    ).to_s

  end

end
