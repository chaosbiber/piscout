#!/bin/bash -e

mkdir "${ROOTFS_DIR}/home/${FIRST_USER_NAME}/install"
install -m 644 files/init.sh "${ROOTFS_DIR}/home/${FIRST_USER_NAME}/install/"
install -m 644 files/start_nightscout.sh "${ROOTFS_DIR}/home/${FIRST_USER_NAME}/"

mkdir "${ROOTFS_DIR}/home/${FIRST_USER_NAME}/.piscout"
install -m 644 files/nightscout.env "${ROOTFS_DIR}/home/${FIRST_USER_NAME}/.piscout/"

install -m 755 files/piscout-configurator "${ROOTFS_DIR}/home/${FIRST_USER_NAME}/"

install -m 644 files/nightscout.service "${ROOTFS_DIR}/etc/systemd/system/"
install -m 644 files/nightscout-init.service "${ROOTFS_DIR}/etc/systemd/system/"
install -m 644 files/piscout-configurator.service "${ROOTFS_DIR}/etc/systemd/system/"

sed -i "s/NIGHTSCOUTUSER/${FIRST_USER_NAME}/g" "${ROOTFS_DIR}/etc/systemd/system/nightscout.service"
sed -i "s/NIGHTSCOUTUSER/${FIRST_USER_NAME}/g" "${ROOTFS_DIR}/etc/systemd/system/nightscout-init.service"
sed -i "s/NIGHTSCOUTUSER/${FIRST_USER_NAME}/g" "${ROOTFS_DIR}/etc/systemd/system/piscout-configurator.service"

rm "${ROOTFS_DIR}/etc/nginx/sites-enabled/default"
install -m 644 files/nightscout.site "${ROOTFS_DIR}/etc/nginx/sites-available/"

on_chroot << EOF
chown -R ${FIRST_USER_NAME}: /home/${FIRST_USER_NAME}/install
chown -R ${FIRST_USER_NAME}: /home/${FIRST_USER_NAME}/.piscout
chown ${FIRST_USER_NAME}: /home/${FIRST_USER_NAME}/start_nightscout.sh
chown ${FIRST_USER_NAME}: /home/${FIRST_USER_NAME}/piscout-configurator
chmod +x /home/${FIRST_USER_NAME}/install/init.sh
chmod +x /home/${FIRST_USER_NAME}/start_nightscout.sh

ln -s /etc/nginx/sites-available/nightscout.site /etc/nginx/sites-enabled/nightscout.site
curl https://ssl-config.mozilla.org/ffdhe2048.txt > /etc/nginx/dhparam

systemctl enable nightscout-init.service
systemctl enable piscout-configurator.service
systemctl disable nginx.service
EOF
