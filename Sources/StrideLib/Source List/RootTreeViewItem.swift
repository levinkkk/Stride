//
//  RootTreeViewItem.swift
//  StrideLib
//
//  Created by Paul MacRory  on 16/05/2019.
//

import Foundation
import Suit

///
/// A TreeViewItem that represents the very root of the tree.
///
public class RootTreeViewItem: TreeViewItem {
  
  /// Is this item highlighted?
  public var isHighlighted: Bool = false
  
  /// Is this item expanded?
  public var isExpanded: Bool = true
  
  /// The child nodes.
  public var children: [TreeViewItem]?
  
  /// True, if this item has child nodes.
  public var hasChildren: Bool {
    return children?.isEmpty == false
  }
  
  /// The renderer for this item.
  public var itemView: View?
}
