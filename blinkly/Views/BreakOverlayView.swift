import SwiftUI
import AppKit
import MediaPlayer

struct BreakOverlayView: View {
    @ObservedObject var timerManager: TimerManager
    @State private var skipMessageVisible = false
    @State private var debugMode = false
    @State private var overlayScale: CGFloat = 0.8
    @State private var overlayOpacity: Double = 0.0
    @State private var wasPlayingBeforePause = false
    @State private var mediaStateChecked = false
    @State private var appsWeActuallyPaused: Set<String> = [] // Track which apps we paused
    @State private var showSkipConfirmation = false
    @State private var skipButtonScale: CGFloat = 1.0
    
    var body: some View {
        GeometryReader { geo in
            // Use full screen frame
            let screenFrame = NSScreen.main?.frame ?? geo.frame(in: .global)
            let width = screenFrame.width
            let height = screenFrame.height
            
            ZStack {
                // Background
                if debugMode {
                    Rectangle()
                        .fill(Color.red)
                        .ignoresSafeArea()
                } else {
                    HighResWallpaperView()
                        .frame(width: width, height: height)
                        .ignoresSafeArea()
                        .blur(radius: width * 0.01)
                    
                    Rectangle()
                        .fill(Color.black.opacity(0.7))
                        .ignoresSafeArea()
                }
                
                VStack(spacing: height * 0.02) {
                    // Top debug controls
                    if debugMode {
                        HStack {
                            Circle()
                                .fill(Color.red)
                                .frame(width: max(40, width * 0.05), height: max(40, width * 0.05))
                                .background(
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: max(60, width * 0.07), height: max(60, width * 0.07))
                                )
                                .shadow(radius: 12)
                            
                            Button("🔴 DEBUG") {
                                debugMode.toggle()
                            }
                            .foregroundColor(.white)
                            .font(.system(size: max(14, width * 0.015), weight: .bold))
                            .padding(6)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .foregroundColor(.black)
                                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.red, lineWidth: 2))
                            )
                            
                            Spacer()
                        }
                        .padding(.top, max(20, height * 0.02))
                        .padding(.horizontal, max(16, width * 0.02))
                    }
                    
                    Spacer()
                    
                    // Timer + Title + Subtitle
                    if width < 900 {
                        // Narrow screens: vertical stack
                        VStack(spacing: height * 0.03) {
                            timerText(width: width, height: height)
                            titleAndSubtitle(width: width, height: height)
                        }
                        .padding(.horizontal, width * 0.05)
                    } else {
                        // Wide screens: horizontal layout
                        HStack(spacing: width * 0.05) {
                            timerText(width: width, height: height)
                            titleAndSubtitle(width: width, height: height)
                        }
                        .padding(.horizontal, width * 0.05)
                    }
                    
                    // Remove curved progress since user requested without graph
                    
