//
//  HashtagTableViewCell.swift
//  Beau.ty
//
//  Created by Boqian Cheng on 2023-01-19.
//

import Foundation
import UIKit

class HashtagTableViewCell: UITableViewCell {
    
    private struct Constants {
        static let leadingSpacing: CGFloat = 20
        static let trailingSpacing: CGFloat = 20
        static let topSpacing: CGFloat = 5
        static let bottomSpacing: CGFloat = 5
        static let horizontalSpacing: CGFloat = 12
    }
    
    private lazy var hashtagNameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isUserInteractionEnabled = false
        label.font = UIFont.systemFont(ofSize: 18)
        label.textColor = UIColor.black
        label.numberOfLines = 1
        label.textAlignment = .left
        return label
    }()
    
    private lazy var viewCountLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isUserInteractionEnabled = false
        label.font = UIFont.systemFont(ofSize: 18)
        label.textColor = UIColor.lightGray
        label.numberOfLines = 1
        label.textAlignment = .right
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func layoutSubviews() {
        self.setupUI()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
    }
    
    func configure(dataModel: HashtagDataModel) {
        self.hashtagNameLabel.text = dataModel.name
        self.viewCountLabel.text = "\(dataModel.count)"
    }
    
    private func setupUI() {
        self.contentView.addSubview(hashtagNameLabel)
        NSLayoutConstraint.activate([
            hashtagNameLabel.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: Constants.leadingSpacing),
            hashtagNameLabel.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: Constants.topSpacing),
            hashtagNameLabel.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -Constants.bottomSpacing)]
        )
        
        self.contentView.addSubview(viewCountLabel)
        NSLayoutConstraint.activate([
            viewCountLabel.leadingAnchor.constraint(equalTo: self.hashtagNameLabel.trailingAnchor, constant: Constants.horizontalSpacing),
            viewCountLabel.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: Constants.topSpacing),
            viewCountLabel.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -Constants.trailingSpacing),
            viewCountLabel.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -Constants.bottomSpacing)]
        )
        
        self.viewCountLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
    }
}
