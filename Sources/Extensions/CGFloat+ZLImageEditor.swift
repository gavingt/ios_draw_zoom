

import AVKit

extension ZLImageEditorWrapper where Base == CGFloat {
    var toPi: CGFloat {
        return base / 180 * .pi
    }
}
