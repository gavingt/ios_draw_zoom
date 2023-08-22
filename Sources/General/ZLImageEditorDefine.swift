import UIKit



func getImage(_ named: String) -> UIImage? {
    if let image = UIImage(named: named) {
        return image
    }
    return UIImage(named: named, in: Bundle.zlImageEditorBundle, compatibleWith: nil)
}
