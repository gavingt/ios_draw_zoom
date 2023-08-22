import UIKit
import Photos
import ZLImageEditor

class ViewController: UIViewController {

    var editImageToolView: UIView!
    var pickImageBtn: UIButton!
    var resultImageView: UIImageView!
    var originalImage: UIImage?
    var resultImageEditModel: ZLEditImageModel?


    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    func setupUI() {
        self.view.backgroundColor = .white

        func createLabel(_ title: String) -> UILabel {
            let label = UILabel()
            label.font = UIFont.systemFont(ofSize: 14)
            label.textColor = .black
            label.text = title
            return label
        }

        let spacing: CGFloat = 20
        // Container
        self.editImageToolView = UIView()
        self.view.addSubview(self.editImageToolView)
        self.editImageToolView.snp.makeConstraints { (make) in
            make.top.equalTo(self.view.snp.topMargin).offset(5)
            make.left.equalTo(self.view).offset(20)
            make.right.equalTo(self.view).offset(-20)
        }

        self.pickImageBtn = UIButton(type: .custom)
        self.pickImageBtn.backgroundColor = .black
        self.pickImageBtn.layer.cornerRadius = 5
        self.pickImageBtn.layer.masksToBounds = true
        self.pickImageBtn.frame.size = CGSize(width: view.frame.width, height: 60)
        self.pickImageBtn.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        self.pickImageBtn.setTitle("Pick an image", for: .normal)
        self.pickImageBtn.addTarget(self, action: #selector(pickImage), for: .touchUpInside)
        self.view.addSubview(self.pickImageBtn)
        self.pickImageBtn.snp.makeConstraints { (make) in
            make.top.equalTo(self.editImageToolView.snp.bottom).offset(spacing)
            make.left.equalTo(self.editImageToolView)
        }

        self.resultImageView = UIImageView()
        self.resultImageView.contentMode = .scaleAspectFit
        self.resultImageView.clipsToBounds = true
        self.view.addSubview(self.resultImageView)
        self.resultImageView.snp.makeConstraints { (make) in
            make.top.equalTo(self.pickImageBtn.snp.bottom).offset(spacing)
            make.left.right.equalTo(self.view)
            make.bottom.equalTo(self.view.snp.bottomMargin)
        }

        let control = UIControl()
        control.addTarget(self, action: #selector(continueEditImage), for: .touchUpInside)
        self.view.addSubview(control)
        control.snp.makeConstraints { (make) in
            make.edges.equalTo(self.resultImageView)
        }
    }


    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.pickImageBtn.frame.size = CGSize(width: view.frame.width - 40, height: 60)
    }


    @objc func pickImage() {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.includeAssetSourceTypes = [.typeUserLibrary, .typeiTunesSynced]
        let photosNotInAlbumsFetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        let phAssetToEdit = photosNotInAlbumsFetchResult.object(at: 6)

        let options = PHImageRequestOptions()
        options.isSynchronous = true
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .fast
        options.isNetworkAccessAllowed = true
        let targetSize = CGSize(width: view.bounds.width, height: view.bounds.height)
        PHImageManager.default().requestImage(for: phAssetToEdit, targetSize: targetSize, contentMode: .default, options: options) { (imageResult, info) in
            self.originalImage = imageResult
            self.editImage(imageResult!, editModel: nil)
        }
    }


    @objc func continueEditImage() {
        guard let oi = self.originalImage else { return }
        self.editImage(oi, editModel: self.resultImageEditModel)
    }


    func editImage(_ image: UIImage, editModel: ZLEditImageModel?) {
        ZLEditImageViewController.showEditImageVC(parentVC: self, image: image, editModel: editModel) { [weak self] (resImage, editModel) in
            self?.resultImageView.image = resImage
            self?.resultImageEditModel = editModel
        }
    }

}
