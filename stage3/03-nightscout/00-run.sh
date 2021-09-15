#!/bin/bash -e

NIGHTSCOUTDIR="${ROOTFS_DIR}/home/${FIRST_USER_NAME}/nightscout-git"
git clone https://github.com/nightscout/cgm-remote-monitor.git $NIGHTSCOUTDIR
cd $NIGHTSCOUTDIR
git checkout master

on_chroot << EOF
cd /home/${FIRST_USER_NAME}/nightscout-git
chown -R pi: .
su ${FIRST_USER_NAME} -c "npm install"
EOF
