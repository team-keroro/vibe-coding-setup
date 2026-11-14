#!/bin/bash
# Double-click launcher for setup-mac.sh (must be in the same folder).
cd "$(dirname "$0")" && /bin/bash ./setup-mac.sh
echo
read -r -p '엔터를 누르면 끝나요. 이 창은 닫아도 돼요.'
