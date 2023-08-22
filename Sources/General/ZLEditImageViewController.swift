import UIKit

public class ZLEditImageModel: NSObject {
    public let drawPaths: [ZLDrawPath]

    public let mosaicPaths: [ZLMosaicPath]

    public let editRect: CGRect?

    public let angle: CGFloat

    public let brightness: Float

    public let contrast: Float

    public let saturation: Float

    public let selectRatio: ZLImageClipRatio?

    public let selectFilter: ZLFilter?

/*    public let textStickers: [(state: ZLTextStickerState, index: Int)]?

    public let imageStickers: [(state: ZLImageStickerState, index: Int)]?*/

    public init(
            drawPaths: [ZLDrawPath],
            mosaicPaths: [ZLMosaicPath],
            editRect: CGRect?,
            angle: CGFloat,
            brightness: Float,
            contrast: Float,
            saturation: Float,
            selectRatio: ZLImageClipRatio?,
            selectFilter: ZLFilter/*,
            textStickers: [(state: ZLTextStickerState, index: Int)]?,
            imageStickers: [(state: ZLImageStickerState, index: Int)]?*/
    ) {
        self.drawPaths = drawPaths
        self.mosaicPaths = mosaicPaths
        self.editRect = editRect
        self.angle = angle
        self.brightness = brightness
        self.contrast = contrast
        self.saturation = saturation
        self.selectRatio = selectRatio
        self.selectFilter = selectFilter
//        self.textStickers = textStickers
//        self.imageStickers = imageStickers
        super.init()
    }
}

open class ZLEditImageViewController: UIViewController {
    static let maxDrawLineImageWidth: CGFloat = 600

    static let shadowColorFrom = UIColor.black.withAlphaComponent(0.35).cgColor

    static let shadowColorTo = UIColor.clear.cgColor

    public var drawColViewH: CGFloat = 50

    public var filterColViewH: CGFloat = 80

    public var adjustColViewH: CGFloat = 60

    public var ashbinSize = CGSize(width: 160, height: 80)

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

    open lazy var topShadowView = UIView()

