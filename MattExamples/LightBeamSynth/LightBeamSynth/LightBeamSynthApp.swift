// Created by Chester for LightBeamSynth in 2025

import SwiftUI

@main
struct LightBeamSynthApp: App {

    @State private var appModel = AppModel()

    var body: some Scene {
        WindowGroup {
            LightBeamSynthView()
                .environment(appModel)
        }
        .windowStyle(.volumetric)

        ImmersiveSpace(id: appModel.immersiveSpaceID) {
            ImmersiveView()
                .environment(appModel)
                .onAppear {
                    appModel.immersiveSpaceState = .open
                }
                .onDisappear {
                    appModel.immersiveSpaceState = .closed
                }
        }
        .immersionStyle(selection: .constant(.mixed), in: .mixed)
    }
}
