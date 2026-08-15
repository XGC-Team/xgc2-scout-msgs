#!/usr/bin/env bash
set -euo pipefail

grep -q '^id: xgc2-scout-msgs$' .xgc2/product.yml
grep -qE '^version: [^[:space:]]+$' .xgc2/product.yml
grep -q '<name>scout_msgs</name>' package.xml
grep -q '<version>0.3.3</version>' package.xml
grep -q 'ros-melodic-scout-msgs' .xgc2/product.yml
grep -q 'ros-noetic-scout-msgs' .xgc2/product.yml
test -f msg/ScoutStatus.msg
test -f msg/ScoutMotorState.msg
test -f msg/ScoutLightState.msg
test -f msg/ScoutLightCmd.msg

echo "Package compliance checks passed."
