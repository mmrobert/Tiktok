//
//  HomeTableViewCell.swift
//  Beau.ty
//
//  Created by Boqian Cheng on 2023-01-21.
//

import Foundation
import UIKit
import AVFoundation
import Lottie
import Combine

class HomeTableViewCell: UITableViewCell {
    
    private struct Constants {
        static let leadingSpacing: CGFloat = 20
        static let trailingSpacing: CGFloat = 20
        static let topSpacing: CGFloat = 5
        static let bottomSpacing: CGFloat = 5
        static let horizontalSpacing: CGFloat = 12
        
        static let toPlaySize: CGFloat = 140
        
        static let loadingAnimationSize: CGFloat = 160
    }
    
    private lazy var videoCover: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.clear
        return view
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
    
    private lazy var toPlay: LottieAnimationView = {
        let view = LottieAnimationView(name: "toPlay")
        view.translatesAutoresizingMaskIntoConstraints = false
        view.contentMode = .scaleAspectFill
        view.animationSpeed = 1.6
        view.loopMode = .loop
        view.isUserInteractionEnabled = true
        return view
    }()
    
    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isUserInteractionEnabled = true
        label.font = UIFont.systemFont(ofSize: 18)
        label.textColor = UIColor.lightGray
        label.numberOfLines = 1
        label.textAlignment = .left
        return label
    }()
    
    private var videoModel: HomePostItemViewModel?
    
    let creator: CachingPlayerItemCreator = CachingPlayerItemCreator()
    
    var avPlayerLayer: AVPlayerLayer!
    var playerLooper: AVPlayerLooper! // should be defined in class
    var queuePlayer: AVQueuePlayer!
    
    private var isPlaying: Bool = false
    
    @Published private var isReadyToPlay: Bool = false
    
    @Published var currentDisplayingCell: Bool = false
    
    private var disposables = Set<AnyCancellable>()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.playingStateObserving()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.playingStateObserving()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.contentView.backgroundColor = UIColor.black
        self.setupUI()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
    }
    
    func configure(viewModel: HomePostItemViewModel) {
        self.videoModel = viewModel
        guard let url = viewModel.videoURL else {
            print("URL error from HomePostItemViewModel")
            return
        }
        
        if avPlayerLayer != nil {
            // table view resuable problem, remove playerlayer if exist
            avPlayerLayer.removeFromSuperlayer()
            queuePlayer = nil
            playerLooper = nil
            avPlayerLayer = nil
        }
        
        guard var saveFilePath = MediaFileHandle.diskCacheDirectoryURL else {
            return
        }
        saveFilePath.appendPathComponent(viewModel.id ?? "temp")
        saveFilePath.appendPathExtension(viewModel.videoFileExtension ?? "mp4")
        
        let playerItem: AVPlayerItem
        if FileManager.default.fileExists(atPath: saveFilePath.path) {
            print("Playing from cached local file.")
            creator.delegate = self
            playerItem = creator.playerItemFromLocalFile(filePathURL: saveFilePath)
        } else {
            print("Playing from remote url.")
            creator.delegate = self
            playerItem = creator.playerItem_Caching_FromRemoteURL(url: url, saveFilePath: saveFilePath.path, customFileExtension: viewModel.videoFileExtension)
        }
        
        self.queuePlayer = AVQueuePlayer(playerItem: playerItem)
        self.queuePlayer.automaticallyWaitsToMinimizeStalling = false
        
        self.avPlayerLayer = AVPlayerLayer(player: queuePlayer)
        self.avPlayerLayer.videoGravity = (viewModel.videoWidth < viewModel.videoHeight) ? .resizeAspectFill : .resizeAspect
        
        self.playerLooper = AVPlayerLooper(player: queuePlayer, templateItem: playerItem)
        
        self.contentView.layer.addSublayer(avPlayerLayer)
        self.avPlayerLayer.frame = self.contentView.layer.bounds
        
        //self.nameLabel.text = viewModel.autherName
        
        self.addGestureRecognizers()
    }
    
    private func addGestureRecognizers() {
        let videoCoverTap = UITapGestureRecognizer(target: self, action: #selector(HomeTableViewCell.handlePause))
        self.videoCover.addGestureRecognizer(videoCoverTap)
        
        let toPlayTap = UITapGestureRecognizer(target: self, action: #selector(HomeTableViewCell.handleToPlay))
        self.toPlay.addGestureRecognizer(toPlayTap)
    }
    
    private func playingStateObserving() {
        /*
        Publishers.CombineLatest(self.$currentDisplayingCell, self.$isReadyToPlay)
            .sink(receiveValue: { [weak self] (isCurrent, isReady) in
                print("cheng=ccc= \(isCurrent)")
                print("cheng=rrr= \(isReady)")
                if isCurrent {
                    if isReady {
                        self?.loading.pause()
                        self?.loading.isHidden = true
                    } else {
                        self?.loading.play()
                        self?.loading.isHidden = false
                    }
                } else {
                    self?.loading.pause()
                    self?.loading.isHidden = true
                }
            })
            .store(in: &disposables)
         */
        self.$currentDisplayingCell
            .sink(receiveValue: { [weak self] isCurrent in
                if isCurrent {
                    if let isReady = self?.isReadyToPlay, isReady {
                        self?.loadingWheel.pause()
                        self?.loadingWheel.isHidden = true
                    } else {
                        self?.loadingWheel.play()
                        self?.loadingWheel.isHidden = false
                    }
                } else {
                    self?.loadingWheel.pause()
                    self?.loadingWheel.isHidden = true
                }
            })
            .store(in: &disposables)
    }
    
    func playVideo() {
        if self.isReadyToPlay && self.currentDisplayingCell {
            if !isPlaying {
                self.isPlaying = true
                self.queuePlayer.play()
            }
        }
    }
    
    func pauseVideo() {
        if isPlaying {
            self.isPlaying = false
            self.queuePlayer.pause()
        }
    }
    
    @objc
    func handlePause() {
        self.toPlay.play()
        self.toPlay.isHidden = false
        self.pauseVideo()
    }
    
    @objc
    func handleToPlay() {
        self.toPlay.pause()
        self.toPlay.isHidden = true
        self.playVideo()
    }
    
    @objc
    func handleNameTap() {
        
    }
    
    private func setupUI() {
        
        self.contentView.addSubview(videoCover)
        NSLayoutConstraint.activate([
            videoCover.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor),
            videoCover.topAnchor.constraint(equalTo: self.contentView.topAnchor),
            videoCover.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor),
            videoCover.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor)]
        )
        
        self.videoCover.addSubview(toPlay)
        NSLayoutConstraint.activate([
            toPlay.centerXAnchor.constraint(equalTo: self.videoCover.centerXAnchor),
            toPlay.centerYAnchor.constraint(equalTo: self.videoCover.centerYAnchor),
            toPlay.widthAnchor.constraint(equalToConstant: Constants.toPlaySize),
            toPlay.heightAnchor.constraint(equalToConstant: Constants.toPlaySize)]
        )
        self.toPlay.pause()
        self.toPlay.isHidden = true
        
        self.videoCover.addSubview(loadingWheel)
        NSLayoutConstraint.activate([
            loadingWheel.centerXAnchor.constraint(equalTo: self.videoCover.centerXAnchor),
            loadingWheel.centerYAnchor.constraint(equalTo: self.videoCover.centerYAnchor),
            loadingWheel.widthAnchor.constraint(equalToConstant: Constants.loadingAnimationSize),
            loadingWheel.heightAnchor.constraint(equalToConstant: Constants.loadingAnimationSize)]
        )
        
        self.videoCover.addSubview(nameLabel)
        NSLayoutConstraint.activate([
            nameLabel.leadingAnchor.constraint(equalTo: self.videoCover.leadingAnchor),
            nameLabel.bottomAnchor.constraint(equalTo: self.videoCover.bottomAnchor)]
        )
        
        let nameTap = UITapGestureRecognizer(target: self, action: #selector(HomeTableViewCell.handleNameTap))
        self.nameLabel.addGestureRecognizer(nameTap)
    }
}

extension HomeTableViewCell: CachingPlayerItemDelegate {
    
    func playerItemReadyToPlay(isReady: Bool) {
        self.isReadyToPlay = true
        self.loadingWheel.pause()
        self.loadingWheel.isHidden = true
        self.playVideo()
    }

    func playerItemDidFailToPlay(withError: Error?) {
        
    }

    func playerItemPlaybackStalled() {
        
    }

    func playerItem(didDownloadBytesSoFar: Int, outOfbytesExpected: Int) {
        
    }

    func playerItem(didFinishDownloadingFileAtPath: String) {
        
    }

    func playerItem(downloadingFailedWithError: Error) {
        
    }
}
