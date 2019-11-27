#!/bin/sh
# helper script to copy the correct release
set -ex

DEST="/app"

PLATFORM=${TARGETOS}_${TARGETARCH}
if [ ! -z "${TARGETVARIANT}" ]; then
    PLATFORM=${TARGETOS}_${TARGETARCH}_${TARGETVARIANT#?}
fi

if [ -f "/dist/${APP}_${PLATFORM}/${APP}" ]; then
    echo "installing ${PLATFORM} binary"
    rsync -arP /dist/${APP}_${PLATFORM}/${APP} ${DEST}
else
    echo "no release for platform: ${TARGETOS}/${TARGETARCH}/${TARGETVARIANT}"
    exit 2
fi
