import CoreAudio
import Foundation

/// Creates and destroys a CoreAudio Multi-Output Device (stacked aggregate).
/// Setting `kAudioAggregateDeviceIsStackedKey = 1` mirrors audio to all sub-devices
/// simultaneously — equivalent to what Audio MIDI Setup creates as a "Multi-Output Device".
/// App Sandbox MUST be disabled; kAudioPlugInCreateAggregateDevice silently fails in sandbox.
final class AudioAggregateBuilder {

    private(set) var multiOutputDeviceID: AudioDeviceID = kAudioObjectUnknown

    var isActive: Bool { multiOutputDeviceID != kAudioObjectUnknown }

    // MARK: - Create

    /// Creates a Multi-Output Device containing `subDevices`.
    /// The built-in output device should be the master for clock stability;
    /// AirPlay devices cannot serve as master.
    @discardableResult
    func createMultiOutputDevice(subDevices: [AudioDevice], masterUID: String) throws -> AudioDeviceID {
        guard subDevices.count >= 2 else { throw AudioMirrorError.needsAtLeastTwo }

        // Use raw string keys — avoids Swift overlay issues with `as String` casts.
        // Raw values from CoreAudio/AudioHardware.h:
        //   kAudioSubDeviceUIDKey                   = "uid"
        //   kAudioSubDeviceDriftCompensationKey      = "drift compensation"
        //   kAudioAggregateDeviceNameKey             = "name"
        //   kAudioAggregateDeviceUIDKey              = "uid"
        //   kAudioAggregateDeviceSubDeviceListKey    = "subdevices"
        //   kAudioAggregateDeviceMasterSubDeviceKey  = "master"
        //   kAudioAggregateDeviceIsStackedKey        = "stacked"   (1 = Multi-Output mirror mode)
        //   kAudioAggregateDeviceIsPrivateKey        = "private"

        let subDeviceList: [[String: Any]] = subDevices.map { device in
            var entry: [String: Any] = ["uid": device.uid]
            if device.uid != masterUID {
                entry["drift compensation"] = NSNumber(value: 1)
            }
            return entry
        }

        let description: NSDictionary = [
            "name":       "AudioMirror Output",
            "uid":        "com.audiomirror.multiout.\(UUID().uuidString)",
            "subdevices": subDeviceList,
            "master":     masterUID,
            "stacked":    NSNumber(value: 1),   // Multi-Output (mirror) mode
            "private":    NSNumber(value: 1),   // Invisible in Audio MIDI Setup
        ]

        let pluginID = try fetchHALPluginID()
        print("[AudioMirror] HAL plugin ID: \(pluginID)")
        print("[AudioMirror] Creating multi-output with \(subDevices.count) devices, master: \(masterUID)")
        print("[AudioMirror] Description: \(description)")

        var address = AudioObjectPropertyAddress(
            mSelector: kAudioPlugInCreateAggregateDevice,
            mScope:    kAudioObjectPropertyScopeGlobal,
            mElement:  kAudioObjectPropertyElementMain
        )

        var newDeviceID = AudioDeviceID(kAudioObjectUnknown)
        var outSize = UInt32(MemoryLayout<AudioDeviceID>.size)

        // CoreAudio expects: const void* → pointer to a CFDictionaryRef (an 8-byte value).
        // Using withUnsafeMutablePointer(to:) on a var ensures the reference is on the stack
        // and its address is stable for the duration of the call.
        var cfDescription: CFDictionary = description as CFDictionary
        let err = withUnsafeMutablePointer(to: &cfDescription) { qualPtr in
            AudioObjectGetPropertyData(
                pluginID,
                &address,
                UInt32(MemoryLayout<CFDictionary>.size),
                qualPtr,
                &outSize,
                &newDeviceID
            )
        }

        print("[AudioMirror] createMultiOutputDevice → err=\(err), newDeviceID=\(newDeviceID)")

        guard err == noErr, newDeviceID != kAudioObjectUnknown else {
            throw AudioMirrorError.createFailed(err)
        }

        multiOutputDeviceID = newDeviceID
        return newDeviceID
    }

    // MARK: - Destroy

    func destroyMultiOutputDevice() {
        guard multiOutputDeviceID != kAudioObjectUnknown else { return }
        guard let pluginID = try? fetchHALPluginID() else { return }

        var address = AudioObjectPropertyAddress(
            mSelector: kAudioPlugInDestroyAggregateDevice,
            mScope:    kAudioObjectPropertyScopeGlobal,
            mElement:  kAudioObjectPropertyElementMain
        )
        var deviceID = multiOutputDeviceID
        AudioObjectSetPropertyData(
            pluginID,
            &address,
            0, nil,
            UInt32(MemoryLayout<AudioDeviceID>.size),
            &deviceID
        )
        multiOutputDeviceID = kAudioObjectUnknown
    }

    // MARK: - HAL plugin lookup

    /// The CoreAudio HAL plugin (bundle ID "com.apple.audio.CoreAudio") is the object
    /// on which kAudioPlugInCreateAggregateDevice / kAudioPlugInDestroyAggregateDevice are called.
    private func fetchHALPluginID() throws -> AudioObjectID {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyPlugInList,
            mScope:    kAudioObjectPropertyScopeGlobal,
            mElement:  kAudioObjectPropertyElementMain
        )
        var dataSize: UInt32 = 0
        AudioObjectGetPropertyDataSize(
            AudioObjectID(kAudioObjectSystemObject),
            &address, 0, nil, &dataSize
        )

        let count = Int(dataSize) / MemoryLayout<AudioObjectID>.size
        var pluginIDs = [AudioObjectID](repeating: 0, count: count)
        AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address, 0, nil, &dataSize, &pluginIDs
        )

        for pid in pluginIDs {
            var bundleAddress = AudioObjectPropertyAddress(
                mSelector: kAudioPlugInPropertyBundleID,
                mScope:    kAudioObjectPropertyScopeGlobal,
                mElement:  kAudioObjectPropertyElementMain
            )
            var bundleRef: CFString? = nil
            var sz = UInt32(MemoryLayout<CFString?>.size)
            AudioObjectGetPropertyData(pid, &bundleAddress, 0, nil, &sz, &bundleRef)
            if let bundle = bundleRef as String?, bundle == "com.apple.audio.CoreAudio" {
                return pid
            }
        }
        throw AudioMirrorError.halPluginNotFound
    }
}
