//
//  SearchBar.swift
//
//
//  Created by Daniiar Erkinov on 3/7/24.
//

#if canImport(UIKit)
import Foundation
import UIKit

public class SearchBar: View {
    public let stackView = StackView(axis: .horizontal)
    public let leftView: Button
    public let textfield: Textfield
    public let rightView: Button
    
    public init(
        leftView: Button = Button(isHidden: true),
        textfield: Textfield,
        rightView: Button = Button(isHidden: true),
        spacing: CGFloat = 8
    ) {
        self.leftView = leftView
        self.textfield = textfield
        self.rightView = rightView
        self.stackView.spacing = spacing
        
        super.init(frame: .zero)

        setupSubviews()
        setupConstraints()
        textfield.backgroundColor = UIColor.white
        textfield.appearance.colors.deselectedBackgroundColor = UIColor.white
    }
    
    func setupSubviews() {
        addSubview(stackView)
        
        stackView.addArrangedSubview(leftView)
        stackView.addArrangedSubview(textfield)
        stackView.addArrangedSubview(rightView)
        
        leftView.setContentCompressionResistancePriority(.required, for: .horizontal)
        rightView.setContentCompressionResistancePriority(.required, for: .horizontal)
    }
    
    func setupConstraints() {
        stackView.fillSuperview()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
#endif