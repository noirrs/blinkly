import SwiftUI

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var timerManager: TimerManager
    @EnvironmentObject var reminderManager: ReminderManager
    @StateObject private var settingsManager = SettingsManager.shared
    @State private var selectedTab = 0
    @State private var showPresetInfo = false
    @State private var showAddPresetSheet = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Break Settings
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HeaderView(title: "Break Settings", subtitle: "Configure your break intervals and duration")
                    
                    SettingsCard {
                        VStack(alignment: .leading, spacing: 16) {
                            ToggleRow(
                                title: "Enable Break Reminders",
                                subtitle: "Smart breaks to protect your eyes",
                                isOn: $timerManager.isEnabled
                            ) {
                                timerManager.toggle()
                            }
                            
                            ToggleRow(
                                title: "Auto-start timer on launch",
                                subtitle: "Begin timer automatically when app starts",
                                isOn: $timerManager.autoStartTimer
                            ) {
                                timerManager.autoStartTimer.toggle()
                                timerManager.saveSettings()
                            }
                            
                            if timerManager.isEnabled {
                                Divider()
                                
                                // Quick Presets Section
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Text("Quick Presets")
                                            .font(.system(size: 16, weight: .medium))
                                        
                                        Spacer()
                                        
                                        Button("Add Custom") {
                                            showAddPresetSheet = true
                                        }
                                        .buttonStyle(.bordered)
                                        
                                        Button(action: { showPresetInfo.toggle() }) {
                                            Image(systemName: "info.circle")
                                                .foregroundColor(.blue)
                                        }
                                        .buttonStyle(.plain)
                                        .popover(isPresented: $showPresetInfo) {
                                            PresetInfoView()
                                        }
                                    }
                                    
                                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                                        ForEach(settingsManager.customPresets) { preset in
                                            CustomPresetButton(
                                                preset: preset,
                                                isSelected: settingsManager.currentPresetId == preset.id,
                                                onSelect: {
                                                    timerManager.applyCustomPreset(preset)
                                                },
                                                onDelete: {
                                                    settingsManager.deleteCustomPreset(preset)
                                                }
                                            )
                                        }
                                    }
                                }
                                
                                Divider()
                                
                                SliderRow(
                                    title: "Break Interval",
                                    subtitle: "Time between breaks",
                                    value: Binding(
                                        get: { timerManager.breakInterval / 60 },
                                        set: { 
                                            timerManager.breakInterval = $0 * 60
                                            timerManager.saveSettings()
                                        }
                                    ),
                                    range: 5...120,
                                    unit: "minutes"
                                )
                                
                                SliderRow(
                                    title: "Break Duration",
                                    subtitle: "How long each break lasts",
                                    value: Binding(
                                        get: { timerManager.breakDuration },
                                        set: { 
                                            timerManager.breakDuration = $0
                                            timerManager.saveSettings()
                                        }
                                    ),
                                    range: 10...600,
                                    unit: "seconds"
                                )
                                
                                Divider()
                                
                                // Break Options
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Break Behavior")
                                        .font(.system(size: 14, weight: .medium))
                                    
                                    ToggleRow(
                                        title: "Show floating countdown",
                                        subtitle: "Display countdown before breaks",
                                        isOn: Binding(
                                            get: { SettingsManager.shared.showFloatingCountdown },
                                            set: { SettingsManager.shared.showFloatingCountdown = $0 }
                                        )
                                    ) {
                                        // Handled by binding
                                    }
                                    
                                    ToggleRow(
                                        title: "Auto-dismiss breaks",
                                        subtitle: "Automatically end breaks after duration",
                                        isOn: Binding(
                                            get: { SettingsManager.shared.autoDismissBreaks },
                                            set: { SettingsManager.shared.autoDismissBreaks = $0 }
                                        )
                                    ) {
                                        // Handled by binding
                                    }
                                    
                                    ToggleRow(
                                        title: "Smart media control",
                                        subtitle: "Pause playing media during breaks",
                                        isOn: Binding(
                                            get: { SettingsManager.shared.smartMediaControl },
                                            set: { SettingsManager.shared.smartMediaControl = $0 }
                                        )
                                    ) {
                                        // Handled by binding
                                    }
                                }
                                .padding(.leading, 16)
                            }
                        }
                    }
                    
                    Spacer(minLength: 20)
                }
                .padding()
            }
            .tabItem {
                Label("Breaks", systemImage: "clock")
            }
            .tag(0)
            
            // Reminder Settings
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HeaderView(title: "Health Reminders", subtitle: "Gentle reminders for better habits")
                    
                    SettingsCard {
                        VStack(alignment: .leading, spacing: 16) {
                            ToggleRow(
                                title: "Blink Reminders",
                                subtitle: "Keep your eyes moist and healthy",
                                isOn: $reminderManager.isBlinkReminderEnabled
                            ) {
                                reminderManager.toggleBlinkReminder()
                            }
                            
                            if reminderManager.isBlinkReminderEnabled {
                                SliderRow(
                                    title: "Blink Reminder Interval",
                                    subtitle: "How often to remind you to blink",
                                    value: Binding(
                                        get: { reminderManager.blinkReminderInterval / 60 },
                                        set: { 
                                            reminderManager.blinkReminderInterval = $0 * 60
                                            reminderManager.saveSettings()
                                        }
                                    ),
                                    range: 1...30,
                                    unit: "minutes"
                                )
                                
                                SliderRow(
                                    title: "Blink Reminder Duration",
                                    subtitle: "How long the reminder stays visible",
                                    value: Binding(
                                        get: { Double(reminderManager.blinkReminderDuration) },
                                        set: { 
                                            reminderManager.blinkReminderDuration = Int($0)
                                            reminderManager.saveSettings()
                                        }
                                    ),
                                    range: 3...15,
                                    unit: "seconds"
                                )
                            }
                            
                            Divider()
                            
                            ToggleRow(
                                title: "Posture Reminders",
                                subtitle: "Maintain good posture while working",
                                isOn: $reminderManager.isPostureReminderEnabled
                            ) {
                                reminderManager.togglePostureReminder()
                            }
                            
                            if reminderManager.isPostureReminderEnabled {
                                SliderRow(
                                    title: "Posture Reminder Interval",
                                    subtitle: "How often to check your posture",
                                    value: Binding(
                                        get: { reminderManager.postureReminderInterval / 60 },
                                        set: { 
                                            reminderManager.postureReminderInterval = $0 * 60
                                            reminderManager.saveSettings()
                                        }
                                    ),
                                    range: 5...60,
                                    unit: "minutes"
                                )
                                
                                SliderRow(
                                    title: "Posture Reminder Duration",
                                    subtitle: "How long the reminder stays visible",
                                    value: Binding(
                                        get: { Double(reminderManager.postureReminderDuration) },
                                        set: { 
                                            reminderManager.postureReminderDuration = Int($0)
                                            reminderManager.saveSettings()
                                        }
                                    ),
                                    range: 3...15,
                                    unit: "seconds"
                                )
                            }
                            
                            Divider()
                            
                            // Smart reminder options
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Smart Features")
                                    .font(.system(size: 14, weight: .medium))
                                
                                ToggleRow(
                                    title: "Skip reminders during breaks",
                                    subtitle: "Don't show reminders during active breaks",
                                    isOn: Binding(
                                        get: { SettingsManager.shared.skipRemindersInBreaks },
                                        set: { SettingsManager.shared.skipRemindersInBreaks = $0 }
                                    )
                                ) {
                                    // Handled by binding
                                }
                                
                                ToggleRow(
                                    title: "Gentle fade animations",
                                    subtitle: "Smooth appearance and disappearance",
                                    isOn: Binding(
                                        get: { SettingsManager.shared.gentleFadeAnimations },
                                        set: { SettingsManager.shared.gentleFadeAnimations = $0 }
                                    )
                                ) {
                                    // Handled by binding
                                }
                            }
                            .padding(.leading, 16)
                        }
                    }
                    
                    Spacer(minLength: 20)
                }
                .padding()
            }
            .tabItem {
                Label("Reminders", systemImage: "bell")
            }
            .tag(1)
            
            // Appearance Settings
            VStack(alignment: .leading, spacing: 20) {
                HeaderView(title: "Appearance & Behavior", subtitle: "Customize the look and feel")
                
                SettingsCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Menu Bar")
                            .font(.system(size: 16, weight: .medium))
                        
                        ToggleRow(
                            title: "Show timer in menu bar",
                            subtitle: "Display countdown in the menu bar",
                            isOn: .constant(true)
                        ) {
                            // Always enabled for now
                        }
                        
                        ToggleRow(
                            title: "Show status indicators",
                            subtitle: "Display emoji indicators for app state",
                            isOn: .constant(true)
                        ) {
                            // Always enabled for now
                        }
                        
                        Divider()
                        
                        Text("Break Overlay")
                            .font(.system(size: 16, weight: .medium))
                        
                        ToggleRow(
                            title: "Multi-screen support",
                            subtitle: "Show break overlay on all connected screens",
                            isOn: .constant(true)
                        ) {
                            // Always enabled for now
                        }
                        
                        ToggleRow(
                            title: "Glassmorphism effects",
                            subtitle: "Modern translucent overlay appearance",
                            isOn: .constant(true)
                        ) {
                            // Always enabled for now
                        }
                        
                        Divider()
                        
                        Text("Animations")
                            .font(.system(size: 16, weight: .medium))
                        
                        ToggleRow(
                            title: "Smooth transitions",
                            subtitle: "Animated overlay appearance/disappearance",
                            isOn: .constant(true)
                        ) {
                            // Always enabled for now
                        }
                        
                        ToggleRow(
                            title: "Realistic eye blinking",
                            subtitle: "Natural blinking animation for reminders",
                            isOn: .constant(true)
                        ) {
                            // Always enabled for now
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
            .tabItem {
                Label("Appearance", systemImage: "paintbrush")
            }
            .tag(2)
            
            // Advanced Settings
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HeaderView(title: "Advanced Settings", subtitle: "Fine-tune Blinkly's behavior")
                    
                    SettingsCard {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Startup & Background")
                                .font(.system(size: 16, weight: .medium))
                            
                            ToggleRow(
                                title: "Launch at login",
                                subtitle: "Start Blinkly automatically when you log in",
                                isOn: $timerManager.launchAtLogin
                            ) {
                                timerManager.launchAtLogin.toggle()
                                timerManager.saveSettings()
                            }
                            
                            ToggleRow(
                                title: "Keep running in background",
                                subtitle: "Continue working even when inactive",
                                isOn: Binding(
                                    get: { SettingsManager.shared.keepRunningInBackground },
                                    set: { SettingsManager.shared.keepRunningInBackground = $0 }
                                )
                            ) {
                                // Handled by binding
                            }
                            
                            Divider()
                            
                            Text("Keyboard & Mouse")
                                .font(.system(size: 16, weight: .medium))
                            
                            ToggleRow(
                                title: "Non-intrusive overlays",
                                subtitle: "Don't capture keyboard focus during breaks",
                                isOn: Binding(
                                    get: { SettingsManager.shared.nonIntrusiveOverlays },
                                    set: { SettingsManager.shared.nonIntrusiveOverlays = $0 }
                                )
                            ) {
                                // Handled by binding
                            }
                            
                            ToggleRow(
                                title: "Click-through reminders",
                                subtitle: "Allow interaction with apps behind reminders",
                                isOn: Binding(
                                    get: { SettingsManager.shared.clickThroughReminders },
                                    set: { SettingsManager.shared.clickThroughReminders = $0 }
                                )
                            ) {
                                // Handled by binding
                            }
                            
                            Divider()
                            
                            Text("Data & Privacy")
                                .font(.system(size: 16, weight: .medium))
                            
                            Text("Blinkly stores your preferences locally and doesn't collect any personal data. All settings are saved to your system's standard preferences location.")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                                .padding(.leading, 16)
                            
                            HStack {
                                Button("Reset All Settings") {
                                    resetAllSettings()
                                }
                                .buttonStyle(.bordered)
                                
                                Spacer()
                                
                                Button("Export Settings") {
                                    exportSettings()
                                }
                                .buttonStyle(.bordered)
                            }
                            .padding(.leading, 16)
                        }
                    }
                    
                    Spacer(minLength: 20)
                }
                .padding()
            }
            .tabItem {
                Label("Advanced", systemImage: "gearshape.2")
            }
            .tag(3)
            
            // About
            VStack(spacing: 30) {
                HeaderView(title: "About Blinkly", subtitle: "Your eye health companion")
                
                SettingsCard {
                    VStack(spacing: 20) {
                        Image(systemName: "eye.circle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .purple, .cyan],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        VStack(spacing: 8) {
                            Text("Blinkly")
                                .font(.system(size: 28, weight: .light, design: .rounded))
                            
                            Text("Version 1.0")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        
                        Text("Protect your eyes with smart break reminders and healthy habits. Built with love for digital workers everywhere.")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Divider()
                        
                        VStack(spacing: 12) {
                            HStack {
                                Text("Features")
                                    .font(.system(size: 16, weight: .medium))
                                Spacer()
                            }
                            
                            FeatureRow(icon: "clock", title: "Smart Break Reminders", description: "Customizable intervals with full-screen overlays")
                            FeatureRow(icon: "eye", title: "Blink Reminders", description: "Gentle prompts to keep your eyes healthy")
                            FeatureRow(icon: "figure.stand", title: "Posture Checks", description: "Maintain good posture while working")
                            FeatureRow(icon: "menubar.rectangle", title: "Menu Bar Integration", description: "Quick access and status display")
                            FeatureRow(icon: "display", title: "Multi-Screen Support", description: "Works seamlessly across all displays")
                        }
                        
                        Divider()
                        
                        VStack(spacing: 8) {
                            Text("Health Tips")
                                .font(.system(size: 16, weight: .medium))
                            
                            Text("The 20-20-20 rule: Every 20 minutes, look at something 20 feet away for 20 seconds. Blinkly helps you follow this and other healthy computer habits.")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding()
                }
                
                Spacer()
            }
            .padding()
            .tabItem {
                Label("About", systemImage: "info.circle")
            }
            .tag(4)
        }
        .frame(width: 650, height: 500)
        // Present Add Custom Preset sheet
        .sheet(isPresented: $showAddPresetSheet) {
            AddPresetSheet(
                timerManager: timerManager,
                reminderManager: reminderManager
            )
        }
    }
    
    private func resetAllSettings() {
        let alert = NSAlert()
        alert.messageText = "Reset All Settings"
        alert.informativeText = "Are you sure you want to reset all settings to their default values? This action cannot be undone."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Reset")
        alert.addButton(withTitle: "Cancel")
        
        if alert.runModal() == .alertFirstButtonReturn {
            // Reset settings manager
            SettingsManager.shared.resetToDefaults()
            
            // Reset to defaults
            timerManager.breakInterval = 1200 // 20 minutes default
            timerManager.breakDuration = 20 // 20 seconds default
            timerManager.isEnabled = true
            timerManager.autoStartTimer = true
            timerManager.launchAtLogin = false
            timerManager.saveSettings()
            
            reminderManager.blinkReminderInterval = 1200 // 20 minutes default
            reminderManager.postureReminderInterval = 1800 // 30 minutes default
            reminderManager.blinkReminderDuration = 5 // 5 seconds default
            reminderManager.postureReminderDuration = 5 // 5 seconds default
            reminderManager.isBlinkReminderEnabled = true
            reminderManager.isPostureReminderEnabled = true
            reminderManager.saveSettings()
        }
    }
    
    private func exportSettings() {
        let panel = NSSavePanel()
        panel.title = "Export Blinkly Settings"
        panel.nameFieldStringValue = "blinkly-settings.json"
        panel.allowedContentTypes = [.json]
        
        if panel.runModal() == .OK, let url = panel.url {
            let settings = [
                "breakInterval": timerManager.breakInterval,
                "breakDuration": timerManager.breakDuration,
                "timerEnabled": timerManager.isEnabled,
                "autoStartTimer": timerManager.autoStartTimer,
                "launchAtLogin": timerManager.launchAtLogin,
                "blinkReminderInterval": reminderManager.blinkReminderInterval,
                "postureReminderInterval": reminderManager.postureReminderInterval,
                "blinkReminderDuration": reminderManager.blinkReminderDuration,
                "postureReminderDuration": reminderManager.postureReminderDuration,
                "blinkReminderEnabled": reminderManager.isBlinkReminderEnabled,
                "postureReminderEnabled": reminderManager.isPostureReminderEnabled
            ] as [String: Any]
            
            do {
                let data = try JSONSerialization.data(withJSONObject: settings, options: .prettyPrinted)
                try data.write(to: url)
            } catch {
                let alert = NSAlert()
                alert.messageText = "Export Failed"
                alert.informativeText = "Failed to export settings: \(error.localizedDescription)"
                alert.alertStyle = .critical
                alert.runModal()
            }
        }
    }
}

