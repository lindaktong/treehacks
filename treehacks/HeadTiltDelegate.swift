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
    
    func startDetectingHeadTilt() {
        motionManager.delegate = self
        // Check if the device supports headphone motion updates
        guard motionManager.isDeviceMotionAvailable else {
            print("Headphone motion updates are not available")
            return
        }
        
        // Start receiving headphone motion updates
//        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] (deviceMotion, error) in
//            if let error = error {
//                print("Error receiving headphone motion updates: \(error)")
//                return
//            }
//            
//            if let deviceMotion = deviceMotion {
//                self?.handleDeviceMotion(deviceMotion)
//            }
//        }
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
        // Get the roll value from the device motion
        let tiltThresholdMet = deviceMotion.attitude.roll * 180 / .pi < -tiltThresholdDeg
        let tiltEndThresholdMet = deviceMotion.attitude.roll * 180 / .pi > -tiltThresholdEndDeg
        
        tiltDeg = deviceMotion.attitude.roll * 180 / .pi
        
        print("yaw: \(deviceMotion.attitude.yaw * 180 / .pi) deg, roll: \(deviceMotion.attitude.roll * 180 / .pi) deg, pitch: \(deviceMotion.attitude.pitch * 180 / .pi) deg")
        
        // Check if the head is tilted to the left by more than 30 degrees
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
