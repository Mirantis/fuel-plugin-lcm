#!/bin/bash
yum -y install tuning-box || (
  echo 'tuning-box (configdb) installation failed. Please inspect before deploy. Stopping nailgun' \
    | tee -a \
        /var/log/messages \
        /var/log/astute/astute.log;
  systemctl stop nailgun;
  exit 1;
)

nailgun_syncdb > /dev/null 2>&1
systemctl reload nailgun
