# Contributing to HPLIP Modern Linux Compatibility

Thank you for helping maintain compatibility for HPLIP on modern Linux distributions!

## Scope of this Repository

This repository focuses on **upstream compatibility patches** and **distribution-level tooling** to ensure HPLIP builds and runs on modern Linux systems (e.g., GCC 14/15+, C23 standard compliance, Python 3.12/3.14+).

### Key Guidelines

1. **Patch Minimality**: Changes should be surgical. Preserve original HPLIP architecture and code style where possible.
2. **No Proprietary Blobs**: Do **NOT** submit pull requests containing HP proprietary firmware, proprietary binary plugins, or precompiled `.so` files.
3. **Reproducibility**: When submitting patches for compiler or runtime errors:
   - State the exact compiler version (`gcc --version`) and Python version (`python3 --version`).
   - Include the error log snippet.
   - Verify that `install.sh` runs cleanly.

## Development Workflow

1. Fork the repository on GitHub.
2. Clone your fork locally:
   ```bash
   git clone https://github.com/<your-username>/hplip-ubuntu-patch.git
   cd hplip-ubuntu-patch
   ```
3. Test any modifications to `install.sh` or the `.patch` file.
4. Verify dry-run patch application:
   ```bash
   patch -p1 --dry-run < hplip-3.26.6-ubuntu-26.04.patch
   ```
5. Submit a Pull Request with a clear description of the issue resolved.