                    // Skip message
                    if skipMessageVisible {
                        Text("Oops! Break skipped.\nLet's get back on track.")
                            .font(.system(size: max(14, width * 0.015), weight: .semibold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .shadow(color: .black, radius: 2, x: 0, y: 0)
                            .shadow(color: .black.opacity(0.6), radius: 6, x: 0, y: 0)
                            .padding(.top, height * 0.02)
                    }
                    
                    Spacer()
                    
                    // Bottom controls
                    HStack(spacing: width * 0.03) {
                        Spacer()
                        Text(getCurrentTime())
                            .font(.system(size: max(12, width * 0.012)))
                            .foregroundColor(.white)
                            .shadow(color: .black, radius: 1, x: 0, y: 0)
                            .shadow(color: .black.opacity(0.5), radius: 3, x: 0, y: 0)
                        
                        Button(action: {
                            if !showSkipConfirmation {
                                // First tap - show confirmation
                                showSkipConfirmation = true
                                
                                // Add pulse animation
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    skipButtonScale = 1.1
                                }
                                withAnimation(.easeInOut(duration: 0.3).delay(0.3)) {
                                    skipButtonScale = 1.0
                                }
                                
                                // Hide confirmation after 3 seconds
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        showSkipConfirmation = false
                                    }
                                }
                            } else {
                                // Second tap - actually skip
                                if let sound = NSSound(named: "Tink") {
                                    sound.volume = 1.0
                                    sound.play()
                                }
                                
                                timerManager.skipBreak()
                                skipMessageVisible = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                                    skipMessageVisible = false
                                }
                            }
                        }) {
                            HStack(spacing: 6) {
                                Text(showSkipConfirmation ? "Sure?" : "Skip")
                                    .font(.system(size: max(14, width * 0.012), weight: .medium))
                                Image(systemName: showSkipConfirmation ? "questionmark" : "chevron.right.2")
                                    .font(.system(size: max(10, width * 0.008), weight: .medium))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(showSkipConfirmation ? Color.red.opacity(0.3) : Color.clear)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(showSkipConfirmation ? Color.red.opacity(0.6) : Color.white.opacity(0.3), lineWidth: showSkipConfirmation ? 2 : 1)
                                    )
                            )
                            .scaleEffect(skipButtonScale)
                            .animation(.easeInOut(duration: 0.2), value: showSkipConfirmation)
                        }
                        .buttonStyle(PlainButtonStyle())
                        Spacer()
                    }
                    .padding(.bottom, max(18, height * 0.03))
                }
                .frame(width: width, height: height)
            }
        }
        .scaleEffect(overlayScale)
        .opacity(overlayOpacity)
        .onAppear {
            print("🔥 BreakOverlayView appeared - fully responsive layout")
            
            // Show overlay immediately, then check media state in background
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                overlayScale = 1.0
                overlayOpacity = 1.0
            }
            
            // Play opening sound immediately
            if let sound = NSSound(named: "Glass") {
                sound.volume = 1.0
                sound.play()
            }
            
            // Check media state in background to avoid blocking UI
            DispatchQueue.global(qos: .userInitiated).async {
                self.checkCurrentMediaState()
                
                // Pause media on main thread after checking
                DispatchQueue.main.async {
                    if self.wasPlayingBeforePause {
                        self.pauseBackgroundMedia()
                    }
                }
            }
        }
        .onDisappear {
            print("🎵 Media control disabled to prevent keyboard interference")
            
            // Only resume if we paused it and it was playing before
            if wasPlayingBeforePause {
                resumeBackgroundMedia()
            }
            
            // Play closing sound at max volume
            if let sound = NSSound(named: "Blow") {
                sound.volume = 1.0
                sound.play()
            }
        }
    }
    
    @ViewBuilder
    private func timerText(width: CGFloat, height: CGFloat) -> some View {
        Text(formatTime(timerManager.currentBreakTimeRemaining))
            .font(.system(size: max(40, min(120, min(width * 0.12, height * 0.35))), weight: .light, design: .default))
            .foregroundColor(.white)
            .lineLimit(1)
            .minimumScaleFactor(0.25)
            .shadow(color: .black, radius: 3, x: 0, y: 0)
            .shadow(color: .black.opacity(0.8), radius: 8, x: 0, y: 0)
    }
    
    @ViewBuilder
    private func titleAndSubtitle(width: CGFloat, height: CGFloat) -> some View {
        VStack(alignment: .center, spacing: height * 0.01) {
            Text("Rest Your Eyes, Refresh Your Mind")
                .font(.system(size: max(24, min(48, width * 0.05)), weight: .semibold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .shadow(color: .black, radius: 2, x: 0, y: 0)
                .shadow(color: .black.opacity(0.6), radius: 6, x: 0, y: 0)
            
            Text("Gentle reminders to protect your vision and boost focus. Take a moment - your eyes deserve it.")
                .font(.system(size: max(12, min(20, width * 0.03))))
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .frame(maxWidth: width * 0.85)
                .shadow(color: .black, radius: 1, x: 0, y: 0)
                .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 0)
        }
    }
    
    private func getCurrentTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: Date())
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // MARK: - Media Control Functions
    private func checkCurrentMediaState() {
        wasPlayingBeforePause = false
        mediaStateChecked = true
        appsWeActuallyPaused.removeAll() // Clear previous state
        
        // Check if any media apps are currently playing
        let runningApps = NSWorkspace.shared.runningApplications
        let runningAppNames = runningApps.compactMap { $0.localizedName }
        
        // Check Spotify state
        if runningAppNames.contains("Spotify") {
            if checkSpotifyPlaying() {
                wasPlayingBeforePause = true
                appsWeActuallyPaused.insert("Spotify")
                print("🎵 Spotify is currently playing - will pause and resume")
            } else {
                print("🎵 Spotify is running but not playing - will not interfere")
            }
        }
        
        // Check Apple Music state
        if runningAppNames.contains("Music") {
            if checkAppleMusicPlaying() {
                wasPlayingBeforePause = true
                appsWeActuallyPaused.insert("Music")
                print("🎵 Apple Music is currently playing - will pause and resume")
            } else {
                print("🎵 Apple Music is running but not playing - will not interfere")
            }
        }
        
        // For browsers, we'll be more conservative and only pause if we detect active media
        // (More complex detection would require browser extensions)
        if runningAppNames.contains("Safari") || runningAppNames.contains("Google Chrome") {
            // For now, we'll assume browser media might be playing but won't auto-resume
            print("🎵 Browser detected - will pause but not auto-resume to avoid interfering with user-paused content")
        }
        
        if appsWeActuallyPaused.isEmpty {
            print("🎵 No actively playing media detected - no interference needed")
        } else {
            print("🎵 Will pause and resume: \(appsWeActuallyPaused.joined(separator: ", "))")
        }
    }
    
    private func checkSpotifyPlaying() -> Bool {
        let script = """
        tell application "Spotify"
            if it is running then
                return player state as string
            end if
        end tell
        """
        
        let appleScript = NSAppleScript(source: script)
        var error: NSDictionary?
        
        // Add timeout to prevent hanging
        let startTime = Date()
        let result = appleScript?.executeAndReturnError(&error)
        let executionTime = Date().timeIntervalSince(startTime)
        
        if executionTime > 1.0 {
            print("⚠️ Spotify check took \(executionTime)s - too slow")
        }
        
        if let stringResult = result?.stringValue {
            return stringResult == "playing"
        }
        return false
    }
    
    private func checkAppleMusicPlaying() -> Bool {
        let script = """
        tell application "Music"
            if it is running then
                return player state as string
            end if
        end tell
        """
        
        let appleScript = NSAppleScript(source: script)
        var error: NSDictionary?
        
        // Add timeout to prevent hanging
        let startTime = Date()
        let result = appleScript?.executeAndReturnError(&error)
        let executionTime = Date().timeIntervalSince(startTime)
        
        if executionTime > 2.0 {
            print("⚠️ Apple Music check took \(executionTime)s - too slow")
        }
        
        if let stringResult = result?.stringValue {
            return stringResult == "playing"
        }
        return false
    }
    
    private func pauseBackgroundMedia() {
        print("🎵 Attempting to pause background media for: \(appsWeActuallyPaused.joined(separator: ", "))")
        
        // Only pause the apps that we detected were actually playing
        pauseWithAppleScript()
        
        // Method 2: Try system media keys as fallback (disabled to prevent keyboard interference)
        // sendMediaKeyEvent(play: false)
    }
    
    private func resumeBackgroundMedia() {
        print("🎵 Attempting to resume background media for: \(appsWeActuallyPaused.joined(separator: ", "))")
        
        // Only resume the apps that we actually paused
        playWithAppleScript()
        
        // Method 2: Try system media keys as fallback (disabled to prevent keyboard interference)
        // sendMediaKeyEvent(play: true)
        
        // Clear the tracking after resuming
        wasPlayingBeforePause = false
        appsWeActuallyPaused.removeAll()
    }
    
    private func pauseWithAppleScript() {
        // Only send pause commands to apps that we detected were playing
        
        // Check and pause Spotify if we detected it was playing
        if appsWeActuallyPaused.contains("Spotify") {
            executeAppleScript("tell application \"Spotify\" to pause")
        }
        
        // Check and pause Apple Music if we detected it was playing
        if appsWeActuallyPaused.contains("Music") {
            executeAppleScript("tell application \"Music\" to pause")
        }
        
        // For browsers, pause all videos but be conservative about resuming
        let runningApps = NSWorkspace.shared.runningApplications
        let runningAppNames = runningApps.compactMap { $0.localizedName }
        
        // Still pause browser videos but don't track them for auto-resume
        if runningAppNames.contains("Safari") {
            executeAppleScript("tell application \"Safari\" to tell front document to do JavaScript \"document.querySelectorAll('video, audio').forEach(el => el.pause())\"")
        }
        
        if runningAppNames.contains("Google Chrome") {
            executeAppleScript("tell application \"Google Chrome\" to tell active tab of front window to execute javascript \"document.querySelectorAll('video, audio').forEach(el => el.pause())\"")
        }
        
        // VLC - only pause if we can detect it's playing (conservative approach)
        if runningAppNames.contains("VLC") {
            executeAppleScript("tell application \"VLC\" to pause")
        }
    }
    
    private func playWithAppleScript() {
        // Only send play commands to apps that we actually paused (and thus were playing before)
        
        // Check and resume Spotify only if we paused it
        if appsWeActuallyPaused.contains("Spotify") {
            executeAppleScript("tell application \"Spotify\" to play")
        }
        
        // Check and resume Apple Music only if we paused it
        if appsWeActuallyPaused.contains("Music") {
            executeAppleScript("tell application \"Music\" to play")
        }
        
        // For browsers, don't auto-resume to avoid interfering with user-paused content
        // User can manually resume if they want
        
        // For VLC, don't auto-resume as it's often used for intentional pausing
        
        print("🎵 Only resumed apps that were actively playing before break: \(appsWeActuallyPaused.joined(separator: ", "))")
    }
    
    private func executeAppleScript(_ script: String) {
        // Execute AppleScript asynchronously to avoid blocking UI
        DispatchQueue.global(qos: .utility).async {
            let appleScript = NSAppleScript(source: script)
            var error: NSDictionary?
            let startTime = Date()
            
            appleScript?.executeAndReturnError(&error)
            
            let executionTime = Date().timeIntervalSince(startTime)
            if executionTime > 0.5 {
                print("⚠️ AppleScript took \(executionTime)s: \(script.prefix(30))...")
            }
            
            if error != nil {
                // Silently fail - app might not be running
            }
        }
    }
    
    private func sendMediaKeyEvent(play: Bool) {
        // DISABLED: Media key events were causing 'y' to be typed
        // This was the source of the keyboard interference problem
        print("🎵 Media control disabled to prevent keyboard interference")
        
        /*
        // Use correct media key codes - 0x10 was causing 'y' to be typed!
        let source = CGEventSource(stateID: .hidSystemState)
        
        // Correct media key codes for macOS
        let playPauseKeyCode: CGKeyCode = 0x49 // Actual Play/Pause media key
        
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: playPauseKeyCode, keyDown: true)
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: playPauseKeyCode, keyDown: false)
        
        // Use proper media key flags
        keyDown?.flags = .maskSecondaryFn
        keyUp?.flags = .maskSecondaryFn
        
        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
        */
    }
}

