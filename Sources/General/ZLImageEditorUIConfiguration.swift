

import UIKit

public class ZLImageEditorUIConfiguration: NSObject {
    private static var single = ZLImageEditorUIConfiguration()
    
    @objc public class func `default`() -> ZLImageEditorUIConfiguration {
        return ZLImageEditorUIConfiguration.single
    }
    
    @objc public class func resetConfiguration() {
        ZLImageEditorUIConfiguration.single = ZLImageEditorUIConfiguration()
    }
    
    /// HUD style. Defaults to dark.
    @objc public var hudStyle: ZLProgressHUD.HUDStyle = .dark
    
    /// Adjust Slider Type
    @objc public var adjustSliderType: ZLAdjustSliderType = .vertical
    

    
    /// Developers can customize images, but the name of the custom image resource must be consistent with the image name in the replaced bundle.
    /// - example: Developers need to replace the selected and unselected image resources, and the array that needs to be passed in is
    /// ["zl_btn_selected", "zl_btn_unselected"].
    @objc public var customImageNames: [String] = [] {
        didSet {
            ZLCustomImageDeploy.imageNames = customImageNames
        }
    }

    
    /// Developers can customize images, but the name of the custom image resource must be consistent with the image name in the replaced bundle.
    /// - example: Developers need to replace the selected and unselected image resources, and the array that needs to be passed in is
    /// ["zl_btn_selected": selectedImage, "zl_btn_unselected": unselectedImage].
    @objc public var customImageForKey_objc: [String: UIImage] = [:] {
        didSet {
            ZLCustomImageDeploy.imageForKey = customImageForKey_objc
        }
    }
    
    // MARK: Color properties
    
    /// The normal color of adjust slider.
    @objc public var adjustSliderNormalColor = UIColor.white
    
    /// The tint color of adjust slider.
    @objc public var adjustSliderTintColor = zlRGB(80, 169, 56)
    
    /// The background color of edit done button.
    @objc public var editDoneBtnBgColor = zlRGB(80, 169, 56)
    
    /// The title color of edit done button.
    @objc public var editDoneBtnTitleColor = UIColor.white
    
    /// The normal background color of ashbin.
    @objc public var ashbinNormalBgColor = zlRGB(40, 40, 40).withAlphaComponent(0.8)
    
    /// The tint background color of ashbin.
    @objc public var ashbinTintBgColor = zlRGB(241, 79, 79).withAlphaComponent(0.98)
    
    /// The normal color of the title below the various tools in the image editor.
    @objc public var toolTitleNormalColor = zlRGB(160, 160, 160)
    
    /// The tint color of the title below the various tools in the image editor.
    @objc public var toolTitleTintColor = UIColor.white

    /// The highlighted color of the tool icon.
    @objc public var toolIconHighlightedColor: UIColor?
}

// MARK: Image source deploy

enum ZLCustomImageDeploy {
    static var imageNames: [String] = []
    
    static var imageForKey: [String: UIImage] = [:]
}

@objc public enum ZLAdjustSliderType: Int {
    case vertical
    case horizontal
}
