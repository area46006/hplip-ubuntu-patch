# HPLIP 3.26.6 Compatibility Patch for Modern Ubuntu & Linux

A patch and automated installer for **HP Linux Imaging and Printing (HPLIP) 3.26.6** on modern Linux systems, specifically tested on **Ubuntu 26.04 ("Resolute")**, **Ubuntu 24.04/25.10**, and modern Debian distributions running **GCC 15+** and **Python 3.14+**.

---

## Background & Issues Resolved

Official HPLIP 3.26.6 fails to build or run on modern Linux systems due to several compiler and standard library updates:

1. **GCC 15 & C23 Standard Enforcement**:
   - In C23 (the default in GCC 15), empty parameter lists `foo()` mean `foo(void)` instead of accepting unverified arguments. This breaks functions like `bb_is_paper_in_adf()`.
   - Strict `-Wreturn-mismatch` rejects returning values in `void` functions (such as `orblite_close()`).
   - Missing headers (`<dlfcn.h>`, `<unistd.h>`) cause fatal implicit function declaration errors (`dlclose`, `usleep`).
   - Missing prototypes for CUPS printer functions (`addCupsPrinter`, `delCupsPrinter`, `setDefaultCupsPrinter`, `controlCupsPrinter`).
   - Implicit `int` declarations in `pserror.c` (`static column = 0;`).

2. **Python 2 Legacy C Extension (`pcardext`)**:
   - `pcard/pcardext/pcardext.c` uses long-removed Python 2 APIs (`PyString_*`, `Py_InitModule4`), causing compilation failures under Python 3. This obsolete module is cleanly decoupled from build targets.

3. **Python 3.14 Breaking Change**:
   - Python 3.14 completely removed `urllib.request.URLopener` (deprecated since Python 3.3).
   - HPLIP subclassed `URLopener` for its custom HTTP/EWS/LEDM handlers in `base/device.py`, causing `AttributeError: module 'urllib.request' has no attribute 'URLopener'` when running `hp-check` or `hp-toolbox`.
   - Python 3.14 syntax warnings (e.g. `return` in `finally` blocks) have been cleaned up.

4. **Data Directory Permission Fix**:
   - `sudo make install` on systems with strict root umasks creates `/usr/share/hplip/data` with mode `750`, preventing non-root users from accessing icons and printer images (`error: Pixmap 'hp-tux-printer.png' not found!`).

---

## Quick Start (Automated Install)

Clone this repository and run the installer script:

```bash
git clone https://github.com/<your-username>/hplip-ubuntu-patch.git
cd hplip-ubuntu-patch
chmod +x install.sh
./install.sh
```

The script will:
1. Verify and install any missing build dependencies via `apt-get`.
2. Locate existing `hplip-3.26.6.run` or download it from SourceForge.
3. Extract the archive without running the flawed installer script.
4. Apply the unified patch.
5. Build, install, and adjust system permissions.

---

## Manual Installation

If you prefer to apply the patch manually to an existing HPLIP 3.26.6 source tree:

### 1. Install Build Dependencies

```bash
sudo apt-get update
sudo apt-get install -y \
    gcc g++ make libtool automake autoconf pkg-config \
    libcups2-dev libcupsimage2-dev libusb-1.0-0-dev \
    libsane-dev libsnmp-dev libssl-dev \
    libavahi-client-dev libavahi-common-dev libdbus-1-dev \
    python3-dev python3-pyqt5 python3-dbus python3-pil python3-reportlab
```

### 2. Extract and Patch

```bash
# Extract without executing
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
   *Note for Wayland users:* If you see repeated warnings (`Wayland does not support QWindow::requestActivate()`), run through XWayland:
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

## License

The patches and installer scripts in this repository are distributed under the [GNU General Public License v2 or later](LICENSE), matching the upstream HPLIP open-source license.
