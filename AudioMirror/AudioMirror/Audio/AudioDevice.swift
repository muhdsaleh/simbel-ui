import CoreAudio
import Foundation

// CoreAudio transport type constants — using raw FourCC values to avoid
// Swift overlay export issues with C macros / less common constants.
private let kTransportAirPlay:     UInt32 = 0x61697270  // 'airp'
private let kTransportBuiltIn:     UInt32 = 0x626C746E  // 'bltn'
private let kTransportBluetooth:   UInt32 = 0x626C7565  // 'blue'
private let kTransportBluetoothLE: UInt32 = 0x626C6561  // 'blea'
private let kTransportUSB:         UInt32 = 0x20757362  // ' usb'
private let kTransportHDMI:        UInt32 = 0x68646D69  // 'hdmi'
private let kTransportDisplayPort: UInt32 = 0x64707274  // 'dprt'

struct AudioDevice: Identifiable, Hashable {
    let id: AudioDeviceID
    let name: String
    /// Persistent UID — survives reboots. Use for storage and as the multi-output sub-device key.
    let uid: String
    let transportType: UInt32

    var isAirPlay: Bool  { transportType == kTransportAirPlay }
    var isBuiltIn: Bool  { transportType == kTransportBuiltIn }
    var isBluetooth: Bool {
        transportType == kTransportBluetooth || transportType == kTransportBluetoothLE
    }

    var systemIconName: String {
        if isAirPlay   { return "appletv.fill" }
        if isBuiltIn   { return "speaker.wave.2.fill" }
        if isBluetooth { return "headphones" }
        switch transportType {
        case kTransportUSB:         return "cable.connector"
        case kTransportHDMI:        return "tv"
        case kTransportDisplayPort: return "display"
        default:                    return "hifispeaker.fill"
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
