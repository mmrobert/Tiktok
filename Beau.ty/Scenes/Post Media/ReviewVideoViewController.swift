//
//  ReviewVideoViewController.swift
//  Beau.ty
//  Created by Boqian Cheng on 2023-01-01.
//

import Foundation
import UIKit
import AVFoundation

class ReviewVideoViewController: UIViewController {
    
    private struct Constants {
        static let leadingSpacing: CGFloat = 20
        static let trailingSpacing: CGFloat = 20
        static let topSpacing: CGFloat = 20
        static let bottomSpacing: CGFloat = 20
        
        static let naviTopSpacing: CGFloat = 50
        
        static let iconBtnHeight: CGFloat = 29
        static let iconBtnWidth: CGFloat = 25
        static let nextBtnHeight: CGFloat = 40
        static let nextBtnWidth: CGFloat = 190
        static let topContainerHeight: CGFloat = 120
        static let bottomContainerHeight: CGFloat = 100
    }
    
    private lazy var playerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.black
        return view
    }()
    
    private lazy var topContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var crossButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage.cross, for: .normal)
        return button
    }()
    
    private lazy var addTitleButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "textformat.alt"), for: .normal)
        button.tintColor = UIColor.white
        return button
    }()
    
    private lazy var bottomContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.tabbarBackground
        return view
    }()
    
    private lazy var nextButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = UIColor.green
        button.setTitle(String.nextStr.localized(), for: .normal)
        button.setTitleColor(UIColor.black, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        button.layer.cornerRadius = Constants.nextBtnHeight / 2
        button.layer.masksToBounds = true
        return button
    }()
    
    private lazy var titleInputBackground: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.clear
        return view
    }()
    
    private lazy var titleInput: UITextView = {
        let input = UITextView()
        input.translatesAutoresizingMaskIntoConstraints = false
        input.returnKeyType = .done
        input.keyboardType = .default
        input.textAlignment = .center
        input.font = UIFont.boldSystemFont(ofSize: 20)
        input.textColor = UIColor.yellow
        input.backgroundColor = UIColor.clear
        input.text = ""
        return input
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isUserInteractionEnabled = true
        label.font = UIFont.boldSystemFont(ofSize: 20)
        label.textColor = UIColor.yellow
        label.numberOfLines = 0
        label.textAlignment = .center
        label.backgroundColor = UIColor.clear
        label.text = nil
        return label
    }()
    
    private var textViewHeightConstraint: NSLayoutConstraint?
    
    private let player: AVQueuePlayer
    private let playerLayer: AVPlayerLayer
    private let playerItem: AVPlayerItem
    private let playerLooper: AVPlayerLooper
    
    private let postMediaViewModel: PostMediaViewModel
    
    private var isDragingTitle = false
    
    private var videoWidth: CGFloat = 9
    private var videoHeight: CGFloat = 16
    
    init(postMediaViewModel: PostMediaViewModel) {
        self.postMediaViewModel = postMediaViewModel
        let sampleURL = Bundle.main.url(forResource: "waterFall", withExtension: "mp4")!
        let videoURL = postMediaViewModel.videoURL ?? sampleURL
        self.playerItem = AVPlayerItem(url: videoURL)
        self.player = AVQueuePlayer(playerItem: self.playerItem)
        self.playerLayer = AVPlayerLayer(player: self.player)
        self.playerLooper = AVPlayerLooper(player: player, templateItem: playerItem)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupUI()
        self.setupButtonActions()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        AppGlobalVariables.shared.currentVC = .ReviewVideoViewController
        self.topContainerBackground()
        self.checkVideoSize(fileURL: self.postMediaViewModel.videoURL)
        self.setupPlayer()
        self.player.play()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.player.pause()
    }
    
    private func setupButtonActions() {
        self.crossButton.addTarget(self, action: #selector(ReviewVideoViewController.dismissVC), for: .touchUpInside)
        self.addTitleButton.addTarget(self, action: #selector(ReviewVideoViewController.addingVideoTitle), for: .touchUpInside)
        self.nextButton.addTarget(self, action: #selector(ReviewVideoViewController.nextVC), for: .touchUpInside)
        let dismissBoardTap = UITapGestureRecognizer(target: self, action: #selector(ReviewVideoViewController.dismissKeyboard))
        self.view.addGestureRecognizer(dismissBoardTap)
    }
    
    private func setupPlayer() {
        self.playerLayer.frame = self.playerView.layer.bounds
        self.playerLayer.videoGravity = (self.videoWidth < self.videoHeight) ? .resizeAspectFill : .resizeAspect
        self.playerLayer.removeFromSuperlayer()
        self.playerView.layer.insertSublayer(playerLayer, at: 0)
    }
    
    @objc
    private func dismissVC() {
        let positiveAction = Action(title: String.discardStr.localized()) { [weak self] _ in
            self?.navigationController?.popToRootViewController(animated: true)
        }
        let negativeAction = Action(title: String.cancelStr.localized(), handler: nil)
        self.showAlert(
            title: String.discardTheVideoStr.localized(),
            msg: nil,
            positiveAction: positiveAction,
            negativeAction: negativeAction
        )
    }
    
    @objc
    private func addingVideoTitle() {
        self.titleInput.becomeFirstResponder()
        self.titleInput.isHidden = false
        self.titleLabel.isHidden = true
    }
    
    @objc
    private func nextVC() {
        let postVC = PostVideoViewController(postMediaViewModel: self.postMediaViewModel)
        postVC.hidesBottomBarWhenPushed = true
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        self.navigationController?.pushViewController(postVC, animated: true)
    }
    
    @objc
    private func dismissKeyboard() {
        self.titleInput.resignFirstResponder()
        self.titleInput.isHidden = true
        self.titleLabel.isHidden = false
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
    
    private func calculateTextHeight(text: String?, width: CGFloat) -> CGFloat {
        self.titleLabel.text = text
        self.postMediaViewModel.caption = text
        let size = self.titleLabel.systemLayoutSizeFitting(CGSize(width: width, height: UIView.layoutFittingCompressedSize.height), withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel)
        return size.height
    }
    
    private func checkVideoSize(fileURL: URL?) {
        guard let url = fileURL else { return }
        let asset = AVURLAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        let timestamp = CMTime(seconds: 1, preferredTimescale: 60)
        
        do {
            let imageRef = try generator.copyCGImage(at: timestamp, actualTime: nil)
            let image = UIImage(cgImage: imageRef)
            self.videoWidth = image.size.width
            self.videoHeight = image.size.height
            return
        } catch let error as NSError {
            print("Image generation failed with error \(error)")
            return
        }
    }
    
    deinit {
        print("🍎 ReviewVideoViewController - deinit")
    }
}

extension ReviewVideoViewController: UITextViewDelegate {
    
    func textViewDidChange(_ textView: UITextView) {
        let width = textView.frame.width - 3
        let height = self.calculateTextHeight(text: textView.text, width: width)
        self.textViewHeightConstraint?.constant = height + 22
        self.titleInputBackground.layoutIfNeeded()
    }
}

extension ReviewVideoViewController {
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self.titleLabel)
        if self.titleLabel.bounds.contains(location) {
            self.isDragingTitle = true
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard self.isDragingTitle, let touch = touches.first else {
            return
        }
        let location = touch.location(in: self.view)
        self.titleLabel.frame.origin.y = location.y
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.isDragingTitle = false
    }
}

// setup UI
extension ReviewVideoViewController {
    
    private func setupUI() {
        
        self.view.addSubview(bottomContainer)
        NSLayoutConstraint.activate(
            [bottomContainer.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 0),
             bottomContainer.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
             bottomContainer.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: 0),
             bottomContainer.heightAnchor.constraint(equalToConstant: Constants.bottomContainerHeight)]
        )
        
        self.bottomContainer.addSubview(nextButton)
        NSLayoutConstraint.activate(
            [nextButton.centerXAnchor.constraint(equalTo: self.bottomContainer.centerXAnchor),
             nextButton.centerYAnchor.constraint(equalTo: self.bottomContainer.centerYAnchor, constant: -12),
             nextButton.widthAnchor.constraint(equalToConstant: Constants.nextBtnWidth),
             nextButton.heightAnchor.constraint(equalToConstant: Constants.nextBtnHeight)]
        )
        
        self.view.addSubview(playerView)
        NSLayoutConstraint.activate(
            [playerView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 0),
             playerView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
             playerView.topAnchor.constraint(equalTo: self.view.topAnchor),
             playerView.bottomAnchor.constraint(equalTo: self.bottomContainer.topAnchor, constant: 0)]
        )
        
        self.playerView.addSubview(topContainer)
        NSLayoutConstraint.activate(
            [topContainer.leadingAnchor.constraint(equalTo: self.playerView.leadingAnchor, constant: 0),
             topContainer.topAnchor.constraint(equalTo: self.playerView.topAnchor, constant: 0),
             topContainer.trailingAnchor.constraint(equalTo: self.playerView.trailingAnchor, constant: 0),
             topContainer.heightAnchor.constraint(equalToConstant: Constants.topContainerHeight)]
        )
        
        self.topContainer.addSubview(crossButton)
        NSLayoutConstraint.activate(
            [crossButton.leadingAnchor.constraint(equalTo: self.topContainer.leadingAnchor, constant: Constants.leadingSpacing),
             crossButton.topAnchor.constraint(equalTo: self.topContainer.topAnchor, constant: Constants.naviTopSpacing),
             crossButton.widthAnchor.constraint(equalToConstant: Constants.iconBtnWidth),
             crossButton.heightAnchor.constraint(equalToConstant: Constants.iconBtnHeight)]
        )
        
        self.topContainer.addSubview(addTitleButton)
        NSLayoutConstraint.activate(
            [addTitleButton.trailingAnchor.constraint(equalTo: self.topContainer.trailingAnchor, constant: -Constants.trailingSpacing),
             addTitleButton.topAnchor.constraint(equalTo: self.topContainer.topAnchor, constant: 55),
             addTitleButton.widthAnchor.constraint(equalToConstant: Constants.iconBtnWidth),
             addTitleButton.heightAnchor.constraint(equalToConstant: Constants.iconBtnHeight)]
        )
        
        self.playerView.addSubview(titleInputBackground)
        NSLayoutConstraint.activate(
            [titleInputBackground.leadingAnchor.constraint(equalTo: playerView.leadingAnchor, constant: Constants.leadingSpacing),
             titleInputBackground.trailingAnchor.constraint(equalTo: self.playerView.trailingAnchor, constant: -Constants.trailingSpacing),
             titleInputBackground.topAnchor.constraint(equalTo: self.playerView.topAnchor, constant: 130)]
        )
        
        self.titleInputBackground.addSubview(titleInput)
        titleInput.delegate = self
        titleInput.resignFirstResponder()
        titleInput.inputAccessoryView = self.createInputAccessoryView()
        
        let heightConstraint = titleInput.heightAnchor.constraint(equalToConstant: 38)
        self.textViewHeightConstraint = heightConstraint
        NSLayoutConstraint.activate(
            [titleInput.leadingAnchor.constraint(equalTo: titleInputBackground.leadingAnchor),
             titleInput.trailingAnchor.constraint(equalTo: titleInputBackground.trailingAnchor),
             titleInput.topAnchor.constraint(equalTo: titleInputBackground.topAnchor),
             titleInput.bottomAnchor.constraint(equalTo: titleInputBackground.bottomAnchor),
             heightConstraint]
        )
        
        self.playerView.addSubview(titleLabel)
        NSLayoutConstraint.activate(
            [titleLabel.leadingAnchor.constraint(equalTo: playerView.leadingAnchor, constant: Constants.leadingSpacing),
             titleLabel.trailingAnchor.constraint(equalTo: self.playerView.trailingAnchor, constant: -Constants.trailingSpacing),
             titleLabel.topAnchor.constraint(equalTo: self.playerView.topAnchor, constant: 130)]
        )
    }
    
    private func topContainerBackground() {
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = self.topContainer.bounds
        gradientLayer.colors = [(UIColor.black.withAlphaComponent(0.5)).cgColor,
                                (UIColor.black.withAlphaComponent(0.0)).cgColor]
        gradientLayer.shouldRasterize = true
        self.topContainer.layer.addSublayer(gradientLayer)
    }
    
    private func createInputAccessoryView() -> UIView {
        let toolbar = UIToolbar()
        toolbar.barStyle = .default
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneBtn = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(ReviewVideoViewController.keyboardDonePressed))
        toolbar.items = [flexSpace, doneBtn]
        toolbar.sizeToFit()
        
        return toolbar
    }
    
    @objc
    private func keyboardDonePressed() {
        self.dismissKeyboard()
    }
}