struct HeaderView: View {
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 24, weight: .medium, design: .rounded))
            
            Text(subtitle)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
    }
}

struct SettingsCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(20)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.quaternary, lineWidth: 1)
            )
    }
}

struct ToggleRow: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    let action: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .onChange(of: isOn) { _ in
                    action()
                }
        }
    }
}

struct SliderRow: View {
    let title: String
    let subtitle: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let unit: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 14, weight: .medium))
                    
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text("\(Int(value)) \(unit)")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            
            Slider(value: $value, in: range, step: 1)
                .accentColor(.blue)
        }
        .padding(.leading, 16)
    }
}

struct PresetButton: View {
    let title: String
    let subtitle: String
    let minutes: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(8)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
    }
}

struct PresetInfoView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Break Presets")
                .font(.system(size: 16, weight: .medium))
            
            VStack(alignment: .leading, spacing: 8) {
                PresetInfoRow(title: "20-20-20 Rule", description: "Based on eye care recommendations - look away every 20 minutes")
                PresetInfoRow(title: "Pomodoro", description: "Traditional productivity technique with 25-minute focus sessions")
                PresetInfoRow(title: "Short Breaks", description: "Frequent 15-minute intervals for intensive work")
                PresetInfoRow(title: "Deep Focus", description: "Longer 45-minute sessions for complex tasks")
            }
        }
        .padding()
        .frame(width: 300)
    }
}

