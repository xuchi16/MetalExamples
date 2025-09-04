// Created by Chester for LowLevelMeshPlane in 2025

import RealityKit
import RealityKitContent
import SwiftUI

struct ImmersiveView: View {
    var body: some View {
        RealityView { content in
            // Create a plane mesh.
            let planeMesh = PlaneMesh(size: [1, 1], dimensions: [16, 16])
            if let mesh = try? MeshResource(from: planeMesh.mesh) {
                // Create an entity with the plane mesh.
                let planeEntity = Entity()
                let planeModel = ModelComponent(mesh: mesh, materials: [SimpleMaterial()])
                planeEntity.components.set(planeModel)

                // Add the plane entity to the scene.
                planeEntity.position = [0, 1.5, -1.5]
                content.add(planeEntity)
            }
        }
    }
}

#Preview(immersionStyle: .mixed) {
    ImmersiveView()
        .environment(AppModel())
}
