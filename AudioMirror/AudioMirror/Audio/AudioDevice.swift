import CoreAudio
import Foundation

// kAudioDeviceTransportTypeAirPlay may not be exported as a Swift symbol in all SDK versions.
// Raw value is the FourCC 'airp' = 0x61697270.
let kAudioTransportTypeAirPlay: UInt32 = 0x61697270

struct AudioDevice: Identifiable, Hashable {
    let id: AudioDeviceID
    let name: String
    /// Persistent UID — survives reboots. Use for storage and as the multi-output sub-device key.
    let uid: String
    let transportType: UInt32

    var isAirPlay: Bool { transportType == kAudioTransportTypeAirPlay }
    var isBuiltIn: Bool { transportType == kAudioDeviceTransportTypeBuiltIn }
    var isBluetooth: Bool {
        transportType == kAudioDeviceTransportTypeBluetooth ||
        transportType == kAudioDeviceTransportTypeBluetoothLE
    }

    var systemIconName: String {
        if isAirPlay       { return "appletv.fill" }
        if isBuiltIn       { return "speaker.wave.2.fill" }
        if isBluetooth     { return "headphones" }
        switch transportType {
        case kAudioDeviceTransportTypeUSB:         return "cable.connector"
        case kAudioDeviceTransportTypeHDMI:        return "tv"
        case kAudioDeviceTransportTypeDisplayPort: return "display"
        default:                                   return "hifispeaker.fill"
        }
    }
}

enum AudioMirrorError: LocalizedError {
    case noDevicesSelected
    case needsAtLeastTwo
    case halPluginNotFound
    case createFailed(OSStatus)
    case setDefaultFailed(OSStatus)

    var errorDescription: String? {
        switch self {
        case .noDevicesSelected:       return "No devices selected."
        case .needsAtLeastTwo:         return "Select at least 2 output devices to mirror."
        case .halPluginNotFound:       return "CoreAudio HAL plugin not found."
        case .createFailed(let s):     return "Failed to create Multi-Output Device (error \(s))."
        case .setDefaultFailed(let s): return "Failed to set default output (error \(s))."
        }
    }
}
