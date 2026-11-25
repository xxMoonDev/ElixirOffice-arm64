#!/bin/bash
# Repack the official ElixirOffice x64 .deb as arm64 by swapping the Electron runtime.
set -euo pipefail
VER=0.9.4
ELECTRON=44.11.5
W=~/eo-arm64
cd "$W"

# 1. Electron linux-arm64, verified against Electron's published SHASUMS256
mkdir -p dl
cd dl
Z=electron-v$ELECTRON-linux-arm64.zip
[ -f "$Z" ] || curl -sSLf -o "$Z" "https://github.com/electron/electron/releases/download/v$ELECTRON/$Z"
curl -sSLf -o SHASUMS256.txt "https://github.com/electron/electron/releases/download/v$ELECTRON/SHASUMS256.txt"
grep " \*\?$Z\$" SHASUMS256.txt | sed 's/ \*/  /' | sha256sum -c -
rm -rf electron-arm64 && mkdir electron-arm64 && cd electron-arm64 && unzip -q "../$Z" && cd "$W"

# 2. Build the arm64 tree: x64 package minus Electron runtime + arm64 runtime
rm -rf arm64 && cp -a x64 arm64
A=arm64/opt/ElixirOffice
E=dl/electron-arm64
for f in chrome-sandbox chrome_crashpad_handler libffmpeg.so libvk_swiftshader.so libvulkan.so.1 \
         icudtl.dat chrome_100_percent.pak chrome_200_percent.pak resources.pak \
         snapshot_blob.bin v8_context_snapshot.bin vk_swiftshader_icd.json LICENSES.chromium.html; do
  [ -e "$E/$f" ] || { echo "missing in arm64 electron: $f"; exit 1; }
  cp -f "$E/$f" "$A/$f"
done
cp -f "$E/electron" "$A/elixiroffice"
rm -rf "$A/locales" && cp -a "$E/locales" "$A/locales"
# anything else in the arm64 zip we did not place (besides default_app resources) -> report
for f in $(ls "$E"); do case $f in resources|electron|version|LICENSE|LICENSES.chromium.html) ;; *) [ -e "$A/$f" ] || echo "NOTE: not copied: $f";; esac; done
chmod 755 "$A/elixiroffice" "$A/chrome_crashpad_handler"; chmod 4755 "$A/chrome-sandbox"

# 3. Fuses must match the shipped x64 binary
python3 - "$W/x64/opt/ElixirOffice/elixiroffice" "$A/elixiroffice" <<'PY'
import sys
S=b"dL7pKGdnNz796PbbjQWNKmHXBZaB9tsX"
def fuses(p):
    d=open(p,'rb').read(); i=d.find(S); assert i>0, p
    i+=len(S); n=d[i+1]; return d[i+2:i+2+n]
a,b=fuses(sys.argv[1]),fuses(sys.argv[2])
print("fuses x64  :",a); print("fuses arm64:",b)
sys.exit(0 if a==b else 3)
PY

# 4. Control file
sed -i 's/^Architecture: amd64$/Architecture: arm64/' arm64/DEBIAN/control
grep -q '^Architecture: arm64$' arm64/DEBIAN/control
# Installed-Size (KiB)
SZ=$(du -sk --exclude=DEBIAN arm64 | cut -f1)
sed -i "s/^Installed-Size: .*/Installed-Size: $SZ/" arm64/DEBIAN/control
# md5sums if present
if [ -f arm64/DEBIAN/md5sums ]; then (cd arm64 && find . -path ./DEBIAN -prune -o -type f -printf '%P\0' | sort -z | xargs -0 md5sum > DEBIAN/md5sums); fi

mkdir -p out
OUT=out/ElixirOffice-$VER-linux-arm64.deb
dpkg-deb --root-owner-group -Zxz -z6 -b arm64 "$OUT" >/dev/null
dpkg-deb -I "$OUT" | grep -E 'Package|Version|Architecture|Installed-Size'
ls -la "$OUT"; sha256sum "$OUT"

# 5. Sanity: every ELF in the package is aarch64
echo "ELF check:"; find arm64/opt -type f -exec file {} + | grep ELF | grep -v aarch64 && { echo "non-arm64 ELF found"; exit 4; } || echo "all ELF files are aarch64"
