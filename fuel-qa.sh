#!/bin/bash

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

# User specific commands.
# This file make sense just for checks on CI.
#
# To enable these checks in the 'lcm_check.sh' you should add option '-s'
# in the 'fuel-qa.opts' file.
#
# All code will be included to the function 'lcm_custom_check'
# of 'lcm_check.sh' script like additional check.
#
# You can use any global variables from parent script (lcm_check.sh).
# But you should declare all custom variables like local.
#
# The result of executing custom code can affect to results of parent script.
# You can provide a final status of custom checks to the parent script,
# via 'CUSTOM_CHECK_RESULT' variable. The values should be '${YEP}' or '${NOP}'.
# The variable 'CUSTOM_CHECK_RESULT' has value '${YEP}' by default.

# Example of code to check something on LCM nodes (time and /etc/hosts for example):
#
#  local i
#  local ind
#  local RESULT
#  log 'Checking time and /etc/hosts on nodes:'
#  let ind=0
#  for i in ${LCM_NODES}; do
#    # ...
#    log "${arr_lcm_nodes_names[ind]}${SHIFT_1}(${i}):${SHIFT_2}" $(ssh -q ${SSH_USER}@${i} "date")
#    # ...
#    RESULT=$(ssh -q ${SSH_USER}@${i} "test -f /etc/hosts 2>/dev/null && echo ${YEP} || echo ${NOP}")
#    if [[ x${RESULT} == x${YEP} ]]; then
#      log "${arr_lcm_nodes_names[ind]}${SHIFT_1}(${i}):${SHIFT_2} Searching the file '/etc/hosts' ${SHIFT_5} is\t ${YEP}"
#    else
#      CUSTOM_CHECK_RESULT=${NOP}
#      log "${arr_lcm_nodes_names[ind]}${SHIFT_1}(${i}):${SHIFT_2} Searching the file '/etc/hosts' ${SHIFT_5} is\t ${NOP}"
#    fi
#    # ...
#    ind=${ind}+1
#  done