// Curved progress view (scales with window)
struct CurvedProgressView: View {
    var body: some View {
        GeometryReader { g in
            let w = g.size.width
            let h = g.size.height
            let leftX = w * 0.08
            let rightX = w * 0.92
            let centerX = w / 2
            let baseY = h * 0.6

            ZStack {
                Path { path in
                    path.move(to: CGPoint(x: leftX, y: baseY))
                    path.addQuadCurve(to: CGPoint(x: rightX, y: baseY), control: CGPoint(x: centerX, y: h * 0.12))
                }
                .stroke(Color.white.opacity(0.28), lineWidth: max(2, h * 0.02))

                Path { path in
                    path.move(to: CGPoint(x: leftX, y: baseY))
                    path.addQuadCurve(to: CGPoint(x: centerX + (w * 0.2), y: baseY - (h * 0.12)), control: CGPoint(x: centerX - (w * 0.12), y: h * 0.08))
                }
                .stroke(LinearGradient(colors: [.green, .yellow, .orange], startPoint: .leading, endPoint: .trailing), lineWidth: max(3, h * 0.025))

                Circle()
                    .fill(Color.orange)
                    .frame(width: max(10, h * 0.12), height: max(10, h * 0.12))
                    .shadow(color: Color.orange.opacity(0.6), radius: 8)
                    .position(x: centerX + (w * 0.2), y: baseY - (h * 0.12))
            }
        }
    }
}

