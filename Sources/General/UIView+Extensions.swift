import UIKit

extension UIView {
    func fadeIn() {
        alpha = 0
        isHidden = false
        UIView.animate(withDuration: 0.1) {
            self.alpha = 1
        }
    }

    func fadeOut() {
        UIView.animate(withDuration: 0.1, animations: {
            self.alpha = 0
        }) { (finished) in
            self.isHidden = finished
        }
    }
}
