import UIKit

public class ZLEditImageModel: NSObject {

    public let drawPaths: [ZLDrawPath]
    public let editRect: CGRect?
    public let angle: CGFloat

    public init(drawPaths: [ZLDrawPath], editRect: CGRect?, angle: CGFloat/*, selectRatio: ZLImageClipRatio?*/) {
        self.drawPaths = drawPaths
        self.editRect = editRect
        self.angle = angle
        super.init()
    }
}


open class ZLEditImageViewController: UIViewController {

    var originalImage: UIImage
    var editRect: CGRect
    var editImage: UIImage
    var currentDrawColor = UIColor(red: 0, green: 0.137, blue: 0.89, alpha: 0.26)
    static let maxDrawLineImageWidth: CGFloat = 600

    var drawPaths: [ZLDrawPath]
    var redoDrawPaths: [ZLDrawPath]
    var drawLineWidth: CGFloat = 10

    var isScrolling = false
    var shouldLayout = true
    var angle: CGFloat

    var panGes: UIPanGestureRecognizer!

    open lazy var mainScrollView: UIScrollView = {
        let view = UIScrollView()
        view.backgroundColor = .black
        view.minimumZoomScale = 1
        view.maximumZoomScale = 3
        view.delegate = self
        return view
    }()

    open lazy var containerView: UIView = {
        let view = UIView()
        view.clipsToBounds = true
        return view
    }()

    // Show image.
    open lazy var imageView: UIImageView = {
        let view = UIImageView(image: originalImage)
        view.contentMode = .scaleAspectFit
        view.clipsToBounds = true
        view.backgroundColor = .black
        return view
    }()

    open lazy var bottomShadowView = UIView()


    open lazy var doneBtn: UIButton = {
        let btn = UIButton(type: .custom)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        btn.backgroundColor = .green
        btn.setTitle("Done", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.addTarget(self, action: #selector(doneBtnClick), for: .touchUpInside)
        btn.layer.masksToBounds = true
        btn.layer.cornerRadius = 5
        return btn
    }()

    open lazy var undoBtn: UIButton = {
        let btn = UIButton(type: .custom)

        btn.setImage(UIImage(named: "zl_revoke_disable", in: Bundle.zlImageEditorBundle, compatibleWith: nil), for: .disabled)
        btn.setImage(UIImage(named: "zl_revoke", in: Bundle.zlImageEditorBundle, compatibleWith: nil), for: .normal)
        btn.adjustsImageWhenHighlighted = false
        btn.isEnabled = false
        btn.addTarget(self, action: #selector(undoBtnClick), for: .touchUpInside)
        return btn
    }()

    open lazy var redoBtn: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage(named: "zl_redo_disable", in: Bundle.zlImageEditorBundle, compatibleWith: nil), for: .disabled)
        btn.setImage(UIImage(named: "zl_redo", in: Bundle.zlImageEditorBundle, compatibleWith: nil), for: .normal)
        btn.adjustsImageWhenHighlighted = false
        btn.isEnabled = false
        btn.addTarget(self, action: #selector(redoBtnClick), for: .touchUpInside)
        return btn
    }()

    // Show draw lines.
    lazy var drawingImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.isUserInteractionEnabled = true
        return view
    }()

    var imageSize: CGSize {
        if angle == -90 || angle == -270 {
            return CGSize(width: originalImage.size.height, height: originalImage.size.width)
        }
        return originalImage.size
    }

    @objc public var editFinishBlock: ((UIImage, ZLEditImageModel?) -> Void)?

    override open var prefersStatusBarHidden: Bool {
        return true
    }

    override open var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }


    @objc public class func showEditImageVC(parentVC: UIViewController?, animate: Bool = true, image: UIImage, editModel: ZLEditImageModel? = nil, completion: ((UIImage, ZLEditImageModel?) -> Void)?) {
        let vc = ZLEditImageViewController(image: image, editModel: editModel)
        vc.editFinishBlock = { ei, editImageModel in
            completion?(ei, editImageModel)
        }
        vc.modalPresentationStyle = .fullScreen
        parentVC?.present(vc, animated: animate, completion: nil)
    }

