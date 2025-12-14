#!/bin/bash

IN=/opt/frame-transfer/incoming

while true; do
    inotifywait -e create -e moved_to "$IN"
    
    # Disable USB immediately so the TV stops scanning.
    /usr/local/bin/toggle_gadget.sh off

    # Give the upload a buffer window (5 secs no activity)
    while inotifywait -t 5 -e create -e moved_to "$IN"; do
        :  # wait for idle
    done

    # Process images
    /usr/local/bin/process_incoming.sh

    # Re-enable gadget with new image set
    /usr/local/bin/toggle_gadget.sh on
done

