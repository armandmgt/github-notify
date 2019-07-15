import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    struct Credentials {
        var username: String
        var accessToken: String
    }
    
    enum KeychainError: Error {
        case noPassword
        case unexpectedPasswordData
        case unhandledError(status: OSStatus)
    }

    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    var defaultItemAction: Selector?
    var settingsWindowController: SettingsWindowController?

    var github: GithubLoader?
    static let server = "github-notify"
    var credentials = Credentials(username: "", accessToken: "")
    
    var unreadCount = 0

    func applicationDidFinishLaunching(_: Notification) {
        unreadCount = 0

        initStatusItem()
        updateMenubarIcon()
        
        do {
            try loadCredentials()
        } catch KeychainError.noPassword {
            openSettings(nil)
        } catch {
            NSAlert(error: error).runModal()
        }

        // Refresh the unread notification count.
        Timer.scheduledTimer(timeInterval: 90.0,
                             target: self,
                             selector: #selector(AppDelegate.refreshNotifications),
                             userInfo: nil,
                             repeats: true)
        refreshNotifications(nil)
    }

    @IBAction func openNotificationUrl(_ sender: Any) {
        NSWorkspace.shared.open(URL(string: "https://github.com/notifications")!)
    }
    
    @IBOutlet var statusItemMenu: NSMenu!
    
    @IBAction func openSettings(_ sender: NSMenuItem?) {
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        if let windowController = storyboard.instantiateController(withIdentifier: "SettingsWindowController") as? SettingsWindowController {
            settingsWindowController = windowController
            settingsWindowController!.showWindow(self)
        }
    }
    
    func updateMenubarIcon() {
        if let button = statusItem.button {
            button.toolTip = "\(unreadCount) unread notifications."

            var icon = "MenuIconDefault"
            if unreadCount > 0 {
                icon = "MenuIconUnread"
                defaultItemAction = button.action
                button.target = self
                button.action = #selector(openNotificationUrl(_:))
                let options: NSEvent.EventTypeMask = [.leftMouseUp, .rightMouseUp]
                button.sendAction(on: options)
            } else if defaultItemAction != nil {
                button.action = defaultItemAction
            }
            button.image = NSImage(named: icon)
        }
    }

    @IBAction func refreshNotifications(_ sender: Any?) {
        github?.refreshNotifications { notifications, error in
            if let error = error as? URLError {
                // Would be too noisy if we alerted every time we closed the lid.
                print("Not connected to internet: \(error)")
                return
            } else if let error = error {
                NSAlert(error: error).runModal()
                return
            }

            self.unreadCount = notifications!.count
            self.updateMenubarIcon()
        }
    }
    
    func loadCredentials() throws {
        let query: [String: Any] = [kSecClass as String: kSecClassInternetPassword,
                                    kSecAttrServer as String: AppDelegate.server,
                                    kSecMatchLimit as String: kSecMatchLimitOne,
                                    kSecReturnAttributes as String: true,
                                    kSecReturnData as String: true]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status != errSecItemNotFound else { throw KeychainError.noPassword }
        guard status == errSecSuccess else { throw KeychainError.unhandledError(status: status) }
        guard let existingItem = item as? [String : Any],
            let passwordData = existingItem[kSecValueData as String] as? Data,
            let accessToken = String(data: passwordData, encoding: String.Encoding.utf8),
            let account = existingItem[kSecAttrAccount as String] as? String
            else {
                throw KeychainError.unexpectedPasswordData
        }
        credentials = Credentials(username: account, accessToken: accessToken)

        github = GithubLoader(username: credentials.username, accessToken: credentials.accessToken)
    }
    
    func storeCredentials() throws {
        let query: [String: Any] = [kSecClass as String: kSecClassInternetPassword,
                                    kSecAttrAccount as String: credentials.username,
                                    kSecAttrServer as String: AppDelegate.server,
                                    kSecValueData as String: credentials.accessToken]
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else { throw KeychainError.unhandledError(status: status) }

        try loadCredentials()
    }
    
    private func initStatusItem() {
        statusItem.title = "GithubNotify"
        statusItem.menu = self.statusItemMenu
    }
}
