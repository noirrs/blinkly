import Foundation
import UserNotifications
import Combine

class ReminderManager: ObservableObject {
    @Published var isBlinkReminderEnabled = true
    @Published var isPostureReminderEnabled = true
    @Published var showBlinkOverlay = false
    @Published var showPostureOverlay = false
    @Published var currentBlinkMessage = ""
    @Published var currentPostureMessage = ""
    
    // Settings - connected to SettingsManager
    @Published var blinkReminderInterval: TimeInterval = 10 // 45 seconds for demo
    @Published var postureReminderInterval: TimeInterval = 5 // 1.5 minutes for demo
    @Published var blinkReminderDuration: Int = 5 // seconds
    @Published var postureReminderDuration: Int = 5 // seconds
    
    private var settingsManager = SettingsManager.shared
    private var blinkTimer: Timer?
    private var postureTimer: Timer?
    
    // Motivational messages
    private let blinkMessages = [
        "👀 Blink time! Rest those hardworking eyes",
        "✨ Give your eyes some love - blink slowly", 
        "💧 Moisture break! Blink to refresh your vision",
        "🌟 Your eyes deserve care - take a blink moment",
        "👁️ Conscious blinking keeps your eyes healthy",
        "� Reset your focus with gentle blinking",
        "💫 Blink meditation: slow, deliberate, refreshing"
    ]
    
    private let postureMessages = [
        "🧘‍♀️ Posture check - sit tall like a champion",
        "💪 Roll those shoulders back and shine!",
        "🏃‍♂️ Spine alignment moment - feel the difference", 
        "✨ Good posture = confident energy",
        "🌟 Straighten up! Your future back thanks you",
        "🎯 Core engaged, shoulders down, chin up",
        "🌱 Grow taller with perfect posture alignment"
    ]
    
    init() {
        loadSettings()
        requestNotificationPermission()
        startReminders()
        print("ReminderManager initialized - blink: \(isBlinkReminderEnabled), posture: \(isPostureReminderEnabled)")
    }
    
    deinit {
        // Cleanup timers
        blinkTimer?.invalidate()
        postureTimer?.invalidate()
    }
    
    private func requestNotificationPermission() {
        // Only request notifications if we're running as a proper app bundle
        guard Bundle.main.bundleIdentifier != nil else {
            print("Skipping notification permission request - not running as app bundle")
            return
        }
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }
    
    func startReminders() {
        startBlinkReminder()
        startPostureReminder()
    }
    
    private func startBlinkReminder() {
        guard isBlinkReminderEnabled else { return }
        
        blinkTimer?.invalidate()
        blinkTimer = Timer.scheduledTimer(withTimeInterval: blinkReminderInterval, repeats: true) { [weak self] _ in
            self?.showBlinkReminder()
        }
    }
    
    private func startPostureReminder() {
        guard isPostureReminderEnabled else { return }
        
        postureTimer?.invalidate()
        postureTimer = Timer.scheduledTimer(withTimeInterval: postureReminderInterval, repeats: true) { [weak self] _ in
            self?.showPostureReminder()
        }
    }
    
    private func showBlinkReminder() {
        let message = blinkMessages.randomElement() ?? blinkMessages[0]
        currentBlinkMessage = message
        showBlinkOverlay = true
        
        // Also log to console
        print("🔔 Blink Reminder: \(message)")
        
        // Try system notification if available
        showNotification(title: "Blink Reminder", body: message, identifier: "blink-reminder")
    }
    
    private func showPostureReminder() {
        let message = postureMessages.randomElement() ?? postureMessages[0]
        currentPostureMessage = message
        showPostureOverlay = true
        
        // Also log to console
        print("🔔 Posture Check: \(message)")
        
        // Try system notification if available
        showNotification(title: "Posture Check", body: message, identifier: "posture-reminder")
    }
    
    private func showNotification(title: String, body: String, identifier: String) {
        // Don't show system notifications since we have visual overlays now
        // Just log for debugging
        // print("🔔 \(title): \(body)")
        
        // Only try system notification if running as proper app bundle
        guard Bundle.main.bundleIdentifier != nil else {
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.badge = 1
        
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error showing notification: \(error)")
            }
        }
    }
    
    func dismissBlinkReminder() {
        showBlinkOverlay = false
    }
    
    func dismissPostureReminder() {
        showPostureOverlay = false
    }
    
    func toggleBlinkReminder() {
        isBlinkReminderEnabled.toggle()
        if isBlinkReminderEnabled {
            startBlinkReminder()
        } else {
            blinkTimer?.invalidate()
        }
        saveSettings()
    }
    
    func togglePostureReminder() {
        isPostureReminderEnabled.toggle()
        if isPostureReminderEnabled {
            startPostureReminder()
        } else {
            postureTimer?.invalidate()
        }
        saveSettings()
    }
    
    private func loadSettings() {
        blinkReminderInterval = settingsManager.blinkReminderInterval
        postureReminderInterval = settingsManager.postureReminderInterval
        blinkReminderDuration = settingsManager.blinkReminderDuration
        postureReminderDuration = settingsManager.postureReminderDuration
        isBlinkReminderEnabled = settingsManager.blinkReminderEnabled
        isPostureReminderEnabled = settingsManager.postureReminderEnabled
        
        print("⚙️ Reminder settings loaded from database")
    }
    
    func saveSettings() {
        settingsManager.blinkReminderInterval = blinkReminderInterval
        settingsManager.postureReminderInterval = postureReminderInterval
        settingsManager.blinkReminderDuration = blinkReminderDuration
        settingsManager.postureReminderDuration = postureReminderDuration
        settingsManager.blinkReminderEnabled = isBlinkReminderEnabled
        settingsManager.postureReminderEnabled = isPostureReminderEnabled
        
        print("💾 Reminder settings saved to database")
    }
    
    // MARK: - Preset Management
    func applyPresetSettings(blinkInterval: TimeInterval, postureInterval: TimeInterval) {
        blinkReminderInterval = blinkInterval
        postureReminderInterval = postureInterval * 60 // Convert minutes to seconds
        
        // Restart timers with new intervals
        if isBlinkReminderEnabled {
            startBlinkReminder()
        }
        if isPostureReminderEnabled {
            startPostureReminder()
        }
        
        saveSettings()
        print("⚙️ Reminder intervals updated - Blink: \(Int(blinkInterval))s, Posture: \(Int(postureInterval))min")
    }
}
