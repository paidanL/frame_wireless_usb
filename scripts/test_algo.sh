#!/usr/bin/bash

_reconciliation_algo() {
    for meta in /var/lib/frame-cache/paths/*/meta; do
        SRC=$(grep '^SRC=' "$meta" | cut -d= -f2)
        HASH=$(grep '^HASH=' "$meta" | cut -d= -f2)

        if [[ ! -f "$SRC" ]]; then
            echo "Removing $SRC"

            USB=$(grep '^USB=' "$meta" | cut -d= -f2)
            rm -f "$USB"
            rm -rf "$(dirname "$meta")"

            SUBDIR="${HASH:0:2}"
            MARKER="/var/lib/frame-cache/hashes/$SUBDIR/$HASH"
            rm -rf $MARKER
            if [[ -z "$( ls -A $(dirname $MARKER) )" ]]; then
                rm -rf $(dirname "$MARKER")
            fi
        fi
    done
}

_reconciliation_algo

