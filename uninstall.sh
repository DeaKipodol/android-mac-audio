#!/bin/zsh
# Removes android-mac-audio. Homebrew packages (scrcpy, adb) are left in place.
emulate -L zsh

PREFIX=${PREFIX:-$HOME/.local}
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/android-mac-audio"

[[ -x $PREFIX/bin/android-mac-audio ]] && "$PREFIX/bin/android-mac-audio" stop >/dev/null 2>&1
rm -f "$PREFIX/bin/android-mac-audio"
rm -rf "$PREFIX/libexec/android-mac-audio"
rm -rf "$HOME/Applications/Android Mac Audio.app" "$HOME/Desktop/Android Mac Audio.app"
rm -rf "$HOME/Library/Logs/android-mac-audio"
print "Removed android-mac-audio from $PREFIX."

print -n "Also delete your settings in $CONFIG_DIR? [y/N] "
read -r answer
if [[ $answer == [Yy]* ]]; then
  rm -rf "$CONFIG_DIR"
  print "Settings deleted."
fi
print "To forget this Mac on the phone: Developer options > Wireless debugging > Paired devices."
