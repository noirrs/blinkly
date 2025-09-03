import Foundation
import ServiceManagement

// MARK: - Settings Database Manager
class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    
    // MARK: - Custom Preset Model
    struct CustomPreset: Codable, Identifiable {
        var id: UUID
        var name: String
        var breakDuration: TimeInterval // in seconds
        var breakInterval: TimeInterval // in minutes
        var blinkInterval: TimeInterval // in seconds
        var postureInterval: TimeInterval // in minutes
        
        init(id: UUID = UUID(), name: String, breakDuration: TimeInterval, breakInterval: TimeInterval, blinkInterval: TimeInterval, postureInterval: TimeInterval) {
            self.id = id
            self.name = name
            self.breakDuration = breakDuration
            self.breakInterval = breakInterval
            self.blinkInterval = blinkInterval
            self.postureInterval = postureInterval
        }
    }
    
    // MARK: - Published Properties
    @Published var customPresets: [CustomPreset] = []
    @Published var currentPresetId: UUID? = nil
    
    // MARK: - Settings Keys
    private struct Keys {
        static let customPresets = "customPresets"
        static let launchAtLogin = "launchAtLogin"
        static let autoStartTimer = "autoStartTimer"
        static let breakInterval = "breakInterval"
        static let breakDuration = "breakDuration"
        static let timerEnabled = "timerEnabled"
        static let blinkReminderInterval = "blinkReminderInterval"
        static let postureReminderInterval = "postureReminderInterval"
        static let blinkReminderDuration = "blinkReminderDuration"
        static let postureReminderDuration = "postureReminderDuration"
        static let blinkReminderEnabled = "blinkReminderEnabled"
        static let postureReminderEnabled = "postureReminderEnabled"
        static let showFloatingCountdown = "showFloatingCountdown"
        static let autoDismissBreaks = "autoDismissBreaks"
        static let smartMediaControl = "smartMediaControl"
        static let multiScreenSupport = "multiScreenSupport"
        static let glassmorphismEffects = "glassmorphismEffects"
        static let smoothTransitions = "smoothTransitions"
        static let realisticEyeBlinking = "realisticEyeBlinking"
        static let skipRemindersInBreaks = "skipRemindersInBreaks"
        static let gentleFadeAnimations = "gentleFadeAnimations"
        static let showTimerInMenuBar = "showTimerInMenuBar"
        static let showStatusIndicators = "showStatusIndicators"
        static let nonIntrusiveOverlays = "nonIntrusiveOverlays"
        static let clickThroughReminders = "clickThroughReminders"
        static let keepRunningInBackground = "keepRunningInBackground"
        static let soundEffects = "soundEffects"
        static let notificationPermission = "notificationPermission"
    }
    
    private init() {
        loadSettings()
        setupDefaultPresets()
    }
    
    // MARK: - Default Settings Values
    private func getDefaultValues() -> [String: Any] {
        return [
            Keys.launchAtLogin: false,
            Keys.autoStartTimer: true,
            Keys.breakInterval: 1200.0, // 20 minutes
            Keys.breakDuration: 20.0, // 20 seconds
            Keys.timerEnabled: true,
            Keys.blinkReminderInterval: 1200.0, // 20 minutes
            Keys.postureReminderInterval: 1800.0, // 30 minutes
            Keys.blinkReminderDuration: 5,
            Keys.postureReminderDuration: 5,
            Keys.blinkReminderEnabled: true,
            Keys.postureReminderEnabled: true,
            Keys.showFloatingCountdown: true,
            Keys.autoDismissBreaks: true,
            Keys.smartMediaControl: true,
            Keys.multiScreenSupport: true,
            Keys.glassmorphismEffects: true,
            Keys.smoothTransitions: true,
            Keys.realisticEyeBlinking: true,
            Keys.skipRemindersInBreaks: true,
            Keys.gentleFadeAnimations: true,
            Keys.showTimerInMenuBar: true,
            Keys.showStatusIndicators: true,
            Keys.nonIntrusiveOverlays: true,
            Keys.clickThroughReminders: false,
            Keys.keepRunningInBackground: true,
            Keys.soundEffects: true,
            Keys.notificationPermission: false
        ]
    }
    
    // MARK: - Load Settings
    private func loadSettings() {
        // Load custom presets
        if let data = UserDefaults.standard.data(forKey: Keys.customPresets),
           let presets = try? JSONDecoder().decode([CustomPreset].self, from: data) {
            customPresets = presets
        }
        
        // Load current preset ID
        loadCurrentPresetId()
    }
    
    private func setupDefaultPresets() {
        // Only add default presets if none exist
        if customPresets.isEmpty {
            let defaultPresets = [
                CustomPreset(
                    name: "20-20-20 Rule",
                    breakDuration: 20,
                    breakInterval: 20,
                    blinkInterval: 20,
                    postureInterval: 30
                ),
                CustomPreset(
                    name: "Pomodoro",
                    breakDuration: 300,
                    breakInterval: 25,
                    blinkInterval: 20,
                    postureInterval: 30
                ),
                CustomPreset(
                    name: "Short Breaks",
                    breakDuration: 15,
                    breakInterval: 15,
                    blinkInterval: 15,
                    postureInterval: 25
                ),
                CustomPreset(
                    name: "Deep Focus",
                    breakDuration: 30,
                    breakInterval: 45,
                    blinkInterval: 25,
                    postureInterval: 45
                )
            ]
            customPresets = defaultPresets
            saveCustomPresets()
        }
    }
    
    // MARK: - Generic Get/Set Methods
    func getValue<T>(for key: String, defaultValue: T) -> T {
        let defaults = getDefaultValues()
        
        if UserDefaults.standard.object(forKey: key) == nil {
            // Return default value if key doesn't exist
            return defaults[key] as? T ?? defaultValue
        }
        
        if T.self == Bool.self {
            return UserDefaults.standard.bool(forKey: key) as! T
        } else if T.self == Double.self || T.self == TimeInterval.self {
            return UserDefaults.standard.double(forKey: key) as! T
        } else if T.self == Int.self {
            return UserDefaults.standard.integer(forKey: key) as! T
        } else if T.self == String.self {
            return (UserDefaults.standard.string(forKey: key) ?? defaultValue as! String) as! T
        }
        
        return defaultValue
    }
    
    func setValue<T>(_ value: T, for key: String) {
        UserDefaults.standard.set(value, forKey: key)
        
        // Handle special cases
        if key == Keys.launchAtLogin {
            configureLaunchAtLogin(value as! Bool)
        }
    }
    
    // MARK: - Custom Presets Management
    func addCustomPreset(_ preset: CustomPreset) {
        customPresets.append(preset)
        saveCustomPresets()
    }
    
    func deleteCustomPreset(_ preset: CustomPreset) {
        customPresets.removeAll { $0.id == preset.id }
        saveCustomPresets()
    }
    
    func updateCustomPreset(_ preset: CustomPreset) {
        if let index = customPresets.firstIndex(where: { $0.id == preset.id }) {
            customPresets[index] = preset
            saveCustomPresets()
        }
    }
    
    private func saveCustomPresets() {
        if let data = try? JSONEncoder().encode(customPresets) {
            UserDefaults.standard.set(data, forKey: Keys.customPresets)
        }
    }
    
    // MARK: - Launch at Login Configuration
    private func configureLaunchAtLogin(_ enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                    print("✅ Launch at login enabled")
                } else {
                    try SMAppService.mainApp.unregister()
                    print("❌ Launch at login disabled")
                }
            } catch {
                print("⚠️ Failed to configure launch at login: \(error)")
            }
        } else {
            // Fallback for older macOS versions
            print("Launch at login configuration requires macOS 13.0+")
        }
    }
    
    // MARK: - Reset Settings
    func resetAllSettings() {
        let keys = [
            Keys.launchAtLogin, Keys.autoStartTimer, Keys.breakInterval, Keys.breakDuration,
            Keys.timerEnabled, Keys.blinkReminderInterval, Keys.postureReminderInterval,
            Keys.blinkReminderDuration, Keys.postureReminderDuration, Keys.blinkReminderEnabled,
            Keys.postureReminderEnabled, Keys.showFloatingCountdown, Keys.autoDismissBreaks,
            Keys.smartMediaControl, Keys.multiScreenSupport, Keys.glassmorphismEffects,
            Keys.smoothTransitions, Keys.realisticEyeBlinking, Keys.skipRemindersInBreaks,
            Keys.gentleFadeAnimations, Keys.showTimerInMenuBar, Keys.showStatusIndicators,
            Keys.nonIntrusiveOverlays, Keys.clickThroughReminders, Keys.keepRunningInBackground,
            Keys.soundEffects, Keys.notificationPermission
        ]
        
        keys.forEach { UserDefaults.standard.removeObject(forKey: $0) }
        
        // Reset custom presets
        customPresets.removeAll()
        UserDefaults.standard.removeObject(forKey: Keys.customPresets)
        setupDefaultPresets()
        
        print("🔄 All settings reset to defaults")
    }
    
    // MARK: - Export/Import Settings
    func exportSettings() -> [String: Any] {
        var settings: [String: Any] = [:]
        let defaults = getDefaultValues()
        
        for (key, defaultValue) in defaults {
            if let value = UserDefaults.standard.object(forKey: key) {
                settings[key] = value
            } else {
                settings[key] = defaultValue
            }
        }
        
        // Add custom presets
        if let presetsData = try? JSONEncoder().encode(customPresets),
           let presetsDict = try? JSONSerialization.jsonObject(with: presetsData) {
            settings["customPresets"] = presetsDict
        }
        
        return settings
    }
    
    func importSettings(_ settings: [String: Any]) {
        for (key, value) in settings {
            if key == "customPresets" {
                // Handle custom presets specially
                if let presetsData = try? JSONSerialization.data(withJSONObject: value),
                   let presets = try? JSONDecoder().decode([CustomPreset].self, from: presetsData) {
                    customPresets = presets
                    saveCustomPresets()
                }
            } else {
                UserDefaults.standard.set(value, forKey: key)
            }
        }
        
        print("📥 Settings imported successfully")
    }
}

