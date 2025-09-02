// Created by Chester for Raybreak in 2025

import MetalKit

protocol Texturable {
    var texture: MTLTexture? { get set }
}

extension Texturable {
    func setTexture(device: MTLDevice, imageName: String) -> MTLTexture? {
        let textureLoader = MTKTextureLoader(device: device)
        
        var texture: MTLTexture?
        
        let textureLoaderOptions: [MTKTextureLoader.Option: Any] = [
            .origin: MTKTextureLoader.Origin.bottomLeft
        ]
        
        if let textureURL = Bundle.main.url(forResource: imageName, withExtension: nil) {
            do {
                texture = try textureLoader.newTexture(URL: textureURL, options: textureLoaderOptions)
            } catch {
                print("Failed to create texture")
            }
        }
        
        return texture
    }
}
