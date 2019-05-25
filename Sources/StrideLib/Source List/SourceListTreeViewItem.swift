//
//  SourceListTreeViewItem.swift
//  StrideLib
//
//  Created by Paul MacRory  on 16/05/2019.
//

import Foundation
import Suit

class SourceListTreeViewItem: TreeViewItem {
  var isHighlighted: Bool = false {
    didSet {
      view.isHighlighted = isHighlighted && !hasChildren
    }
  }
  
  fileprivate var calculatedChildren: [TreeViewItem]?
  let url: URL?
  let view: SourceListItemView
  
  public var isExpanded = false
  
  public typealias SelectionAction = (URL) -> Void
  public var selectionAction: SelectionAction?
  
  public var hasChildren: Bool {
    return url == nil || url?.hasDirectoryPath == true
  }
  
  public var children: [TreeViewItem]? {
    set {
      calculatedChildren = newValue
    }
    get {
      if calculatedChildren == nil, let url = url {
        let files = FileManager.default.loadFiles(at: url)
        calculatedChildren = files?.map {
          let item = SourceListTreeViewItem(url: $0)
          item.selectionAction = selectionAction
          return item
        }
      }
      return calculatedChildren
    }
  }
  
  public var itemView: View? {
    return view
  }
  
  public init(url: URL? = nil, title: String? = nil) {
    self.url = url
    view = SourceListItemView()
    
    view.filePath = url?.path
    
    view.width = 500~
    view.height = 15~
    view.title = title ?? url?.lastPathComponent
    
    view.onPress = { [weak self] in
      guard let `self` = self, let url = self.url else { return }
      self.selectionAction?(url)
    }
  }
}
