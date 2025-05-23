//
//  Textfield.swift
//  WrapKit
//
//  Created by Stanislav Li on 8/12/23.
//

import Foundation

public struct TextfieldAppearance {
    public init(
        colors: TextfieldAppearance.Colors,
        font: Font,
        border: TextfieldAppearance.Border? = nil,
        placeholder: TextfieldAppearance.Placeholder? = nil
    ) {
        self.colors = colors
        self.font = font
        self.border = border
        self.placeholder = placeholder
    }
    
    public struct Colors {
        public init(
            textColor: Color,
            selectedBorderColor: Color,
            selectedBackgroundColor: Color,
            selectedErrorBorderColor: Color,
            errorBorderColor: Color,
            errorBackgroundColor: Color,
            deselectedBorderColor: Color,
            deselectedBackgroundColor: Color,
            disabledTextColor: Color,
            disabledBackgroundColor: Color
        ) {
            self.textColor = textColor
            self.selectedBorderColor = selectedBorderColor
            self.selectedBackgroundColor = selectedBackgroundColor
            self.selectedErrorBorderColor = selectedErrorBorderColor
            self.errorBorderColor = errorBorderColor
            self.errorBackgroundColor = errorBackgroundColor
            self.deselectedBorderColor = deselectedBorderColor
            self.deselectedBackgroundColor = deselectedBackgroundColor
            self.disabledTextColor = disabledTextColor
            self.disabledBackgroundColor = disabledBackgroundColor
        }
        
        public var textColor: Color
        public var selectedBorderColor: Color
        public var selectedBackgroundColor: Color
        public var errorBorderColor: Color
        public var selectedErrorBorderColor: Color
        public var errorBackgroundColor: Color
        public var deselectedBorderColor: Color
        public var deselectedBackgroundColor: Color
        public var disabledTextColor: Color
        public var disabledBackgroundColor: Color
    }
    public struct Border {
        public init(idleBorderWidth: CGFloat, selectedBorderWidth: CGFloat) {
            self.idleBorderWidth = idleBorderWidth
            self.selectedBorderWidth = selectedBorderWidth
        }
        
        public var idleBorderWidth: CGFloat
        public var selectedBorderWidth: CGFloat
    }
    public struct Placeholder {
        public init(color: Color, disabledColor: Color? = nil, font: Font, text: String? = nil) {
            self.color = color
            self.disabledColor = disabledColor
            self.font = font
            self.text = text
        }
        
        public var color: Color
        public var disabledColor: Color?
        public var font: Font
        public var text: String?
    }
    
    public var colors: Colors
    public var font: Font
    public var border: Border?
    public var placeholder: Placeholder?
}

#if canImport(UIKit)
import UIKit

open class Textfield: UITextField {
    public enum TrailingViewStyle {
        case clear(trailingView: View)
        case custom(trailingView: View)
    }
    
    public var leadingView: View? {
        didSet {
            oldValue?.removeFromSuperview()
            setupLeadingView()
        }
    }
    public var trailingView: View? {
        didSet {
            oldValue?.removeFromSuperview()
            setupTrailingView()
        }
    }
    
    private var isValidState = true
    
    public var padding: UIEdgeInsets = .zero
    public var midPadding: CGFloat = 0
    public var clearButtonEdgeInsets = UIEdgeInsets(top: 0, left: -8, bottom: 0, right: 8)

    public var isTextSelectionDisabled = false
    public var isEnabledForEditing = true {
        didSet {
            if !isEnabledForEditing {
                _  = resignFirstResponder()
            }
        }
    }
    
    public var onPress: (() -> Void)?
    public var onPaste: ((String?) -> Void)?
    public var nextTextfield: UIResponder? = nil { didSet { returnKeyType = nextTextfield == nil ? .done : .next } }
    public var onBecomeFirstResponder: (() -> Void)?
    public var onResignFirstResponder: (() -> Void)?
    public var onTapBackspace: (() -> Void)?
    
    public var didChangeText = [((String?) -> Void)]()
    
    open override var placeholder: String? {
        didSet {
            updatePlaceholder()
        }
    }
    
    open override var text: String? {
        didSet {
            if let delegate = delegate as? MaskedTextfieldDelegate {
                delegate.fullText = text ?? ""
            }
        }
    }
    
    public var maskedTextfieldDelegate: MaskedTextfieldDelegate? {
        didSet {
            maskedTextfieldDelegate?.applyTo(textfield: self)
        }
    }
    
    public var appearance: TextfieldAppearance { didSet { updateAppearance() }}
    
