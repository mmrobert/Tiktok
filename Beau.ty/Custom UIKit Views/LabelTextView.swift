//
//  LabelTextView.swift
//  Beau.ty
//  Created by Boqian Cheng on 2023-01-09.
//

import Foundation
import UIKit

protocol LabelTextViewDelegate: AnyObject {
    func textViewDidBeginEditing(viewID: String?)
    func textViewDidEndEditing(viewID: String?)
    func textViewKeyboardDonePressed(viewID: String?)
}

class LabelTextView: UIView {

    struct Theme {
        var labelTitleFont: UIFont = UIFont.systemFont(ofSize: 16)
        var labelTitleColor: UIColor = UIColor.lightGray
        var textFont: UIFont = UIFont.systemFont(ofSize: 16)
        var textColor: UIColor = UIColor.darkGray
        var titleFocuseColor: UIColor = UIColor.gray
        var textFocusColor: UIColor = UIColor.black
        
        static let `default`: Theme = Theme()
    }

    private struct Constants {
        static let leadingSpacing: CGFloat = 0
        static let trailingSpacing: CGFloat = 0
        static let topSpacing: CGFloat = 2
        static let bottomSpacing: CGFloat = 2
        static let verticalSpacing: CGFloat = 7
        static let labelTitleOffset: CGFloat = 5
        static let borderWidth: CGFloat = 1
        static let cornerRadius: CGFloat = 6
    }

    private lazy var labelTitle: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isUserInteractionEnabled = false
        label.font = Theme.default.labelTitleFont
        label.textColor = Theme.default.labelTitleColor
        label.numberOfLines = 1
        label.textAlignment = .left
        label.text = ""
        return label
    }()

    private lazy var inputTextView: UITextView = {
        let input = UITextView(frame: .zero, textContainer: nil)
        input.translatesAutoresizingMaskIntoConstraints = false
        input.textAlignment = .left
        input.returnKeyType = .done
        input.keyboardType = .default
        input.layer.borderColor = (UIColor.gray.withAlphaComponent(0.3)).cgColor
        input.layer.borderWidth = Constants.borderWidth
        input.layer.cornerRadius = Constants.cornerRadius
        input.layer.masksToBounds = true
        return input
    }()
    
    
    private lazy var sampleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = Theme.default.textFont
        label.numberOfLines = 0
        label.textAlignment = .left
        label.text = ""

        return label
    }()
    
    private var labelTitleStr: String?
    private var theme: LabelTextView.Theme = Theme.default
    private var textViewHeightConstraint: NSLayoutConstraint?
    
    var delegate: LabelTextViewDelegate?
    var viewID: String?
    
    public var text: String? {
        get {
            self.inputTextView.text
        }
        set {
            self.inputTextView.text = newValue
        }
    }
    
    init(labelTitleStr: String?,
         theme: LabelTextView.Theme = LabelTextView.Theme.default) {
        super.init(frame: .zero)
        self.labelTitleStr = labelTitleStr
        self.theme = theme
        self.configure()
    }

    override init(frame: CGRect) {
        fatalError("init(frame:) has not been implemented")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        
        if self.inputTextView.isFirstResponder {
            self.labelTitle.textColor = self.theme.textFocusColor
            self.inputTextView.textColor = self.theme.textFocusColor
        } else {
            self.labelTitle.textColor = self.theme.labelTitleColor
            self.inputTextView.textColor = self.theme.textColor
        }
    }

    func configure() {
        
        self.inputTextView.font = theme.textFont
        self.inputTextView.textColor = theme.textColor

        if self.labelTitleStr != nil {
            self.setupLabelTitle()
        }
        self.setupTextView()
    }

    private func setupLabelTitle() {
        self.addSubview(self.labelTitle)
        self.labelTitle.font = self.theme.labelTitleFont
        self.labelTitle.textColor = self.theme.labelTitleColor
        self.labelTitle.text = self.labelTitleStr

        let offsetX = Constants.leadingSpacing + Constants.labelTitleOffset
        NSLayoutConstraint.activate([
            labelTitle.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: offsetX),
            labelTitle.topAnchor.constraint(equalTo: self.topAnchor, constant: Constants.topSpacing),
            labelTitle.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -Constants.trailingSpacing)
        ])
    }

    private func setupTextView() {
        self.addSubview(self.inputTextView)
        self.inputTextView.delegate = self
        self.inputTextView.inputAccessoryView = self.createInputAccessoryView()
        
        let heightConstraint = self.inputTextView.heightAnchor.constraint(equalToConstant: 38)
        self.textViewHeightConstraint = heightConstraint
        if self.labelTitleStr != nil {
            NSLayoutConstraint.activate([
                inputTextView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: Constants.leadingSpacing),
                inputTextView.topAnchor.constraint(equalTo: self.labelTitle.bottomAnchor, constant: Constants.verticalSpacing),
                inputTextView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -Constants.trailingSpacing),
                inputTextView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -Constants.bottomSpacing),
                heightConstraint
            ])
        } else {
            NSLayoutConstraint.activate([
                inputTextView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: Constants.leadingSpacing),
                inputTextView.topAnchor.constraint(equalTo: self.topAnchor, constant: Constants.topSpacing),
                inputTextView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -Constants.trailingSpacing),
                inputTextView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -Constants.bottomSpacing),
                heightConstraint
            ])
        }
    }

    private func createInputAccessoryView() -> UIView {
        let toolbar = UIToolbar()
        toolbar.barStyle = .default
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneBtn = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(LabelTextView.keyboardDonePressed))
        toolbar.items = [flexSpace, doneBtn]
        toolbar.sizeToFit()
        
        return toolbar
    }

    @objc
    private func keyboardDonePressed() {
        self.inputTextView.resignFirstResponder()
        self.delegate?.textViewKeyboardDonePressed(viewID: self.viewID)
    }
    
    func textViewBecomeFirstResponder() {
        self.inputTextView.becomeFirstResponder()
    }
    
    func textViewResignFirstResponder() {
        self.inputTextView.resignFirstResponder()
    }
}

extension LabelTextView: UITextViewDelegate {
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        self.labelTitle.textColor = self.theme.textFocusColor
        self.inputTextView.textColor = self.theme.textFocusColor
        self.delegate?.textViewDidBeginEditing(viewID: self.viewID)
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        self.labelTitle.textColor = self.theme.labelTitleColor
        self.inputTextView.textColor = self.theme.textColor
        self.delegate?.textViewDidEndEditing(viewID: self.viewID)
    }
    
    func textViewDidChange(_ textView: UITextView) {
        let width = textView.frame.width - 3
        let height = self.calculateTextHeight(text: textView.text, width: width)
        self.textViewHeightConstraint?.constant = height + 22
        self.layoutIfNeeded()
    }
    
    private func calculateTextHeight(text: String?, width: CGFloat) -> CGFloat {
        self.sampleLabel.text = text
        let size = self.sampleLabel.systemLayoutSizeFitting(CGSize(width: width, height: UIView.layoutFittingCompressedSize.height), withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel)
        return size.height
    }
}
