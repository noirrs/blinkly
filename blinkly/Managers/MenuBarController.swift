import AppKit
import SwiftUI
import Combine

class MenuBarController: NSObject, ObservableObject {
    private var statusItem: NSStatusItem?
    private var timerManager: TimerManager?
    private var reminderManager: ReminderManager?
    private var cancellables = Set<AnyCancellable>()
    private var settingsWindow: NSWindow? // Keep reference to prevent multiple windows
    private var settingsWindowDelegate: SettingsWindowDelegate? // Strong reference to delegate
    
    override init() {
        super.init()
        setupMenuBar()
        setupObservers()
    }
    
    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            // Use a system symbol for the menu bar icon
            let image = NSImage(systemSymbolName: "eye.fill", accessibilityDescription: "Blinkly")
            image?.size = NSSize(width: 18, height: 18)
            button.image = image
            button.target = self
            button.action = #selector(statusBarButtonClicked)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        
        updateMenuBar()
        print("Menu bar setup complete - should be visible now")
    }
    
    private func setupObservers() {
        // We'll inject these dependencies later
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateMenuBar()
        }
    }
    
    func setManagers(timerManager: TimerManager, reminderManager: ReminderManager) {
        self.timerManager = timerManager
        self.reminderManager = reminderManager
        
        // Observe timer changes
        timerManager.$timeUntilNextBreak
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    self?.updateMenuBar()
                }
            }
            .store(in: &cancellables)
    }
    
    private func updateMenuBar() {
        guard let button = statusItem?.button else { return }
        
        if let timerManager = timerManager {
            let minutes = Int(timerManager.timeUntilNextBreak) / 60
            let seconds = Int(timerManager.timeUntilNextBreak) % 60
            
            if timerManager.isBreakActive {
                button.title = "🔴 Break"
            } else if timerManager.isEnabled {
                button.title = String(format: "%02d:%02d", minutes, seconds)
            } else {
                button.title = "Paused"
            }
        } else {
            button.title = "Blinkly"
        }
        
        // Debug: Uncomment to see timer updates
        // print("⏰ Menu bar updated: \(button.title)")
    }
    
    @objc private func statusBarButtonClicked() {
        guard statusItem?.button != nil else { return }
        
        // Detect which mouse button was clicked
        let event = NSApp.currentEvent
        if event?.type == .rightMouseUp {
            // Right-click: show context menu
            showContextMenu()
        } else {
            // Left-click: show comprehensive menu
            showMainMenu()
        }
    }
    
    private func showMainMenu() {
        let menu = NSMenu()
        
        // Status info header
        if let timerManager = timerManager {
            let minutes = Int(timerManager.timeUntilNextBreak) / 60
            let seconds = Int(timerManager.timeUntilNextBreak) % 60
            
            if timerManager.isBreakActive {
                let breakItem = NSMenuItem(title: "🔴 Break in progress...", action: nil, keyEquivalent: "")
                breakItem.isEnabled = false
                menu.addItem(breakItem)
            } else if timerManager.isEnabled {
                let nextBreakItem = NSMenuItem(title: "⏰ Next break in \(minutes):\(String(format: "%02d", seconds))", action: nil, keyEquivalent: "")
                nextBreakItem.isEnabled = false
                menu.addItem(nextBreakItem)
            } else {
                let pausedItem = NSMenuItem(title: "⏸️ Timer paused", action: nil, keyEquivalent: "")
                pausedItem.isEnabled = false
                menu.addItem(pausedItem)
            }
        }
        
        menu.addItem(NSMenuItem.separator())
        
        // Quick timer actions
        if let timerManager = timerManager {
            if timerManager.isBreakActive {
                menu.addItem(NSMenuItem(title: "✅ End Break", action: #selector(endBreak), keyEquivalent: ""))
                menu.addItem(NSMenuItem(title: "⏭️ Skip Break", action: #selector(skipBreak), keyEquivalent: ""))
            } else {
                menu.addItem(NSMenuItem(title: "▶️ Start Break Now", action: #selector(startBreakNow), keyEquivalent: ""))
                
                // Postpone options submenu
                let postponeSubmenu = NSMenu()
                postponeSubmenu.addItem(NSMenuItem(title: "Postpone +5 minutes", action: #selector(postpone5), keyEquivalent: ""))
                postponeSubmenu.addItem(NSMenuItem(title: "Postpone +15 minutes", action: #selector(postpone15), keyEquivalent: ""))
                postponeSubmenu.addItem(NSMenuItem(title: "Postpone +30 minutes", action: #selector(postpone30), keyEquivalent: ""))
                postponeSubmenu.addItem(NSMenuItem(title: "Postpone +1 hour", action: #selector(postpone60), keyEquivalent: ""))
                
                let postponeItem = NSMenuItem(title: "⏰ Postpone Break", action: nil, keyEquivalent: "")
                postponeItem.submenu = postponeSubmenu
                menu.addItem(postponeItem)
                
                let toggleTitle = timerManager.isEnabled ? "⏸️ Pause Timer" : "▶️ Resume Timer"
                menu.addItem(NSMenuItem(title: toggleTitle, action: #selector(toggleTimer), keyEquivalent: ""))
            }
        }
        
        menu.addItem(NSMenuItem.separator())
        
        // Quick interval presets
        let presetsSubmenu = NSMenu()
        presetsSubmenu.addItem(NSMenuItem(title: "20-20-20 Rule (20 min)", action: #selector(setPreset20), keyEquivalent: ""))
        presetsSubmenu.addItem(NSMenuItem(title: "Pomodoro (25 min)", action: #selector(setPreset25), keyEquivalent: ""))
        presetsSubmenu.addItem(NSMenuItem(title: "Short breaks (15 min)", action: #selector(setPreset15), keyEquivalent: ""))
        presetsSubmenu.addItem(NSMenuItem(title: "Long focus (45 min)", action: #selector(setPreset45), keyEquivalent: ""))
        
        let presetsItem = NSMenuItem(title: "⚡ Quick Presets", action: nil, keyEquivalent: "")
        presetsItem.submenu = presetsSubmenu
        menu.addItem(presetsItem)
        
        // Reminder controls
        if let reminderManager = reminderManager {
            menu.addItem(NSMenuItem.separator())
            
            let blinkTitle = reminderManager.isBlinkReminderEnabled ? "👁️ Disable Blink Reminders" : "👁️ Enable Blink Reminders"
            menu.addItem(NSMenuItem(title: blinkTitle, action: #selector(toggleBlinkReminders), keyEquivalent: ""))
            
            let postureTitle = reminderManager.isPostureReminderEnabled ? "🪑 Disable Posture Reminders" : "🪑 Enable Posture Reminders"
            menu.addItem(NSMenuItem(title: postureTitle, action: #selector(togglePostureReminders), keyEquivalent: ""))
        }
        
        menu.addItem(NSMenuItem.separator())
        
        // Settings and quit
        menu.addItem(NSMenuItem(title: "⚙️ Settings...", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem(title: "ℹ️ About Blinkly", action: #selector(showAbout), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "❌ Quit Blinkly", action: #selector(quitApp), keyEquivalent: "q"))
        
        // Set targets for all menu items recursively
        setTargetsRecursively(for: menu)
        
        // Show menu without disrupting timer updates
        statusItem?.menu = menu
        statusItem?.button?.performClick(nil)
        
        // Important: Clear menu after display to allow timer updates to continue
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.statusItem?.menu = nil
        }
    }
    
    private func showContextMenu() {
        // Simple right-click menu for quick actions
        let menu = NSMenu()
        
        if let timerManager = timerManager {
            if timerManager.isBreakActive {
                menu.addItem(NSMenuItem(title: "End Break", action: #selector(endBreak), keyEquivalent: ""))
            } else {
                menu.addItem(NSMenuItem(title: "Start Break Now", action: #selector(startBreakNow), keyEquivalent: ""))
                let toggleTitle = timerManager.isEnabled ? "Pause Timer" : "Resume Timer"
                menu.addItem(NSMenuItem(title: toggleTitle, action: #selector(toggleTimer), keyEquivalent: ""))
            }
        }
        
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: ""))
        
        setTargetsRecursively(for: menu)
        
        // Show context menu without disrupting timer updates
        statusItem?.menu = menu
        statusItem?.button?.performClick(nil)
        
        // Important: Clear menu after display to allow timer updates to continue
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.statusItem?.menu = nil
        }
    }
    
    private func setTargetsRecursively(for menu: NSMenu) {
        for item in menu.items {
            if item.target == nil && item.action != nil {
                item.target = self
            }
            if let submenu = item.submenu {
                setTargetsRecursively(for: submenu)
            }
        }
    }
    
    @objc private func startBreakNow() {
        timerManager?.startBreak()
    }
    
    @objc private func endBreak() {
        timerManager?.endBreak()
    }
    
    @objc private func skipBreak() {
        timerManager?.skipBreak()
    }
    
    @objc private func postpone5() {
        timerManager?.postponeBreak(by: 300) // 5 minutes
    }
    
    @objc private func postpone15() {
        timerManager?.postponeBreak(by: 900) // 15 minutes
    }
    
    @objc private func postpone30() {
        timerManager?.postponeBreak(by: 1800) // 30 minutes
    }
    
    @objc private func postpone60() {
        timerManager?.postponeBreak(by: 3600) // 1 hour
    }
    
    @objc private func toggleTimer() {
        timerManager?.toggle()
    }
    
    // Quick preset actions
    @objc private func setPreset20() {
        timerManager?.setBreakPreset(interval: 20 * 60, duration: 20) // 20 minutes, 20 seconds (20-20-20 rule)
    }
    
    @objc private func setPreset25() {
        timerManager?.setBreakPreset(interval: 25 * 60, duration: 300) // 25 minutes, 5 minutes break (Pomodoro)
    }
    
    @objc private func setPreset15() {
        timerManager?.setBreakPreset(interval: 15 * 60, duration: 15) // 15 minutes, 15 seconds
    }
    
    @objc private func setPreset45() {
        timerManager?.setBreakPreset(interval: 45 * 60, duration: 30) // 45 minutes, 30 seconds
    }
    
    // Reminder toggle actions
    @objc private func toggleBlinkReminders() {
        reminderManager?.toggleBlinkReminder()
    }
    
    @objc private func togglePostureReminders() {
        reminderManager?.togglePostureReminder()
    }
    
    @objc private func showAbout() {
        // Show about dialog
        let alert = NSAlert()
        alert.messageText = "About Blinkly"
        alert.informativeText = """
        Blinkly v1.0
        
        Your digital eye health companion. Protect your vision with smart break reminders, blink prompts, and posture checks.
        
        Built with ❤️ for digital workers everywhere.
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        
        // Set app icon if available
        if let appIcon = NSApp.applicationIconImage {
            alert.icon = appIcon
        }
        
        alert.runModal()
    }
    
    @objc private func openSettings() {
        // Check if settings window already exists and is visible - with safe unwrapping
        if let existingWindow = settingsWindow {
            // Check if window is still valid and visible
            if existingWindow.isVisible {
                existingWindow.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
                print("📱 Brought existing settings window to front")
                return
            } else {
                // Window was closed, clear the reference
                settingsWindow = nil
            }
        }
        
        // Create new settings window
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 650, height: 500),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "Blinkly Settings"
    // Prevent AppKit from deallocating the window when closed; we own it via settingsWindow
    window.isReleasedWhenClosed = false
    // Safely unwrap managers; if missing, create placeholders and link them
    let tm = timerManager ?? TimerManager()
    let rm = reminderManager ?? ReminderManager()
    // Link timer -> reminder for preset propagation when using placeholders
    tm.setReminderManager(rm)
        window.contentView = NSHostingView(
            rootView: SettingsView()
                .environmentObject(tm)
                .environmentObject(rm)
        )
        
        // Set up window close callback to clear reference
        settingsWindowDelegate = SettingsWindowDelegate { [weak self] in
            DispatchQueue.main.async { [weak self] in
                if let win = self?.settingsWindow {
                    // Hide and release content before dropping references
                    win.orderOut(nil)
                    win.contentView = nil
                }
                self?.settingsWindow = nil
                self?.settingsWindowDelegate = nil
            }
        }
        window.delegate = settingsWindowDelegate
        
        // Set the window reference
        settingsWindow = window
        
        // Center and show the window
        window.center()
        window.makeKeyAndOrderFront(nil)
        
        // Activate the app to bring window to front
        NSApp.activate(ignoringOtherApps: true)
        
        print("📱 Settings window opened")
    }
    
    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}

// Helper class to handle settings window closing
class SettingsWindowDelegate: NSObject, NSWindowDelegate {
    private let onClose: () -> Void
    
    init(onClose: @escaping () -> Void) {
        self.onClose = onClose
        super.init()
    }
    
    func windowWillClose(_ notification: Notification) {
        // Ensure AppKit no longer holds an unsafe reference to this delegate
        if let window = notification.object as? NSWindow {
            window.delegate = nil
        }
        // Defer cleanup to next runloop to avoid dealloc during callback
        DispatchQueue.main.async { [onClose] in
            onClose()
        }
    }
}