// MARK: - Convenience Extensions
extension SettingsManager {
    // Timer settings
    var launchAtLogin: Bool {
        get { getValue(for: Keys.launchAtLogin, defaultValue: false) }
        set { setValue(newValue, for: Keys.launchAtLogin) }
    }
    
    var autoStartTimer: Bool {
        get { getValue(for: Keys.autoStartTimer, defaultValue: true) }
        set { setValue(newValue, for: Keys.autoStartTimer) }
    }
    
    var breakInterval: TimeInterval {
        get { getValue(for: Keys.breakInterval, defaultValue: 1200.0) }
        set { setValue(newValue, for: Keys.breakInterval) }
    }
    
    var breakDuration: TimeInterval {
        get { getValue(for: Keys.breakDuration, defaultValue: 20.0) }
        set { setValue(newValue, for: Keys.breakDuration) }
    }
    
    var timerEnabled: Bool {
        get { getValue(for: Keys.timerEnabled, defaultValue: true) }
        set { setValue(newValue, for: Keys.timerEnabled) }
    }
    
    // Reminder settings
    var blinkReminderInterval: TimeInterval {
        get { getValue(for: Keys.blinkReminderInterval, defaultValue: 1200.0) }
        set { setValue(newValue, for: Keys.blinkReminderInterval) }
    }
    
