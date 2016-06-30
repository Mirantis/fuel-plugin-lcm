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

  newfunction(:get_priority_by_uid, :type => :rvalue, :doc => <<-EOS
    Returns keepalived priority for given uid
    EOS
  ) do |args|

    lcm_nodes_hash,uid = args

    i=0
    idx=0
    lcm_nodes_hash.each do |node|
      i+=1
      node.each do |k, v|
        if k['uid'].to_i==uid.to_i then idx=i end
      end
    end

    return (150-idx).to_s

  end

end
