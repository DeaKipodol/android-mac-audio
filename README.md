# android-mac-audio

Listen to your Android phone's audio on your Mac's speakers over Wi-Fi — and have the phone pause by itself while you talk to your Mac.

[한국어 README](README.ko.md)

- **Audio over Wi-Fi.** No cable, no Bluetooth, no screen mirroring. Built on [scrcpy](https://github.com/Genymobile/scrcpy).
- **Pauses while you speak.** When any Mac app starts using the microphone (voice input in Claude or ChatGPT, dictation, a call), the player **on the phone** is paused, so the song doesn't play on while you aren't listening. When the microphone is free again, playback resumes where it stopped. It only resumes what it paused.
- **One-click launcher.** A small Mac app starts it; closing its window stops it.
- **Guided pairing.** Type the 6-digit code from your phone; the rest is found on the network automatically.

## How it works

```
Android phone ── Wi-Fi (wireless debugging) ──▶ scrcpy, audio only ──▶ Mac speakers
      ▲
      └── pause / play media key (adb) ◀── mic-watch: which Mac apps are using the microphone?
```

- `scrcpy --no-video --no-control` captures the phone's audio output and plays it on the Mac. While it runs, the phone's own speaker stays silent.
- `mic-watch` (a small Swift program) asks Core Audio which processes are receiving microphone input, four times a second. It reads input only, so audio playing to AirPods does not count as microphone use.
- When an app starts using the microphone and the phone is playing, a pause key is sent to the phone. After the microphone has been idle for 1 second, a play key is sent.

## Requirements

- macOS 14.2 or later (per-app microphone information), Apple Silicon or Intel
- Android 11 or later (wireless debugging and audio forwarding)
- [Homebrew](https://brew.sh) and the Xcode Command Line Tools (`xcode-select --install`)
- The phone and the Mac on the same Wi-Fi network

## Install

```bash
git clone https://github.com/DeaKipodol/android-mac-audio.git
cd android-mac-audio
./install.sh
```

The installer installs `scrcpy` and `adb` with Homebrew if they are missing, builds `mic-watch`, and puts `android-mac-audio` in `~/.local/bin` (set `PREFIX` to change this).

## Set up your phone (once)

```bash
android-mac-audio setup
```

1. On the phone: **Settings > About phone > Software information**, tap **Build number** 7 times to enable Developer options.
2. **Settings > Developer options > Wireless debugging**: turn it on.
3. In Wireless debugging, tap **Pair device with pairing code** and keep that screen open.
4. Type the 6-digit code into the terminal.

`setup` finds the phone's pairing address on the network, pairs, registers the phone in your settings file, and offers to put an **Android Mac Audio** launcher on your Desktop.

## Use

| To | Do |
|---|---|
| Start | Double-click **Android Mac Audio**, or run `android-mac-audio` |
| Stop | Close the small **android-mac-audio** window, or run `android-mac-audio stop` |
| Check | `android-mac-audio status` |
| See which apps use the mic | `android-mac-audio mic-list` |
| Make the launcher again | `android-mac-audio app ~/Desktop` |

Pairing is remembered. **Wireless debugging, however, turns itself off** when the phone restarts or leaves the Wi-Fi network. Turn it back on before starting. Tip: **Developer options > Quick settings developer tiles > Wireless debugging** adds a toggle to the quick settings panel.

## Settings

`~/.config/android-mac-audio/config` (written by `setup`):

| Key | Default | Meaning |
|---|---|---|
| `AUDIO_BUFFER_MS` | `400` | Audio buffered before playback. Increase if the sound stutters. It only adds delay, which doesn't matter for music. |
| `AUDIO_OUTPUT_BUFFER_MS` | `10` | Buffer right before the Mac's speakers |
| `PAUSE_ON_MIC` | `1` | `0` turns pause-on-mic off |
| `MIC_IGNORE` | `com.apple.CoreSpeech` | Apps that never trigger a pause. Comma-separated bundle IDs (prefix match) or process names. `com.apple.CoreSpeech` listens for "Hey Siri" all the time. |
| `MIC_ONLY` | *(empty)* | Empty: any app triggers a pause. For Claude only: `com.anthropic.claudefordesktop,claude` |
| `MIC_RELEASE_MS` | `1000` | How long the microphone must be idle before playback resumes |

## Troubleshooting

**The phone is on the same Wi-Fi but cannot be reached ("No route to host", or `adb pair` fails with "protocol fault").**
macOS blocks apps without the **Local Network** permission from reaching devices on your network, and the error doesn't say so. Open **System Settings > Privacy & Security > Local Network** and turn on your terminal app (Terminal, iTerm, …) or **Android Mac Audio**. `android-mac-audio` detects this case and opens that page for you.

**"Phone not found".** Wireless debugging is probably off; turn it on again on the phone.

**The sound stutters.** Raise `AUDIO_BUFFER_MS`, for example to `800`.

**No sound from one app.** Some apps forbid audio capture; Android then doesn't forward their sound.

**Music stays paused.** Some app keeps the microphone open. Run `android-mac-audio mic-list` and add it to `MIC_IGNORE`.

Logs: `~/Library/Logs/android-mac-audio/` (`scrcpy.log`, `mic.log`).

## Security

Wireless debugging gives full adb access to the computers you paired, over your network. Turn it off when you don't need it, and remove old computers under **Wireless debugging > Paired devices**.

## Uninstall

```bash
./uninstall.sh
```

## Credits

Audio forwarding is done by [scrcpy](https://github.com/Genymobile/scrcpy) by Genymobile, licensed under Apache 2.0. This project does not include scrcpy's code; it runs the scrcpy you installed. It is not affiliated with Genymobile, Google or Samsung. Android is a trademark of Google LLC.

## License

[MIT](LICENSE)