    var postureReminderInterval: TimeInterval {
        get { getValue(for: Keys.postureReminderInterval, defaultValue: 1800.0) }
        set { setValue(newValue, for: Keys.postureReminderInterval) }
    }
    
    var blinkReminderDuration: Int {
        get { getValue(for: Keys.blinkReminderDuration, defaultValue: 5) }
        set { setValue(newValue, for: Keys.blinkReminderDuration) }
    }
    
    var postureReminderDuration: Int {
        get { getValue(for: Keys.postureReminderDuration, defaultValue: 5) }
        set { setValue(newValue, for: Keys.postureReminderDuration) }
    }
    
    var blinkReminderEnabled: Bool {
        get { getValue(for: Keys.blinkReminderEnabled, defaultValue: true) }
        set { setValue(newValue, for: Keys.blinkReminderEnabled) }
    }
    
    var postureReminderEnabled: Bool {
        get { getValue(for: Keys.postureReminderEnabled, defaultValue: true) }
        set { setValue(newValue, for: Keys.postureReminderEnabled) }
    }
    
    // Feature toggles
    var showFloatingCountdown: Bool {
        get { getValue(for: Keys.showFloatingCountdown, defaultValue: true) }
        set { setValue(newValue, for: Keys.showFloatingCountdown) }
    }
    
