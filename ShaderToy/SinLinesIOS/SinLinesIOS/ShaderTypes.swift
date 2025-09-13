// Created by Chester for SinLinesIOS in 2025

import Foundation

enum ShaderType: String, CaseIterable, Identifiable {
    case sineWave = "sineLines"
    case noiseSculptorShape = "noiseSculptorShape"
    case raveLasers = "raveLasers"
    case gradientForTest = "gradientForTest"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .sineWave: return "Sine Wave"
        case .noiseSculptorShape: return "Noise Sculptor Shape"
        case .raveLasers: return "Rave Lasers"
        case .gradientForTest: return "Gradient For Test"
        }
    }
    
    var fragmentShaderName: String {
        return rawValue
    }
}

struct ShaderOption {
    let type: ShaderType
    let displayName: String
    let fragmentShaderName: String
    
    init(type: ShaderType) {
        self.type = type
        self.displayName = type.displayName
        self.fragmentShaderName = type.fragmentShaderName
    }
}
