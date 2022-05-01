#!/bin/sh
# helper script to copy the correct release
set -ex

DEST="/app"
INPUT=${TARGETOS}/${TARGETARCH}/${TARGETVARIANT}

PLATFORM=${TARGETOS}_${TARGETARCH}
if [ ${TARGETARCH} == "arm" ] && [ ! -z ${TARGETVARIANT} ]; then
    # docker="arm_v6" golang="arm_6"
    PLATFORM=${TARGETOS}_${TARGETARCH}_${TARGETVARIANT#?}
elif [ ${TARGETARCH} == "amd64" ] && [ -z ${TARGETVARIANT} ]; then
    # docker="amd64" golang="amd64_v1"
    PLATFORM=${TARGETOS}_${TARGETARCH}_v1
elif [ ! -z "${TARGETVARIANT}" ]; then
    PLATFORM=${TARGETOS}_${TARGETARCH}_${TARGETVARIANT}
fi

if [ -f "/dist/${APP}_${PLATFORM}/${APP}" ]; then
    echo "installing ${PLATFORM} binary"
    rsync -arP /dist/${APP}_${PLATFORM}/${APP} ${DEST}
else
    echo "no release for platform: ${TARGETOS}/${TARGETARCH}/${TARGETVARIANT}"
    exit 2
fi