    @objc public init(image: UIImage, editModel: ZLEditImageModel? = nil) {
        originalImage = image.zl.fixOrientation()
        editImage = originalImage
        editRect = editModel?.editRect ?? CGRect(origin: .zero, size: image.size)
        drawPaths = editModel?.drawPaths ?? []
        redoDrawPaths = drawPaths
        angle = editModel?.angle ?? 0
        super.init(nibName: nil, bundle: nil)
    }


    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override open func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        rotationImageView()
    }

    override open func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard shouldLayout else { return }

        shouldLayout = false
        var insets = UIEdgeInsets.zero
        insets = self.view.safeAreaInsets

        mainScrollView.frame = view.bounds
        resetContainerViewFrame()

        bottomShadowView.frame = CGRect(x: 0, y: view.zl.height - 140 - insets.bottom, width: view.zl.width, height: 140 + insets.bottom)

        redoBtn.frame = CGRect(x: view.zl.width - 15 - 35, y: 30, width: 35, height: 30)
        undoBtn.frame = CGRect(x: redoBtn.zl.left - 10 - 35, y: 30, width: 35, height: 30)

        doneBtn.frame = CGRect(x: 20, y: 83, width: view.frame.width - 40, height: 40)

        if !drawPaths.isEmpty {
            drawLine()
        }
    }

    override open func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        shouldLayout = true
    }


    func resetContainerViewFrame() {
        mainScrollView.setZoomScale(1, animated: true)
        imageView.image = editImage

        let editSize = editRect.size
        let scrollViewSize = mainScrollView.frame.size
        let ratio = min(scrollViewSize.width / editSize.width, scrollViewSize.height / editSize.height)
        let w = ratio * editSize.width * mainScrollView.zoomScale
        let h = ratio * editSize.height * mainScrollView.zoomScale
        containerView.frame = CGRect(x: max(0, (scrollViewSize.width - w) / 2), y: max(0, (scrollViewSize.height - h) / 2), width: w, height: h)
        mainScrollView.contentSize = containerView.frame.size

/*        if selectRatio?.isCircle == true {
            let mask = CAShapeLayer()
            let path = UIBezierPath(arcCenter: CGPoint(x: w / 2, y: h / 2), radius: w / 2, startAngle: 0, endAngle: .pi * 2, clockwise: true)
            mask.path = path.cgPath
            containerView.layer.mask = mask
        } else {*/
            containerView.layer.mask = nil
        //}

        let scaleImageOrigin = CGPoint(x: -editRect.origin.x * ratio, y: -editRect.origin.y * ratio)
        let scaleImageSize = CGSize(width: imageSize.width * ratio, height: imageSize.height * ratio)
        imageView.frame = CGRect(origin: scaleImageOrigin, size: scaleImageSize)
        drawingImageView.frame = imageView.frame

        // Optimization for long pictures.
        if (editRect.height / editRect.width) > (view.frame.height / view.frame.width * 1.1) {
            let widthScale = view.frame.width / w
            mainScrollView.maximumZoomScale = widthScale
            mainScrollView.zoomScale = widthScale
            mainScrollView.contentOffset = .zero
        } else if editRect.width / editRect.height > 1 {
            mainScrollView.maximumZoomScale = max(3, view.frame.height / h)
        }

        isScrolling = false
    }


    func setupUI() {
        view.backgroundColor = .black

        view.addSubview(mainScrollView)
        mainScrollView.addSubview(containerView)
        containerView.addSubview(imageView)
        containerView.addSubview(drawingImageView)

        view.addSubview(bottomShadowView)
        bottomShadowView.addSubview(doneBtn)

        bottomShadowView.addSubview(undoBtn)
        bottomShadowView.addSubview(redoBtn)

        let tapGes = UITapGestureRecognizer(target: self, action: #selector(tapAction(_:)))
        tapGes.delegate = self
        view.addGestureRecognizer(tapGes)

        panGes = UIPanGestureRecognizer(target: self, action: #selector(drawAction(_:)))
        panGes.maximumNumberOfTouches = 1
        panGes.delegate = self
        view.addGestureRecognizer(panGes)
        mainScrollView.panGestureRecognizer.require(toFail: panGes)
    }


    func rotationImageView() {
        let transform = CGAffineTransform(rotationAngle: angle.zl.base / 180 * .pi)
        imageView.transform = transform
        drawingImageView.transform = transform
    }


    @objc func cancelBtnClick() {
        dismiss(animated: true, completion: nil)
    }


    @objc func doneBtnClick() {
        var hasEdit = true
        if drawPaths.isEmpty, editRect.size == imageSize, angle == 0 {
            hasEdit = false
        }

        var resImage = originalImage
        var editModel: ZLEditImageModel?
        if hasEdit {
            autoreleasepool {
//                let hud = ZLProgressHUD(style: .dark)
//                hud.show()

                resImage = buildImage()
                if let oriDataSize = originalImage.jpegData(compressionQuality: 1)?.count {
                    resImage = resImage.zl.compress(to: oriDataSize)
                }

                //hud.hide()
            }

            editModel = ZLEditImageModel(drawPaths: drawPaths, editRect: editRect, angle: angle/*, selectRatio: selectRatio*/)
        }

        dismiss(animated: true) {
            self.editFinishBlock?(resImage, editModel)
        }
    }


    @objc func undoBtnClick() {
        guard !drawPaths.isEmpty else { return }
        drawPaths.removeLast()
        undoBtn.isEnabled = !drawPaths.isEmpty
        redoBtn.isEnabled = drawPaths.count != redoDrawPaths.count
        drawLine()
    }


    @objc func redoBtnClick() {
        guard drawPaths.count < redoDrawPaths.count else { return }
        let path = redoDrawPaths[drawPaths.count]
        drawPaths.append(path)
        undoBtn.isEnabled = !drawPaths.isEmpty
        redoBtn.isEnabled = drawPaths.count != redoDrawPaths.count
        drawLine()
    }


    @objc func tapAction(_ tap: UITapGestureRecognizer) {

    }


    @objc func drawAction(_ pan: UIPanGestureRecognizer) {
        let point = pan.location(in: drawingImageView)
        if pan.state == .began {
            let originalRatio = min(mainScrollView.frame.width / originalImage.size.width, mainScrollView.frame.height / originalImage.size.height)
            let ratio = min(mainScrollView.frame.width / editRect.width, mainScrollView.frame.height / editRect.height)
            let scale = ratio / originalRatio
            // Zoom to original size
            var size = drawingImageView.frame.size
            size.width /= scale
            size.height /= scale
            if angle == -90 || angle == -270 {
                swap(&size.width, &size.height)
            }

            var toImageScale = ZLEditImageViewController.maxDrawLineImageWidth / size.width
            if editImage.size.width / editImage.size.height > 1 {
                toImageScale = ZLEditImageViewController.maxDrawLineImageWidth / size.height
            }

            let path = ZLDrawPath(pathColor: currentDrawColor, pathWidth: drawLineWidth/* / mainScrollView.zoomScale*/, ratio: ratio / originalRatio / toImageScale, startPoint: point)
            drawPaths.append(path)
            redoDrawPaths = drawPaths
        } else if pan.state == .changed {
            let path = drawPaths.last
            path?.addLine(to: point)
            drawLine()
        } else if pan.state == .cancelled || pan.state == .ended {
            undoBtn.isEnabled = !drawPaths.isEmpty
            redoBtn.isEnabled = false
        }
    }


    func drawLine() {
        let originalRatio = min(mainScrollView.frame.width / originalImage.size.width, mainScrollView.frame.height / originalImage.size.height)
        let ratio = min(mainScrollView.frame.width / editRect.width, mainScrollView.frame.height / editRect.height)
        let scale = ratio / originalRatio
        // Zoom to original size
        var size = drawingImageView.frame.size
        size.width /= scale
        size.height /= scale
        if angle == -90 || angle == -270 {
            swap(&size.width, &size.height)
        }
        var toImageScale = ZLEditImageViewController.maxDrawLineImageWidth / size.width
        if editImage.size.width / editImage.size.height > 1 {
            toImageScale = ZLEditImageViewController.maxDrawLineImageWidth / size.height
        }
        size.width *= toImageScale
        size.height *= toImageScale

        UIGraphicsBeginImageContextWithOptions(size, false, editImage.scale)
        let context = UIGraphicsGetCurrentContext()

        context?.setAllowsAntialiasing(true)
        context?.setShouldAntialias(true)
        for path in drawPaths {
            path.drawPath()
        }
        drawingImageView.image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
    }


    func buildImage() -> UIImage {
        let imageSize = originalImage.size

        UIGraphicsBeginImageContextWithOptions(editImage.size, false, editImage.scale)
        editImage.draw(at: .zero)

        drawingImageView.image?.draw(in: CGRect(origin: .zero, size: imageSize))

        let temp = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        guard let cgi = temp?.cgImage else {
            return editImage
        }
        return UIImage(cgImage: cgi, scale: editImage.scale, orientation: .up)
    }

}


extension ZLEditImageViewController: UIGestureRecognizerDelegate {
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer is UITapGestureRecognizer {
            if bottomShadowView.alpha == 1 {
                let p = gestureRecognizer.location(in: view)
                return !bottomShadowView.frame.contains(p)
            } else {
                return true
            }
        } else if gestureRecognizer is UIPanGestureRecognizer {
            return !isScrolling
        }

        return true
    }
}


