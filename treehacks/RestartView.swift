import SwiftUI

struct RestartView: View {
    var restartAction: () -> Void

    var body: some View {
        ZStack {
            // Full-screen background image
            Image("enuf")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            
            // "Play Again" button positioned at the bottom
            VStack {
                Spacer()
                Button(action: restartAction) {
                    Image("again")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 200)  // Adjust size as needed
                }
                .padding(.bottom, 150)  // Adjust bottom spacing as needed
            }
        }
    }
}

struct RestartView_Previews: PreviewProvider {
    static var previews: some View {
        RestartView(restartAction: {})
    }
}
