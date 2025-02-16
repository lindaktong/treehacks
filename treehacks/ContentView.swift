import SwiftUI
import AVFoundation

/// A small struct that holds yaw and pitch values.
/// Marked `Equatable` so we can use `onChange(of:)`.
struct YawPitch: Equatable {
    let yaw: Double
    let pitch: Double
}



class AudioManager {
    static let shared = AudioManager()
    private var audioPlayers: [AVAudioPlayer] = []

    private init() {}

    func playBackgroundMusic(_ fileName: String, fileType: String = "mp3", volume: Float = 0.5, pan: Float = 0.0) {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: fileType) else {
            print("Music file not found")
            return
        }

        do {
            let audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer.volume = volume
            audioPlayer.pan = pan
            audioPlayer.numberOfLoops = -1
            audioPlayer.prepareToPlay()
            audioPlayer.play()

            audioPlayers.append(audioPlayer)
        } catch {
            print("Error playing music: \(error.localizedDescription)")
        }
    }

    // Move this function OUTSIDE of playBackgroundMusic
    func updateBackgroundMusicVolume(_ volume: Float, pan: Float) {
        DispatchQueue.main.async {
            self.audioPlayers.forEach {
                $0.volume = volume
                $0.pan = pan // Apply left-right audio panning
            }
        }
    }

    func playSound(_ fileName: String, fileType: String = "mp3", volume: Float = 1.0) {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: fileType) else {
            print("Sound file not found")
            return
        }

        do {
            let audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer.volume = volume
            audioPlayer.prepareToPlay()
            audioPlayer.play()

            audioPlayers.append(audioPlayer)
        } catch {
            print("Error playing sound: \(error.localizedDescription)")
        }
    }

    func stopAllMusic() {
        for player in audioPlayers {
            player.stop()
        }
        audioPlayers.removeAll()
    }
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
                
                Text("bzzzzzzz")
                    .font(.title)
                    .bold()
                    .opacity(opacity)
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
//    @State private var squareColor: Color = .black
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
    
    let squareSize: CGFloat = 75
    
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.white.ignoresSafeArea()
                
         
                // Square (target)
                
                ZStack {
                    Circle()
                        .frame(width: squareSize, height: squareSize) // Ensures it's a circle

                    Image(squareImage) // Replace with your actual image name
                        .resizable()
                        .scaledToFit()
                        .frame(width: squareSize * 1, height: squareSize * 1) // Slightly smaller than the circle
                        .clipShape(Circle()) // Ensures the image is clipped to a circular shape
                }
                .position(squarePosition)
