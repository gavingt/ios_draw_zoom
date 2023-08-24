import UIKit

extension UIScrollView {

    var snapshotVisibleArea: UIImage? {
        UIGraphicsBeginImageContext(bounds.size)
        UIGraphicsGetCurrentContext()?.translateBy(x: -contentOffset.x, y: -contentOffset.y)
        layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }

}