import SwiftUI
import AVFoundation

/// A small struct that holds yaw and pitch values.
/// Marked `Equatable` so we can use `onChange(of:)`.
struct YawPitch: Equatable {
    let yaw: Double
    let pitch: Double
}

struct SplashScreenView: View {
    @State private var isActive = false
    @State private var opacity = 0.0
  

    var body: some View {
        if isActive {
            ContentView() // Go to main screen after animation
        } else {
            VStack {
                Image("flower_purple") // Your logo
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 150)
                    .opacity(opacity)
                    .onAppear {
                        withAnimation(.easeIn(duration: 2.0)) {
                            opacity = 1.0
                        }
                    }
                Image("bzzz")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
            }
            .onAppear {
                AudioManager.shared.playSound("bee_sound")
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    withAnimation {
                        isActive = true
                    }
                }
            }
        }
    }
}

struct ContentView: View {
    @StateObject private var headTiltDetector = HeadTiltDetector()
    
    // Square properties
    @State private var squarePosition: CGPoint = .zero
    @State private var squareImage: String = "flower_black" // Initial image
    @State private var collisionDetected = false
    @State private var audioPlayer: AVAudioPlayer?
    
    @State private var gamesPlayed: Int = 0 // Track the number of games played
       
    // Game time properties
    @State private var timeRemaining: Int = 60
    @State private var gameEnded = false
    @State private var fadeInText = false

    @State private var restartTimer: Timer?
    @State private var countdownToRestart = 7 // 7 seconds countdown
    
    // New state variable to trigger the restart screen
    @State private var showRestartScreen = false
    
    // Bee trail state: record positions of the bug
    @State private var beeTrail: [CGPoint] = []
    
    let squareSize: CGFloat = 75
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.white.ignoresSafeArea()
                
                // Draw the bee trail behind everything
                BeeTrailView(points: beeTrail)
                
                // Square (target)
                ZStack {
                    Circle()
                        .frame(width: squareSize, height: squareSize)
                    Image(squareImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: squareSize, height: squareSize)
                        .clipShape(Circle())
                }
                .position(squarePosition)
                // Blue dot whose position depends on yaw/pitch
//                Circle()
//                    .fill(Color.blue)
//                    .frame(width: 30, height: 30)
//                    .position(
//                        x: calculateX(in: geometry.size, yaw: headTiltDetector.yaw),
//                        y: calculateY(in: geometry.size, pitch: headTiltDetector.pitch)
//                    )
                Image("bug2") // Replace with your actual image asset name
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .clipShape(Circle())
                    .position(
                        x: calculateX(in: geometry.size, yaw: headTiltDetector.yaw),
                        y: calculateY(in: geometry.size, pitch: headTiltDetector.pitch)
                    )
                