// MARK: scroll view delegate
extension ZLEditImageViewController: UIScrollViewDelegate {
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return containerView
    }

    public func scrollViewDidZoom(_ scrollView: UIScrollView) {
        let offsetX = (scrollView.frame.width > scrollView.contentSize.width) ? (scrollView.frame.width - scrollView.contentSize.width) * 0.5 : 0
        let offsetY = (scrollView.frame.height > scrollView.contentSize.height) ? (scrollView.frame.height - scrollView.contentSize.height) * 0.5 : 0
        containerView.center = CGPoint(x: scrollView.contentSize.width * 0.5 + offsetX, y: scrollView.contentSize.height * 0.5 + offsetY)
    }

    public func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        isScrolling = false
    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView == mainScrollView else { return }
        isScrolling = true
    }

    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard scrollView == mainScrollView else { return }
        isScrolling = decelerate
    }

    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard scrollView == mainScrollView else { return }
        isScrolling = false
    }

    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        guard scrollView == mainScrollView else { return }
        isScrolling = false
    }
}


// MARK: Draw path
public class ZLDrawPath: NSObject {
    let pathColor: UIColor
    let path: UIBezierPath
    let ratio: CGFloat
    let shapeLayer: CAShapeLayer

    init(pathColor: UIColor, pathWidth: CGFloat, ratio: CGFloat, startPoint: CGPoint) {
        self.pathColor = pathColor
        path = UIBezierPath()
        path.lineWidth = pathWidth / ratio
        path.lineCapStyle = .round
        path.lineJoinStyle = .round
        path.move(to: CGPoint(x: startPoint.x / ratio, y: startPoint.y / ratio))

        shapeLayer = CAShapeLayer()
        shapeLayer.lineCap = .round
        shapeLayer.lineJoin = .round
        shapeLayer.lineWidth = pathWidth / ratio
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.strokeColor = pathColor.cgColor
        shapeLayer.path = path.cgPath

        self.ratio = ratio
        super.init()
    }

    func addLine(to point: CGPoint) {
        path.addLine(to: CGPoint(x: point.x / ratio, y: point.y / ratio))
        shapeLayer.path = path.cgPath
    }

    func drawPath() {
        pathColor.set()
        path.stroke()
    }
}