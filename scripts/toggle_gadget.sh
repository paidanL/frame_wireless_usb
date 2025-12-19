#!/bin/bash
set -euo pipefail

G=/sys/kernel/config/usb_gadget/frame_gadget
CONFIGFS=/sys/kernel/config/usb_gadget
USBIMG=/opt/frame-transfer/usbimage/piusb.img
READY=/opt/frame-transfer/processed
MOD=libcomposite

# Ensure module is loaded
if ! lsmod | grep -q "$MOD"; then
  modprobe $MOD
fi

# Ensure configfs exists
if [ ! -d "$CONFIGFS" ]; then
  echo "ERROR: configfs not available"
  exit 1
fi

disable_gadget() {
    if [ -d "$G" ]; then
        echo "" > $G/UDC 2>/dev/null
    fi
}

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

enable_gadget() {
    # Reconcile current data
    _reconciliation_algo;

    # If gadget does not exist, recreate it
    if [ ! -d "$G" ]; then
        mkdir -p "$G"
        echo 0x1d6b > $G/idVendor
        echo 0x0104 > $G/idProduct

        mkdir $G/strings/0x409
        echo "FrameStorage" > $G/strings/0x409/product

        mkdir $G/configs/c.1
        mkdir $G/functions/mass_storage.usb0
        echo "$USBIMG" > $G/functions/mass_storage.usb0/lun.0/file
        ln -s $G/functions/mass_storage.usb0 $G/configs/c.1
    fi

    # Mount it temporarily
    mkdir -p /mnt/frame_usb
    loopdev=$(losetup -f --show "$USBIMG")
    mount "$loopdev" /mnt/frame_usb

    # sync only changed photos
    sudo rsync -rtv --delete --no-perms --no-owner --no-group --modify-window=2 "$READY"/* /mnt/frame_usb

    # Copy the ready photos
    #cp "$READY"/* /mnt/frame_usb/

    sync
    umount /mnt/frame_usb
    losetup -d "$loopdev"

    # Bind UDC
    UDC=$(ls /sys/class/udc)
    echo "$UDC" > $G/UDC

    # cleanup
    sudo rm -rf "$READY"/*
}

case "$1" in
    off) disable_gadget ;;
    on)  enable_gadget ;;
    *) echo "Usage: toggle_gadget.sh {on|off}" ;;
esac

