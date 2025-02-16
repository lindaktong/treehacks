//
//  HeadTiltDelegate.swift
//  treehacks
//
//  Created by Linda on 2/15/25.
//

import Foundation
import CoreMotion
import Combine

protocol HeadTiltDelegate: AnyObject {
    func startTilt()
    func endTilt()
}

class HeadTiltDetector: NSObject, ObservableObject, CMHeadphoneMotionManagerDelegate {
    private let motionManager = CMHeadphoneMotionManager()
    private let tiltThresholdDeg = 28.0
    private let tiltThresholdEndDeg = 20.0
    
    var delegate: HeadTiltDelegate?
    
    @Published var isTracking = false
    @Published var headphonesConnected = false
    @Published var isTilting = false
    @Published var tiltDeg = 0.0
    
    // New published properties for head orientation
    @Published var yaw: Double = 0.0
    @Published var pitch: Double = 0.0
    @Published var roll: Double = 0.0
    
    func startDetectingHeadTilt() {
        motionManager.delegate = self
        // Check if the device supports headphone motion updates
        guard motionManager.isDeviceMotionAvailable else {
            print("Headphone motion updates are not available")
            return
        }
        
        // Start receiving headphone motion updates
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] deviceMotion, error in
            if let error = error {
                print("Error receiving headphone motion updates: \(error)")
                return
            }
            guard let self = self, let deviceMotion = deviceMotion else { return }
            
            // Debug print to see if you're getting roll data
            print("Roll: \(deviceMotion.attitude.roll * 180 / .pi)°")
            
            self.handleDeviceMotion(deviceMotion)
        }
        isTracking = true
    }
    
    // Receive headphone connect updates so we can update the UI
    func headphoneMotionManagerDidConnect(_ manager: CMHeadphoneMotionManager) {
        headphonesConnected = true
    }
    
    func headphoneMotionManagerDidDisconnect(_ manager: CMHeadphoneMotionManager) {
        headphonesConnected = false
    }
    
    private func handleDeviceMotion(_ deviceMotion: CMDeviceMotion) {
        // Update the published orientation values in degrees
        self.yaw = deviceMotion.attitude.yaw * 180 / .pi
        self.pitch = deviceMotion.attitude.pitch * 180 / .pi
        self.roll = deviceMotion.attitude.roll * 180 / .pi
        
        // Also update tiltDeg for your tilt detection logic
        tiltDeg = self.roll
        
        // Debug print orientation values
        print("yaw: \(self.yaw) deg, roll: \(self.roll) deg, pitch: \(self.pitch) deg")
        
        // Check tilt thresholds using the updated roll value
        let tiltThresholdMet = self.roll < -tiltThresholdDeg
        let tiltEndThresholdMet = self.roll > -tiltThresholdEndDeg
        
        if tiltThresholdMet && !isTilting {
            isTilting = true
            delegate?.startTilt()
        } else if tiltEndThresholdMet && isTilting {
            isTilting = false
            delegate?.endTilt()
        }
    }
    
    func stopDetectingHeadTilt() {
        motionManager.stopDeviceMotionUpdates()
        isTracking = false
    }
}
