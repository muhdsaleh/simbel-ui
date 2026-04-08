import Foundation

/// Reference-type wrapper around the active mirroring state.
/// Shared between StatusMenuController and MenuBarView so that
/// cleanup/sleep handlers can deactivate the live running state.
final class MirrorState: ObservableObject {
    @Published var isActive = false
    var deactivateHandler: (() -> Void)?

    func deactivate() {
        deactivateHandler?()
    }
}
