import Foundation

/// Stores the UID of the default output device that was active before AudioMirror took over,
/// so it can be restored when mirroring is deactivated.
enum UserPreferences {
    private static let defaults = UserDefaults.standard
    private static let originalDeviceUIDKey = "originalDeviceUID"

    static var originalDeviceUID: String? {
        get { defaults.string(forKey: originalDeviceUIDKey) }
        set { defaults.set(newValue, forKey: originalDeviceUIDKey) }
    }

    /// Call this BEFORE creating the multi-output device to save the current default.
    static func captureCurrentDefault() {
        let currentID = AudioDeviceManager.fetchDefaultOutputDeviceID()
        let devices   = AudioDeviceManager.fetchOutputDevices()
        if let current = devices.first(where: { $0.id == currentID }) {
            originalDeviceUID = current.uid
        }
    }
}
