#!/usr/bin/env bash
# ==============================================================================
# HPLIP 3.26.6 Installer & Patch for Ubuntu 24.04 / 25.10 / 26.04+
# Fixes GCC 15 / C23 build errors and Python 3.14 URLopener removals.
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PATCH_FILE="${SCRIPT_DIR}/hplip-3.26.6-ubuntu-26.04.patch"
HPLIP_VER="3.26.6"
HPLIP_RUN="hplip-${HPLIP_VER}.run"
SRC_DIR="hplip-${HPLIP_VER}"
DOWNLOAD_URL="https://downloads.sourceforge.net/project/hplip/hplip/${HPLIP_VER}/${HPLIP_RUN}"

echo "=========================================================="
echo "  HPLIP ${HPLIP_VER} Modern Ubuntu / Linux Installer"
echo "  Patches for GCC 15 (C23) & Python 3.14 Compatibility"
echo "=========================================================="

if [ ! -f "${PATCH_FILE}" ]; then
    echo "[-] Error: Patch file '${PATCH_FILE}' not found!"
    exit 1
fi

# 1. Dependency Check & Installation
echo "[*] Checking build dependencies..."
REQUIRED_PKGS=(
    gcc
    g++
    make
    libtool
    automake
    autoconf
    pkg-config
    libcups2-dev
    libcupsimage2-dev
    libusb-1.0-0-dev
    libsane-dev
    libsnmp-dev
    libssl-dev
    libavahi-client-dev
    libavahi-common-dev
    libdbus-1-dev
    python3-dev
    python3-pyqt5
    python3-dbus
    python3-pil
    python3-reportlab
    patch
    wget
)

MISSING_PKGS=()
for pkg in "${REQUIRED_PKGS[@]}"; do
    if ! dpkg -s "${pkg}" >/dev/null 2>&1; then
        MISSING_PKGS+=("${pkg}")
    fi
done

if [ ${#MISSING_PKGS[@]} -gt 0 ]; then
    echo "[!] Missing required packages: ${MISSING_PKGS[*]}"
    echo "[*] Installing missing dependencies..."
    sudo apt-get update
    sudo apt-get install -y "${MISSING_PKGS[@]}"
else
    echo "[+] All required dependencies are installed."
fi

# 2. Locate or Download HPLIP self-extracting archive
if [ ! -f "${HPLIP_RUN}" ]; then
    SEARCH_PATHS=(
        "${HOME}/Desktop/${HPLIP_RUN}"
        "${HOME}/Downloads/${HPLIP_RUN}"
    )
    FOUND=""
    for p in "${SEARCH_PATHS[@]}"; do
        if [ -f "$p" ]; then
            echo "[+] Found existing archive at: $p"
            cp "$p" "./${HPLIP_RUN}"
            FOUND="yes"
            break
        fi
    done

    if [ -z "$FOUND" ]; then
        echo "[*] Downloading ${HPLIP_RUN} from SourceForge..."
        wget --progress=bar:force -O "${HPLIP_RUN}" "${DOWNLOAD_URL}"
    fi
fi

# 3. Extract Archive
if [ -d "${SRC_DIR}" ]; then
    echo "[!] Existing directory '${SRC_DIR}' detected. Backing up..."
    mv "${SRC_DIR}" "${SRC_DIR}.bak.$(date +%s)"
fi

echo "[*] Extracting ${HPLIP_RUN}..."
sh "./${HPLIP_RUN}" --noexec --target "./${SRC_DIR}"

# 4. Apply Patches
echo "[*] Applying Ubuntu / GCC 15 / Python 3.14 patch..."
cd "${SRC_DIR}"
patch -p1 < "${PATCH_FILE}"

# Convert python shebangs to python3 if present
find . -maxdepth 2 -type f -name "*.py" -exec sed -i '1s|^#!/usr/bin/env python$|#!/usr/bin/env python3|' {} +

# 5. Configure
echo "[*] Configuring HPLIP build..."
./configure --prefix=/usr \
            --enable-qt5 \
            --disable-qt4 \
            --enable-hpcups-install \
            --enable-cups-drv-install \
            --enable-gui-build \
            --enable-scan-build \
            --enable-fax-build \
            --enable-dbus-build \
            --enable-network-build

# 6. Build
echo "[*] Compiling with $(nproc) parallel jobs..."
make -j"$(nproc)"

# 7. Install
echo "[*] Installing HPLIP to system directories..."
sudo make install

# Ensure data directory has proper global read permissions
echo "[*] Setting appropriate permissions on /usr/share/hplip/data..."
sudo chmod -R a+rX /usr/share/hplip/data
sudo ldconfig

echo "=========================================================="
echo "  HPLIP ${HPLIP_VER} successfully installed and patched!"
echo "=========================================================="
echo ""
echo "Quick Test / Management Commands:"
echo "  - Diagnostics: hp-check -r"
echo "  - HP Device Manager GUI: hp-toolbox"
echo "    (If on Wayland and you see focus warnings, use: QT_QPA_PLATFORM=xcb hp-toolbox)"
echo "  - Ink / Toner Levels: hp-levels"
echo "  - Print Test Page: hp-testpage"
echo ""
