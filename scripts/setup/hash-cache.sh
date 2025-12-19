#!/bin/sh

CACHE_DIR="/var/lib/frame-cache" 

if [ ! -d $CACHE_DIR ]; then
    mkdir -p "$CACHE_DIR/hashes"
    mkdir -p "$CACHE_DIR/paths"
fi

