import SwiftUI
import AppKit
import Combine

struct BlinklyApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        // Hidden main window (required for menu bar apps)
        WindowGroup {
            EmptyView()
                .onAppear {
                    setupApp()
                }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        
        // Settings window
        WindowGroup("Settings", id: "settings") {
            SettingsView()
                .environmentObject(appState.timerManager)
                .environmentObject(appState.reminderManager)
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 600, height: 400)
        .windowToolbarStyle(.unified)
        .commandsRemoved()
    }
    
    private func setupApp() {
        // Hide the dock icon since this is a menu bar app
        NSApp.setActivationPolicy(.accessory)
        
        // Set up manager dependencies
        appState.menuBarController.setManagers(
            timerManager: appState.timerManager,
            reminderManager: appState.reminderManager
        )
        
        // Set up break overlay management
        appState.setupBreakOverlayManagement()
        
        // Hide all windows initially
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            NSApp.windows.forEach { window in
                if window.title.isEmpty || window.title == "Blinkly" {
                    window.setIsVisible(false)
                }
            }
        }
    }
}

// Centralized app state management
class AppState: ObservableObject {
    let menuBarController = MenuBarController()
    let timerManager = TimerManager()
    let reminderManager = ReminderManager()
    
    private var breakWindow: NSWindow?
    private var breakWindows: [NSWindow] = [] // Support multiple screens
    private var floatingCountdownWindow: NSWindow?
    private var reminderWindow: NSWindow?
    private var mouseTrackingTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Set up manager dependencies
        timerManager.setReminderManager(reminderManager)
    }
    
    deinit {
        // Cleanup windows on deinit
        hideBreakOverlay()
        hideFloatingCountdown()
        hideReminderOverlay()
        mouseTrackingTimer?.invalidate()
        cancellables.removeAll()
    }
    
    func setupBreakOverlayManagement() {
        // Monitor timer state changes to show/hide break overlay
        timerManager.$isBreakActive
            .sink { [weak self] isBreakActive in
                DispatchQueue.main.async {
                    if isBreakActive {
                        self?.showBreakOverlay()
                    } else {
                        self?.hideBreakOverlay()
                    }
                }
            }
            .store(in: &cancellables)
        
        // Monitor countdown visibility
        timerManager.$isCountdownVisible
            .sink { [weak self] isVisible in
                DispatchQueue.main.async {
                    if isVisible {
                        self?.showFloatingCountdown()
                    } else {
                        self?.hideFloatingCountdown()
                    }
                }
            }
            .store(in: &cancellables)
        
        // Monitor blink reminder overlay
        reminderManager.$showBlinkOverlay
            .sink { [weak self] show in
                DispatchQueue.main.async {
                    if show {
                        self?.showReminderOverlay(type: .blink, message: self?.reminderManager.currentBlinkMessage ?? "")
                    } else {
                        self?.hideReminderOverlay()
                    }
                }
            }
            .store(in: &cancellables)
        
        // Monitor posture reminder overlay
        reminderManager.$showPostureOverlay
            .sink { [weak self] show in
                DispatchQueue.main.async {
                    if show {
                        self?.showReminderOverlay(type: .posture, message: self?.reminderManager.currentPostureMessage ?? "")
                    } else {
                        self?.hideReminderOverlay()
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    private func showBreakOverlay() {
        hideBreakOverlay() // Close any existing overlays
        
        // Get ALL screens and create overlay on each
        let screens = NSScreen.screens
        
        for screen in screens {
            let frame = screen.frame
            
            // Create simple borderless window for this screen
            let window = NSWindow(
                contentRect: frame,
                styleMask: [.borderless],
                backing: .buffered,
                defer: false
            )
            
            // Configure window for full-screen overlay - NON-INTRUSIVE
            window.level = .popUpMenu // Changed from .popUpMenu to be less intrusive
            window.backgroundColor = .clear
            window.isOpaque = false
            window.hasShadow = false
            window.ignoresMouseEvents = false
            window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
            window.isReleasedWhenClosed = false
            window.acceptsMouseMovedEvents = false // Prevent mouse event capture
            window.hidesOnDeactivate = false // Don't hide when user switches apps
            
            // Create SwiftUI content
            let contentView = BreakOverlayView(timerManager: timerManager)
            let hostingView = NSHostingView(rootView: contentView)
            hostingView.frame = frame
            
            window.contentView = hostingView
            // NON-INTRUSIVE: Don't make key window to avoid keyboard interference
            window.orderFrontRegardless()
            // Don't make key - we want non-intrusive break overlays
            
            // Add to our array of break windows
            breakWindows.append(window)
            
            print("✅ Break overlay window created on screen: \(screens.firstIndex(of: screen) ?? 0)")
        }
        
        print("✅ Break overlay shown on \(screens.count) screen(s)")
    }
    
    private func hideBreakOverlay() {
        // Hide and close all break windows
        for window in breakWindows {
            // First hide the window
            window.orderOut(nil)
            
            // Clear the content view to prevent retain cycles
            window.contentView = nil
            
            // Schedule window closure after a delay to ensure cleanup
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak window] in
                window?.close()
            }
        }
        
        // Clear our array
        breakWindows.removeAll()
        
        // Also handle legacy single window if it exists
        if let window = breakWindow {
            window.orderOut(nil)
            window.contentView = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak window] in
                window?.close()
            }
            breakWindow = nil
        }
        
        print("Break overlay windows hidden on all screens")
    }
    
    private func showFloatingCountdown() {
        hideFloatingCountdown() // Close any existing countdown
        
        // Fixed window size matching tracking
        let windowSize = CGSize(width: 200, height: 80)
        
        // Get current mouse position and CENTER the window on cursor
        let mouseLocation = NSEvent.mouseLocation
        let frame = CGRect(
            x: mouseLocation.x - windowSize.width / 2, 
            y: mouseLocation.y - windowSize.height / 2, 
            width: windowSize.width, 
            height: windowSize.height
        )
        
        floatingCountdownWindow = NSWindow(
            contentRect: frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        guard let window = floatingCountdownWindow else { return }
        
        // Configure window - NON-INTRUSIVE
        window.level = .floating
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = false // No shadow for clean look
        window.ignoresMouseEvents = true
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        window.isReleasedWhenClosed = false
        window.acceptsMouseMovedEvents = false // Prevent mouse event capture
        window.hidesOnDeactivate = false // Don't hide when user switches apps
        
        // Create SwiftUI content
        let contentView = FloatingCountdownView(timerManager: timerManager)
        let hostingView = NSHostingView(rootView: contentView)
        hostingView.frame = CGRect(origin: .zero, size: windowSize)
        
        window.contentView = hostingView
        // NON-INTRUSIVE: Don't make key window to avoid keyboard interference
        window.orderFrontRegardless()
        // Don't make key - we want non-intrusive floating countdown
        
        // Start RESPONSIVE mouse tracking
        startMouseTracking()
        
        print("Floating countdown window created with centered cursor tracking")
    }
    
    private func hideFloatingCountdown() {
        guard let window = floatingCountdownWindow else { return }
        
        // Stop mouse tracking
        mouseTrackingTimer?.invalidate()
        mouseTrackingTimer = nil
        
        // First hide the window
        window.orderOut(nil)
        
        // Clear the content view to prevent retain cycles
        window.contentView = nil
        
        // Schedule window closure after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak window] in
            window?.close()
        }
        
        // Clear our reference
        floatingCountdownWindow = nil
        print("Floating countdown window hidden")
    }
    
    private func showReminderOverlay(type: ReminderOverlayView.ReminderType, message: String) {
        hideReminderOverlay() // Close any existing reminder
        
        // LookAway-style positioning - gentle and non-intrusive
        let windowSize = CGSize(width: 80, height: 80) // Smaller, more elegant
        
        reminderWindow = NSWindow(
            contentRect: CGRect(origin: .zero, size: windowSize),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        guard let window = reminderWindow else { return }
        
        // Configure window - NON-INTRUSIVE
        window.level = .floating
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = false
        window.ignoresMouseEvents = false
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        window.isReleasedWhenClosed = false
        window.acceptsMouseMovedEvents = false // Prevent mouse event capture
        window.hidesOnDeactivate = false // Don't hide when user switches apps
        
        // LookAway exact positioning: bottom-center like you requested
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let marginFromBottom: CGFloat = 100 // Distance from bottom edge
            
            let x = (screenFrame.width - windowSize.width) / 2 // Horizontal center
            let y = screenFrame.minY + marginFromBottom // From bottom
            
            window.setFrameOrigin(CGPoint(x: x, y: y))
        }
        
        // Create SwiftUI content
        let contentView = ReminderOverlayView(
            reminderType: type,
            message: message
        ) {
            // Dismiss callback
            if type == .blink {
                self.reminderManager.dismissBlinkReminder()
            } else {
                self.reminderManager.dismissPostureReminder()
            }
        }
        let hostingView = NSHostingView(rootView: contentView)
        hostingView.frame = CGRect(origin: .zero, size: windowSize)
        
        window.contentView = hostingView
        // NON-INTRUSIVE: Don't make key window to avoid keyboard interference
        window.orderFrontRegardless()
        // Don't make key - we want non-intrusive reminder overlays
        
        print("LookAway-style reminder overlay created: \(type)")
    }
    
    private func hideReminderOverlay() {
        guard let window = reminderWindow else { return }
        
        // First hide the window
        window.orderOut(nil)
        
        // Clear the content view to prevent retain cycles
        window.contentView = nil
        
        // Schedule window closure after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak window] in
            window?.close()
        }
        
        // Clear our reference
        reminderWindow = nil
        print("Reminder overlay window hidden")
    }
    
    private func startMouseTracking() {
        mouseTrackingTimer?.invalidate()
        
        mouseTrackingTimer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { [weak self] _ in // 60 FPS for smooth tracking
            guard let self = self,
                  let window = self.floatingCountdownWindow,
                  self.timerManager.isCountdownVisible else {
                self?.mouseTrackingTimer?.invalidate()
                self?.mouseTrackingTimer = nil
                return
            }
            
            // Get CURRENT mouse position
            let mouseLocation = NSEvent.mouseLocation
            let windowSize = CGSize(width: 200, height: 80) // Match showFloatingCountdown size
            
            // Center window on cursor (no offset, direct follow)
            let newX = mouseLocation.x - windowSize.width / 2
            let newY = mouseLocation.y - windowSize.height / 2
            
            // Keep window completely on screen
            if let screen = NSScreen.main {
                let screenFrame = screen.frame
                let constrainedX = max(0, min(newX, screenFrame.width - windowSize.width))
                let constrainedY = max(0, min(newY, screenFrame.height - windowSize.height))
                
                let newOrigin = CGPoint(x: constrainedX, y: constrainedY)
                
                // IMMEDIATE movement (no animation for responsive tracking)
                window.setFrameOrigin(newOrigin)
            }
        }
    }
}