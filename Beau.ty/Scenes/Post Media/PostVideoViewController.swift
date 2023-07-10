//
//  PostVideoViewController.swift
//  Beau.ty
//  Created by Boqian Cheng on 2023-01-04.
//

import Foundation
import UIKit
import AVFoundation
import Lottie
import Combine

class PostVideoViewController: UIViewController {
    
    private struct Constants {
        static let leadingSpacing: CGFloat = 17
        static let trailingSpacing: CGFloat = 17
        static let topSpacing: CGFloat = 17
        static let bottomSpacing: CGFloat = 22
        
        static let naviTopSpacing: CGFloat = 50
        
        static let horizontalSpacing: CGFloat = 12
        static let verticalSpacing: CGFloat = 12
        
        static let iconBtnHeight: CGFloat = 29
        static let iconBtnWidth: CGFloat = 25
        static let postBtnHeight: CGFloat = 40
        static let postBtnWidth: CGFloat = 190
        static let topContainerHeight: CGFloat = 90
        static let bottomContainerHeight: CGFloat = 100
        
        static let videoCoverWidth: CGFloat = 85
        
        static let loadingAnimationSize: CGFloat = 160
    }
    
    private lazy var topContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.gray226
        return view
    }()
    
    private lazy var crossButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        let image = UIImage.cross?.withTintColor(UIColor.black)
        button.setImage(image, for: .normal)
        return button
    }()
    
    private let midScrollView: UIScrollView = {
        let container = UIScrollView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = UIColor.screenBase243
        return container
    }()
    
    private let midContainer: UIView = {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = UIColor.clear
        return container
    }()
    
    private lazy var videoImageCover: UIImageView = {
        let imgView = UIImageView(image: nil)
        imgView.translatesAutoresizingMaskIntoConstraints = false
        imgView.isUserInteractionEnabled = false
        imgView.backgroundColor = UIColor.black
        return imgView
    }()
    
    private lazy var keywordInput: PlaceholderTextView = {
        let input = PlaceholderTextView(frame: .zero)
        input.translatesAutoresizingMaskIntoConstraints = false
        input.returnKeyType = .done
        input.keyboardType = .default
        input.textAlignment = .left
        return input
    }()
    
    private lazy var hashtagInput: LabelTextView = {
        let textField = LabelTextView(labelTitleStr: String.hashtagsStr.localized())
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private lazy var broadcastLink: LabelTextView = {
        let textField = LabelTextView(labelTitleStr: String.broadcastLinkStr.localized())
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private lazy var bottomContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.tabbarBackground
        return view
    }()
    
    private lazy var postButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = UIColor.green
        button.setTitle(String.postVideoStr.localized(), for: .normal)
        button.setTitleColor(UIColor.black, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        button.layer.cornerRadius = Constants.postBtnHeight / 2
        button.layer.masksToBounds = true
        return button
    }()
    
    private lazy var uploadingCover: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.white.withAlphaComponent(0.7)
        return view
    }()
    
    private lazy var uploadingLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.backgroundColor = UIColor.clear
        label.isUserInteractionEnabled = false
        label.font = UIFont.systemFont(ofSize: 18)
        label.textColor = UIColor.black
        label.numberOfLines = 1
        label.textAlignment = .left
        label.text = String.uploadingStr.localized()
        return label
    }()
    
    private lazy var loadingWheel: LottieAnimationView = {
        let view = LottieAnimationView(name: "loading-animation")
        view.translatesAutoresizingMaskIntoConstraints = false
        view.contentMode = .scaleAspectFill
        view.animationSpeed = 1.6
        view.loopMode = .loop
        view.isUserInteractionEnabled = false
        return view
    }()
    
    private lazy var progressBar: UIProgressView = {
        let view = UIProgressView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.progressViewStyle = .default
        view.progressTintColor = UIColor.blue
        view.layer.cornerRadius = 11
        view.layer.masksToBounds = true
        
        return view
    }()
    
    private let postMediaViewModel: PostMediaViewModel
    private let hashtagsTextViewID: String = UUID().uuidString
    private let broadcastLinkTextViewID: String = UUID().uuidString
    
    private var videoWidth: CGFloat = 80
    private var videoHeight: CGFloat = 80 * 16 / 9
    
    private var disposables = Set<AnyCancellable>()
    
    init(postMediaViewModel: PostMediaViewModel) {
        self.postMediaViewModel = postMediaViewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.clear
        
        let url = self.postMediaViewModel.videoURL
        self.videoImageCover.image = self.videoSnapshot(fileURL: url)
        
        self.setupUI()
        self.setupButtonActions()
        self.observeHashtagsInput()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        AppGlobalVariables.shared.currentVC = .PostVideoViewController
        self.keywordInput.becomeFirstResponder()
    }
    
    private func setupButtonActions() {
        self.crossButton.addTarget(self, action: #selector(PostVideoViewController.dismissVC), for: .touchUpInside)
        
        self.postButton.addTarget(self, action: #selector(PostVideoViewController.postVideo), for: .touchUpInside)
    }
    
    private func observeHashtagsInput() {
        self.postMediaViewModel.$hashtags
            .sink(receiveValue: { [weak self] input in
                guard let strongSelf = self else { return }
                let inputStr = input.reduce("", +)
                if inputStr.isEmpty {
                    strongSelf.hashtagInput.text = "#"
                } else {
                    strongSelf.hashtagInput.text = inputStr
                }
            })
            .store(in: &disposables)
    }
    
    @objc
    private func postVideo() {
        let hashtagsStr = self.hashtagInput.text ?? ""
        var hashtagsArr = hashtagsStr.components(separatedBy: "#")
        hashtagsArr = hashtagsArr.map { ele in
            var newEle = ele.trimmingCharacters(in: .whitespacesAndNewlines)
            newEle = newEle.filter {
                ![",", ".", "，", "。", " ", "\n", "\t", "\r", "\"", "\'"].contains($0)
            }
            return newEle
        }
        hashtagsArr = hashtagsArr.filter {
            !$0.isEmpty
        }
        hashtagsArr = hashtagsArr.map { "#" + $0 }
        
        self.postMediaViewModel.hashtags = hashtagsArr
        self.postMediaViewModel.broadcastLink = self.broadcastLink.text ?? ""
        self.postMediaViewModel.videoWidth = Int(self.videoWidth)
        self.postMediaViewModel.videoHeight = Int(self.videoHeight)
        self.uploadingCover.isHidden = false
        self.progressBar.isHidden = false
        self.uploadingLabel.isHidden = false
        postMediaViewModel.publishVideoToStorage(
            progress: { [weak self] fraction in
                self?.progressBar.progress = Float(fraction)
                if fraction > 0.999 {
                    self?.progressBar.isHidden = true
                    self?.uploadingLabel.isHidden = true
                    self?.loadingWheel.isHidden = false
                    self?.loadingWheel.play()
                }
            },
            completion: { [weak self] result in
                switch result {
                case .success(_):
                    self?.progressBar.isHidden = true
                    self?.uploadingLabel.isHidden = true
                    self?.loadingWheel.pause()
                    self?.loadingWheel.isHidden = true
                    self?.uploadingCover.isHidden = true
                    let positiveAction = Action(title: String.OKStr.localized(), handler: { _ in
                        self?.finishPosting()
                    })
                    self?.showAlert(
                        title: String.uploadedSuccessfullyStr.localized(),
                        msg: nil,
                        positiveAction: positiveAction,
                        negativeAction: nil
                    )
                case .failure(_):
                    self?.progressBar.isHidden = true
                    self?.uploadingLabel.isHidden = true
                    self?.loadingWheel.pause()
                    self?.loadingWheel.isHidden = true
                    self?.uploadingCover.isHidden = true
                    let positiveAction = Action(title: String.OKStr.localized(), handler: nil)
                    self?.showAlert(
                        title: String.uploadingFailedStr.localized(),
                        msg: String.pleaseReuploadFromProfileStr.localized(),
                        positiveAction: positiveAction,
                        negativeAction: nil
                    )
                }
            })
    }
    
    @objc
    private func dismissVC() {
        let positiveAction = Action(title: String.discardStr.localized()) { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        }
        let negativeAction = Action(title: String.cancelStr.localized(), handler: nil)
        self.showAlert(
            title: String.discardTheVideoDetailsStr.localized(),
            msg: nil,
            positiveAction: positiveAction,
            negativeAction: negativeAction
        )
    }
    
    private func showAlert(title: String?, msg: String?, positiveAction: Action?, negativeAction: Action?) {
        let alert = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        if positiveAction != nil {
            let positiveHandler: (UIAlertAction) -> Void = { alertAction in
                positiveAction?.handler?(alertAction.title)
            }
            alert.addAction(UIAlertAction(title: positiveAction?.title, style: .default, handler: positiveHandler))
        }
        if negativeAction != nil {
            let negativeHandler: (UIAlertAction) -> Void = { alertAction in
                negativeAction?.handler?(alertAction.title)
            }
            alert.addAction(UIAlertAction(title: negativeAction?.title, style: .cancel, handler: negativeHandler))
        }
        self.present(alert, animated: true, completion: nil)
    }
    
    private func videoSnapshot(fileURL: URL?) -> UIImage? {
        guard let url = fileURL else { return nil }
        let asset = AVURLAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        let timestamp = CMTime(seconds: 1, preferredTimescale: 60)
        
        do {
            let imageRef = try generator.copyCGImage(at: timestamp, actualTime: nil)
            let image = UIImage(cgImage: imageRef)
            self.videoWidth = image.size.width
            self.videoHeight = image.size.height
            return image
        } catch let error as NSError {
            print("Image generation failed with error \(error)")
            return nil
        }
    }
    
    private func createInputAccessoryView() -> UIView {
        let toolbar = UIToolbar()
        toolbar.barStyle = .default
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneBtn = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(PostVideoViewController.keyboardDonePressed))
        toolbar.items = [flexSpace, doneBtn]
        toolbar.sizeToFit()
        
        return toolbar
    }
    
    @objc
    private func keyboardDonePressed() {
        self.dismissKeyboard()
    }
    
    @objc
    private func dismissKeyboard() {
        self.keywordInput.resignFirstResponder()
        self.hashtagInput.resignFirstResponder()
        self.broadcastLink.resignFirstResponder()
    }
    
    private func finishPosting() {
        self.postMediaViewModel.resetViewModel()
        self.navigationController?.popToRootViewController(animated: true)
    }
}

