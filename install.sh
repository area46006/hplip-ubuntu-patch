#!/usr/bin/env bash
# ==============================================================================
# HPLIP 3.26.6 Automated Installer & Patch for Ubuntu 24.04 / 25.10 / 26.04+
# Complete dependency resolver, GCC 15 (C23) and Python 3.14 compatibility engine.
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PATCH_FILE="${SCRIPT_DIR}/hplip-3.26.6-ubuntu-26.04.patch"
HPLIP_VER="3.26.6"
HPLIP_RUN="hplip-${HPLIP_VER}.run"
SRC_DIR="hplip-${HPLIP_VER}"
DOWNLOAD_URL="https://downloads.sourceforge.net/project/hplip/hplip/${HPLIP_VER}/${HPLIP_RUN}"

echo "===================================================================="
echo "  HPLIP ${HPLIP_VER} Universal Modern Linux Installer"
echo "  Tested on Ubuntu 24.04 LTS, 25.10, and 26.04 LTS ('Resolute')"
echo "===================================================================="

# Ensure sudo access upfront
sudo -v

# ------------------------------------------------------------------------------
# 1. Comprehensive Dependency Verification & Installation
# ------------------------------------------------------------------------------
echo ""
echo "[*] Auditing system dependencies for HPLIP build and runtime..."

# Core build system and compilers
CORE_BUILD_DEPS=(
    build-essential
    gcc
    g++
    make
    libtool
    libtool-bin
    automake
    autoconf
    pkg-config
    patch
    wget
)

# Printing subsystem and libraries (CUPS)
CUPS_DEPS=(
    cups
    cups-bsd
    cups-client
    cups-filters
    libcups2-dev
    libcupsimage2-dev
)

# Scanning subsystem (SANE)
SANE_DEPS=(
    sane
    sane-utils
    libsane-dev
    xsane
)

# Hardware, Bus, Security & Network libraries
SYSTEM_LIB_DEPS=(
    libusb-1.0-0-dev
    libsnmp-dev
    libssl-dev
    libavahi-client-dev
    libavahi-common-dev
    libavahi-core-dev
    avahi-utils
    avahi-daemon
    dbus
    libdbus-1-dev
    polkitd
    libjpeg-dev
    ghostscript
)

# Python 3 runtime and PyQt5 GUI libraries
PYTHON_DEPS=(
    python3
    python3-dev
    python3-pyqt5
    python3-dbus
    python3-dbus.mainloop.pyqt5
    python3-gi
    python3-lxml
    python3-pil
    python3-reportlab
    python3-notify2
)

# ScanJet OCR and document processing (Optional but recommended)
OCR_DEPS=(
    tesseract-ocr
    qpdf
)

ALL_DEPS=(
    "${CORE_BUILD_DEPS[@]}"
    "${CUPS_DEPS[@]}"
    "${SANE_DEPS[@]}"
    "${SYSTEM_LIB_DEPS[@]}"
    "${PYTHON_DEPS[@]}"
    "${OCR_DEPS[@]}"
)

MISSING_DEPS=()
for dep in "${ALL_DEPS[@]}"; do
    if ! dpkg -s "${dep}" >/dev/null 2>&1; then
        MISSING_DEPS+=("${dep}")
    fi
done