//                Rectangle()
//                    .fill(squareColor)
//                    .frame(width: squareSize, height: squareSize)
//                    .position(squarePosition)
                
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
                    .clipShape(Circle()) // Ensures the image remains circular
                    .position(
                        x: calculateX(in: geometry.size, yaw: headTiltDetector.yaw),
                        y: calculateY(in: geometry.size, pitch: headTiltDetector.pitch)
                    )

                
                
                // Debug info at the bottom
                VStack {
                    Spacer()
//                    Text("Yaw: \(headTiltDetector.yaw, specifier: "%.2f")°")
//                    Text("Pitch: \(headTiltDetector.pitch, specifier: "%.2f")°")
//                    Text("Roll: \(headTiltDetector.roll, specifier: "%.2f")°")
//                        .padding(.bottom, 20)
                    
                    // Time display
                    if !gameEnded {
                        Text("\(timeRemaining)")
                            .foregroundColor(.black)
                            .padding(.bottom, 20)
                        if (timeRemaining < 10) {
                            // make it red!
                        }
                    } else {
                        Text("game over")
                            .font(.title)
                            .foregroundColor(.red)
                            .padding(.bottom, 20)
                    }
                }
            }
            // Start/stop head tracking
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
            // Use the YawPitch struct to avoid tuple Equatable issues
            // change volume based on distance 
            .onChange(of: YawPitch(yaw: headTiltDetector.yaw, pitch: headTiltDetector.pitch)) { newValue in
                let dotX = calculateX(in: geometry.size, yaw: newValue.yaw)
                let dotY = calculateY(in: geometry.size, pitch: newValue.pitch)
                
                let distance = calculateDistance(dotX: dotX, dotY: dotY, squareX: squarePosition.x, squareY: squarePosition.y)
                
                // checks if the bug is on the right or the left side of the flower
                let bugPosition = detectBugPosition(dotX: dotX, squareX: squarePosition.x)
//                    print("Bug is on the \(bugPosition) of the circle")
                
                // Normalize distance to volume (closer = louder)
                let maxDistance: CGFloat = sqrt(pow(geometry.size.width, 2) + pow(geometry.size.height, 2)) // Max possible distance
                let maxVolume: Float = 1.0
//                let normalizedVolume = maxVolume - Float(distance / maxDistance) * (maxVolume - minVolume)
                // let exponent: CGFloat = 2.5  Adjust for more/less drastic effect
//                let normalizedFactor = pow(distance / maxDistance, exponent)
//                let normalizedVolume = maxVolume - Float(normalizedFactor) * (maxVolume - minVolume)
                
                let normalizedVolume = maxVolume / (1 + Float(distance / (maxDistance * 0.2)))
                
                // Calculate pan value (-1.0 for left, 1.0 for right)
                let screenMidX = geometry.size.width / 2
                let pan: Float = -Float((dotX - screenMidX) / screenMidX) // Normalizes -1 to 1

                // Update audio volume and panning
                AudioManager.shared.updateBackgroundMusicVolume(normalizedVolume, pan: pan)
//                AudioManager.shared.updateBackgroundMusicVolume(normalizedVolume)
                checkCollision(dotX: dotX, dotY: dotY, geometrySize: geometry.size)
                
            }

        }
    }
    
    
    private func restartGame() {
        // Reset the game state
        squarePosition = CGPoint(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2)
        timeRemaining = 5
        gameEnded = false
        fadeInText = false
        collisionDetected = false
        countdownToRestart = 7;
        

        // Start the timer again
        startGameTimer()
    }

    // MARK: - Timer Logic

    /// Starts the countdown timer for the game
    private func startGameTimer() {
        // Timer updates every second
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                // Stop the game when the timer reaches zero
                gameEnded = true
                fadeInText = true // Trigger fade-in effect
//                startRestartCountdown() // Start the countdown to restart the game
                timer.invalidate()
            }
        }
    }

//    private func startRestartCountdown() {
//        // Start countdown for 7 seconds
//        restartTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
//            if countdownToRestart > 0 {
//                countdownToRestart -= 1
//            } else {
//                // When countdown reaches 0, reset the game
//                restartGame()
//                timer.invalidate()
//            }
//        }
//    }

    
    
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
    
    
    // function to play sound
    private func playSound(_ soundFileName: String, volume: Float = 1.0) {
        guard let url = Bundle.main.url(forResource: soundFileName, withExtension: nil) else {
            print("Unable to find the sound file: \(soundFileName)")
            return
        }
        
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = volume  // Set volume (Range: 0.0 to 1.0)
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


    // MARK: - Collision Detection
    /// Checks if the dot collides with the square.
    /// If collision occurs, turn square green, wait 3s, then move it & revert to black.
    private func checkCollision(dotX: CGFloat, dotY: CGFloat, geometrySize: CGSize) {
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
    
    // MARK: - Relative Position
    /// checks distance between circles
    private func calculateDistance(dotX: CGFloat, dotY: CGFloat, squareX: CGFloat, squareY: CGFloat) -> CGFloat {
        let deltaX = dotX - squareX
        let deltaY = dotY - squareY
        return sqrt(deltaX * deltaX + deltaY * deltaY)
    }
    
    /// checks if the bee is on the right or the left side
    private func detectBugPosition(dotX: CGFloat, squareX: CGFloat) -> String {
        return dotX < squareX ? "left" : "right"
    }
    
    
    
    struct ContentView_Previews: PreviewProvider {
        static var previews: some View {
            ContentView()
        }
    }
}

