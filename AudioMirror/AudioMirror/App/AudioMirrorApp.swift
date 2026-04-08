import SwiftUI

@main
struct AudioMirrorApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // All UI is in the menu bar popover managed by AppDelegate/StatusMenuController.
        // A Settings scene is required to satisfy SwiftUI's App protocol on macOS.
        Settings { EmptyView() }
    }
}
