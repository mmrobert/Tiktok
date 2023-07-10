//
//  HomeViewController.swift
//  Beau.ty
//  Created by Boqian Cheng on 2022-11-26.
//

import Foundation
import UIKit
import Combine

class HomeViewController: UIViewController {
    
    private struct Constants {
        static let leadingSpacing: CGFloat = 17
        static let trailingSpacing: CGFloat = 17
        static let topSpacing: CGFloat = 17
        static let bottomSpacing: CGFloat = 17
        
        static let naviTopSpacing: CGFloat = 50
        
        static let horizontalSpacing: CGFloat = 12
        static let verticalSpacing: CGFloat = 15
        
        static let iconBtnHeight: CGFloat = 29
        static let iconBtnWidth: CGFloat = 25
        static let topContainerHeight: CGFloat = 90
        
        static let cellReuseIdentifier: String = "homeVideoPlayCell"
    }
    
    private lazy var videoTableView: UITableView = {
        let view = UITableView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.clear
        return view
    }()
    
    private var disposables = Set<AnyCancellable>()
    
    private var viewModel: HomePostListViewModel = HomePostListViewModel()
    
    private var postsList: [HomePostItemViewModel] = []
    
    private var playingCell: HomeTableViewCell?
    
    private var prefetchTasks: [String:VideoPrefetchToLocalFile] = [:]
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.isTranslucent = true
        
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        AudioManager.shared.setAudioMode()
        
        self.setupUI()
        self.addAppStateObserver()
        self.fbDatabaseObserving()
        
        self.viewModel.fetchPosts() { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let posts):
                    self?.postsList = posts
                    self?.videoTableView.reloadData()
                case .failure(let error):
                    print("Fetch Posts Error: \(error.localizedDescription)")
                    let positiveAction = Action(title: String.OKStr.localized(), handler: nil)
                    self?.showAlert(
                        title: String.networkErrorStr.localized(),
                        msg: nil,
                        positiveAction: positiveAction,
                        negativeAction: nil
                    )
                }
            }
        }
    }
    
    private func addAppStateObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(HomeViewController.appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(HomeViewController.appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
    }
    
    private func fbDatabaseObserving() {
        viewModel.$postsAdded
            .sink(receiveValue: { [weak self] added in
                guard let strongSelf = self else { return }
                strongSelf.postsList.append(contentsOf: added)
                let newCount = strongSelf.postsList.count
                let oldCount = strongSelf.postsList.count - added.count
                var indexPathes: [IndexPath] = []
                for index in oldCount..<newCount {
                    indexPathes.append(IndexPath(row: index, section: 0))
                }
                strongSelf.videoTableView.performBatchUpdates({
                    strongSelf.videoTableView.insertRows(at: indexPathes, with: .none)
                }, completion: nil)
            })
            .store(in: &disposables)
        
        /*
        viewModel.$postsRemoved
            .sink(receiveValue: { [weak self] removed in
                guard let strongSelf = self else { return }
                var indexPathes: [IndexPath] = []
                var idsDeleted: [String] = []
                var arrIndexs: [Int] = []
                for item in removed {
                    if let index = strongSelf.postsList.firstIndex(where: {
                        $0.id == item.id
                    }) {
                        arrIndexs.append(index)
                        idsDeleted.append(item.id ?? "")
                    }
                }
                arrIndexs = arrIndexs.sorted(by: >)
                for inds in arrIndexs {
                    strongSelf.postsList.remove(at: inds)
                }
                indexPathes = arrIndexs.map {
                    IndexPath(row: $0, section: 0)
                }
                strongSelf.videoTableView.performBatchUpdates({
                    strongSelf.videoTableView.deleteRows(at: indexPathes, with: .none)
                }, completion: nil)
                strongSelf.viewModel.deleteVideoCache(ids: idsDeleted)
            })
            .store(in: &disposables)
        */
        
        self.viewModel.observeDBChange()
    }
    
    @objc
    private func appDidBecomeActive() {
        if AppGlobalVariables.shared.currentVC == .HomeViewController {
            self.playingCell?.playVideo()
        }
    }
    
    @objc
    private func appDidEnterBackground() {
        if AppGlobalVariables.shared.currentVC == .HomeViewController {
            self.playingCell?.pauseVideo()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        AppGlobalVariables.shared.currentVC = .HomeViewController
        self.playingCell?.playVideo()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.playingCell?.pauseVideo()
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
    
    deinit {
        print("🍎 HomeViewController - deinit")
    }
}

extension HomeViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.postsList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.cellReuseIdentifier, for: indexPath) as! HomeTableViewCell
        cell.selectionStyle = .none
        
        let item = self.postsList[indexPath.row]
        
        if let existedPrefetch = self.prefetchTasks[item.id ?? "temp"] {
            existedPrefetch.cancelDownloading()
            self.prefetchTasks.removeValue(forKey: item.id ?? "temp")
        }
        
        cell.currentDisplayingCell = false
        cell.configure(viewModel: item)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return tableView.frame.height
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        self.playingCell?.pauseVideo()
            
        let _cell = cell as? HomeTableViewCell
        _cell?.currentDisplayingCell = true
        self.playingCell = _cell
    }
    
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        if let cell = cell as? HomeTableViewCell {
            cell.currentDisplayingCell = false
            cell.pauseVideo()
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.playingCell?.playVideo()
    }
}

