#!/bin/zsh
# Installs android-mac-audio into $PREFIX (default: ~/.local).
#   ./install.sh               -> ~/.local/bin/android-mac-audio
#   PREFIX=/usr/local ./install.sh
emulate -L zsh
set -e

PREFIX=${PREFIX:-$HOME/.local}
REPO=${0:A:h}
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

[[ $(uname) == Darwin ]] || { print "android-mac-audio runs on macOS only." >&2; exit 1; }

# Homebrew packages: scrcpy and adb.
missing=()
(( $+commands[scrcpy] )) || missing+=scrcpy
(( $+commands[adb] )) || missing+=android-platform-tools
if (( $#missing )); then
  if ! (( $+commands[brew] )); then
    print "Homebrew is required to install scrcpy and adb: https://brew.sh" >&2
    exit 1
  fi
  print "Installing with Homebrew: ${missing[*]}"
  (( $+commands[scrcpy] )) || brew install scrcpy
  (( $+commands[adb] )) || brew install --cask android-platform-tools
fi

# Swift compiler for the microphone watcher (Xcode Command Line Tools).
if ! (( $+commands[swiftc] )); then
  print "The Swift compiler is missing. Install the Xcode Command Line Tools, then run this again:" >&2
  print "  xcode-select --install" >&2
  exit 1
fi

print "Installing to $PREFIX"
mkdir -p "$PREFIX/bin" "$PREFIX/libexec/android-mac-audio"
install -m 755 "$REPO/bin/android-mac-audio" "$PREFIX/bin/android-mac-audio"
swiftc -O -o "$PREFIX/libexec/android-mac-audio/mic-watch" "$REPO/src/mic-watch.swift"

print "Installed: $PREFIX/bin/android-mac-audio"
if [[ ":$PATH:" != *":$PREFIX/bin:"* ]]; then
  print
  print "$PREFIX/bin is not on your PATH. Add this line to ~/.zshrc:"
  print "  export PATH=\"$PREFIX/bin:\$PATH\""
fi
print
print "Next: android-mac-audio setup"
