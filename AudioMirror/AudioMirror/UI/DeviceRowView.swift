import SwiftUI

struct DeviceRowView: View {
    let device: AudioDevice
    let isSelected: Bool
    let isLocked: Bool   // true while mirroring is active (no changes allowed)
    let onToggle: (Bool) -> Void

    var body: some View {
        Button {
            guard !isLocked else { return }
            onToggle(!isSelected)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: device.systemIconName)
                    .frame(width: 20)
                    .foregroundColor(isSelected ? .accentColor : .secondary)

                VStack(alignment: .leading, spacing: 1) {
                    Text(device.name)
                        .font(.system(size: 13))
                        .foregroundColor(isLocked && !isSelected ? .secondary : .primary)
                    if device.isAirPlay {
                        Text("AirPlay")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.accentColor)
                }
            }
            .contentShape(Rectangle())
            .padding(.vertical, 5)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .disabled(isLocked)
    }
}