    open lazy var topShadowLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.colors = [ZLEditImageViewController.shadowColorFrom, ZLEditImageViewController.shadowColorTo]
        layer.locations = [0, 1]
        return layer
    }()

    open lazy var bottomShadowView = UIView()

    open lazy var bottomShadowLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.colors = [ZLEditImageViewController.shadowColorTo, ZLEditImageViewController.shadowColorFrom]
        layer.locations = [0, 1]
        return layer
    }()

    open lazy var cancelBtn: ZLEnlargeButton = {
        let btn = ZLEnlargeButton(type: .custom)
        btn.setImage(getImage("zl_retake"), for: .normal)
        btn.addTarget(self, action: #selector(cancelBtnClick), for: .touchUpInside)
        btn.adjustsImageWhenHighlighted = false
        btn.enlargeInset = 30
        return btn
    }()

    open lazy var doneBtn: UIButton = {
        let btn = UIButton(type: .custom)
        btn.titleLabel?.font = ZLImageEditorLayout.bottomToolTitleFont
        btn.backgroundColor = .zl.editDoneBtnBgColor
        btn.setTitle(localLanguageTextValue(.editFinish), for: .normal)
        btn.setTitleColor(.zl.editDoneBtnTitleColor, for: .normal)
        btn.addTarget(self, action: #selector(doneBtnClick), for: .touchUpInside)
        btn.layer.masksToBounds = true
        btn.layer.cornerRadius = ZLImageEditorLayout.bottomToolBtnCornerRadius
        return btn
    }()

    open lazy var revokeBtn: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(getImage("zl_revoke_disable"), for: .disabled)
        btn.setImage(getImage("zl_revoke"), for: .normal)
        btn.adjustsImageWhenHighlighted = false
        btn.isEnabled = false
        btn.isHidden = true
        btn.addTarget(self, action: #selector(revokeBtnClick), for: .touchUpInside)
        return btn
    }()

    open var redoBtn: UIButton?

/*    open lazy var editToolCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 30, height: 30)
        layout.minimumLineSpacing = 20
        layout.minimumInteritemSpacing = 20
        layout.scrollDirection = .horizontal

        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.backgroundColor = .clear
        view.delegate = self
        view.dataSource = self
        view.showsHorizontalScrollIndicator = false
        ZLEditToolCell.zl.register(view)

        return view
    }()

    open var drawColorCollectionView: UICollectionView?

    open var filterCollectionView: UICollectionView?

    open var adjustCollectionView: UICollectionView?*/

    open lazy var ashbinView: UIView = {
        let view = UIView()
        view.backgroundColor = .zl.ashbinNormalBgColor
        view.layer.cornerRadius = 15
        view.layer.masksToBounds = true
        view.isHidden = true
        return view
    }()

    open lazy var ashbinImgView = UIImageView(image: getImage("zl_ashbin"), highlightedImage: getImage("zl_ashbin_open"))

    var adjustSlider: ZLAdjustSlider?

    var animateDismiss = true

    var originalImage: UIImage

    // The frame after first layout, used in dismiss animation.
    var originalFrame: CGRect = .zero

    var editRect: CGRect

    let tools: [ZLImageEditorConfiguration.EditTool]

    let adjustTools: [ZLImageEditorConfiguration.AdjustTool]

    var selectRatio: ZLImageClipRatio?

    var editImage: UIImage

    var editImageWithoutAdjust: UIImage

    var editImageAdjustRef: UIImage?

    // Show draw lines.
    lazy var drawingImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.isUserInteractionEnabled = true
        return view
    }()

    // Show text and image stickers.
    lazy var stickersContainer = UIView()

    var mosaicImage: UIImage?

    // Show mosaic image
    var mosaicImageLayer: CALayer?

    // The mask layer of mosaicImageLayer
    var mosaicImageLayerMaskLayer: CAShapeLayer?

    var selectedTool: ZLImageEditorConfiguration.EditTool?

    var selectedAdjustTool: ZLImageEditorConfiguration.AdjustTool?

    let drawColors: [UIColor]

    var currentDrawColor = UIColor(red: 0, green: 0.137, blue: 0.89, alpha: 0.26)

    var drawPaths: [ZLDrawPath]

    var redoDrawPaths: [ZLDrawPath]

    var drawLineWidth: CGFloat = 5

    var mosaicPaths: [ZLMosaicPath]

    var redoMosaicPaths: [ZLMosaicPath]

    var mosaicLineWidth: CGFloat = 25

    var thumbnailFilterImages: [UIImage] = []

    // Cache the filter image of original image
    var filterImages: [String: UIImage] = [:]

    var currentFilter: ZLFilter

    var stickers: [UIView] = []

    var isScrolling = false

    var shouldLayout = true

    var imageStickerContainerIsHidden = true

    var fontChooserContainerIsHidden = true

    var angle: CGFloat

    var brightness: Float

    var contrast: Float

    var saturation: Float

    var panGes: UIPanGestureRecognizer!

    var imageSize: CGSize {
        if angle == -90 || angle == -270 {
            return CGSize(width: originalImage.size.height, height: originalImage.size.width)
        }
        return originalImage.size
    }

    var toolViewStateTimer: Timer?

    let canRedo = ZLImageEditorConfiguration.default().canRedo

    var hasAdjustedImage = false

    @objc public var editFinishBlock: ((UIImage, ZLEditImageModel?) -> Void)?

    override open var prefersStatusBarHidden: Bool {
        return true
    }

    override open var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }


    @objc public class func showEditImageVC(
            parentVC: UIViewController?,
            animate: Bool = true,
            image: UIImage,
            editModel: ZLEditImageModel? = nil,
            completion: ((UIImage, ZLEditImageModel?) -> Void)?
    ) {
        let tools = ZLImageEditorConfiguration.default().tools
        if ZLImageEditorConfiguration.default().showClipDirectlyIfOnlyHasClipTool, tools.count == 1, tools.contains(.clip) {
            let vc = ZLClipImageViewController(image: image, editRect: editModel?.editRect, angle: editModel?.angle ?? 0, selectRatio: editModel?.selectRatio)
            vc.clipDoneBlock = { angle, editRect, ratio in
                let m = ZLEditImageModel(drawPaths: [], mosaicPaths: [], editRect: editRect, angle: angle, brightness: 0, contrast: 0, saturation: 0, selectRatio: ratio, selectFilter: .normal/*, textStickers: nil, imageStickers: nil*/)
                completion?(image.zl.clipImage(angle: angle, editRect: editRect, isCircle: ratio.isCircle) ?? image, m)
            }
            vc.animateDismiss = animate
            vc.modalPresentationStyle = .fullScreen
            parentVC?.present(vc, animated: animate, completion: nil)
        } else {
            let vc = ZLEditImageViewController(image: image, editModel: editModel)
            vc.editFinishBlock = { ei, editImageModel in
                completion?(ei, editImageModel)
            }
            vc.animateDismiss = animate
            vc.modalPresentationStyle = .fullScreen
            parentVC?.present(vc, animated: animate, completion: nil)
        }
    }

    @objc public init(image: UIImage, editModel: ZLEditImageModel? = nil) {
        originalImage = image.zl.fixOrientation()
        editImage = originalImage
        editImageWithoutAdjust = originalImage
        editRect = editModel?.editRect ?? CGRect(origin: .zero, size: image.size)
        drawColors = ZLImageEditorConfiguration.default().drawColors
        currentFilter = editModel?.selectFilter ?? .normal
        drawPaths = editModel?.drawPaths ?? []
        redoDrawPaths = drawPaths
        mosaicPaths = editModel?.mosaicPaths ?? []
        redoMosaicPaths = mosaicPaths
        angle = editModel?.angle ?? 0
        brightness = editModel?.brightness ?? 0
        contrast = editModel?.contrast ?? 0
        saturation = editModel?.saturation ?? 0
        selectRatio = editModel?.selectRatio

        var ts = ZLImageEditorConfiguration.default().tools
        if ts.contains(.imageSticker), ZLImageEditorConfiguration.default().imageStickerContainerView == nil {
            ts.removeAll { $0 == .imageSticker }
        }
        tools = ts
        adjustTools = ZLImageEditorConfiguration.default().adjustTools
        selectedAdjustTool = adjustTools.first

        super.init(nibName: nil, bundle: nil)

        /*        if !drawColors.contains(currentDrawColor) {
            currentDrawColor = drawColors.first!
        }*/

/*        let teStic = editModel?.textStickers ?? []
        let imStic = editModel?.imageStickers ?? []

        var stickers: [UIView?] = Array(repeating: nil, count: teStic.count + imStic.count)
        teStic.forEach { cache in
            let v = ZLTextStickerView(from: cache.state)
            stickers[cache.index] = v
        }
        imStic.forEach { cache in
            let v = ZLImageStickerView(from: cache.state)
            stickers[cache.index] = v
        }

        self.stickers = stickers.compactMap { $0 }*/
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override open func viewDidLoad() {
        super.viewDidLoad()

        setupUI()

        rotationImageView()
        /*        if tools.contains(.filter) {
            generateFilterImages()
        }*/

        // Start in drawing mode.
        drawBtnClick()
    }

    override open func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard shouldLayout else { return }

        shouldLayout = false
        var insets = UIEdgeInsets.zero
        insets = self.view.safeAreaInsets

        mainScrollView.frame = view.bounds
        resetContainerViewFrame()

        topShadowView.frame = CGRect(x: 0, y: 0, width: view.zl.width, height: 150)
        topShadowLayer.frame = topShadowView.bounds
        cancelBtn.frame = CGRect(x: 30, y: insets.top + 10, width: 28, height: 28)

        bottomShadowView.frame = CGRect(x: 0, y: view.zl.height - 140 - insets.bottom, width: view.zl.width, height: 140 + insets.bottom)
        bottomShadowLayer.frame = bottomShadowView.bounds

        if canRedo, let redoBtn = redoBtn {
            redoBtn.frame = CGRect(x: view.zl.width - 15 - 35, y: 30, width: 35, height: 30)
            revokeBtn.frame = CGRect(x: redoBtn.zl.left - 10 - 35, y: 30, width: 35, height: 30)
        } else {
            revokeBtn.frame = CGRect(x: view.zl.width - 15 - 35, y: 30, width: 35, height: 30)
        }
/*        drawColorCollectionView?.frame = CGRect(x: 20, y: 20, width: revokeBtn.zl.left - 20 - 10, height: drawColViewH)

        adjustCollectionView?.frame = CGRect(x: 20, y: 10, width: view.zl.width - 40, height: adjustColViewH)
        if ZLImageEditorUIConfiguration.default().adjustSliderType == .vertical {
            adjustSlider?.frame = CGRect(x: view.zl.width - 60, y: view.zl.height / 2 - 100, width: 60, height: 200)
        } else {
            let sliderHeight: CGFloat = 60
            let sliderWidth = UIDevice.current.userInterfaceIdiom == .phone ? view.zl.width - 100 : view.zl.width / 2
            adjustSlider?.frame = CGRect(
                    x: (view.zl.width - sliderWidth) / 2,
                    y: bottomShadowView.zl.top - sliderHeight,
                    width: sliderWidth,
                    height: sliderHeight
            )
        }

        filterCollectionView?.frame = CGRect(x: 20, y: 0, width: view.zl.width - 40, height: filterColViewH)*/

        ashbinView.frame = CGRect(
                x: (view.zl.width - ashbinSize.width) / 2,
                y: view.zl.height - ashbinSize.height - 40,
                width: ashbinSize.width,
                height: ashbinSize.height
        )
        ashbinImgView.frame = CGRect(
                x: (ashbinSize.width - 25) / 2,
                y: 15,
                width: 25,
                height: 25
        )

        let toolY: CGFloat = 85

        let doneBtnH = ZLImageEditorLayout.bottomToolBtnH
        let doneBtnW = localLanguageTextValue(.editFinish).zl.boundingRect(font: ZLImageEditorLayout.bottomToolTitleFont, limitSize: CGSize(width: CGFloat.greatestFiniteMagnitude, height: doneBtnH)).width + 20
        doneBtn.frame = CGRect(x: view.zl.width - 20 - doneBtnW, y: toolY - 2, width: doneBtnW, height: doneBtnH)

        //editToolCollectionView.frame = CGRect(x: 20, y: toolY, width: view.zl.width - 20 - 20 - doneBtnW - 20, height: 30)

        if !drawPaths.isEmpty {
            drawLine()
        }
/*        if !mosaicPaths.isEmpty {
            generateNewMosaicImage()
        }*/

/*        if let index = drawColors.firstIndex(where: { $0 == self.currentDrawColor }) {
            drawColorCollectionView?.scrollToItem(at: IndexPath(row: index, section: 0), at: .centeredHorizontally, animated: false)
        }*/
    }

    override open func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        shouldLayout = true
    }