// High-resolution wallpaper with gradient fallback
struct HighResWallpaperView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSImageView {
        let imageView = NSImageView()
        imageView.imageScaling = .scaleAxesIndependently
        imageView.imageAlignment = .alignCenter
        
        // Set immediate background color for instant display
        imageView.wantsLayer = true
        imageView.layer?.backgroundColor = NSColor(calibratedRed: 0.12, green: 0.32, blue: 0.18, alpha: 1.0).cgColor

        // Load wallpaper asynchronously to avoid blocking UI
        DispatchQueue.global(qos: .utility).async {
            let image: NSImage?
            
            // Try to load bundled wallpaper resource
            if let wallpaperURL = Bundle.main.url(forResource: "break-wallpaper", withExtension: "png"),
               let img = NSImage(contentsOf: wallpaperURL) {
                image = img
                print("✅ Loaded bundled wallpaper from app resources")
            } else {
                // Create a smaller, simpler gradient for better performance
                let size = CGSize(width: 800, height: 600) // Smaller size for better performance
                image = NSImage(size: size, flipped: false) { rect in
                    let colors = [
                        NSColor(calibratedRed: 0.12, green: 0.32, blue: 0.18, alpha: 1.0),
                        NSColor(calibratedRed: 0.06, green: 0.22, blue: 0.12, alpha: 1.0)
                    ]
                    NSGradient(colors: colors)?.draw(in: rect, angle: 45)
                    return true
                }
                print("✅ Using optimized gradient fallback wallpaper")
            }
            
            // Update on main thread
            DispatchQueue.main.async {
                imageView.image = image
            }
        }

        return imageView
    }

    func updateNSView(_ nsView: NSImageView, context: Context) {}
}

#Preview {
    BreakOverlayView(timerManager: {
        let manager = TimerManager()
        manager.isBreakActive = true
        manager.currentBreakTimeRemaining = 27
        return manager
    }())
    .background(Color.black)
}