    public init(
        cornerRadius: CGFloat = 10,
        textAlignment: NSTextAlignment = .natural,
        appearance: TextfieldAppearance,
        midPadding: CGFloat = 6.67,
        padding: UIEdgeInsets = .init(top: 10, left: 12, bottom: 10, right: 12),
        nextTextfield: UIResponder? = nil,
        leadingView: View? = nil,
        trailingView: TrailingViewStyle? = nil,
        inputView: UIView? = nil,
        autocapitalizationType: UITextAutocapitalizationType = .none,
        delegate: MaskedTextfieldDelegate? = nil
    ) {
        self.midPadding = midPadding
        self.padding = padding
        self.nextTextfield = nextTextfield
        self.appearance = appearance
        super.init(frame: .zero)

        self.textAlignment = textAlignment
        self.cornerRadius = cornerRadius
        self.autocorrectionType = .no
        self.textColor = appearance.colors.textColor
        self.autocapitalizationType = .none
        self.inputView = inputView
        maskedTextfieldDelegate = delegate
        delegate?.applyTo(textfield: self)
        returnKeyType = nextTextfield == nil ? .done : .next
        addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        
        self.leadingView = leadingView
        updateAppearance()
        
        switch trailingView {
        case .custom(let trailingView):
            self.trailingView = trailingView
        case .clear(let trailingView):
            trailingView.onPress = { [weak self] in
                self?.text = ""
                self?.sendActions(for: .editingChanged)
                trailingView.isHidden = true
            }
            self.didChangeText.append { [weak self] text in
                let text = self?.maskedTextfieldDelegate?.onlySpecifiersIfMaskedText ?? text ?? ""
                self?.trailingView?.isHidden = text.isEmpty
            }
            self.trailingView = trailingView
            trailingView.isHidden = true
        default:
            break
        }
        setupLeadingView()
        setupTrailingView()
    }
    
    open override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        if let trailingView = trailingView, trailingView.frame.contains(point) {
            return true
        } else if let leadingView = leadingView, leadingView.frame.contains(point) {
            return true
        }
        let isTouchInside = super.point(inside: point, with: event)
        if isTouchInside {
            onPress?()
        }
        return isTouchInside
    }
    
    open override func deleteBackward() {
        super.deleteBackward()
        
        onTapBackspace?()
    }
    
    open override var isUserInteractionEnabled: Bool {
        didSet {
            textColor = isUserInteractionEnabled ? appearance.colors.textColor : appearance.colors.disabledTextColor
            backgroundColor = isUserInteractionEnabled ? appearance.colors.deselectedBackgroundColor : appearance.colors.disabledBackgroundColor
            updatePlaceholder()
        }
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func textFieldDidChange() {
        didChangeText.forEach {
            if let delegate = self.delegate as? MaskedTextfieldDelegate {
                $0(delegate.fullText)
            } else {
                $0(self.text)
            }
        }
    }
    
    public func updatePlaceholder() {
        guard let customizedPlaceholder = appearance.placeholder else { return }
        attributedPlaceholder = NSAttributedString(
            string: customizedPlaceholder.text ?? placeholder ?? "",
            attributes: [
                NSAttributedString.Key.foregroundColor: isUserInteractionEnabled ? customizedPlaceholder.color : (customizedPlaceholder.disabledColor ?? customizedPlaceholder.color),
                NSAttributedString.Key.font: customizedPlaceholder.font
            ]
        )
    }
    
    open override func textRect(forBounds bounds: CGRect) -> CGRect {
        return textArea(for: bounds)
    }
    
    open override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        return textArea(for: bounds)
    }
    
    open override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return textArea(for: bounds)
    }
    
    open override func paste(_ sender: Any?) {
        super.paste(sender)
        onPaste?(UIPasteboard.general.string)
    }
    
    @discardableResult
    open override func becomeFirstResponder() -> Bool {
        guard isEnabledForEditing else { return false }
        let success = super.becomeFirstResponder()
        if success { onBecomeFirstResponder?() }
        if isSecureTextEntry, let text = self.text {
            self.text?.removeAll()
            insertText(text)
        }
        updateAppearance()
        return success
    }
    
    open override var canBecomeFirstResponder: Bool {
         return isEnabledForEditing
     }
    
    open override func resignFirstResponder() -> Bool {
        let result = super.resignFirstResponder()
        if result { onResignFirstResponder?() }
        updateAppearance()
        return result
    }
    
    open override var isSecureTextEntry: Bool {
        didSet {
            if isFirstResponder {
                _ = becomeFirstResponder()
            }
        }
    }
    
    open override func caretRect(for position: UITextPosition) -> CGRect {
        return isTextSelectionDisabled ? .zero : super.caretRect(for: position)
    }
    
    open override func selectionRects(for range: UITextRange) -> [UITextSelectionRect] {
        return isTextSelectionDisabled ? [] : super.selectionRects(for: range)
    }
    
    open override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return isTextSelectionDisabled ? false : super.canPerformAction(action, withSender: sender)
    }
    
    open override func clearButtonRect(forBounds bounds: CGRect) -> CGRect {
        let bounds = super.clearButtonRect(forBounds: bounds)
        return bounds.inset(by: clearButtonEdgeInsets)
    }
    
    private func textArea(for bounds: CGRect) -> CGRect {
        var padding = padding
        if let leftView = leadingView, !leftView.isHidden {
            if UIView.userInterfaceLayoutDirection(for: semanticContentAttribute) == .rightToLeft {
                padding.right += leftView.frame.width + midPadding
            } else {
                padding.left += leftView.frame.width + midPadding
            }
        }
        if let rightView = trailingView, !rightView.isHidden {
            if UIView.userInterfaceLayoutDirection(for: semanticContentAttribute) == .rightToLeft {
                padding.left += rightView.frame.width + midPadding
            } else {
                padding.right += rightView.frame.width + midPadding
            }
        }
        return bounds.inset(by: padding)
    }
    
    func setupTrailingView() {
        guard let trailingView = trailingView else { return }
        addSubview(trailingView)
        trailingView.anchor(
            .topGreaterThanEqual(topAnchor),
            .trailing(trailingAnchor, constant: padding.right),
            .centerY(centerYAnchor),
            .bottomLessThanEqual(bottomAnchor)
        )
    }
    
    func setupLeadingView() {
        guard let leadingView = leadingView else { return }
        addSubview(leadingView)
        leadingView.anchor(
            .topGreaterThanEqual(topAnchor),
            .leading(leadingAnchor, constant: padding.left),
            .centerY(centerYAnchor),
            .bottomLessThanEqual(bottomAnchor)
        )
    }
    
    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        updateAppearance()
    }
}

