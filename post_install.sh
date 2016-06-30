#!/bin/bash
PD=/etc/fuel/plugins;
CD=/usr/local/repos/configdb;
(test -d ${PD} || test -s ${PD}) || ln -fs /var/www/nailgun/plugins ${PD}
mkdir -p ${CD}
cp -fs ${PD}/%{name}/repositories/centos/*.rpm ${CD}/
createrepo ${CD}/
(
  echo '[configdb]';
  echo 'name=ConfigDB';
  echo "baseurl=file://${CD}/";
  echo 'gpgcheck=0';
  echo 'skip_if_unavailable=1'
) > /etc/yum.repos.d/configdb.repo
