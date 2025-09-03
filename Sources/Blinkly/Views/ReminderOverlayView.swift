import SwiftUI

struct ReminderOverlayView: View {
    let reminderType: ReminderType
    let message: String
    let onDismiss: () -> Void
    
    @State private var opacity: Double = 0.0
    @State private var scale: CGFloat = 0.8
    @State private var iconScale: CGFloat = 1.0
    @State private var iconRotation: Double = 0.0
    @State private var blinkAnimation: CGFloat = 1.0
    @State private var pulseScale: CGFloat = 1.0
    @State private var postureOffset: CGFloat = 0.0  // For upward movement
    @State private var backgroundPulse: CGFloat = 1.0  // For background animation
    
    enum ReminderType {
        case blink, posture
        
        var icon: String {
            switch self {
            case .blink: return "eye.fill"      // Use actual eye icon for realistic blinking
            case .posture: return "chevron.up"   // Up arrow for posture
            }
        }
        
        var backgroundGradient: [Color] {
            switch self {
            case .blink: 
                // Pink/purple gradient matching LookAway blink screenshot exactly
                return [
                    Color(red: 1.0, green: 0.6, blue: 0.8),  // Light pink center
                    Color(red: 0.8, green: 0.4, blue: 0.9)   // Purple edge
                ]
            case .posture:
                // Pink/orange gradient matching LookAway posture screenshot exactly
                return [
                    Color(red: 1.0, green: 0.7, blue: 0.8),  // Light pink center
                    Color(red: 1.0, green: 0.5, blue: 0.3)   // Orange edge
                ]
            }
        }
    }
    
    var body: some View {
        ZStack {
            // LookAway exact design - thick black border with gradient fill
            ZStack {
                // Thick black outer ring - NO scaling to keep clean
                Circle()
                    .fill(.black)
                    .frame(width: 80, height: 80)
                
                // Inner gradient circle - NO scaling to keep clean
                Circle()
                    .fill(
                        RadialGradient(
                            colors: reminderType.backgroundGradient,
                            center: .center,
                            startRadius: 5,
                            endRadius: 30
                        )
                    )
                    .frame(width: 64, height: 64)
                
                // LookAway exact icons with enhanced animations
                if reminderType == .blink {
                    // Realistic blinking eye - scales vertically to simulate blinking
                    Image(systemName: "eye.fill")
                        .font(.system(size: 18, weight: .black))
                        .foregroundStyle(.black)
                        .scaleEffect(x: 1.0, y: blinkAnimation) // Only vertical scaling for realistic blink
                } else {
                    // Posture arrow with upward movement - NO background scaling
                    Image(systemName: "chevron.up")
                        .font(.system(size: 16, weight: .black))
                        .foregroundStyle(.black)
                        .offset(y: postureOffset)  // Only upward movement, no scaling
                }
            }
            .scaleEffect(pulseScale) // Only overall pulse, not background
        }
        .scaleEffect(scale)
        .opacity(opacity)
        .onAppear {
            startLookAwayExactAnimations()
            startAutoDismiss()
        }
        .onTapGesture {
            dismissWithAnimation()
        }
    }
    
    private func startLookAwayExactAnimations() {
        // LookAway entrance animation
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            opacity = 1.0
            scale = 1.0
        }
        
        // Enhanced pulse effect - NO background scaling for better look
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            pulseScale = 1.03  // Very subtle overall pulse only
        }
        
        // Type-specific LookAway animations
        if reminderType == .blink {
            startLookAwayBlinkAnimation()
        } else {
            startLookAwayPostureAnimation()
        }
    }
    
    private func startLookAwayBlinkAnimation() {
        // Realistic eye blinking - eye closes and opens naturally
        let blinkSequence = {
            withAnimation(.easeInOut(duration: 0.1)) {
                blinkAnimation = 0.1  // Close eye (flatten vertically)
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.15)) {
                    blinkAnimation = 1.0  // Open eye back to normal
                }
            }
        }
        
        // Start immediate blink
        blinkSequence()
        
        // Repeat every 2.5 seconds for natural blinking rhythm
        Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { timer in
            guard opacity > 0.5 else {
                timer.invalidate()
                return
            }
            blinkSequence()
        }
    }
    
    private func startLookAwayPostureAnimation() {
        // Clean posture animation - ONLY arrow movement, NO background scaling
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            postureOffset = -6.0  // Move 6 pixels upward smoothly
        }
        
        // NO background pulse or scaling for posture - keep it clean
    }
    
    private func startAutoDismiss() {
        // LookAway timing - 4 seconds visible
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            dismissWithAnimation()
        }
    }
    
    private func dismissWithAnimation() {
        withAnimation(.easeOut(duration: 0.3)) {
            opacity = 0.0
            scale = 0.8
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onDismiss()
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        HStack(spacing: 60) {
            ReminderOverlayView(
                reminderType: .blink,
                message: "",
                onDismiss: {}
            )
            
            ReminderOverlayView(
                reminderType: .posture,
                message: "",
                onDismiss: {}
            )
        }
    }
}
