import SwiftUI

/// A small struct that holds yaw and pitch values.
/// Marked `Equatable` so we can use `onChange(of:)`.
struct YawPitch: Equatable {
    let yaw: Double
    let pitch: Double
}

struct ContentView: View {
    @StateObject private var headTiltDetector = HeadTiltDetector()
    
    // Square properties
    @State private var squarePosition: CGPoint = .zero
    @State private var squareColor: Color = .black
    @State private var collisionDetected = false
    
    let squareSize: CGFloat = 50
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.white.ignoresSafeArea()
                
                // Blue dot whose position depends on yaw/pitch
                Circle()
                    .fill(Color.blue)
                    .frame(width: 30, height: 30)
                    .position(
                        x: calculateX(in: geometry.size, yaw: headTiltDetector.yaw),
                        y: calculateY(in: geometry.size, pitch: headTiltDetector.pitch)
                    )
                
                // Square (target)
                Rectangle()
                    .fill(squareColor)
                    .frame(width: squareSize, height: squareSize)
                    .position(squarePosition)
                
                // Debug info at the bottom
                VStack {
                    Spacer()
                    Text("Yaw: \(headTiltDetector.yaw, specifier: "%.2f")°")
                    Text("Pitch: \(headTiltDetector.pitch, specifier: "%.2f")°")
                    Text("Roll: \(headTiltDetector.roll, specifier: "%.2f")°")
                        .padding(.bottom, 20)
                }
            }
            // Start/stop head tracking
            .onAppear {
                headTiltDetector.startDetectingHeadTilt()
                
                // Initialize square in center if not set yet
                if squarePosition == .zero {
                    squarePosition = CGPoint(
                        x: geometry.size.width / 2,
                        y: geometry.size.height / 2
                    )
                }
            }
            .onDisappear {
                headTiltDetector.stopDetectingHeadTilt()
            }
            // Use the YawPitch struct to avoid tuple Equatable issues
            .onChange(of: YawPitch(yaw: headTiltDetector.yaw, pitch: headTiltDetector.pitch)) { newValue in
                let dotX = calculateX(in: geometry.size, yaw: newValue.yaw)
                let dotY = calculateY(in: geometry.size, pitch: newValue.pitch)
                checkCollision(dotX: dotX, dotY: dotY, geometrySize: geometry.size)
            }
        }
    }
    
    // MARK: - Mapping Functions
    
    /// Convert yaw (±45°) into a horizontal screen position (0...width).
    /// We invert the mapping so positive yaw (head turned left) moves the dot left.
    private func calculateX(in size: CGSize, yaw: Double) -> CGFloat {
        let minYaw: Double = -45
        let maxYaw: Double = 45
        let clampedYaw = min(max(yaw, minYaw), maxYaw)
        
        // Invert: high yaw => smaller normalized => dot on left
        let normalized = (maxYaw - clampedYaw) / (maxYaw - minYaw)
        return CGFloat(normalized) * size.width
    }
    
    /// Convert pitch (±45°) into a vertical screen position (0...height).
    /// We invert so that a higher pitch (looking up) moves the dot upward.
    private func calculateY(in size: CGSize, pitch: Double) -> CGFloat {
        let minPitch: Double = -45
        let maxPitch: Double = 45
        let clampedPitch = min(max(pitch, minPitch), maxPitch)
        
        let normalized = (clampedPitch - minPitch) / (maxPitch - minPitch)
        return size.height - CGFloat(normalized) * size.height
    }
    
    // MARK: - Collision Detection
    
    /// Checks if the dot collides with the square.
    /// If collision occurs, turn square green, wait 3s, then move it & revert to black.
    private func checkCollision(dotX: CGFloat, dotY: CGFloat, geometrySize: CGSize) {
        if !collisionDetected &&
            abs(dotX - squarePosition.x) < squareSize / 2 &&
            abs(dotY - squarePosition.y) < squareSize / 2 {
            
            collisionDetected = true
            squareColor = .green
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                // Random new position for the square
                squarePosition = CGPoint(
                    x: CGFloat.random(in: squareSize/2 ... geometrySize.width - squareSize/2),
                    y: CGFloat.random(in: squareSize/2 ... geometrySize.height - squareSize/2)
                )
                squareColor = .black
                collisionDetected = false
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
