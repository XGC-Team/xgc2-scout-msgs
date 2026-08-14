#!/usr/bin/env bash
set -euo pipefail

INSTALL_ROOT=""
OUTPUT_DIR=""
ROS_DISTRO="${ROS_DISTRO:-melodic}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
PACKAGE="ros-${ROS_DISTRO}-scout-msgs"
ROS_PACKAGE="scout_msgs"

product_version() {
  sed -n 's/^version:[[:space:]]*//p' "${REPO_ROOT}/.xgc2/product.yml" | head -n 1 | tr -d '\r'
}

VERSION="${PACKAGE_VERSION:-$(product_version)}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --install-root)
      INSTALL_ROOT="$2"
      shift 2
      ;;
    --output-dir)
      OUTPUT_DIR="$2"
      shift 2
      ;;
    *)
      echo "unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

if [[ -z "${INSTALL_ROOT}" || -z "${OUTPUT_DIR}" ]]; then
  echo "--install-root and --output-dir are required" >&2
  exit 1
fi
if [[ -z "${VERSION}" ]]; then
  echo "package version is missing" >&2
  exit 1
fi

ARCH="$(dpkg --print-architecture)"
PREFIX="/opt/ros/${ROS_DISTRO}"
PREFIX_ROOT="${INSTALL_ROOT}${PREFIX}"
PKG_ROOT="$(mktemp -d)"

cleanup() {
  rm -rf "${PKG_ROOT}"
}
trap cleanup EXIT

mkdir -p "${OUTPUT_DIR}" "${PKG_ROOT}/DEBIAN" "${PKG_ROOT}/usr/share/doc/${PACKAGE}"
rm -f "${OUTPUT_DIR}/${PACKAGE}_"*.deb

copy_path() {
  local src="$1"
  if [[ -e "${src}" ]]; then
    mkdir -p "${PKG_ROOT}$(dirname "${src#${INSTALL_ROOT}}")"
    cp -a "${src}" "${PKG_ROOT}${src#${INSTALL_ROOT}}"
  fi
}

copy_glob() {
  local pattern
  local src
  shopt -s nullglob
  for pattern in "$@"; do
    for src in ${pattern}; do
      copy_path "${src}"
    done
  done
  shopt -u nullglob
}

copy_path "${PREFIX_ROOT}/share/${ROS_PACKAGE}"
copy_path "${PREFIX_ROOT}/include/${ROS_PACKAGE}"
copy_glob "${PREFIX_ROOT}"/lib/python*/dist-packages/"${ROS_PACKAGE}"
copy_path "${PREFIX_ROOT}/share/common-lisp/ros/${ROS_PACKAGE}"
copy_path "${PREFIX_ROOT}/share/gennodejs/ros/${ROS_PACKAGE}"
copy_path "${PREFIX_ROOT}/share/roseus/ros/${ROS_PACKAGE}"

if [[ ! -e "${PKG_ROOT}${PREFIX}/share/${ROS_PACKAGE}/package.xml" ]]; then
  echo "missing installed package.xml for ${ROS_PACKAGE}" >&2
  exit 1
fi

cat > "${PKG_ROOT}/DEBIAN/control" <<EOF
Package: ${PACKAGE}
Version: ${VERSION}
Section: misc
Priority: optional
Architecture: ${ARCH}
Maintainer: XGC2 <apt@example.com>
Depends: ros-${ROS_DISTRO}-message-runtime, ros-${ROS_DISTRO}-std-msgs
Conflicts: ros-${ROS_DISTRO}-xgc2-agilex-scout-msgs
Replaces: ros-${ROS_DISTRO}-xgc2-agilex-scout-msgs
Provides: ros-${ROS_DISTRO}-xgc2-agilex-scout-msgs
Description: AgileX Scout ROS message definitions
 ROS ${ROS_DISTRO} scout_msgs package kept compatible with the recovered
 vehicle Scout base driver. Replaces the retired vehicle-tree fork.
EOF

cat > "${PKG_ROOT}/usr/share/doc/${PACKAGE}/README" <<EOF
${PACKAGE}

ROS package:
  ${ROS_PACKAGE}

Version:
  ${VERSION}
EOF

find "${PKG_ROOT}" -type d -exec chmod 0755 {} +
find "${PKG_ROOT}" -type f -exec chmod 0644 {} +
chmod 0755 "${PKG_ROOT}/DEBIAN"

fakeroot dpkg-deb --build "${PKG_ROOT}" "${OUTPUT_DIR}/${PACKAGE}_${VERSION}_${ARCH}.deb" >/dev/null
find "${OUTPUT_DIR}" -maxdepth 1 -type f -name "${PACKAGE}_*.deb" -print | sort
