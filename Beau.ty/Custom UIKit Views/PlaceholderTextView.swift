//
//  PlaceholderTextView.swift
//  Beau.ty
//  Created by Boqian Cheng on 2023-01-09.
//

import Foundation
import UIKit

class PlaceholderTextView: UITextView, UITextViewDelegate {

    struct Theme {
        var placeholderFont: UIFont = UIFont.systemFont(ofSize: 16)
        var placeholderColor: UIColor = UIColor.lightGray
        var textFont: UIFont = UIFont.systemFont(ofSize: 16)
        var textColor: UIColor = UIColor.black
        
        static let `default`: Theme = Theme()
    }

    private struct Constants {
        static let leadingSpacing: CGFloat = 5
        static let trailingSpacing: CGFloat = 5
        static let topSpacing: CGFloat = 8
        static let bottomSpacing: CGFloat = 8
    }

    private lazy var placeholderLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isUserInteractionEnabled = false
        label.lineBreakMode = .byWordWrapping
        label.numberOfLines = 0
        label.textAlignment = .left

        return label
    }()

    private var placeholder: String?
    private var theme: Theme = Theme.default

    init(frame: CGRect, placeholder: String? = nil, theme: PlaceholderTextView.Theme = PlaceholderTextView.Theme.default) {
        super.init(frame: frame, textContainer: nil)
        self.placeholder = placeholder
        self.theme = theme
        self.configure(placeholder: placeholder, theme: theme)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.setupPlaceholder()
        self.delegate = self
    }

    func configure(placeholder: String?, theme: PlaceholderTextView.Theme) {
        
        self.placeholder = placeholder
        self.font = theme.textFont
        self.textColor = theme.textColor
        self.placeholderLabel.font = theme.placeholderFont
        self.placeholderLabel.textColor = theme.placeholderColor
        self.placeholderLabel.text = placeholder
        self.placeholderLabel.sizeToFit()
    }

    private func setupPlaceholder() {
        self.addSubview(self.placeholderLabel)
        self.placeholderLabel.text = self.placeholder
        
        let top = self.theme.textFont.pointSize / 2

        NSLayoutConstraint.activate([
            placeholderLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: Constants.leadingSpacing),
            placeholderLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: top),
            placeholderLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -Constants.trailingSpacing)
        ])
        
        self.placeholderLabel.isHidden = !self.text.isEmpty
    }
    
    public func textViewDidChange(_ textView: UITextView) {
        placeholderLabel.isHidden = !self.text.isEmpty
    }
}
