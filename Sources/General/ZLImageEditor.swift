/*
import UIKit

public struct ZLImageEditorWrapper<Base> {
    public let base: Base
    
    public init(_ base: Base) {
        self.base = base
    }
}

public protocol ZLImageEditorCompatible: AnyObject { }

public protocol ZLImageEditorCompatibleValue { }

extension ZLImageEditorCompatible {
    public var zl: ZLImageEditorWrapper<Self> {
        get { ZLImageEditorWrapper(self) }
        set { }
    }
    
    public static var zl: ZLImageEditorWrapper<Self>.Type {
        get { ZLImageEditorWrapper<Self>.self }
        set { }
    }
}

extension ZLImageEditorCompatibleValue {
    public var zl: ZLImageEditorWrapper<Self> {
        get { ZLImageEditorWrapper(self) }
        set { }
    }
}

extension UIImage: ZLImageEditorCompatible { }
extension CIImage: ZLImageEditorCompatible { }
extension UIColor: ZLImageEditorCompatible { }
extension UIView: ZLImageEditorCompatible { }

extension String: ZLImageEditorCompatibleValue { }
extension CGFloat: ZLImageEditorCompatibleValue { }
*/
