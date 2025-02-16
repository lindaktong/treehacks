// BeeTrailView.swift
import SwiftUI

struct BeeTrailView: View {
    var points: [CGPoint]
    
    var body: some View {
        Path { path in
            guard let first = points.first else { return }
            path.move(to: first)
            for point in points.dropFirst() {
                path.addLine(to: point)
            }
        }
        .stroke(
            style: StrokeStyle(
                lineWidth: 2,
                lineCap: .round,
                lineJoin: .round,
                dash: [5, 20]  // 5 points drawn, 10 points gap
            )
        )
        .foregroundColor(.gray)
        .opacity(0.3)
    }
}

struct BeeTrailView_Previews: PreviewProvider {
    static var previews: some View {
        BeeTrailView(points: [
            CGPoint(x: 50, y: 50),
            CGPoint(x: 100, y: 100),
            CGPoint(x: 150, y: 80)
        ])
        .frame(width: 300, height: 300)
    }
}
