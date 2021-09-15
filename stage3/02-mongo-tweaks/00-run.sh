#!/bin/bash -e

cp "${ROOTFS_DIR}/lib/systemd/system/mongod.service" "${ROOTFS_DIR}/etc/systemd/system/mongod.service"
sed -i 's/\/var\/run\/mongodb\/mongod.pid/\/run\/mongodb\/mongod.pid/' "${ROOTFS_DIR}/etc/systemd/system/mongod.service"

on_chroot << EOF
systemctl enable mongod.service
EOF
