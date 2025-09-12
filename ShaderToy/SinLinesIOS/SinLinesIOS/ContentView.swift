// Created by Chester for SinLinesIOS in 2025

import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack {
            MetalView()
                .ignoresSafeArea()
            
            Text("Hello Sine Wave")
                .font(.title)
                .foregroundColor(.white)
        }
    }
}

#Preview {
    ContentView()
}
