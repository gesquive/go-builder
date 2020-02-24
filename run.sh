#!/bin/sh
# This is a wrapper entrypoint script for fixuid
eval $( fixuid )
"$@"