/*    func generateFilterImages() {
        let size: CGSize
        let ratio = (originalImage.size.width / originalImage.size.height)
        let fixLength: CGFloat = 200
        if ratio >= 1 {
            size = CGSize(width: fixLength * ratio, height: fixLength)
        } else {
            size = CGSize(width: fixLength, height: fixLength / ratio)
        }
        let thumbnailImage = originalImage.zl.resize(size) ?? originalImage

        DispatchQueue.global().async {
            self.thumbnailFilterImages = ZLImageEditorConfiguration.default().filters.map { $0.applier?(thumbnailImage) ?? thumbnailImage }

            DispatchQueue.main.async {
                self.filterCollectionView?.reloadData()
                self.filterCollectionView?.performBatchUpdates {} completion: { _ in
                    if let index = ZLImageEditorConfiguration.default().filters.firstIndex(where: { $0 == self.currentFilter }) {
                        self.filterCollectionView?.scrollToItem(at: IndexPath(row: index, section: 0), at: .centeredHorizontally, animated: false)
                    }
                }
            }
        }
    }*/

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

        if selectRatio?.isCircle == true {
            let mask = CAShapeLayer()
            let path = UIBezierPath(arcCenter: CGPoint(x: w / 2, y: h / 2), radius: w / 2, startAngle: 0, endAngle: .pi * 2, clockwise: true)
            mask.path = path.cgPath
            containerView.layer.mask = mask
        } else {
            containerView.layer.mask = nil
        }

        let scaleImageOrigin = CGPoint(x: -editRect.origin.x * ratio, y: -editRect.origin.y * ratio)
        let scaleImageSize = CGSize(width: imageSize.width * ratio, height: imageSize.height * ratio)
        imageView.frame = CGRect(origin: scaleImageOrigin, size: scaleImageSize)
        mosaicImageLayer?.frame = imageView.bounds
        mosaicImageLayerMaskLayer?.frame = imageView.bounds
        drawingImageView.frame = imageView.frame
        stickersContainer.frame = imageView.frame

        // Optimization for long pictures.
        if (editRect.height / editRect.width) > (view.frame.height / view.frame.width * 1.1) {
            let widthScale = view.frame.width / w
            mainScrollView.maximumZoomScale = widthScale
            mainScrollView.zoomScale = widthScale
            mainScrollView.contentOffset = .zero
        } else if editRect.width / editRect.height > 1 {
            mainScrollView.maximumZoomScale = max(3, view.frame.height / h)
        }

        originalFrame = view.convert(containerView.frame, from: mainScrollView)
        isScrolling = false
    }

    func setupUI() {
        view.backgroundColor = .black

        view.addSubview(mainScrollView)
        mainScrollView.addSubview(containerView)
        containerView.addSubview(imageView)
        containerView.addSubview(drawingImageView)
        containerView.addSubview(stickersContainer)

        view.addSubview(topShadowView)
        topShadowView.layer.addSublayer(topShadowLayer)
        topShadowView.addSubview(cancelBtn)

        view.addSubview(bottomShadowView)
        bottomShadowView.layer.addSublayer(bottomShadowLayer)
        //bottomShadowView.addSubview(editToolCollectionView)
        bottomShadowView.addSubview(doneBtn)

        //if tools.contains(.draw) {
            let drawColorLayout = UICollectionViewFlowLayout()
            let drawColorItemWidth: CGFloat = 30
            drawColorLayout.itemSize = CGSize(width: drawColorItemWidth, height: drawColorItemWidth)
            drawColorLayout.minimumLineSpacing = 15
            drawColorLayout.minimumInteritemSpacing = 15
            drawColorLayout.scrollDirection = .horizontal
            let drawColorTopBottomInset = (drawColViewH - drawColorItemWidth) / 2
            drawColorLayout.sectionInset = UIEdgeInsets(top: drawColorTopBottomInset, left: 0, bottom: drawColorTopBottomInset, right: 0)

/*            let drawCV = UICollectionView(frame: .zero, collectionViewLayout: drawColorLayout)
            drawCV.backgroundColor = .clear
            drawCV.delegate = self
            drawCV.dataSource = self
            drawCV.isHidden = true
            drawCV.showsHorizontalScrollIndicator = false
            bottomShadowView.addSubview(drawCV)

            ZLDrawColorCell.zl.register(drawCV)
            drawColorCollectionView = drawCV
        //}*/

/*        if tools.contains(.filter) {
            if let applier = currentFilter.applier {
                let image = applier(originalImage)
                editImage = image
                editImageWithoutAdjust = image
                filterImages[currentFilter.name] = image
            }

            let filterLayout = UICollectionViewFlowLayout()
            filterLayout.itemSize = CGSize(width: filterColViewH - 20, height: filterColViewH)
            filterLayout.minimumLineSpacing = 15
            filterLayout.minimumInteritemSpacing = 15
            filterLayout.scrollDirection = .horizontal

            let filterCV = UICollectionView(frame: .zero, collectionViewLayout: filterLayout)
            filterCV.backgroundColor = .clear
            filterCV.delegate = self
            filterCV.dataSource = self
            filterCV.isHidden = true
            filterCV.showsHorizontalScrollIndicator = false
            bottomShadowView.addSubview(filterCV)

            ZLFilterImageCell.zl.register(filterCV)
            filterCollectionView = filterCV
        }*/

/*        if tools.contains(.adjust) {
            editImage = editImage.zl.adjust(brightness: brightness, contrast: contrast, saturation: saturation) ?? editImage

            let adjustLayout = UICollectionViewFlowLayout()
            adjustLayout.itemSize = CGSize(width: adjustColViewH, height: adjustColViewH)
            adjustLayout.minimumLineSpacing = 10
            adjustLayout.minimumInteritemSpacing = 10
            adjustLayout.scrollDirection = .horizontal

            let adjustCV = UICollectionView(frame: .zero, collectionViewLayout: adjustLayout)

            adjustCV.backgroundColor = .clear
            adjustCV.delegate = self
            adjustCV.dataSource = self
            adjustCV.isHidden = true
            adjustCV.showsHorizontalScrollIndicator = false
            bottomShadowView.addSubview(adjustCV)

            ZLAdjustToolCell.zl.register(adjustCV)
            adjustCollectionView = adjustCV

            adjustSlider = ZLAdjustSlider()
            if let selectedAdjustTool = selectedAdjustTool {
                changeAdjustTool(selectedAdjustTool)
            }
            adjustSlider?.beginAdjust = {}
            adjustSlider?.valueChanged = { [weak self] value in
                self?.adjustValueChanged(value)
            }
            adjustSlider?.endAdjust = { [weak self] in
                self?.hasAdjustedImage = true
            }
            adjustSlider?.isHidden = true
            view.addSubview(adjustSlider!)
        }*/

        bottomShadowView.addSubview(revokeBtn)
        if canRedo {
            let btn = UIButton(type: .custom)
            btn.setImage(getImage("zl_redo_disable"), for: .disabled)
            btn.setImage(getImage("zl_redo"), for: .normal)
            btn.adjustsImageWhenHighlighted = false
            btn.isEnabled = false
            btn.isHidden = true
            btn.addTarget(self, action: #selector(redoBtnClick), for: .touchUpInside)
            bottomShadowView.addSubview(btn)
            redoBtn = btn
        }

        view.addSubview(ashbinView)
        ashbinView.addSubview(ashbinImgView)

        let asbinTipLabel = UILabel(frame: CGRect(x: 0, y: ashbinSize.height - 34, width: ashbinSize.width, height: 34))
        asbinTipLabel.font = UIFont.systemFont(ofSize: 12)
        asbinTipLabel.textAlignment = .center
        asbinTipLabel.textColor = .white
        asbinTipLabel.text = localLanguageTextValue(.textStickerRemoveTips)
        asbinTipLabel.numberOfLines = 2
        asbinTipLabel.lineBreakMode = .byCharWrapping
        ashbinView.addSubview(asbinTipLabel)

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
        let transform = CGAffineTransform(rotationAngle: angle.zl.toPi)
        imageView.transform = transform
        drawingImageView.transform = transform
        stickersContainer.transform = transform
    }

    @objc func cancelBtnClick() {
        dismiss(animated: animateDismiss, completion: nil)
    }

    func drawBtnClick() {
        let isSelected = selectedTool != .draw
        if isSelected {
            selectedTool = .draw
        } else {
            selectedTool = nil
        }
        revokeBtn.isHidden = !isSelected
        revokeBtn.isEnabled = !drawPaths.isEmpty
        redoBtn?.isHidden = !isSelected
        redoBtn?.isEnabled = drawPaths.count != redoDrawPaths.count
    }


    @objc func doneBtnClick() {
        var hasEdit = true
        if drawPaths.isEmpty, editRect.size == imageSize, angle == 0, mosaicPaths.isEmpty, true, true, currentFilter.applier == nil, brightness == 0, contrast == 0, saturation == 0 {
            hasEdit = false
        }

        var resImage = originalImage
        var editModel: ZLEditImageModel?
        if hasEdit {
            autoreleasepool {
                let hud = ZLProgressHUD(style: ZLImageEditorUIConfiguration.default().hudStyle)
                hud.show()

                resImage = buildImage()
                resImage = resImage.zl.clipImage(angle: angle, editRect: editRect, isCircle: selectRatio?.isCircle ?? false) ?? resImage
                if let oriDataSize = originalImage.jpegData(compressionQuality: 1)?.count {
                    resImage = resImage.zl.compress(to: oriDataSize)
                }

                hud.hide()
            }

            editModel = ZLEditImageModel(
                    drawPaths: drawPaths,
                    mosaicPaths: mosaicPaths,
                    editRect: editRect,
                    angle: angle,
                    brightness: brightness,
                    contrast: contrast,
                    saturation: saturation,
                    selectRatio: selectRatio,
                    selectFilter: currentFilter
            )
        }

        dismiss(animated: animateDismiss) {
            self.editFinishBlock?(resImage, editModel)
        }
    }

    @objc func revokeBtnClick() {
            guard !drawPaths.isEmpty else {
                return
            }
            drawPaths.removeLast()
            revokeBtn.isEnabled = !drawPaths.isEmpty
            redoBtn?.isEnabled = drawPaths.count != redoDrawPaths.count
            drawLine()
    }

    @objc func redoBtnClick() {
            guard drawPaths.count < redoDrawPaths.count else {
                return
            }
            let path = redoDrawPaths[drawPaths.count]
            drawPaths.append(path)
            revokeBtn.isEnabled = !drawPaths.isEmpty
            redoBtn?.isEnabled = drawPaths.count != redoDrawPaths.count
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

                let path = ZLDrawPath(pathColor: currentDrawColor, pathWidth: drawLineWidth / mainScrollView.zoomScale, ratio: ratio / originalRatio / toImageScale, startPoint: point)
                drawPaths.append(path)
                redoDrawPaths = drawPaths
            } else if pan.state == .changed {
                let path = drawPaths.last
                path?.addLine(to: point)
                drawLine()
            } else if pan.state == .cancelled || pan.state == .ended {
                revokeBtn.isEnabled = !drawPaths.isEmpty
                redoBtn?.isEnabled = false
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

    func finishClipDismissAnimate() {
        mainScrollView.alpha = 1
        UIView.animate(withDuration: 0.1) {
            self.topShadowView.alpha = 1
            self.bottomShadowView.alpha = 1
            self.adjustSlider?.alpha = 1
        }
    }
}

extension ZLEditImageViewController: UIGestureRecognizerDelegate {
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard imageStickerContainerIsHidden, fontChooserContainerIsHidden else {
            return false
        }
        if gestureRecognizer is UITapGestureRecognizer {
            if bottomShadowView.alpha == 1 {
                let p = gestureRecognizer.location(in: view)
                return !bottomShadowView.frame.contains(p)
            } else {
                return true
            }
        } else if gestureRecognizer is UIPanGestureRecognizer {
            guard let st = selectedTool else {
                return false
            }
            return (st == .draw || st == .mosaic) && !isScrolling
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
        guard scrollView == mainScrollView else {
            return
        }
        isScrolling = true
    }

    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard scrollView == mainScrollView else {
            return
        }
        isScrolling = decelerate
    }

    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard scrollView == mainScrollView else {
            return
        }
        isScrolling = false
    }

    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        guard scrollView == mainScrollView else {
            return
        }
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

// MARK: Mosaic path
public class ZLMosaicPath: NSObject {
    let path: UIBezierPath

    let ratio: CGFloat

    let startPoint: CGPoint

    var linePoints: [CGPoint] = []

    init(pathWidth: CGFloat, ratio: CGFloat, startPoint: CGPoint) {
        path = UIBezierPath()
        path.lineWidth = pathWidth
        path.lineCapStyle = .round
        path.lineJoinStyle = .round
        path.move(to: startPoint)

        self.ratio = ratio
        self.startPoint = CGPoint(x: startPoint.x / ratio, y: startPoint.y / ratio)

        super.init()
    }

    func addLine(to point: CGPoint) {
        path.addLine(to: point)
        linePoints.append(CGPoint(x: point.x / ratio, y: point.y / ratio))
    }
}
