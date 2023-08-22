

import UIKit

public class ZLProgressHUD: UIView {
    @objc public enum HUDStyle: Int {
        case light
        case lightBlur
        case dark
        case darkBlur
        
        var bgColor: UIColor {
            switch self {
            case .light:
                return .white
            case .dark:
                return .darkGray
            case .lightBlur:
                return UIColor.white.withAlphaComponent(0.8)
            case .darkBlur:
                return UIColor.darkGray.withAlphaComponent(0.8)
            }
        }
        
        var icon: UIImage? {
            switch self {
            case .light, .lightBlur:
                return getImage("zl_loading_dark")
            case .dark, .darkBlur:
                return getImage("zl_loading_light")
            }
        }
        
        var textColor: UIColor {
            switch self {
            case .light, .lightBlur:
                return .black
            case .dark, .darkBlur:
                return .white
            }
        }
        
        var blurEffectStyle: UIBlurEffect.Style? {
            switch self {
            case .light, .dark:
                return nil
            case .lightBlur:
                return .extraLight
            case .darkBlur:
                return .dark
            }
        }
    }
    
    private let style: ZLProgressHUD.HUDStyle
    
    private lazy var loadingView = UIImageView(image: style.icon)
    
    deinit {
        zl_debugPrint("ZLProgressHUD deinit")
    }
    
    @objc public init(style: ZLProgressHUD.HUDStyle) {
        self.style = style
        super.init(frame: UIScreen.main.bounds)
        setupUI()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 135, height: 135))
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 12
        view.backgroundColor = style.bgColor
        view.clipsToBounds = true
        view.center = center
        
        if let effectStyle = style.blurEffectStyle {
            let effect = UIBlurEffect(style: effectStyle)
            let effectView = UIVisualEffectView(effect: effect)
            effectView.frame = view.bounds
            view.addSubview(effectView)
        }
        
        loadingView.frame = CGRect(x: 135 / 2 - 22, y: 25, width: 44, height: 44)
        view.addSubview(loadingView)
        
        let label = UILabel(frame: CGRect(x: 0, y: 85, width: view.bounds.width, height: 30))
        label.textAlignment = .center
        label.textColor = style.textColor
        label.font = UIFont.systemFont(ofSize: 16)
        label.text = localLanguageTextValue(.hudLoading)
        view.addSubview(label)
        
        addSubview(view)
    }
    
    private func startAnimation() {
        let animation = CABasicAnimation(keyPath: "transform.rotation.z")
        animation.fromValue = 0
        animation.toValue = CGFloat.pi * 2
        animation.duration = 0.8
        animation.repeatCount = .infinity
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        loadingView.layer.add(animation, forKey: nil)
    }
    
    @objc public func show() {
        DispatchQueue.main.async {
            self.startAnimation()
            UIApplication.shared.keyWindow?.addSubview(self)
        }
    }
    
    @objc public func hide() {
        DispatchQueue.main.async {
            self.loadingView.layer.removeAllAnimations()
            self.removeFromSuperview()
        }
    }
}