extension PostVideoViewController: LabelTextViewDelegate {
    
    func textViewDidBeginEditing(viewID: String?) {
        if viewID == self.hashtagsTextViewID {
            self.hashtagInput.textViewResignFirstResponder()
            let hashtagsVC = HashtagsInputViewController(postMediaViewModel: self.postMediaViewModel)
            hashtagsVC.modalPresentationStyle = .fullScreen
            hashtagsVC.modalTransitionStyle = .flipHorizontal
            self.present(hashtagsVC, animated: true)
        } else if viewID == self.broadcastLinkTextViewID {
            
        }
    }
    
    func textViewDidEndEditing(viewID: String?) {
        //let originalPoint = CGPoint(x: 0, y: 0)
        //self.midScrollView.contentOffset = originalPoint
    }
    
    func textViewKeyboardDonePressed(viewID: String?) {
        
    }
}

// setup UI
extension PostVideoViewController {
    
    private func setupUI() {
        
        self.view.addSubview(topContainer)
        NSLayoutConstraint.activate(
            [topContainer.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
             topContainer.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
             topContainer.topAnchor.constraint(equalTo: self.view.topAnchor),
             topContainer.heightAnchor.constraint(equalToConstant: Constants.topContainerHeight)]
        )
        
        self.topContainer.addSubview(crossButton)
        NSLayoutConstraint.activate(
            [crossButton.leadingAnchor.constraint(equalTo: self.topContainer.leadingAnchor, constant: Constants.leadingSpacing),
             crossButton.topAnchor.constraint(equalTo: self.topContainer.topAnchor, constant: Constants.naviTopSpacing),
             crossButton.widthAnchor.constraint(equalToConstant: Constants.iconBtnWidth),
             crossButton.heightAnchor.constraint(equalToConstant: Constants.iconBtnHeight)]
        )
        
        self.view.addSubview(bottomContainer)
        NSLayoutConstraint.activate(
            [bottomContainer.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
             bottomContainer.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
             bottomContainer.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
             bottomContainer.heightAnchor.constraint(equalToConstant: Constants.bottomContainerHeight)]
        )
        
        self.bottomContainer.addSubview(postButton)
        NSLayoutConstraint.activate(
            [postButton.centerXAnchor.constraint(equalTo: self.bottomContainer.centerXAnchor),
             postButton.centerYAnchor.constraint(equalTo: self.bottomContainer.centerYAnchor, constant: -12),
             postButton.widthAnchor.constraint(equalToConstant: Constants.postBtnWidth),
             postButton.heightAnchor.constraint(equalToConstant: Constants.postBtnHeight)]
        )
        
        self.view.addSubview(midScrollView)
        NSLayoutConstraint.activate(
            [midScrollView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
             midScrollView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
             midScrollView.topAnchor.constraint(equalTo: self.topContainer.bottomAnchor),
             midScrollView.bottomAnchor.constraint(lessThanOrEqualTo: self.bottomContainer.topAnchor)]
        )
        
        self.midScrollView.addSubview(midContainer)
        NSLayoutConstraint.activate(
            [midContainer.leadingAnchor.constraint(equalTo: midScrollView.leadingAnchor),
             midContainer.trailingAnchor.constraint(equalTo: midScrollView.trailingAnchor),
             midContainer.topAnchor.constraint(equalTo: midScrollView.topAnchor),
             midContainer.bottomAnchor.constraint(equalTo: midScrollView.bottomAnchor),
             midContainer.widthAnchor.constraint(equalTo: self.view.widthAnchor)]
        )
        
        self.midContainer.addSubview(videoImageCover)
        self.videoImageCover.contentMode = (self.videoWidth > self.videoHeight) ? .scaleAspectFit : .scaleAspectFill
        let videoRatio = 16.0 / 9.0
        NSLayoutConstraint.activate(
            [videoImageCover.topAnchor.constraint(equalTo: self.midContainer.topAnchor, constant: Constants.topSpacing),
             videoImageCover.trailingAnchor.constraint(equalTo: self.midContainer.trailingAnchor, constant: -Constants.trailingSpacing),
             videoImageCover.widthAnchor.constraint(equalToConstant: Constants.videoCoverWidth),
             videoImageCover.heightAnchor.constraint(equalToConstant: Constants.videoCoverWidth * videoRatio)]
        )
        
        self.keywordInput.inputAccessoryView = self.createInputAccessoryView()
        self.midContainer.addSubview(keywordInput)
        NSLayoutConstraint.activate(
            [keywordInput.leadingAnchor.constraint(equalTo: self.midContainer.leadingAnchor, constant: Constants.leadingSpacing),
             keywordInput.topAnchor.constraint(equalTo: self.midContainer.topAnchor, constant: Constants.topSpacing),
             keywordInput.trailingAnchor.constraint(equalTo: self.videoImageCover.leadingAnchor, constant: -Constants.horizontalSpacing),
             keywordInput.bottomAnchor.constraint(equalTo: self.videoImageCover.bottomAnchor, constant: 0)]
        )
        self.keywordInput.configure(
            placeholder: String.addKeywordForSearchStr.localized(),
            theme: PlaceholderTextView.Theme.default
        )
        
        self.midContainer.addSubview(hashtagInput)
        NSLayoutConstraint.activate(
            [hashtagInput.leadingAnchor.constraint(equalTo: self.midContainer.leadingAnchor, constant: Constants.leadingSpacing),
             hashtagInput.topAnchor.constraint(equalTo: self.keywordInput.bottomAnchor, constant: Constants.verticalSpacing),
             hashtagInput.trailingAnchor.constraint(equalTo: self.midContainer.trailingAnchor, constant: -Constants.trailingSpacing)]
        )
        self.hashtagInput.delegate = self
        self.hashtagInput.viewID = self.hashtagsTextViewID
        
        self.midContainer.addSubview(broadcastLink)
        NSLayoutConstraint.activate(
            [broadcastLink.leadingAnchor.constraint(equalTo: self.midContainer.leadingAnchor, constant: Constants.leadingSpacing),
             broadcastLink.topAnchor.constraint(equalTo: self.hashtagInput.bottomAnchor, constant: Constants.verticalSpacing),
             broadcastLink.trailingAnchor.constraint(equalTo: self.midContainer.trailingAnchor, constant: -Constants.trailingSpacing),
             broadcastLink.bottomAnchor.constraint(equalTo: self.midContainer.bottomAnchor, constant: -Constants.bottomSpacing)]
        )
        self.broadcastLink.delegate = self
        self.broadcastLink.viewID = self.broadcastLinkTextViewID
        
        self.view.addSubview(uploadingCover)
        NSLayoutConstraint.activate(
            [uploadingCover.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
             uploadingCover.topAnchor.constraint(equalTo: self.view.topAnchor),
             uploadingCover.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
             uploadingCover.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)]
        )
        self.view.bringSubviewToFront(uploadingCover)
        self.uploadingCover.isHidden = true
        
