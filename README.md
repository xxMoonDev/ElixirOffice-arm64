# ElixirOffice for Linux arm64

[ElixirOffice](https://github.com/leag1234/elixiroffice) is an offline office suite (documents, spreadsheets, presentations) built on Electron. It publishes Linux builds for x64 only. This repository has a script that turns the official **amd64 `.deb` into an arm64 `.deb`**, for example for Ubuntu on a phone ([PhoneDesktop](https://github.com/xxMoonDev/PhoneDesktop)) or an arm64 laptop or single-board computer.

The ready-made package is on the [Releases](https://github.com/xxMoonDev/ElixirOffice-arm64/releases) page:

| File | Version | SHA-256 |
|---|---|---|
| `ElixirOffice-0.9.4-linux-arm64.deb` | ElixirOffice 0.9.4, Electron 44.11.5 | `12dd059fe68932122c071843e9f91c2b18b2d99aa2068edac8be09452beda55f` |

```
sudo apt install ./ElixirOffice-0.9.4-linux-arm64.deb
```

## How it works

ElixirOffice's own code is JavaScript and WebAssembly (`app.asar` has no native modules), so only the Electron runtime is tied to x64. The script:

1. Downloads Electron's official linux-arm64 build and checks it against Electron's published `SHASUMS256.txt`.
2. Copies the x64 package tree and swaps every Electron runtime file (the `elixiroffice` binary, `chrome-sandbox`, `libffmpeg.so`, the `.pak` files, `locales\` and so on) for the arm64 one.
3. Checks that the Electron **fuses** of the arm64 binary match the shipped x64 binary, so the security settings stay the same.
4. Sets `Architecture: arm64`, the installed size and `md5sums`, and builds the `.deb`.
5. Checks that every ELF file in the package is aarch64.

## Building it yourself

On a Linux PC (x64 or arm64) with `curl`, `unzip`, `python3`, `file` and `dpkg-deb`:

```
mkdir -p ~/eo-arm64 && cd ~/eo-arm64
curl -LO https://github.com/leag1234/elixiroffice/releases/download/v0.9.4/ElixirOffice-0.9.4-linux-amd64.deb
dpkg-deb -R ElixirOffice-0.9.4-linux-amd64.deb x64
bash /path/to/repack-arm64.sh
```

The package ends up in `~/eo-arm64/out/`. For another release, change `VER` and `ELECTRON` at the top of the script. The matching Electron version is in ElixirOffice's `desktop/package.json`.

## Notes

- **Updates:** ElixirOffice's built-in updater only offers x64 builds, so it doesn't update this package. Install a newer repack instead.
- **Tested** with 0.9.4 on Ubuntu 24.04 in a chroot on a Snapdragon 8+ Gen 1 phone. It runs with Chromium's normal sandbox and no extra flags. Under proot you may need `--no-sandbox`. Without OpenGL ES 3 the first GPU process fails and Chromium falls back to software rendering by itself.

## Credits

- [ElixirOffice](https://github.com/leag1234/elixiroffice) by its contributors (AGPL-3.0). The repacked package contains ElixirOffice unchanged apart from the runtime. Its source code is in the ElixirOffice repository.
- [Electron](https://github.com/electron/electron) (MIT) and [Chromium](https://www.chromium.org/) (BSD-3-Clause and others; see `LICENSES.chromium.html` in the package).

This project isn't affiliated with ElixirOffice.

## License

The repack script is Copyright 2026 xxMoonDev, licensed under the [Apache License 2.0](LICENSE). The package it builds is ElixirOffice, under ElixirOffice's own license (AGPL-3.0).
