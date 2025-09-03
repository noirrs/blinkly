import SwiftUI

// Floating countdown view with smooth design
struct FloatingCountdownView: View {
    @ObservedObject var timerManager: TimerManager
    @State private var pulseScale: CGFloat = 1.0
    @State private var opacity: Double = 0.0
    
    var body: some View {
        HStack(spacing: 12) {
            // Eye icon
            Image(systemName: "eye.fill")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white)
                .scaleEffect(pulseScale)
            
            Text("Break in \(formatTime(timerManager.timeUntilNextBreak))")
                .font(.system(size: 16, weight: .semibold, design: .default))
                .foregroundColor(.white)
                .fixedSize(horizontal: true, vertical: false)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .frame(minWidth: 180)
        .background(
            Capsule()
                .fill(.black.opacity(0.8))
                .overlay(
                    Capsule()
                        .stroke(.white.opacity(0.3), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
        .opacity(opacity)
        .scaleEffect(timerManager.isCountdownVisible ? 1.0 : 0.8)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: timerManager.isCountdownVisible)
        .onAppear {
            startAnimations()
        }
    }
    
    private func startAnimations() {
        withAnimation(.easeInOut(duration: 0.8)) {
            opacity = 1.0
        }
        
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            pulseScale = 1.1
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let seconds = Int(time)
        return "\(seconds)s"
    }
}

#Preview {
    FloatingCountdownView(timerManager: TimerManager())
        .background(Color.blue) // For preview only
}
