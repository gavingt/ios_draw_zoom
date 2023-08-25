import UIKit

public class ZLEditImageModel: NSObject {

    public let drawPaths: [ZLDrawPath]
    public let editRect: CGRect?
    public let angle: CGFloat

    public init(drawPaths: [ZLDrawPath], editRect: CGRect?, angle: CGFloat) {
        self.drawPaths = drawPaths
        self.editRect = editRect
        self.angle = angle
        super.init()
    }
}


open class ZLEditImageViewController: UIViewController {

    var originalImage: UIImage
    var editedImage: UIImage
    var editRect: CGRect

    static let normalDrawColor = UIColor(red: 0, green: 0.137, blue: 0.89, alpha: 0.26)
    static let maxDrawLineImageWidth: CGFloat = 600
    static let minimumZoomScale: CGFloat = 0.9

    var drawPaths: [ZLDrawPath]
    var redoDrawPaths: [ZLDrawPath]
    var drawLineWidth: CGFloat = 10

    var isDrawing = false
    var isScrolling = false
    var shouldLayout = true
    var angle: CGFloat

    var panGes: UIPanGestureRecognizer!

    var lastPointTouched = CGPoint()

    var zoomerMargin: CGFloat = 60

    lazy var zoomerWindowDiameter: CGFloat = {
        view.frame.width / 3
    }()

    open lazy var mainScrollView: UIScrollView = {
        let view = UIScrollView()
        view.backgroundColor = .black
        view.minimumZoomScale = ZLEditImageViewController.minimumZoomScale
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
        btn.setImage(UIImage(named: "zl_revoke_disable"), for: .disabled)
        btn.setImage(UIImage(named: "zl_revoke"), for: .normal)
        btn.adjustsImageWhenHighlighted = false
        btn.isEnabled = false
        btn.addTarget(self, action: #selector(undoBtnClick), for: .touchUpInside)
        return btn
    }()

    open lazy var redoBtn: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage(named: "zl_redo_disable"), for: .disabled)
        btn.setImage(UIImage(named: "zl_redo"), for: .normal)
        btn.adjustsImageWhenHighlighted = false
        btn.isEnabled = false
        btn.addTarget(self, action: #selector(redoBtnClick), for: .touchUpInside)
        return btn
    }()

    open lazy var zoomerImageView: UIImageView = {
        let zoomerView = UIImageView(frame: CGRect(x: (view.frame.width / 3), y: zoomerMargin, width: view.frame.width / 3, height: view.frame.width / 3))
        zoomerView.backgroundColor = .black
        zoomerView.layer.borderWidth = 5.0
        zoomerView.layer.masksToBounds = false
        zoomerView.layer.borderColor = UIColor.lightGray.cgColor
        zoomerView.layer.cornerRadius = zoomerView.frame.size.width / 2
        zoomerView.clipsToBounds = true
        zoomerView.isHidden = true
        return zoomerView
    }()


    @objc public var editFinishBlock: ((UIImage, ZLEditImageModel?) -> Void)?

    override open var prefersStatusBarHidden: Bool {
        true
    }

