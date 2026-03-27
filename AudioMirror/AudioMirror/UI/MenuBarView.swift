import SwiftUI

struct MenuBarView: View {
    @ObservedObject var deviceManager: AudioDeviceManager
    let aggregateBuilder: AudioAggregateBuilder

    @State private var selectedUIDs: Set<String> = []
    @State private var isActive = false
    @State private var errorMessage: String?
    @AppStorage("savedSelectedUIDs") private var savedUIDsJSON = "[]"

    private var canActivate: Bool { selectedUIDs.count >= 2 }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()
            deviceList
            Divider()
            controls
        }
        .frame(width: 300)
        .onAppear {
            loadSavedSelection()
        }
        .onChange(of: selectedUIDs) { _ in
            saveSelection()
        }
    }

    // MARK: - Subviews

    private var header: some View {
        HStack {
            Image(systemName: "hifispeaker.2.fill")
                .foregroundColor(.accentColor)
            Text("AudioMirror")
                .font(.headline)
            Spacer()
            Button {
                deviceManager.refresh()
                // Re-validate selection against updated device list
                let validUIDs = Set(deviceManager.outputDevices.map(\.uid))
                selectedUIDs = selectedUIDs.intersection(validUIDs)
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.caption)
            }
            .buttonStyle(.plain)
            .help("Refresh device list")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private var deviceList: some View {
        Group {
            if deviceManager.outputDevices.isEmpty {
                Text("No output devices found.\nTry clicking refresh.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(deviceManager.outputDevices) { device in
                            DeviceRowView(
                                device: device,
                                isSelected: selectedUIDs.contains(device.uid),
                                isLocked: isActive
                            ) { selected in
                                if selected {
                                    selectedUIDs.insert(device.uid)
                                } else {
                                    selectedUIDs.remove(device.uid)
                                }
                            }
                        }
                        if deviceManager.outputDevices.contains(where: \.isAirPlay) == false {
                            airPlayHint
                        }
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                }
                .frame(maxHeight: 240)
            }
        }
    }

    private var airPlayHint: some View {
        HStack(alignment: .top, spacing: 6) {
            Image(systemName: "info.circle")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 1)
            Text("AirPlay devices appear here once enabled in Control Center → Sound.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.top, 4)
    }

    private var controls: some View {
        VStack(spacing: 8) {
            if let err = errorMessage {
                Text(err)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack {
                Text(statusText)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Toggle("Mirror Audio", isOn: Binding(
                    get: { isActive },
                    set: { newVal in
                        if newVal { activateMirroring() }
                        else      { deactivateMirroring() }
                    }
                ))
                .toggleStyle(.switch)
                .disabled(!canActivate && !isActive)
                .help(canActivate || isActive ? "" : "Select at least 2 devices first")
            }

            HStack {
                Spacer()
                Button("Quit") {
                    deactivateMirroring()
                    NSApp.terminate(nil)
                }
                .buttonStyle(.plain)
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private var statusText: String {
        if isActive {
            return "Mirroring to \(selectedUIDs.count) devices"
        } else if selectedUIDs.count == 1 {
            return "Select 1 more device"
        } else {
            return "\(selectedUIDs.count) device\(selectedUIDs.count == 1 ? "" : "s") selected"
        }
    }

    // MARK: - Activate / Deactivate

    private func activateMirroring() {
        guard canActivate else {
            errorMessage = AudioMirrorError.needsAtLeastTwo.localizedDescription
            return
        }
        errorMessage = nil

        // Save the current default so we can restore it later
        UserPreferences.captureCurrentDefault()

        let selected = deviceManager.outputDevices.filter { selectedUIDs.contains($0.uid) }
        // Built-in output is the safest clock master; fall back to first selected device
        let master = selected.first(where: \.isBuiltIn) ?? selected[0]

        do {
            let newID = try aggregateBuilder.createMultiOutputDevice(
                subDevices: selected,
                masterUID: master.uid
            )
            try AudioDeviceManager.setDefaultOutputDevice(newID)
            AudioDeviceManager.setSystemSoundDevice(newID)
            isActive = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deactivateMirroring() {
        guard isActive else { return }

        // Restore original default output before destroying the aggregate device
        if let originalUID = UserPreferences.originalDeviceUID {
            let devices = AudioDeviceManager.fetchOutputDevices()
            if let original = devices.first(where: { $0.uid == originalUID }) {
                try? AudioDeviceManager.setDefaultOutputDevice(original.id)
                AudioDeviceManager.setSystemSoundDevice(original.id)
            }
        }

        aggregateBuilder.destroyMultiOutputDevice()
        isActive = false
        deviceManager.refresh()
    }

    // MARK: - Persistence

    private func loadSavedSelection() {
        guard let data = savedUIDsJSON.data(using: .utf8),
              let uids = try? JSONDecoder().decode([String].self, from: data) else { return }
        let validUIDs = Set(deviceManager.outputDevices.map(\.uid))
        selectedUIDs = Set(uids).intersection(validUIDs)
    }

    private func saveSelection() {
        if let data = try? JSONEncoder().encode(Array(selectedUIDs)),
           let json = String(data: data, encoding: .utf8) {
            savedUIDsJSON = json
        }
    }
}
