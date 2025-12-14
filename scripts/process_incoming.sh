#!/usr/bin/env bash

#set -euo pipefail
IN=/opt/frame-transfer/incoming
STAGE=/opt/frame-transfer/staging
PROCESSED=/opt/frame-transfer/processed
TMPDIR=/tmp/frame_proc

mkdir -p "$STAGE" "$PROCESSED" "$TMPDIR"

# loop over new files
#inotifywait -m -e close_write --format '%w%f' "$IN" | while read file; do

cp "$IN"/* "$TMPDIR" 2>/dev/null

for file in "$TMPDIR"/*; do
  [ -f "$file" ] || continue
  # basic sanity
  BASENAME=$(basename "$file")
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
  OUT="$STAGE/${name}.${ext}"
  cp "$file" "$OUT"
  #fi

  # fix orientation & re-export optimized jpeg
  # create final JPEG file (map name -> final file)
  FINAL="/opt/frame-transfer/staging/${name}.${ext}"
#  convert "$OUT" -auto-orient -gravity center -crop 16:9 +repage \
#	 mpr:tiles \
#	 \( mpr:tiles[0] -resize 1920x1080\> "$FINAL" \)
#
  # crop and downsample to 1080p at 16:9
  convert "$OUT" -auto-orient -gravity center -crop 16:9 +repage \
	  -resize 1920x1080\> "$FINAL"

  # strip large metadata
  exiftool -all= "$FINAL"

#  convert "$OUT" \
#    -resize "x1080" \
#    -gravity center -crop 1920x1080 \
#    - quality 92 \
#    "$FINAL"

  # strip/normalize filenames (no spaces)
  CLEANNAME=$(echo "${name}" | tr ' ' '_' | tr -c '[:alnum:]_-' '_')
  CLEANFILE="/opt/frame-transfer/staging/${CLEANNAME}.${ext}"
  mv "$FINAL" "$CLEANFILE"
  
  # mark processed
  #mv "$CLEANFILE" "$PROCESSED/"

done

# cleanup temp dir
rm -rf "$TMPDIR" "$STAGE"/*

