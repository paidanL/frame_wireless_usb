
#set -euo pipefail
# source "$(dirname '$0')/../../lib/logging.sh"

fail=0

need() {
    command -v "$1" >/dev/null || {
        echo "Missing: $1"
        fail=1
    }
}

need convert
need exiftool

if [ $fail -eq 1 ]; then
    echo "Dependency check failed"
    exit 1
fi

