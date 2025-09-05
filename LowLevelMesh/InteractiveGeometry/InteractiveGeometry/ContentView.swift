// Created by Chester for InteractiveGeometry in 2025

import RealityKit
import RealityKitContent
import SwiftUI

struct ContentView: View {
    private let meshDimensions = SIMD2<UInt32>(512, 512)
    private let meshSize = SIMD2<Float>(1, 1)
    private var sceneContainer: Entity = .init()
    private let defaultPlaneContainer: Entity = .init()
    private let heightMapMeshEntity: HeightMapMeshEntity

    // Materials
    private let sineWaveMaterial: SimpleMaterial = .init(color: #colorLiteral(red: 0.4666666687, green: 0.7647058964, blue: 0.2666666806, alpha: 1), roughness: 0.85, isMetallic: false)
    private let terrainMaterial: SimpleMaterial = .init(color: #colorLiteral(red: 0.5058823824, green: 0.3372549117, blue: 0.06666667014, alpha: 1), roughness: 0.25, isMetallic: false)
    private let waterMaterial: SimpleMaterial = .init(color: #colorLiteral(red: 0, green: 0.8260448575, blue: 0.960488379, alpha: 1), roughness: 0.05, isMetallic: false)

    init() {
        heightMapMeshEntity = HeightMapMeshEntity()
    }
    
    // Pickers
    enum Generator: String, CaseIterable, Identifiable {
        var id: String { rawValue }

        /// Default plane.
        case plane = "Plane"

        /// Sine wave height map.
        case sine = "Sine"

        /// Terrain height map.
        case terrain = "Terrain"

        /// Water simulation height map.
        case water = "Water"

        var displayName: String { rawValue }
    }

    @State var generator: Generator = .plane

    var generatorPicker: some View {
        Picker("Generator", selection: $generator) {
            ForEach(Generator.allCases) { generator in
                Text(generator.displayName).tag(generator)
            }
        }.pickerStyle(.segmented)
            .onChange(of: generator) { _, newValue in
                // Show the plane entity and hide the height map mesh entity when the person selects the plane generator.
                // Otherwise, hide the plane entity and show the height map mesh entity.
                let isDefaultPlaneSelected = newValue == .plane
                defaultPlaneContainer.isEnabled = isDefaultPlaneSelected
                heightMapMeshEntity.isEnabled = !isDefaultPlaneSelected

                // Set the current height map generator.
                switch newValue {
                    case .sine:
                        print("Sine")

//                        setHeightMapGenerator(heightMapGenerator: sineWaveHeightMapGenerator, material: sineWaveMaterial)
                    case .terrain:
                        print("Terrain")

//                        setHeightMapGenerator(heightMapGenerator: terrainHeightMapGenerator, material: terrainMaterial)
                    case .water:
                        print("Water")

//                        setHeightMapGenerator(heightMapGenerator: waterHeightMapGenerator, material: waterMaterial)
                    case .plane:
                        break
                }
            }
    }

//    private func setHeightMapGenerator(heightMapGenerator: HeightMapGenerator, material: SimpleMaterial) {
//        heightMapGenerator.reset()
//        heightMapMeshEntity.heightMapMesh?.heightMap.heightMapGenerator = heightMapGenerator
//        heightMapMeshEntity.model?.materials = [material]
//    }

    var body: some View {
        RealityView { content in
            let scene = createScene()
            // Position it just above the toolbar of the volume.
            scene.position.y = -0.425
            // Add it to the reality view.
            sceneContainer.addChild(scene)
            content.add(sceneContainer)
        }
        .toolbar {
            ToolbarItem(placement: .bottomOrnament) {
                generatorPicker
            }
        }
    }

    func createScene() -> Entity {
        // Create a scene entity.
        let scene = Entity()

        // Create the default plane mesh.
        let planeMesh = PlaneMesh(size: meshSize, dimensions: meshDimensions)
        if let mesh = try? MeshResource(from: planeMesh.mesh) {
            // Create an entity with the plane mesh.
            let planeEntity = Entity()
            let planeModel = ModelComponent(mesh: mesh, materials: [SimpleMaterial()])
            planeEntity.components.set(planeModel)

            // Add the entity to the scene.
            defaultPlaneContainer.addChild(planeEntity)
            scene.addChild(defaultPlaneContainer)
        }

        // Rotate the scene to position the planes in xz-plane instead of the xy-plane.
        scene.transform.rotation = simd_quatf(angle: -.pi / 2, axis: [1, 0, 0])

        return scene
    }
}
