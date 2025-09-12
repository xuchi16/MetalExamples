// Created by Chester for SinLinesIOS in 2025

import SwiftUI

struct ContentView: View {
    @State private var selectedShader: ShaderType = .sineWave

    var body: some View {
        ZStack {
            MetalView(selectedShader: $selectedShader)
                .ignoresSafeArea()

            VStack {
                Picker("Select Shader", selection: $selectedShader) {
                    ForEach(ShaderType.allCases) { shader in
                        Text(shader.displayName)
                            .tag(shader)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding(12)
                .buttonStyle(.glassProminent)

                Spacer()
            }
        }
    }
}

#Preview {
    ContentView()
}
