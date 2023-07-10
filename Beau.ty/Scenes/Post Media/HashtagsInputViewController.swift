//
//  HashtagsInputViewController.swift
//  Beau.ty
//
//  Created by Boqian Cheng on 2023-01-17.
//

import Foundation
import UIKit

class HashtagsInputViewController: UIViewController {
    
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
        
        static let cornerRadius: CGFloat = 8
        
        static let cellReuseIdentifier: String = "hashtagsListCell"
    }
    
    private lazy var topContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.gray226
        return view
    }()
    
    private lazy var doneButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(String.doneStr.localized(), for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        button.backgroundColor = UIColor.clear
        button.setTitleColor(UIColor.black, for: .normal)
        return button
    }()
    
    private lazy var hashtagInput: LabelTextView = {
        let textField = LabelTextView(labelTitleStr: String.hashtagsStr.localized())
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private lazy var hashtagsList: UITableView = {
        let view = UITableView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = Constants.cornerRadius
        view.layer.masksToBounds = true
        return view
    }()
    
    private let postMediaViewModel: PostMediaViewModel
    
    private var allHashtags: [HashtagDataModel] = []
    
    init(postMediaViewModel: PostMediaViewModel) {
        self.postMediaViewModel = postMediaViewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.screenBase243
        
        self.setupUI()
        self.setupButtonActions()
        
        self.postMediaViewModel.fetchHashtags { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let hashtags):
                    self?.allHashtags = hashtags
                    self?.hashtagsList.reloadData()
                case .failure(let error):
                    print("Fetch hashtags: \(error)")
                }
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        AppGlobalVariables.shared.currentVC = .HashtagsInputViewController
        self.hashtagInput.textViewBecomeFirstResponder()
    }
    
    private func setupButtonActions() {
        self.doneButton.addTarget(self, action: #selector(HashtagsInputViewController.dismissVC), for: .touchUpInside)
    }
    
    @objc
    private func dismissVC() {
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
        
        self.dismiss(animated: true, completion: nil)
    }
}

extension HashtagsInputViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.allHashtags.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.cellReuseIdentifier, for: indexPath) as! HashtagTableViewCell
        let hashtag = self.allHashtags[indexPath.row]
        cell.configure(dataModel: hashtag)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let hashtag = self.allHashtags[indexPath.row].name
        let hashtagsStr = self.hashtagInput.text ?? ""
        
        if let last = hashtagsStr.last, last == "#" {
            self.hashtagInput.text = hashtagsStr.dropLast(1) + " " + hashtag
        } else {
            self.hashtagInput.text = hashtagsStr + " " + hashtag
        }
    }
}

// setup UI
extension HashtagsInputViewController {
    
    private func setupUI() {
        
        self.view.addSubview(topContainer)
        NSLayoutConstraint.activate(
            [topContainer.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
             topContainer.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
             topContainer.topAnchor.constraint(equalTo: self.view.topAnchor),
             topContainer.heightAnchor.constraint(equalToConstant: Constants.topContainerHeight)]
        )
        
        self.topContainer.addSubview(doneButton)
        NSLayoutConstraint.activate(
            [doneButton.topAnchor.constraint(equalTo: self.topContainer.topAnchor, constant: Constants.naviTopSpacing),
             doneButton.trailingAnchor.constraint(equalTo: self.topContainer.trailingAnchor, constant: -Constants.trailingSpacing),
             doneButton.widthAnchor.constraint(equalToConstant: 2 * Constants.iconBtnWidth),
             doneButton.heightAnchor.constraint(equalToConstant: Constants.iconBtnHeight)]
        )
        
        self.view.addSubview(hashtagInput)
        NSLayoutConstraint.activate(
            [hashtagInput.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: Constants.leadingSpacing),
             hashtagInput.topAnchor.constraint(equalTo: self.topContainer.bottomAnchor, constant: Constants.topSpacing),
             hashtagInput.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -Constants.trailingSpacing)]
        )
        self.hashtagInput.text = "#"
        
        self.view.addSubview(hashtagsList)
        NSLayoutConstraint.activate(
            [hashtagsList.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: Constants.leadingSpacing),
             hashtagsList.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -Constants.trailingSpacing),
             hashtagsList.topAnchor.constraint(equalTo: self.hashtagInput.bottomAnchor, constant: 5),
             hashtagsList.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -Constants.bottomSpacing)]
        )
        hashtagsList.dataSource = self
        hashtagsList.delegate = self
        hashtagsList.register(HashtagTableViewCell.self, forCellReuseIdentifier: Constants.cellReuseIdentifier)
        hashtagsList.separatorStyle = .none
        
        
        NSLayoutConstraint.activate(
            [hashtagsList.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor)]
        )
    }
}
