import Foundation
import Combine

class TimerManager: ObservableObject {
    @Published var isBreakActive = false
    @Published var timeUntilNextBreak: TimeInterval = 30 // 30 seconds for demo
    @Published var currentBreakTimeRemaining: TimeInterval = 10 // 10 seconds for demo
    @Published var isCountdownVisible = false
    
    // Settings - connected to SettingsManager
    @Published var breakInterval: TimeInterval = 30 // 30 seconds for demo
    @Published var breakDuration: TimeInterval = 10 // 10 seconds for demo
    @Published var isEnabled = true
    @Published var autoStartTimer = true
    @Published var launchAtLogin = false
    
    private var settingsManager = SettingsManager.shared
    private weak var reminderManager: ReminderManager?
    private var breakTimer: Timer?
    private var countdownTimer: Timer?
    private var breakCountdownTimer: Timer? // Timer for break duration countdown
    private var countdownStartTime: Date?
    
    init() {
        loadSettings()
        if autoStartTimer {
            startBreakTimer()
        }
    }
    
    // MARK: - Manager Dependencies
    func setReminderManager(_ reminderManager: ReminderManager) {
        self.reminderManager = reminderManager
    }
    
    deinit {
        // Cleanup timers on deinit
        breakTimer?.invalidate()
        countdownTimer?.invalidate()
        breakCountdownTimer?.invalidate() // Clean up break countdown timer
    }
    
    func startBreakTimer() {
        guard isEnabled else { return }
        
        breakTimer?.invalidate()
        timeUntilNextBreak = breakInterval
        
        print("Starting break timer - next break in \(breakInterval) seconds")
        
        breakTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateBreakTimer()
        }
    }
    
    private func updateBreakTimer() {
        timeUntilNextBreak -= 1
        
        if timeUntilNextBreak <= 10 && !isCountdownVisible {
            // Show floating countdown when 10 seconds remain (for demo)
            print("Showing floating countdown - \(timeUntilNextBreak) seconds remaining")
            showFloatingCountdown()
        }
        
        if timeUntilNextBreak <= 0 {
            print("Time's up! Starting break...")
            startBreak()
        }
    }
    
    private func showFloatingCountdown() {
        isCountdownVisible = true
        countdownStartTime = Date()
        
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateCountdownTimer()
        }
    }
    
    private func updateCountdownTimer() {
        guard let startTime = countdownStartTime else { return }
        
        let elapsed = Date().timeIntervalSince(startTime)
        let remaining = max(0, 10 - elapsed) // 10 seconds countdown for demo
        
        if remaining <= 0 {
            hideFloatingCountdown()
        }
    }
    
    private func hideFloatingCountdown() {
        isCountdownVisible = false
        countdownTimer?.invalidate()
        countdownTimer = nil
        countdownStartTime = nil
    }
    
    func startBreak() {
        print("Break starting now!")
        breakTimer?.invalidate() // Stop the main timer
        isBreakActive = true
        currentBreakTimeRemaining = breakDuration
        hideFloatingCountdown()
        
        // Start break countdown timer
        breakCountdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            self.currentBreakTimeRemaining -= 1
            print("Break time remaining: \(self.currentBreakTimeRemaining)")
            
            if self.currentBreakTimeRemaining <= 0 {
                print("Break time finished!")
                timer.invalidate()
                self.breakCountdownTimer = nil // Clear the reference
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.endBreak()
                }
            }
        }
        
        // Store the timer reference so we can invalidate it if needed
        if let timer = breakCountdownTimer {
            RunLoop.current.add(timer, forMode: .common)
        }
    }
    
    func endBreak() {
        print("Ending break and restarting timer")
        
        // Clean up break countdown timer
        breakCountdownTimer?.invalidate()
        breakCountdownTimer = nil
        
        isBreakActive = false
        // Reset break time for next cycle
        currentBreakTimeRemaining = breakDuration
        startBreakTimer()
    }
    
    func skipBreak() {
        print("Skipping break")
        
        // IMPORTANT: Stop the break countdown timer to prevent background counting
        breakCountdownTimer?.invalidate()
        breakCountdownTimer = nil
        
        isBreakActive = false
        hideFloatingCountdown()
        // Reset break time for next cycle
        currentBreakTimeRemaining = breakDuration
        startBreakTimer()
    }
    
    func postponeBreak(by seconds: TimeInterval) {
        timeUntilNextBreak += seconds
        hideFloatingCountdown()
    }
    
    private func loadSettings() {
        breakInterval = settingsManager.breakInterval
        breakDuration = settingsManager.breakDuration
        isEnabled = settingsManager.timerEnabled
        autoStartTimer = settingsManager.autoStartTimer
        launchAtLogin = settingsManager.launchAtLogin
        
        print("⚙️ Timer settings loaded from database")
    }
    
    func saveSettings() {
        settingsManager.breakInterval = breakInterval
        settingsManager.breakDuration = breakDuration
        settingsManager.timerEnabled = isEnabled
        settingsManager.autoStartTimer = autoStartTimer
        settingsManager.launchAtLogin = launchAtLogin
        
        print("💾 Timer settings saved to database")
    }
    
    func toggle() {
        isEnabled.toggle()
        if isEnabled {
            startBreakTimer()
        } else {
            breakTimer?.invalidate()
            hideFloatingCountdown()
        }
        saveSettings()
    }
    
    func setBreakInterval(_ interval: TimeInterval) {
        breakInterval = interval
        saveSettings()
        // Restart timer with new interval if currently enabled
        if isEnabled && !isBreakActive {
            startBreakTimer()
        }
    }
    
    func setBreakPreset(interval: TimeInterval, duration: TimeInterval) {
        breakInterval = interval
        breakDuration = duration
        saveSettings()
        // Restart timer with new settings if currently enabled
        if isEnabled && !isBreakActive {
            startBreakTimer()
        }
    }
    
    func applyCustomPreset(_ preset: SettingsManager.CustomPreset) {
        breakInterval = preset.breakInterval * 60 // Convert minutes to seconds
        breakDuration = preset.breakDuration
        
        // Mark this preset as current
        SettingsManager.shared.setCurrentPreset(preset.id)
        
        // Apply reminder settings if reminder manager is available
        if let reminderManager = reminderManager {
            reminderManager.applyPresetSettings(
                blinkInterval: preset.blinkInterval,
                postureInterval: preset.postureInterval
            )
        }
        
        // Restart the timer with new interval
        if isEnabled {
            breakTimer?.invalidate()
            startBreakTimer()
        }
        
        saveSettings()
        print("📋 Applied custom preset: \(preset.name) - Timer restarted with \(Int(breakInterval/60))min interval")
    }
}
