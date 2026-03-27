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

        let subDeviceList: [[String: Any]] = subDevices.map { device in
            var entry: [String: Any] = [kAudioSubDeviceUIDKey as String: device.uid]
            if device.uid != masterUID {
                // Enable drift compensation for non-master devices (important for AirPlay)
                entry[kAudioSubDeviceDriftCompensationKey as String] = true
            }
            return entry
        }

        let description: [String: Any] = [
            kAudioAggregateDeviceNameKey as String:           "AudioMirror Output",
            kAudioAggregateDeviceUIDKey as String:            "com.audiomirror.multiout.\(UUID().uuidString)",
            kAudioAggregateDeviceSubDeviceListKey as String:  subDeviceList,
            kAudioAggregateDeviceMasterSubDeviceKey as String: masterUID,
            // isStacked = 1 → Multi-Output (mirror) mode, not interleaved aggregate
            kAudioAggregateDeviceIsStackedKey as String:      1,
            // isPrivate = 1 → invisible in Audio MIDI Setup and other apps
            kAudioAggregateDeviceIsPrivateKey as String:      1,
        ]

        let pluginID = try fetchHALPluginID()

        var address = AudioObjectPropertyAddress(
            mSelector: kAudioPlugInCreateAggregateDevice,
            mScope:    kAudioObjectPropertyScopeGlobal,
            mElement:  kAudioObjectPropertyElementMain
        )

        var newDeviceID = AudioDeviceID(kAudioObjectUnknown)
        var outSize = UInt32(MemoryLayout<AudioDeviceID>.size)

        // The qualifier IS a CFDictionaryRef — pass a pointer to the reference (8 bytes on 64-bit)
        let cfDescription: CFDictionary = description as CFDictionary
        let err = withUnsafePointer(to: cfDescription) { qualPtr in
            AudioObjectGetPropertyData(
                pluginID,
                &address,
                UInt32(MemoryLayout<CFDictionary>.size),
                qualPtr,
                &outSize,
                &newDeviceID
            )
        }

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
