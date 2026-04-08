import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusMenuController: StatusMenuController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Belt-and-suspenders alongside LSUIElement in Info.plist
        NSApp.setActivationPolicy(.accessory)
        statusMenuController = StatusMenuController()
    }

    func applicationWillTerminate(_ notification: Notification) {
        statusMenuController?.cleanup()
    }
}