public extension Textfield {
    func updateAppearance(isValid: Bool) {
        if self.isValidState == isValid { return }
        self.isValidState = isValid
        font = appearance.font
        let isFirstResponder = isFirstResponder
        let appearance = appearance
        UIView.animate(withDuration: 0.1, delay: .leastNonzeroMagnitude, options: [.allowUserInteraction]) {
            if isValid {
                self.backgroundColor = isFirstResponder ? appearance.colors.selectedBackgroundColor : appearance.colors.deselectedBackgroundColor
                self.layer.borderColor = isFirstResponder ? appearance.colors.selectedBorderColor.cgColor : appearance.colors.deselectedBorderColor.cgColor
            } else {
                self.backgroundColor = appearance.colors.errorBackgroundColor
                self.layer.borderColor = isFirstResponder ? appearance.colors.selectedErrorBorderColor.cgColor : appearance.colors.errorBorderColor.cgColor
            }
            self.layer.borderWidth = (isFirstResponder ? appearance.border?.selectedBorderWidth : appearance.border?.idleBorderWidth) ?? 0
        }
    }
    
    func updateAppearance() {
        updatePlaceholder()
        font = appearance.font
        let text = (delegate as? MaskedTextfieldDelegate)?.fullText ?? text
        let isValid = isValidState
        let isFirstResponder = isFirstResponder
        let appearance = appearance
        UIView.animate(withDuration: 0.1, delay: .leastNonzeroMagnitude, options: [.allowUserInteraction]) {
            if isValid {
                self.backgroundColor = isFirstResponder ? appearance.colors.selectedBackgroundColor : appearance.colors.deselectedBackgroundColor
                self.layer.borderColor = isFirstResponder ? appearance.colors.selectedBorderColor.cgColor : appearance.colors.deselectedBorderColor.cgColor
            } else {
                self.backgroundColor = appearance.colors.errorBackgroundColor
                self.layer.borderColor = isFirstResponder ? appearance.colors.selectedErrorBorderColor.cgColor : appearance.colors.errorBorderColor.cgColor
            }
            self.layer.borderWidth = (isFirstResponder ? appearance.border?.selectedBorderWidth : appearance.border?.idleBorderWidth) ?? 0
        }
    }
}
#endif
