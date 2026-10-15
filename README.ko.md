# android-mac-audio

안드로이드 폰의 소리를 Wi-Fi로 Mac 스피커에서 듣고, Mac에 말을 거는 동안에는 폰 재생이 저절로 멈추게 합니다.

[English README](README.md)

- **Wi-Fi로 소리 전송.** 케이블, 블루투스, 화면 미러링이 필요 없습니다. [scrcpy](https://github.com/Genymobile/scrcpy)를 기반으로 합니다.
- **말하는 동안 일시정지.** Mac에서 어떤 앱이든 마이크를 쓰기 시작하면(Claude·ChatGPT 음성 입력, 받아쓰기, 통화) **폰의 플레이어 자체**를 일시정지합니다. 듣지 못하는 사이에 노래가 넘어가지 않습니다. 마이크 사용이 끝나면 멈춘 위치부터 이어서 재생합니다. 이 기능이 멈춘 경우에만 다시 재생합니다.
- **더블클릭으로 실행.** 작은 Mac 앱으로 켜고, 뜨는 창을 닫으면 꺼집니다.
- **안내형 페어링.** 폰에 뜬 6자리 코드만 입력하면 나머지는 네트워크에서 자동으로 찾습니다.

## 동작 방식

```
안드로이드 폰 ── Wi-Fi (무선 디버깅) ──▶ scrcpy (소리만) ──▶ Mac 스피커
      ▲
      └── 일시정지/재생 미디어 키 (adb) ◀── mic-watch: 지금 마이크를 쓰는 Mac 앱이 있는가?
```

- `scrcpy --no-video --no-control`이 폰의 소리 출력을 받아 Mac에서 재생합니다. 실행되는 동안 폰 스피커에서는 소리가 나지 않습니다.
- `mic-watch`(작은 Swift 프로그램)가 1초에 네 번, 마이크 입력을 받는 프로세스가 있는지 Core Audio에 묻습니다. 입력만 보기 때문에 AirPods로 소리를 듣는 것은 마이크 사용으로 치지 않습니다.
- 마이크 사용이 시작되고 폰이 재생 중이면 폰에 일시정지 키를 보냅니다. 마이크가 1초 동안 쉬면 재생 키를 보냅니다.

## 필요한 환경

- macOS 14.2 이상 (앱별 마이크 사용 정보), Apple Silicon 또는 Intel
- 안드로이드 11 이상 (무선 디버깅과 소리 전송)
- [Homebrew](https://brew.sh)와 Xcode Command Line Tools (`xcode-select --install`)
- 폰과 Mac이 같은 Wi-Fi에 연결되어 있을 것

## 설치

```bash
git clone https://github.com/DeaKipodol/android-mac-audio.git
cd android-mac-audio
./install.sh
```

설치 스크립트는 `scrcpy`와 `adb`가 없으면 Homebrew로 설치하고, `mic-watch`를 빌드하고, `android-mac-audio`를 `~/.local/bin`에 넣습니다. 설치 위치는 `PREFIX`로 바꿀 수 있습니다.

## 폰 등록 (처음 한 번)

```bash
android-mac-audio setup
```

1. 폰에서 **설정 > 휴대전화 정보 > 소프트웨어 정보**로 가서 **빌드번호**를 7번 눌러 개발자 옵션을 켭니다.
2. **설정 > 개발자 옵션 > 무선 디버깅**을 켭니다.
3. 무선 디버깅에서 **페어링 코드로 기기 페어링**을 누르고 그 창을 띄워 둡니다.
4. 터미널에 6자리 코드를 입력합니다.

`setup`은 폰의 페어링 주소를 네트워크에서 찾아 페어링하고, 폰을 설정 파일에 등록한 뒤, 바탕화면에 **Android Mac Audio** 앱을 만들지 묻습니다.

## 사용법

| 하려는 일 | 방법 |
|---|---|
| 켜기 | **Android Mac Audio** 더블클릭, 또는 `android-mac-audio` |
| 끄기 | 작은 **android-mac-audio** 창 닫기, 또는 `android-mac-audio stop` |
| 상태 보기 | `android-mac-audio status` |
| 마이크 쓰는 앱 보기 | `android-mac-audio mic-list` |
| 실행 앱 다시 만들기 | `android-mac-audio app ~/Desktop` |

페어링은 한 번 하면 기억됩니다. 다만 **무선 디버깅은 폰을 재시작하거나 Wi-Fi가 끊기면 저절로 꺼지므로**, 켜기 전에 다시 켜 주세요. **개발자 옵션 > 빠른 설정 개발자 타일 > 무선 디버깅**을 켜 두면 빠른 설정 패널에서 바로 켤 수 있습니다.

## 설정

`~/.config/android-mac-audio/config` (`setup`이 만듭니다):

| 항목 | 기본값 | 뜻 |
|---|---|---|
| `AUDIO_BUFFER_MS` | `400` | 재생 전에 미리 모아 두는 소리의 양. 소리가 끊기면 늘립니다. 지연만 늘어나며, 음악 감상에는 문제가 없습니다. |
| `AUDIO_OUTPUT_BUFFER_MS` | `10` | Mac 스피커로 내보내기 직전의 버퍼 |
| `PAUSE_ON_MIC` | `1` | `0`이면 말할 때 일시정지 기능을 끕니다 |
| `MIC_IGNORE` | `com.apple.CoreSpeech` | 일시정지를 일으키지 않을 앱. 번들 ID(앞부분 일치) 또는 프로세스 이름을 쉼표로 구분합니다. `com.apple.CoreSpeech`는 Siri 호출을 기다리느라 항상 마이크를 씁니다. |
| `MIC_ONLY` | *(비어 있음)* | 비어 있으면 모든 앱에 반응합니다. Claude에만 반응하려면 `com.anthropic.claudefordesktop,claude` |
| `MIC_RELEASE_MS` | `1000` | 마이크가 이 시간 동안 쉬어야 이어서 재생합니다 |

## 문제 해결

**같은 Wi-Fi인데 폰에 접속이 안 됩니다 ("No route to host", 또는 `adb pair`가 "protocol fault"로 실패).**
macOS는 **로컬 네트워크** 권한이 없는 앱이 같은 네트워크의 기기에 접속하는 것을 막습니다. 오류 메시지에는 이 이유가 나오지 않습니다. **시스템 설정 > 개인정보 보호 및 보안 > 로컬 네트워크**에서 쓰고 있는 터미널 앱(터미널, iTerm 등) 또는 **Android Mac Audio**를 켜세요. `android-mac-audio`는 이 상황을 감지하면 그 설정 화면을 열어 줍니다.

**"폰을 찾지 못했습니다".** 폰의 무선 디버깅이 꺼졌을 가능성이 큽니다. 다시 켜 주세요.

**소리가 끊깁니다.** `AUDIO_BUFFER_MS`를 예를 들어 `800`으로 늘리세요.

**특정 앱의 소리만 안 나옵니다.** 일부 앱은 소리 캡처를 막아 두었고, 그런 앱의 소리는 안드로이드가 전송하지 않습니다.

**음악이 계속 멈춰 있습니다.** 어떤 앱이 마이크를 계속 쓰고 있는 것입니다. `android-mac-audio mic-list`로 확인해서 `MIC_IGNORE`에 추가하세요.

기록: `~/Library/Logs/android-mac-audio/` (`scrcpy.log`, `mic.log`)

## 보안

무선 디버깅을 켜 두면 페어링한 컴퓨터가 네트워크를 통해 폰에 adb로 전부 접근할 수 있습니다. 쓰지 않을 때는 꺼 두고, 더 쓰지 않는 컴퓨터는 **무선 디버깅 > 페어링된 기기**에서 지우세요.

## 제거

```bash
./uninstall.sh
```

## 출처

소리 전송은 Genymobile의 [scrcpy](https://github.com/Genymobile/scrcpy)(Apache 2.0 라이선스)가 합니다. 이 프로젝트는 scrcpy 코드를 포함하지 않고, 설치된 scrcpy를 실행합니다. Genymobile, Google, Samsung과 관련이 없습니다. Android는 Google LLC의 상표입니다.

## 라이선스

[MIT](LICENSE)
