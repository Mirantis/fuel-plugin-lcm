#!/bin/bash

read_config(){
  echo -e """import yaml

modules_list = yaml.load(file('deployment_scripts/master/puppet_modules.yaml','r'))
for module in modules_list:
  for module_name, module_hash in module.items():
    print module_hash['url'] + ' ' + module_name + ' ' + module_hash['version']"""\
  | /usr/bin/env python
}

fetch(){
  git clone -b "$3" "$1" "${T}/$2" || touch "${T}/$2.failed"
  if [ $(find ${T} -maxdepth 1 -iname *.failed | wc -l) -gt 0 ]; then
    echo "Failed to fetch $2 module";
    exit 1;
  fi;
  rm -rf "deployment_scripts/puppet/modules/$2"
  mv -f "${T}/$2" "deployment_scripts/puppet/modules/"
}

T=/tmp/lcm_plugin_tmp
rm -rf /tmp/lcm_plugin_tmp
mkdir -p ${T}

if [ "${http_proxy}x" != "x" ]; then
  echo "Setting proxy ${http_proxy} for git."
  git config --global http.proxy "${http_proxy}"
fi;

read_config | while read line; do
  fetch ${line};
done;
