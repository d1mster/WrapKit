//
//  AssetColorTypeAlias.swift
//  WrapKit
//
//  Created by Stanislav Li on 3/7/24.
//

#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#elseif os(tvOS) || os(watchOS)
import UIKit
#endif
#if canImport(SwiftUI)
import SwiftUI
#endif

public typealias AssetColorTypeAlias = ColorAsset.Color

public final class ColorAsset {
    public fileprivate(set) var name: String
    
#if os(macOS)
    public typealias Color = NSColor
#elseif os(iOS) || os(tvOS) || os(watchOS)
    public typealias Color = UIColor
#endif
    
    @available(iOS 11.0, tvOS 11.0, watchOS 4.0, macOS 10.13, *)
    public private(set) lazy var color: Color = {
        guard let color = Color(asset: self) else {
            fatalError("Unable to load color asset named \(name).")
        }
        return color
    }()
    
#if os(iOS) || os(tvOS)
    @available(iOS 11.0, tvOS 11.0, *)
    public func color(compatibleWith traitCollection: UITraitCollection) -> Color {
        guard let color = Bundle.allBundles.compactMap({ Color(named: name, in: $0, compatibleWith: traitCollection) }).first
        else { fatalError("Unable to load color asset named \(name).") }
        return color
    }
#endif
    
#if canImport(SwiftUI)
    @available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
    public func swiftUIColor() -> SwiftUI.Color {
        for bundle in Bundle.allBundles {
            if let _ = ColorAsset.Color(asset: self) {
                return SwiftUI.Color(name, bundle: bundle)
            }
        }
        return SwiftUI.Color(name)
    }
#endif
    
    public init(name: String) {
        self.name = name
    }
}

public extension ColorAsset.Color {
    @available(iOS 11.0, tvOS 11.0, watchOS 4.0, macOS 10.13, *)
    convenience init?(asset: ColorAsset) {
        for bundle in Bundle.allBundles {
#if os(iOS) || os(tvOS)
            if ColorAsset.Color(named: asset.name, in: bundle, compatibleWith: nil) != nil {
                self.init(named: asset.name, in: bundle, compatibleWith: nil)
                return
            }
#elseif os(macOS)
            if ColorAsset.Color(named: NSColor.Name(asset.name), bundle: bundle) != nil {
                self.init(named: NSColor.Name(asset.name), bundle: bundle)
                return
            }
#elseif os(watchOS)
            if ColorAsset.Color(named: asset.name) != nil {
                self.init(named: asset.name)
                return
            }
#endif
        }
        return nil
    }
}