        self.uploadingCover.addSubview(uploadingLabel)
        NSLayoutConstraint.activate(
            [uploadingLabel.leadingAnchor.constraint(equalTo: self.uploadingCover.leadingAnchor, constant: Constants.leadingSpacing),
             uploadingLabel.centerYAnchor.constraint(equalTo: self.uploadingCover.centerYAnchor, constant: -(3 * Constants.verticalSpacing)),
             uploadingLabel.trailingAnchor.constraint(equalTo: self.uploadingCover.trailingAnchor, constant: -Constants.trailingSpacing)]
        )
        self.uploadingLabel.isHidden = true
        
        self.uploadingCover.addSubview(progressBar)
        NSLayoutConstraint.activate(
            [progressBar.leadingAnchor.constraint(equalTo: self.uploadingCover.leadingAnchor, constant: Constants.leadingSpacing),
             progressBar.topAnchor.constraint(equalTo: self.uploadingLabel.bottomAnchor, constant: 0.4 * Constants.verticalSpacing),
             progressBar.trailingAnchor.constraint(equalTo: self.uploadingCover.trailingAnchor, constant: -Constants.trailingSpacing),
             progressBar.heightAnchor.constraint(equalToConstant: 22)]
        )
        self.progressBar.progress = 0.0
        self.progressBar.isHidden = true
        
        self.uploadingCover.addSubview(loadingWheel)
        NSLayoutConstraint.activate([
            loadingWheel.centerXAnchor.constraint(equalTo: self.uploadingCover.centerXAnchor),
            loadingWheel.centerYAnchor.constraint(equalTo: self.uploadingCover.centerYAnchor),
            loadingWheel.widthAnchor.constraint(equalToConstant: Constants.loadingAnimationSize),
            loadingWheel.heightAnchor.constraint(equalToConstant: Constants.loadingAnimationSize)]
        )
        self.loadingWheel.isHidden = true
        
        NSLayoutConstraint.activate(
            [midScrollView.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor)]
        )
    }
}