if [ ${#MISSING_DEPS[@]} -gt 0 ]; then
    echo "[!] The following required or recommended dependencies are missing:"
    for m in "${MISSING_DEPS[@]}"; do
        echo "    - ${m}"
    done
    echo "[*] Updating package index and installing dependencies..."
    sudo apt-get update
    sudo apt-get install -y "${MISSING_DEPS[@]}"
else
    echo "[+] All $((${#ALL_DEPS[@]})) system dependencies are already installed and satisfied."
fi

# Ensure CUPS service is active
if ! systemctl is-active --quiet cups; then
    echo "[*] Starting CUPS printing daemon..."
    sudo systemctl enable --now cups
fi

# Ensure current user is in lp and lpadmin groups
for grp in lp lpadmin; do
    if ! id -nG "$USER" | grep -qw "$grp"; then
        echo "[*] Adding $USER to $grp group..."
        sudo usermod -a -G "$grp" "$USER"
    fi
done

# ------------------------------------------------------------------------------
# 2. Acquire HPLIP 3.26.6 Self-Extracting Archive
# ------------------------------------------------------------------------------
echo ""
echo "[*] Locating HPLIP ${HPLIP_VER} archive..."
if [ ! -f "${HPLIP_RUN}" ]; then
    SEARCH_LOCATIONS=(
        "${SCRIPT_DIR}/${HPLIP_RUN}"
        "${HOME}/Desktop/${HPLIP_RUN}"
        "${HOME}/Downloads/${HPLIP_RUN}"
    )
    ACQUIRED=""
    for loc in "${SEARCH_LOCATIONS[@]}"; do
        if [ -f "$loc" ]; then
            echo "[+] Found existing archive at: $loc"
            cp "$loc" "./${HPLIP_RUN}"
            ACQUIRED="yes"
            break
        fi
    done

    if [ -z "$ACQUIRED" ]; then
        echo "[*] Downloading official ${HPLIP_RUN} from SourceForge..."
        wget --progress=bar:force -O "${HPLIP_RUN}" "${DOWNLOAD_URL}"
    fi
fi

# ------------------------------------------------------------------------------
# 3. Extraction
# ------------------------------------------------------------------------------
echo ""
if [ -d "${SRC_DIR}" ]; then
    BACKUP_DIR="${SRC_DIR}.bak.$(date +%s)"
    echo "[!] Existing build directory '${SRC_DIR}' detected. Moving to ${BACKUP_DIR}..."
    mv "${SRC_DIR}" "${BACKUP_DIR}"
fi

echo "[*] Extracting ${HPLIP_RUN} archive..."
sh "./${HPLIP_RUN}" --noexec --target "./${SRC_DIR}"

# ------------------------------------------------------------------------------
# 4. Patch Application
# ------------------------------------------------------------------------------
echo ""
echo "[*] Applying modern toolchain and Python 3.14 compatibility patch..."
if [ ! -f "${PATCH_FILE}" ]; then
    echo "[-] Error: Patch file '${PATCH_FILE}' not found!"
    exit 1
fi

cd "${SRC_DIR}"
patch -p1 < "${PATCH_FILE}"

# Normalize any leftover Python shebangs to python3
find . -maxdepth 2 -type f -name "*.py" -exec sed -i '1s|^#!/usr/bin/env python$|#!/usr/bin/env python3|' {} +

# ------------------------------------------------------------------------------
# 5. Build Configuration
# ------------------------------------------------------------------------------
echo ""
echo "[*] Running ./configure with Qt5, CUPS, SANE, and DBus enabled..."
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

# ------------------------------------------------------------------------------
# 6. Parallel Compilation
# ------------------------------------------------------------------------------
echo ""
NUM_CORES="$(nproc)"
echo "[*] Compiling HPLIP with ${NUM_CORES} parallel cores..."
make -j"${NUM_CORES}"

# ------------------------------------------------------------------------------
# 7. System Installation & Security Permissions
# ------------------------------------------------------------------------------
echo ""
echo "[*] Installing HPLIP into system directories..."
sudo make install

# Ensure global read and execute permissions on HPLIP data directory (icons/images)
echo "[*] Setting correct permissions on /usr/share/hplip/data..."
sudo chmod -R a+rX /usr/share/hplip/data

# Reload dynamic linker cache
echo "[*] Updating library cache with ldconfig..."
sudo ldconfig

# Reload udev rules for HP USB devices
if [ -f /etc/udev/rules.d/56-hpmud.rules ]; then
    echo "[*] Reloading udev rules..."
    sudo udevadm control --reload-rules || true
    sudo udevadm trigger || true
fi

echo ""
echo "===================================================================="
echo "  HPLIP ${HPLIP_VER} Installation & Configuration Complete!"
echo "===================================================================="
echo ""
echo "Post-Installation Verification:"
echo "  1. Run diagnostic check:     hp-check -r"
echo "  2. Open HP Device Manager:   hp-toolbox"
echo "     (On Wayland sessions:     QT_QPA_PLATFORM=xcb hp-toolbox)"
echo "  3. Query supply levels:      hp-levels"
echo "  4. Print test page:          hp-testpage"
echo ""
