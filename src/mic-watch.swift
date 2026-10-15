// mic-watch — reports when Mac apps start and stop using the microphone.
//
//   mic-watch --pid <PID> [--ignore a,b] [--only x,y] [--release-ms 1000]
//       Prints "on <apps>" when an app starts using the mic and "off" once no app has used it
//       for --release-ms. Exits when process <PID> (scrcpy) exits.
//   mic-watch --list [--ignore a,b] [--only x,y]
//       Prints the apps using the mic right now and exits.
//
// --ignore / --only take comma-separated bundle IDs (prefix match) or process names.
// Uses the per-process Core Audio API (macOS 14.2+), so it sees microphone input only,
// even on devices that also play audio (e.g. AirPods).
import CoreAudio
import Darwin
import Foundation

func address(_ selector: AudioObjectPropertySelector) -> AudioObjectPropertyAddress {
    AudioObjectPropertyAddress(mSelector: selector,
                               mScope: kAudioObjectPropertyScopeGlobal,
                               mElement: kAudioObjectPropertyElementMain)
}

func u32Property(_ object: AudioObjectID, _ selector: AudioObjectPropertySelector) -> UInt32? {
    var addr = address(selector)
    var value: UInt32 = 0
    var size = UInt32(MemoryLayout<UInt32>.size)
    return AudioObjectGetPropertyData(object, &addr, 0, nil, &size, &value) == noErr ? value : nil
}

func bundleID(_ object: AudioObjectID) -> String {
    var addr = address(kAudioProcessPropertyBundleID)
    var value: Unmanaged<CFString>?
    var size = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
    guard AudioObjectGetPropertyData(object, &addr, 0, nil, &size, &value) == noErr,
          let string = value?.takeRetainedValue() else { return "" }
    return string as String
}

func processName(_ pid: Int32) -> String {
    var buffer = [CChar](repeating: 0, count: 4096)  // PROC_PIDPATHINFO_MAXSIZE
    guard proc_pidpath(pid, &buffer, UInt32(buffer.count)) > 0 else { return "pid\(pid)" }
    return URL(fileURLWithPath: String(cString: buffer)).lastPathComponent
}

struct MicUser {
    let pid: Int32
    let bundle: String
    let name: String
    var label: String { bundle.isEmpty ? name : bundle }
    func matches(_ patterns: [String]) -> Bool {
        patterns.contains { (!bundle.isEmpty && bundle.hasPrefix($0)) || name == $0 }
    }
}

func micUsers() -> [MicUser] {
    let system = AudioObjectID(kAudioObjectSystemObject)
    var addr = address(kAudioHardwarePropertyProcessObjectList)
    var size: UInt32 = 0
    guard AudioObjectGetPropertyDataSize(system, &addr, 0, nil, &size) == noErr, size > 0 else { return [] }
    var ids = [AudioObjectID](repeating: 0, count: Int(size) / MemoryLayout<AudioObjectID>.size)
    guard AudioObjectGetPropertyData(system, &addr, 0, nil, &size, &ids) == noErr else { return [] }
    return ids.compactMap { id in
        guard u32Property(id, kAudioProcessPropertyIsRunningInput) == 1 else { return nil }
        let pid = Int32(bitPattern: u32Property(id, kAudioProcessPropertyPID) ?? 0)
        return MicUser(pid: pid, bundle: bundleID(id), name: processName(pid))
    }
}

func fail(_ message: String) -> Never {
    FileHandle.standardError.write((message + "\n").data(using: .utf8)!)
    exit(64)
}

func list(_ value: String?) -> [String] {
    (value ?? "").split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
}

var options: [String: String] = [:]
var listMode = false
var args = CommandLine.arguments.dropFirst().makeIterator()
while let arg = args.next() {
    switch arg {
    case "--list": listMode = true
    case "--pid", "--ignore", "--only", "--release-ms":
        guard let value = args.next() else { fail("missing value for \(arg)") }
        options[arg] = value
    default: fail("unknown option: \(arg)")
    }
}
let ignore = list(options["--ignore"])
let only = list(options["--only"])

func counted(_ user: MicUser) -> Bool {
    !user.matches(ignore) && (only.isEmpty || user.matches(only))
}

if listMode {
    let users = micUsers()
    if users.isEmpty { print("(no app is using the microphone)") }
    for user in users {
        let note = counted(user) ? "" : "  [ignored]"
        print("\(user.pid)\t\(user.name)\t\(user.bundle.isEmpty ? "-" : user.bundle)\(note)")
    }
    exit(0)
}

guard let pidText = options["--pid"], let watchPID = Int32(pidText) else { fail("usage: mic-watch --pid <PID> | --list") }
let interval: useconds_t = 250_000
let releaseTicks = max(1, (Int(options["--release-ms"] ?? "") ?? 1000) / 250)
setvbuf(stdout, nil, _IOLBF, 0)

var micOn = false
var idleTicks = 0
while kill(watchPID, 0) == 0 {
    let users = micUsers().filter(counted)
    if !users.isEmpty {
        idleTicks = 0
        if !micOn {
            micOn = true
            print("on " + users.map(\.label).joined(separator: ","))
        }
    } else if micOn {
        idleTicks += 1
        if idleTicks >= releaseTicks {
            micOn = false
            idleTicks = 0
            print("off")
        }
    }
    usleep(interval)
}
