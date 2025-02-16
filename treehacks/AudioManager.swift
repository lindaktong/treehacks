//
//  AudioManager.swift
//  treehacks
//
//  Created by Linda on 2/16/25.
//

import AVFoundation

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