    override open var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .portrait
    }


    @objc public class func showEditImageVC(parentVC: UIViewController?, image: UIImage, editModel: ZLEditImageModel? = nil, completion: ((UIImage, ZLEditImageModel?) -> Void)?) {
        let vc = ZLEditImageViewController(image: image, editModel: editModel)
        vc.editFinishBlock = { ei, editImageModel in
            completion?(ei, editImageModel)
        }
        vc.modalPresentationStyle = .fullScreen
        parentVC?.present(vc, animated: false, completion: nil)
    }

    @objc public init(image: UIImage, editModel: ZLEditImageModel? = nil) {
        originalImage = image.zl.fixOrientation()
        editedImage = originalImage
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
        insets = view.safeAreaInsets

        mainScrollView.frame = view.bounds

        resetContainerViewFrame()

        bottomShadowView.frame = CGRect(x: 0, y: view.zl.height - 140 - insets.bottom, width: view.zl.width, height: 140 + insets.bottom)

        redoBtn.frame = CGRect(x: view.zl.width - 15 - 35, y: 30, width: 35, height: 30)
        undoBtn.frame = CGRect(x: redoBtn.zl.left - 10 - 35, y: 30, width: 35, height: 30)
        doneBtn.frame = CGRect(x: 20, y: 83, width: view.frame.width - 40, height: 40)

        if !drawPaths.isEmpty {
            drawAllLines()
        }
    }

    override open func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        shouldLayout = true
    }


    func resetContainerViewFrame() {
        mainScrollView.setZoomScale(1, animated: true)
        imageView.image = editedImage

        let editSize = editRect.size
        let scrollViewSize = mainScrollView.frame.size
        let ratio = min(scrollViewSize.width / editSize.width, scrollViewSize.height / editSize.height)
        let w = ratio * editSize.width * mainScrollView.zoomScale
        let h = ratio * editSize.height * mainScrollView.zoomScale
        containerView.frame = CGRect(x: max(0, (scrollViewSize.width - w) / 2), y: max(0, (scrollViewSize.height - h) / 2), width: w, height: h)
        mainScrollView.contentSize = containerView.frame.size
        containerView.layer.mask = nil

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
        view.addSubview(zoomerImageView)

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

        var editModel: ZLEditImageModel?
        if hasEdit {
            autoreleasepool {
                // Temporarily increase the line width before creating the mask.
                drawPaths.forEach { path in
                    path.path.lineWidth += 10
                    path.pathColor = .white
                }
                drawAllLines()

                // Set editedImage to all black.
                let imageSize = originalImage.size
                let color: UIColor = .black
                UIGraphicsBeginImageContextWithOptions(imageSize, true, 0)
                let context = UIGraphicsGetCurrentContext()!
                color.setFill()
                context.fill(CGRect(x: 0, y: 0, width: imageSize.width, height: imageSize.height))
                editedImage = UIGraphicsGetImageFromCurrentImageContext()!
                UIGraphicsEndImageContext()

                editedImage = buildImage()
                //paintedImage = paintedImage.zl.compress(to: originalImageData.count)

                // Reduce the line width back to normal so the user can't see that anything changed.
                drawPaths.forEach { path in
                    path.path.lineWidth -= 10
                    path.pathColor = ZLEditImageViewController.normalDrawColor
                }
                drawAllLines()
            }
            editModel = ZLEditImageModel(drawPaths: drawPaths, editRect: editRect, angle: angle)
        }

        dismiss(animated: false) {
            self.editFinishBlock?(self.editedImage, editModel)
        }
    }


    @objc func undoBtnClick() {
        guard !drawPaths.isEmpty else { return }
        drawPaths.removeLast()
        undoBtn.isEnabled = !drawPaths.isEmpty
        redoBtn.isEnabled = drawPaths.count != redoDrawPaths.count
        drawAllLines()
    }


    @objc func redoBtnClick() {
        guard drawPaths.count < redoDrawPaths.count else { return }
        let path = redoDrawPaths[drawPaths.count]
        drawPaths.append(path)
        undoBtn.isEnabled = !drawPaths.isEmpty
        redoBtn.isEnabled = drawPaths.count != redoDrawPaths.count
        drawAllLines()
    }


    @objc func tapAction(_ tap: UITapGestureRecognizer) {

    }


    @objc func drawAction(_ pan: UIPanGestureRecognizer) {
        let point = pan.location(in: drawingImageView)
        // Since point is relative to drawingImageView, we must convert it to be relative to the view.
        lastPointTouched = view.convert(point, from: drawingImageView)

        if pan.state == .began {
            isDrawing = true
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
            if editedImage.size.width / editedImage.size.height > 1 {
                toImageScale = ZLEditImageViewController.maxDrawLineImageWidth / size.height
            }

            let path = ZLDrawPath(pathColor: ZLEditImageViewController.normalDrawColor, pathWidth: drawLineWidth, ratio: ratio / originalRatio / toImageScale, startPoint: point)
            drawPaths.append(path)
            redoDrawPaths = drawPaths
        } else if pan.state == .changed {
            let path = drawPaths.last
            path?.addLine(to: point)
            drawAllLines()
        } else if pan.state == .cancelled || pan.state == .ended {
            isDrawing = false
            undoBtn.isEnabled = !drawPaths.isEmpty
            redoBtn.isEnabled = false
            zoomerImageView.isHidden = true
        }
    }


    // Draw lines to editedImage, and also set the image to drawingImageView.
    func drawAllLines() {
        let originalRatio = min(mainScrollView.frame.width / originalImage.size.width, mainScrollView.frame.height / originalImage.size.height)
        let ratio = min(mainScrollView.frame.width / editRect.width, mainScrollView.frame.height / editRect.height)
        let scale = ratio / originalRatio
        // Zoom to original size.
        var size = drawingImageView.frame.size
        size.width /= scale
        size.height /= scale
        if angle == -90 || angle == -270 {
            swap(&size.width, &size.height)
        }
        var toImageScale = ZLEditImageViewController.maxDrawLineImageWidth / size.width
        if editedImage.size.width / editedImage.size.height > 1 {
            toImageScale = ZLEditImageViewController.maxDrawLineImageWidth / size.height
        }
        size.width *= toImageScale
        size.height *= toImageScale

        UIGraphicsBeginImageContextWithOptions(size, false, editedImage.scale)
        let context = UIGraphicsGetCurrentContext()

        context?.setAllowsAntialiasing(true)
        context?.setShouldAntialias(true)

        for path in drawPaths {
            path.drawPath()
        }

        drawingImageView.image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        drawZoomerImageView()
    }


    func drawZoomerImageView() {
        // Create a blank bitmap context of size zoomerWindowWidth x zoomerWindowWidth.
        UIGraphicsBeginImageContextWithOptions(CGSize(width: zoomerWindowDiameter, height: zoomerWindowDiameter), false, 0)
        // Create a rect the size of the entire view, but shifted so the desired content is in the top-left corner.
        let cropRect = CGRect(x: -(lastPointTouched.x - zoomerWindowDiameter / 2), y: -(lastPointTouched.y - zoomerWindowDiameter / 2), width: view.bounds.size.width, height: view.bounds.size.height)
        // Draw mainScrollView to the blank bitmap context. This draws just the desired content to the bitmap and discards the rest.
        mainScrollView.drawHierarchy(in: cropRect, afterScreenUpdates: true)
        // Fetch bitmap from context.
        zoomerImageView.image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        if (zoomerImageView.isHidden) {
            // Zoomer is not initially visible, so set it visible in the opposite "hemisphere" to what was touched.
            if (lastPointTouched.y > view.frame.height / 2) {
                zoomerImageView.frame = CGRect(x: (view.frame.width / 3), y: zoomerMargin, width: view.frame.width / 3, height: view.frame.width / 3)
            } else {
                zoomerImageView.frame = CGRect(x: (view.frame.width / 3), y: view.frame.height - zoomerWindowDiameter - zoomerMargin, width: view.frame.width / 3, height: view.frame.width / 3)
            }
        } else {
            // Zoomer was already visible, so only change its "hemisphere" if user's touch crosses certain thresholds.
            let touchDistanceFromZoomer = abs(hypot(lastPointTouched.x - (zoomerImageView.frame.origin.x + zoomerWindowDiameter / 2), lastPointTouched.y - (zoomerImageView.frame.origin.y + zoomerWindowDiameter / 2)))
            if (lastPointTouched.y <= zoomerWindowDiameter * 1.5 + zoomerMargin) {
                zoomerImageView.frame = CGRect(x: (view.frame.width / 3), y: view.frame.height - zoomerWindowDiameter - zoomerMargin, width: view.frame.width / 3, height: view.frame.width / 3)
            } else if (lastPointTouched.y >= view.frame.height - (zoomerWindowDiameter * 1.5) - zoomerMargin || (lastPointTouched.y >= view.frame.height / 2 && touchDistanceFromZoomer <= zoomerWindowDiameter * 1.5)) {
                zoomerImageView.frame = CGRect(x: (view.frame.width / 3), y: zoomerMargin, width: view.frame.width / 3, height: view.frame.width / 3)
            }
        }

        if (zoomerImageView.isHidden && isDrawing) {
            zoomerImageView.isHidden = false
        }
    }


    func buildImage() -> UIImage {
        let imageSize = originalImage.size

        UIGraphicsBeginImageContextWithOptions(editedImage.size, false, editedImage.scale)
        editedImage.draw(at: .zero)

        drawingImageView.image?.draw(in: CGRect(origin: .zero, size: imageSize))

        let temp = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        guard let cgi = temp?.cgImage else {
            return editedImage
        }
        return UIImage(cgImage: cgi, scale: editedImage.scale, orientation: .up)
    }

}


extension ZLEditImageViewController: UIGestureRecognizerDelegate {
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer is UITapGestureRecognizer {
            let p = gestureRecognizer.location(in: view)
            return !bottomShadowView.frame.contains(p)
        } else if gestureRecognizer is UIPanGestureRecognizer {
            return !isScrolling
        }

        return true
    }
}


// MARK: scroll view delegate
extension ZLEditImageViewController: UIScrollViewDelegate {
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        containerView
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
        isScrolling = false
    }

    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        isScrolling = decelerate
    }

    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        isScrolling = false
    }

    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        isScrolling = false
    }
}


// MARK: Draw path
public class ZLDrawPath: NSObject {
    var pathColor: UIColor
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