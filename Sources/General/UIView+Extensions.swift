import UIKit

extension UIView {

/*    func snapshot(scrollView: UIScrollView) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(scrollView.contentSize, false, UIScreen.main.scale)
        layer.render(in: UIGraphicsGetCurrentContext()!)
        let savedContentOffset = scrollView.contentOffset
        let savedFrame = frame

        scrollView.contentOffset = CGPoint.zero
        frame = CGRect(x: 0, y: 0, width: scrollView.contentSize.width, height: scrollView.contentSize.height)

        layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()

        scrollView.contentOffset = savedContentOffset
        frame = savedFrame

        UIGraphicsEndImageContext()

        return image
    }*/

    public func snapshotImage() -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(bounds.size, isOpaque, 0)
        drawHierarchy(in: bounds, afterScreenUpdates: false)
        let snapshotImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return snapshotImage
    }



}