struct PresetInfoRow: View {
    let title: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
            
            Text(description)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .frame(width: 20)
                .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                
                Text(description)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

// Custom Preset Management Components
struct CustomPresetButton: View {
    let preset: SettingsManager.CustomPreset
    let isSelected: Bool
    let onSelect: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(preset.name)
                    .font(.system(size: 14, weight: .medium))
                
                Text("Break: \(Int(preset.breakDuration))s / \(Int(preset.breakInterval))min")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.blue)
                    .font(.system(size: 16))
            }
            
            Button("Apply") {
                onSelect()
            }
            .buttonStyle(.borderless)
            .font(.system(size: 12))

            Button("Delete") {
                onDelete()
            }
            .buttonStyle(.borderless)
            .foregroundColor(.red)
            .font(.system(size: 12))
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.blue.opacity(0.1) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.blue : Color.secondary.opacity(0.3), lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
    }
}

struct AddPresetSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var timerManager: TimerManager
    @ObservedObject var reminderManager: ReminderManager
    @ObservedObject var settingsManager = SettingsManager.shared
    
    @State private var presetName = ""
    @State private var useCurrentSettings = true
    @State private var customBreakDuration = 20.0
    @State private var customBreakInterval = 20.0
    @State private var customBlinkInterval = 20.0
    @State private var customPostureInterval = 30.0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Add Custom Preset")
                .font(.system(size: 18, weight: .medium))
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Preset Name")
                    .font(.system(size: 14, weight: .medium))
                
                TextField("Enter preset name", text: $presetName)
                    .textFieldStyle(.roundedBorder)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Toggle("Use current settings", isOn: $useCurrentSettings)
                    .font(.system(size: 14, weight: .medium))
                
                if !useCurrentSettings {
                    VStack(alignment: .leading, spacing: 8) {
                        SliderRow(
                            title: "Break Duration",
                            subtitle: "How long each break lasts",
                            value: $customBreakDuration,
                            range: 10...300,
                            unit: "seconds"
                        )
                        
                        SliderRow(
                            title: "Break Interval",
                            subtitle: "Time between breaks",
                            value: $customBreakInterval,
                            range: 5...120,
                            unit: "minutes"
                        )
                        
                        SliderRow(
                            title: "Blink Reminder",
                            subtitle: "Interval for blink reminders",
                            value: $customBlinkInterval,
                            range: 5...60,
                            unit: "seconds"
                        )
                        
                        SliderRow(
                            title: "Posture Reminder",
                            subtitle: "Interval for posture reminders",
                            value: $customPostureInterval,
                            range: 10...120,
                            unit: "minutes"
                        )
                    }
                    .padding(.leading, 20)
                }
            }
            
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Add Preset") {
                    addPreset()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(presetName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(24)
        .frame(width: 400)
    }
    
    private func addPreset() {
        // Convert current settings to expected units for CustomPreset:
        // - breakDuration: seconds (already seconds)
        // - breakInterval: minutes (convert from timerManager.seconds)
        // - blinkInterval: seconds (already seconds)
        // - postureInterval: minutes (convert from reminderManager.seconds)
        let preset = SettingsManager.CustomPreset(
            id: UUID(),
            name: presetName.trimmingCharacters(in: .whitespacesAndNewlines),
            breakDuration: useCurrentSettings ? timerManager.breakDuration : customBreakDuration,
            breakInterval: useCurrentSettings ? (timerManager.breakInterval / 60) : customBreakInterval,
            blinkInterval: useCurrentSettings ? reminderManager.blinkReminderInterval : customBlinkInterval,
            postureInterval: useCurrentSettings ? (reminderManager.postureReminderInterval / 60) : customPostureInterval
        )
        
    settingsManager.addCustomPreset(preset)
    // Auto-apply and select the newly added preset
    timerManager.applyCustomPreset(preset)
    }
}

#Preview {
    SettingsView()
        .environmentObject(TimerManager())
        .environmentObject(ReminderManager())
}
