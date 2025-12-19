#!/usr/bin/env bash

#set -euo pipefail
#source "$(dirname "$0")/../lib/logging.sh"

IN=/opt/frame-transfer/incoming
STAGE=/opt/frame-transfer/staging
PROCESSED=/opt/frame-transfer/processed
TMPDIR=/tmp/frame_proc
CACHE_DIR="/var/lib/frame-cache"

# protect against bad dependencies
command -v convert >/dev/null || {
    echo "ImageMagick not installed"
    # log "ImageMagick not installed"
    exit 1
}

#mkdir -p "$STAGE" "$PROCESSED" "$TMPDIR"
mkdir -p "$STAGE" "$PROCESSED"

# loop over new files
#inotifywait -m -e close_write --format '%w%f' "$IN" | while read file; do

#cp "$IN"/* "$TMPDIR" 2>/dev/null

for file in "$IN"/*; do
#for file in "$TMPDIR"/*; do
  [ -f "$file" ] || continue

  # basic sanity
  BASENAME=$(basename "$file")

  echo "Processing image: ${BASENAME}..."
  # log "Processing image: ${BASENAME}..."

  # skip dotfiles
  if [[ "$BASENAME" =~ ^\. ]]; then continue; fi

  # If HEIC -> convert to JPG
  ## this probably will not work
  ext="${BASENAME##*.}"
  name="${BASENAME%.*}"
  #if [[ "${ext,,}" == "heic" || "${ext,,}" == "heif" ]]; then
  #  # heif-convert output.jpg
  #  OUT="$STAGE/${name}.jpg"
  #  heif-convert "$file" "$OUT" || {
  #    # fallback to imagemagick if heif-convert fails
  #    magick "$file" "$OUT"
  #  }
  #else
  # For JPEG/PNG — copy to staging
  SRC=$file
  HASH=$(sha1sum "$file" | awk '{print $1}')
  SUBDIR="${HASH:0:2}"
  MARKER="$CACHE_DIR/hashes/$SUBDIR/$HASH"

  mkdir -p "$CACHE_DIR/hashes/$SUBDIR"

  if [[ -f "$MARKER" ]]; then
      echo "Already processed: $SRC"
      continue
  fi

  PATH_KEY=$(printf '%s' "$file" | sha1sum | awk '{print $1}')
  CLEANNAME=$(echo "${name}" | tr ' ' '_' | tr -c '[:alnum:]_-' '_')
  USB_OUT="$PROCESSED/${CLEANNAME}.${ext}"

  #if [[ -f "USB_OUT" ]]; then
  #    echo "File already stored on USB"
  #    continue
  #fi

  OUT="$STAGE/${name}.${ext}"
  cp "$file" "$OUT"
  #fi

  # fix orientation & re-export optimized jpeg
  # create final JPEG file (map name -> final file)
  FINAL="/opt/frame-transfer/staging/${name}.${ext}"
#
  # crop and downsample to 1080p at 16:9
  convert "$OUT" \
      -auto-orient \
      -gravity center \
      -crop 16:9 \
      +repage \
	  -resize 1920x1080\> \
      "$FINAL"

  # strip large metadata
  exiftool -all= "$FINAL"

  # strip/normalize filenames (no spaces)
  CLEANNAME=$(echo "${name}" | tr ' ' '_' | tr -c '[:alnum:]_-' '_')
  CLEANFILE="/opt/frame-transfer/staging/${CLEANNAME}.${ext}"
  mv "$FINAL" "$CLEANFILE"
  
  # mark processed
  mv "$CLEANFILE" "$PROCESSED/"

  # update/add hash
  touch "$MARKER"

  # update meta data
  mkdir -p "$CACHE_DIR/paths/$PATH_KEY"
  cat > "$CACHE_DIR/paths/$PATH_KEY/meta" <<EOF
SRC=$SRC
HASH=$HASH
USB=$USB_OUT
EOF

done

# cleanup temp dir
rm -rf "$STAGE"/*
#rm -rf "$TMPDIR" "$STAGE"/*

