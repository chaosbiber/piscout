#!/bin/sh

# https://github.com/nightscout/cgm-remote-monitor/blob/master/README.md

export $(grep -v '^#' ~/.piscout/mongopw.env | xargs)
export $(grep -v '^#' ~/.piscout/apisecret.env | xargs)
export $(grep -v '^#' ~/.piscout/nightscout.env | xargs)

export MONGO_CONNECTION=mongodb://nightscoutuser:${MONGO_PW}@127.0.0.1:27017/nightscout

cd ${HOME}/nightscout-git
node server.js