extension HomeViewController: UITableViewDataSourcePrefetching {
    
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            let item = self.postsList[indexPath.row]
            self.prefetchFor(postID: item.id, videoURL: item.videoURL, videoFileExtension: item.videoFileExtension)
        }
    }
    
    func tableView(_ tableView: UITableView, cancelPrefetchingForRowsAt indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            let item = self.postsList[indexPath.row]
            if let existedPrefetch = self.prefetchTasks[item.id ?? "temp"] {
                existedPrefetch.cancelDownloading()
                self.prefetchTasks.removeValue(forKey: item.id ?? "temp")
            }
        }
    }
    
    private func prefetchFor(postID: String?, videoURL: URL?, videoFileExtension: String?) {
        guard let url = videoURL else {
            print("URL error from HomePostItemViewModel")
            return
        }
        guard var saveFilePath = MediaFileHandle.diskCacheDirectoryURL else {
            return
        }
        saveFilePath.appendPathComponent(postID ?? "temp")
        saveFilePath.appendPathExtension(videoFileExtension ?? "mp4")
        
        if FileManager.default.fileExists(atPath: saveFilePath.path) {
            if let existedPrefetch = self.prefetchTasks[postID ?? "temp"] {
                existedPrefetch.cancelDownloading()
                self.prefetchTasks.removeValue(forKey: postID ?? "temp")
            }
            return
        } else {
            let prefetch = VideoPrefetchToLocalFile()
            prefetch.delegate = self
            prefetch.download(url: url, saveFilePath: saveFilePath.path, customFileExtension: videoFileExtension)
            self.prefetchTasks[postID ?? "temp"] = prefetch
        }
    }
}

extension HomeViewController: VideoPrefetchToLocalFileDelegate {
    
    func playerItem(didFinishDownloadingFileAtPath: String) {
        
    }
    
    func playerItem(didDownloadBytesSoFar: Int, outOfbytesExpected: Int) {
        
    }
    
    func playerItem(downloadingFailedWithError: Error) {
        
    }
}

// setup UI
extension HomeViewController {
    
    private func setupUI() {
        videoTableView.isPagingEnabled = true
        videoTableView.contentInsetAdjustmentBehavior = .never
        videoTableView.showsVerticalScrollIndicator = false
        videoTableView.separatorStyle = .none
        self.view.addSubview(videoTableView)
        
        videoTableView.register(HomeTableViewCell.self, forCellReuseIdentifier: Constants.cellReuseIdentifier)
        
        videoTableView.delegate = self
        videoTableView.dataSource = self
        videoTableView.prefetchDataSource = self
        
        NSLayoutConstraint.activate(
            [videoTableView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
             videoTableView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
             videoTableView.topAnchor.constraint(equalTo: self.view.topAnchor),
             videoTableView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)]
        )
    }
}
