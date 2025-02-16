//
//  ContentView.swift
//  treehacks
//
//  Created by Linda on 2/15/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var headTiltDetector = HeadTiltDetector()

    var body: some View {
        VStack {
            Text("Tilt Angle: \(headTiltDetector.tiltDeg, specifier: "%.2f")°")
                .font(.largeTitle)
                .padding()

            if headTiltDetector.isTilting {
                Text("🟢 Tilting Detected!")
                    .foregroundColor(.green)
                    .bold()
            } else {
                Text("⚪️ No Tilt")
                    .foregroundColor(.gray)
            }

            Button(action: {
                if headTiltDetector.isTracking {
                    headTiltDetector.stopDetectingHeadTilt()
                } else {
                    headTiltDetector.startDetectingHeadTilt()
                }
            }) {
                Text(headTiltDetector.isTracking ? "Stop Tracking" : "Start Tracking")
                    .padding()
                    .background(headTiltDetector.isTracking ? Color.red : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()
        }
        .onAppear {
            headTiltDetector.startDetectingHeadTilt()
        }
        .onDisappear {
            headTiltDetector.stopDetectingHeadTilt()
        }
    }
}
