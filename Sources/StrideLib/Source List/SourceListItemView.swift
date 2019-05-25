//
//  SourceListItemView.swift
//  StrideLib
//
//  Created by pmacro on 16/05/2019.
//

import Foundation
import Suit

///
/// A cell that represents a directory/file item in the source list view.
///
class SourceListItemView: Button {
  /// Whether or not this item is currently highlighted within the source list view.
  var isHighlighted: Bool = false
  
  /// The icon view for the file type or directory.
  var iconView: ImageView?
  
  /// The path represented by this item.
  var filePath: String?
  
  required init() {
    super.init()
    
    imageView.mode = .maintainAspectRatio
    titleLabel.horizontalArrangement = .left
    titleLabel.verticalArrangement = .center
    
    #if os(Linux)
    titleLabel.font = Font.ofType(.system, category: .small)
    #else
    titleLabel.font = Font.ofType(.system, category: .smallMedium)
    #endif
    
    background.color = .clear
    // Add some space between the icon and the label.
    imageView.set(margin: 3~, for: .right)
    updateAppearance(style: Appearance.current)
  }
  
  override func didAttachToWindow() {
    super.didAttachToWindow()
    if let filePath = filePath,
      let icon = IconService.icon(forFile: filePath) {
      set(image: icon)
      imageView.width = 15~
    }
  }
  
  override func updateAppearance(style: AppearanceStyle) {
    super.updateAppearance(style: style)
    
    if isHighlighted {
      set(foregroundColor: .white, forState: .focused)
      set(foregroundColor: .white, forState: .unfocused)
    } else {
      set(foregroundColor: .textColor, forState: .focused)
      set(foregroundColor: .textColor, forState: .unfocused)
    }
    
    switch style {
    case .light:
      set(foregroundColor: .darkerGray, forState: .pressed)
    case .dark:
      set(foregroundColor: .lighterGray, forState: .pressed)
    }
  }
}
