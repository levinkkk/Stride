//
//  ProjectWindow.swift
//  StrideLib
//
//  Created by pmacro on 27/03/2019.
//

import Foundation
import Suit

extension Window {
    
  ///
  /// Displays a message in a popup on top of this window.
  ///
  /// - parameter title: the message title.
  /// - parameter content: the message content.
  ///
  func displayMessage(withTitle title: String, content: String) {
    let notification = NotificationComponent(title: title,
                                             message: content)
    notification.show(in: self)
  }
}
