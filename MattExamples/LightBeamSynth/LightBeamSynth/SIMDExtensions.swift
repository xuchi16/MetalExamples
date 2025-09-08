import simd

//extension SIMD3 where Scalar == Float {
//    /// 返回向量的归一化（单位长度）版本
//    var normalized: SIMD3<Float> {
//        let length = simd_length(self)
//        guard length > 0 else { return .zero }
//        return self / length
//    }
//    
//    /// 对向量进行原地归一化（修改自身）
//    mutating func normalize() {
//        let length = simd_length(self)
//        guard length > 0 else {
//            self = .zero
//            return
//        }
//        self /= length
//    }
//}

extension SIMD3 where Scalar == Float {
    func normalized() -> SIMD3<Float> {
        let magnitude = simd_length(self)
        // Avoid division by zero
        guard magnitude > 0 else { return SIMD3<Float>(0, 0, 0) }
        return self / magnitude
    }
}
