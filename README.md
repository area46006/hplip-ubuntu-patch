# HPLIP 3.26.6 Compatibility Patch for Modern Ubuntu & Linux

[![Patch Integrity & Lint](https://github.com/area46006/hplip-ubuntu-patch/actions/workflows/ci.yml/badge.svg)](https://github.com/area46006/hplip-ubuntu-patch/actions/workflows/ci.yml)
[![License: GPL-2.0](https://img.shields.io/badge/License-GPL_2.0-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Ubuntu%2024.04%20%7C%2025.10%20%7C%2026.04-orange.svg)](#)

A complete patch, automated installer, and dependency manager for **HP Linux Imaging and Printing (HPLIP) 3.26.6** on modern Linux systems. Tested and verified on **Ubuntu 26.04 ("Resolute")**, **Ubuntu 24.04 LTS / 25.10**, and modern Debian distributions running **GCC 15+** and **Python 3.14+**.

---

## Upstream Project & Official Channels

This repository is maintained to assist Linux users until these modern toolchain fixes are integrated into an official upstream release by HP:

- **Official HP Developer Portal**: [developers.hp.com/hp-linux-imaging-and-printing](https://developers.hp.com/hp-linux-imaging-and-printing)
- **Official SourceForge Repository**: [sourceforge.net/projects/hplip](https://sourceforge.net/projects/hplip/)
- **Official Upstream Bug Tracker (Launchpad)**: [bugs.launchpad.net/hplip](https://bugs.launchpad.net/hplip)

### Upstream Contribution Notice
HP tracks community bugs, hardware support questions, and patch contributions on their official [Launchpad bug tracker](https://bugs.launchpad.net/hplip). The unified patch provided here (`hplip-3.26.6-ubuntu-26.04.patch`) is formatted as a standard patch that can be submitted to HP's Launchpad maintainers so future HPLIP releases incorporate native support for GCC 15 and Python 3.14.

---

## Legal & Compliance Notice

- **Open Source Patch Model**: This repository distributes **only** unified source code patches and open-source installer automation under the GNU General Public License v2 (GPL-2.0).
- **No Proprietary Binary Redistribution**: This repository does **NOT** host or redistribute HP proprietary binary firmware or closed-source driver plugins (such as `libImageProcessor.so`). The installer downloads the official upstream archive directly from HP / SourceForge onto the user's local machine, fully adhering to HP's distribution terms and open-source licensing guidelines.
- **Trademark Disclaimer**: HP, HPLIP, and Hewlett-Packard are registered trademarks of HP Inc. This is an independent open-source community maintenance project and is not affiliated with, endorsed by, or sponsored by HP Inc.

---

## Application & Package Compatibility (APT, Snap & Flatpak)

This project installs HPLIP as a native host driver while ensuring full interoperability across all packaging formats:

1. **Native APT & System Applications (Default)**:
   - The driver is compiled and installed directly into standard system locations (`/usr/bin`, `/usr/lib/cups`, `/usr/lib/sane`, `/usr/share/hplip`).
   - All native applications installed via `apt` or `.deb` (such as native LibreOffice, Evince, GIMP, Document Viewer, Simple Scan, and the CUPS web interface at `http://localhost:631`) communicate directly with HPLIP through native CUPS and SANE.

2. **Sandboxed Applications (Snap & Flatpak)**:
   - On modern Ubuntu releases, several default desktop applications are distributed as Snaps or Flatpaks (e.g. Snap Firefox, Flatpak LibreOffice).
   - **Flatpak Applications**: Flatpak apps print by delegating print jobs to the host through the standard **XDG Desktop Portal** (`org.freedesktop.portal.Print`). Because this driver registers with the host CUPS daemon, all Flatpak apps print seamlessly through the desktop print dialog.
   - **Snap Applications**: Snapped applications print via the standard `cups` / `cups-control` interface (`/var/run/cups/cups.sock`). They automatically recognize and print to all queues managed by HPLIP.

3. **Why HPLIP Itself is Built as a Native Host Driver**:
   - Hardware drivers require deep system integration: CUPS backend filters, SANE scanner shared libraries, and low-level kernel `udev` rules (`/etc/udev/rules.d/56-hpmud.rules`) that need raw access to USB hardware bus nodes (`/dev/bus/usb/*`).
   - Sandboxed application containers (like Flatpak) isolate software from the host driver tree by design. Installing this driver on the host provides universal, zero-configuration printing for **both** native APT applications and sandboxed Snap/Flatpak applications.

---

## Issues Resolved

Official HPLIP 3.26.6 fails to build or run out of the box on modern Linux systems due to compiler and standard library updates:

1. **GCC 15 & C23 Standard Compliance**:
   - In C23 (default in GCC 15), empty parameter lists `foo()` mean `foo(void)` instead of accepting unverified arguments. This breaks functions like `bb_is_paper_in_adf()`.
   - Strict `-Wreturn-mismatch` rejects returning values in `void` functions (such as `orblite_close()`).
   - Missing headers (`<dlfcn.h>`, `<unistd.h>`) cause fatal implicit function declaration errors (`dlclose`, `usleep`).
   - Missing prototypes for CUPS printer functions (`addCupsPrinter`, `delCupsPrinter`, `setDefaultCupsPrinter`, `controlCupsPrinter`).
   - Implicit `int` declarations in `pserror.c` (`static column = 0;`).

2. **Python 2 Legacy C Extension (`pcardext`)**:
   - `pcard/pcardext/pcardext.c` uses long-removed Python 2 APIs (`PyString_*`, `Py_InitModule4`), causing compilation failures under Python 3. This obsolete module is cleanly decoupled from build targets.

3. **Python 3.14 Breaking Change (`URLopener` Removal)**:
   - Python 3.14 completely removed `urllib.request.URLopener` (deprecated since Python 3.3).
   - HPLIP subclassed `URLopener` for its custom HTTP/EWS/LEDM handlers in `base/device.py`, causing `AttributeError: module 'urllib.request' has no attribute 'URLopener'` when running `hp-check` or `hp-toolbox`.
   - Python 3.14 syntax warnings (e.g. `return` in `finally` blocks) have been cleaned up in `prnt/cups.py` and `ui5/faxsetupdialog.py`.

4. **Data Directory Permission Fix**:
   - `sudo make install` on systems with strict root umasks creates `/usr/share/hplip/data` with mode `750`, preventing non-root users from accessing icons and printer images (`error: Pixmap 'hp-tux-printer.png' not found!`).

---

## Dependencies Managed

The included `install.sh` automatically checks and installs all required and recommended packages across 6 subsystems using `apt-get`:

- **Build Toolchain**: `build-essential`, `gcc`, `g++`, `make`, `libtool`, `libtool-bin`, `automake`, `autoconf`, `pkg-config`, `patch`, `wget`
- **Printing Subsystem (CUPS)**: `cups`, `cups-bsd`, `cups-client`, `cups-filters`, `libcups2-dev`, `libcupsimage2-dev`
- **Scanning Subsystem (SANE)**: `sane`, `sane-utils`, `libsane-dev`, `xsane`
- **Hardware, Bus & Security**: `libusb-1.0-0-dev`, `libsnmp-dev`, `libssl-dev`, `libavahi-client-dev`, `libavahi-common-dev`, `libavahi-core-dev`, `avahi-utils`, `avahi-daemon`, `dbus`, `libdbus-1-dev`, `polkitd`, `libjpeg-dev`, `ghostscript`
- **Python 3 & PyQt5 GUI**: `python3`, `python3-dev`, `python3-pyqt5`, `python3-dbus`, `python3-dbus.mainloop.pyqt5`, `python3-gi`, `python3-lxml`, `python3-pil`, `python3-reportlab`, `python3-notify2`
- **OCR & Document Processing**: `tesseract-ocr`, `qpdf`

It also ensures the CUPS daemon is active, reloads HP `udev` rules, and adds the current user to the `lp` and `lpadmin` groups.

---

## Quick Start (Automated Install)

Clone this repository and run the installer script:

```bash
git clone https://github.com/area46006/hplip-ubuntu-patch.git
cd hplip-ubuntu-patch
chmod +x install.sh
./install.sh
```

The script handles the full lifecycle: dependency installation, downloading/extracting official `hplip-3.26.6.run`, applying the patch, compiling with all CPU cores, installing, and configuring system permissions.

---

## Manual Installation

If you prefer to compile manually:

### 1. Install Dependencies

```bash
sudo apt-get update
sudo apt-get install -y \
    build-essential gcc g++ make libtool libtool-bin automake autoconf pkg-config patch wget \
    cups cups-bsd cups-client cups-filters libcups2-dev libcupsimage2-dev \
    sane sane-utils libsane-dev xsane \
    libusb-1.0-0-dev libsnmp-dev libssl-dev libavahi-client-dev libavahi-common-dev \
    avahi-utils avahi-daemon dbus libdbus-1-dev polkitd libjpeg-dev ghostscript \
    python3 python3-dev python3-pyqt5 python3-dbus python3-dbus.mainloop.pyqt5 \
    python3-gi python3-lxml python3-pil python3-reportlab python3-notify2 \
    tesseract-ocr qpdf
```

### 2. Extract and Patch

```bash
# Extract without running the broken upstream installer
sh hplip-3.26.6.run --noexec --target hplip-3.26.6
cd hplip-3.26.6

# Apply patch
patch -p1 < /path/to/hplip-3.26.6-ubuntu-26.04.patch
```

### 3. Configure, Build, and Install

```bash
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

make -j$(nproc)
sudo make install
sudo chmod -R a+rX /usr/share/hplip/data
sudo ldconfig
```

---

## Verification & Usage

1. **Verify Installation**:
   ```bash
   hp-check -r
   ```
   All extensions (`cupsext`, `hpmudext`, `hpaio`, `scanext`) should report `3.26.6 OK` with no missing required dependencies.

2. **Launch HP Device Manager**:
   ```bash
   hp-toolbox
   ```
   *Note for Wayland users:* If you see repeated `Wayland does not support QWindow::requestActivate()` messages, run through XWayland:
   ```bash
   QT_QPA_PLATFORM=xcb hp-toolbox
   ```

3. **Check Supplies / Levels**:
   ```bash
   hp-levels
   ```

4. **Print Test Page**:
   ```bash
   hp-testpage
   ```

---

## Contributing & Security

- Contributions are welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) and [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).
- To report security issues, refer to [SECURITY.md](SECURITY.md).

---

## License

This project is licensed under the [GNU General Public License v2.0](LICENSE).