    var autoDismissBreaks: Bool {
        get { getValue(for: Keys.autoDismissBreaks, defaultValue: true) }
        set { setValue(newValue, for: Keys.autoDismissBreaks) }
    }
    
    var smartMediaControl: Bool {
        get { getValue(for: Keys.smartMediaControl, defaultValue: true) }
        set { setValue(newValue, for: Keys.smartMediaControl) }
    }
    
    var skipRemindersInBreaks: Bool {
        get { getValue(for: Keys.skipRemindersInBreaks, defaultValue: true) }
        set { setValue(newValue, for: Keys.skipRemindersInBreaks) }
    }
    
    var gentleFadeAnimations: Bool {
        get { getValue(for: Keys.gentleFadeAnimations, defaultValue: true) }
        set { setValue(newValue, for: Keys.gentleFadeAnimations) }
    }
    
    var keepRunningInBackground: Bool {
        get { getValue(for: Keys.keepRunningInBackground, defaultValue: true) }
        set { setValue(newValue, for: Keys.keepRunningInBackground) }
    }
    
    var nonIntrusiveOverlays: Bool {
        get { getValue(for: Keys.nonIntrusiveOverlays, defaultValue: true) }
        set { setValue(newValue, for: Keys.nonIntrusiveOverlays) }
    }
    
    var clickThroughReminders: Bool {
        get { getValue(for: Keys.clickThroughReminders, defaultValue: false) }
        set { setValue(newValue, for: Keys.clickThroughReminders) }
    }
    
    // MARK: - Current Preset Tracking
    func setCurrentPreset(_ presetId: UUID?) {
        currentPresetId = presetId
        if let id = presetId {
            UserDefaults.standard.set(id.uuidString, forKey: "currentPresetId")
        } else {
            UserDefaults.standard.removeObject(forKey: "currentPresetId")
        }
    }
    
    func loadCurrentPresetId() {
        if let idString = UserDefaults.standard.string(forKey: "currentPresetId"),
           let id = UUID(uuidString: idString) {
            currentPresetId = id
        }
    }
    
    // MARK: - Reset Methods
    func resetToDefaults() {
        // Remove all custom settings to restore defaults
        let allKeys = [
            Keys.customPresets, Keys.launchAtLogin, Keys.autoStartTimer,
            Keys.breakInterval, Keys.breakDuration, Keys.timerEnabled,
            Keys.blinkReminderInterval, Keys.postureReminderInterval,
            Keys.blinkReminderDuration, Keys.postureReminderDuration,
            Keys.blinkReminderEnabled, Keys.postureReminderEnabled,
            Keys.showFloatingCountdown, Keys.autoDismissBreaks,
            Keys.smartMediaControl, Keys.multiScreenSupport,
            Keys.glassmorphismEffects, Keys.smoothTransitions,
            Keys.realisticEyeBlinking, Keys.skipRemindersInBreaks,
            Keys.gentleFadeAnimations, Keys.keepRunningInBackground,
            Keys.nonIntrusiveOverlays, Keys.clickThroughReminders
        ]
        
        for key in allKeys {
            UserDefaults.standard.removeObject(forKey: key)
        }
        
        // Reset published properties
        customPresets = []
        
        // Trigger UI update
        objectWillChange.send()
    }
}
