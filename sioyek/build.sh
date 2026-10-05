#!/usr/bin/env bash
# Build sioyek from source and install it to ~/Applications/sioyek.app.
# Why: the Homebrew cask is disabled (fails Gatekeeper since 2026-09); a locally
# built app is not quarantined, so no Gatekeeper bypass is needed.
# Idempotent: clones or fast-forwards ~/.local/src/sioyek, rebuilds, reinstalls.
#   sioyek/build.sh            build the development branch (what upstream ships from)
#   SIOYEK_REF=v2.0.0 sioyek/build.sh   build a tag instead (v2.0.0 is Qt5-era, needs qt@5)
set -euo pipefail

SRC="${SIOYEK_SRC:-$HOME/.local/src/sioyek}"
REF="${SIOYEK_REF:-development}"
DEST="$HOME/Applications/sioyek.app"
JOBS="$(sysctl -n hw.logicalcpu)"

# Qt 6 modules the .pro asks for: core/gui/widgets/opengl/network (qtbase),
# quickwidgets (qtdeclarative), svg (qtsvg), texttospeech (qtspeech).
# Granular formulae instead of `qt`, which drags in qtwebengine and friends.
deps=(qtbase qtdeclarative qtsvg qtspeech)
missing=()
for f in "${deps[@]}"; do brew list --versions "$f" >/dev/null 2>&1 || missing+=("$f"); done
if ((${#missing[@]})); then
  echo "==> brew install ${missing[*]}"
  brew install "${missing[@]}"
fi
QTBIN="$(brew --prefix qtbase)/bin"

if [[ -d "$SRC/.git" ]]; then
  echo "==> updating $SRC ($REF)"
  git -C "$SRC" fetch --tags origin
  git -C "$SRC" checkout -q "$REF"
  # a branch fast-forwards; a tag is already exact
  git -C "$SRC" symbolic-ref -q HEAD >/dev/null && git -C "$SRC" merge -q --ff-only "origin/$REF"
else
  echo "==> cloning into $SRC"
  mkdir -p "$(dirname "$SRC")"
  git clone --branch "$REF" https://github.com/ahrm/sioyek "$SRC"
fi
git -C "$SRC" submodule update --init --recursive

cd "$SRC"
echo "==> building mupdf"
make -C mupdf HAVE_GLUT=no -j"$JOBS" >/dev/null

echo "==> building sioyek"
"$QTBIN/qmake" "CONFIG+=non_portable" pdf_viewer_build_config.pro
make -j"$JOBS"

# assemble the bundle the way upstream's build_mac.sh does
app="$SRC/sioyek.app"
res="$app/Contents/Resources"
rm -rf "$res/shaders"
cp -R pdf_viewer/shaders "$res/shaders"
cp pdf_viewer/prefs.config pdf_viewer/prefs_user.config pdf_viewer/keys.config pdf_viewer/keys_user.config tutorial.pdf "$res/"

# bundle the Qt frameworks so a later `brew upgrade` of Qt can't break the app
"$QTBIN/macdeployqt" "$app"
codesign --force --deep --sign - "$app"

echo "==> installing to $DEST"
mkdir -p "$(dirname "$DEST")"
rm -rf "$DEST"
mv "$app" "$DEST"
/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$DEST/Contents/Info.plist"