                // Debug info at the bottom
                VStack {
                    Spacer()
                    if !gameEnded {
                        Text("\(timeRemaining)")
                            .foregroundColor(timeRemaining <= 10 ? Color(red: 229/255.0, green: 0, blue: 255/255.0) : .black)
                            .padding(.bottom, 20)
                    } else {
                        Text("game over")
                            .font(.title)
                            .foregroundColor(.black)
                            .padding(.bottom, 20)
                    }
                }
            }
            .onAppear {
                AudioManager.shared.playBackgroundMusic("calm_music")
                headTiltDetector.startDetectingHeadTilt()
                
                // Initialize square in center if not set yet
                if squarePosition == .zero {
                    squarePosition = CGPoint(
                        x: geometry.size.width / 2,
                        y: geometry.size.height / 2
                    )
                }
                startGameTimer()
            }
            .onDisappear {
                headTiltDetector.stopDetectingHeadTilt()
            }
            // Update audio settings, check for collisions, and update bee trail
            .onChange(of: YawPitch(yaw: headTiltDetector.yaw, pitch: headTiltDetector.pitch)) { newValue in
                let dotX = calculateX(in: geometry.size, yaw: newValue.yaw)
                let dotY = calculateY(in: geometry.size, pitch: newValue.pitch)
                
                // Append the new position to the bee trail and limit its length if needed
                let newPoint = CGPoint(x: dotX, y: dotY)
                beeTrail.append(newPoint)
                if beeTrail.count > 50 { // Limit to last 50 points
                    beeTrail.removeFirst()
                }
                
                let distance = calculateDistance(dotX: dotX, dotY: dotY,
                                                 squareX: squarePosition.x,
                                                 squareY: squarePosition.y)
                
                let maxDistance: CGFloat = sqrt(pow(geometry.size.width, 2) + pow(geometry.size.height, 2))
                let maxVolume: Float = 1.0
                let normalizedVolume = maxVolume / (1 + Float(distance / (maxDistance * 0.2)))
                
                let screenMidX = geometry.size.width / 2
                let pan: Float = -Float((dotX - screenMidX) / screenMidX)
                
                AudioManager.shared.updateBackgroundMusicVolume(normalizedVolume, pan: pan)
                checkCollision(dotX: dotX, dotY: dotY, geometrySize: geometry.size)
            }
            // Present the restart screen when the game is over.
            .fullScreenCover(isPresented: $showRestartScreen) {
                RestartView(restartAction: {
                    showRestartScreen = false
                    restartGame()
                })
            }
        }
    }
    
    private func restartGame() {
        // Reset the game state
        squarePosition = CGPoint(x: UIScreen.main.bounds.width / 2,
                                 y: UIScreen.main.bounds.height / 2)
        timeRemaining = 60
        gameEnded = false
        fadeInText = false
        collisionDetected = false
        countdownToRestart = 7
        beeTrail.removeAll()  // Clear the trail
        
        startGameTimer()
    }
    
    // MARK: - Timer Logic
    
    /// Starts the countdown timer for the game
    private func startGameTimer() {
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                gameEnded = true
                fadeInText = true // Trigger fade-in effect
                timer.invalidate()
                // After a short delay, present the restart screen.
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    showRestartScreen = true
                }
            }
        }
    }
    
    // MARK: - Mapping Functions
    
    private func calculateX(in size: CGSize, yaw: Double) -> CGFloat {
        let minYaw: Double = -45
        let maxYaw: Double = 45
        let clampedYaw = min(max(yaw, minYaw), maxYaw)
        let normalized = (maxYaw - clampedYaw) / (maxYaw - minYaw)
        return CGFloat(normalized) * size.width
    }
    
    private func calculateY(in size: CGSize, pitch: Double) -> CGFloat {
        let minPitch: Double = -45
        let maxPitch: Double = 45
        let clampedPitch = min(max(pitch, minPitch), maxPitch)
        let normalized = (clampedPitch - minPitch) / (maxPitch - minPitch)
        return size.height - CGFloat(normalized) * size.height
    }
    
    private func calculateDistance(dotX: CGFloat,
                                   dotY: CGFloat,
                                   squareX: CGFloat,
                                   squareY: CGFloat) -> CGFloat {
        let deltaX = dotX - squareX
        let deltaY = dotY - squareY
        return sqrt(deltaX * deltaX + deltaY * deltaY)
    }
    
    private func detectBugPosition(dotX: CGFloat, squareX: CGFloat) -> String {
        return dotX < squareX ? "left" : "right"
    }
    
    private func checkCollision(dotX: CGFloat,
                                dotY: CGFloat,
                                geometrySize: CGSize) {
        if !collisionDetected &&
            abs(dotX - squarePosition.x) < squareSize / 2 &&
            abs(dotY - squarePosition.y) < squareSize / 2 {
            
            DispatchQueue.main.async {
                self.collisionDetected = true
                self.squareImage = "flower_purple"
                self.playSound("point.mp3", volume: 1.0)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self.squarePosition = CGPoint(
                        x: CGFloat.random(in: self.squareSize/2 ... geometrySize.width - self.squareSize/2),
                        y: CGFloat.random(in: self.squareSize/2 ... geometrySize.height - self.squareSize/2)
                    )
                    self.squareImage = "flower_black"
                    self.collisionDetected = false
                }
            }
        }
    }
    
    private func playSound(_ soundFileName: String, volume: Float = 1.0) {
        guard let url = Bundle.main.url(forResource: soundFileName, withExtension: nil) else {
            print("Unable to find the sound file: \(soundFileName)")
            return
        }
        
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = volume
            player.prepareToPlay()
            player.play()
            
            DispatchQueue.main.async {
                self.audioPlayer = player
            }
            
            print("Played with volume: \(volume)")
        } catch {
            print("Error playing sound: \(error.localizedDescription)")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
