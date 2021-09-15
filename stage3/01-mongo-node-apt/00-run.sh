#!/bin/bash -e

install -m 644 files/mongodb-org-4.4.list "${ROOTFS_DIR}/etc/apt/sources.list.d/"
#install -m 644 files/nodesource.list "${ROOTFS_DIR}/etc/apt/sources.list.d/"

sed -i "s/RELEASE/${RELEASE}/g" "${ROOTFS_DIR}/etc/apt/sources.list.d/mongodb-org-4.4.list"
#sed -i "s/RELEASE/${RELEASE}/g" "${ROOTFS_DIR}/etc/apt/sources.list.d/nodesource.list"

#on_chroot curl -s https://www.mongodb.org/static/pgp/server-4.4.asc | apt-key add -
on_chroot << EOF
curl -s https://www.mongodb.org/static/pgp/server-4.4.asc | apt-key add -
curl -fsSL https://deb.nodesource.com/setup_14.x | bash -
EOF
