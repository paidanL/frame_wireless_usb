#set -euo pipefail

APT_DEPS_FILE="$(dirname "$0")/../../deps/apt.txt"

sudo apt update
xargs -a "$APT_DEPS_FILE" sudo apt install -y

