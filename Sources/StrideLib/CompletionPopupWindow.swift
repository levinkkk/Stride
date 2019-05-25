//
//  CompletionPopupWindow.swift
//  Editor
//
//  Created by pmacro on 24/06/2018.
//

import Suit
import Foundation

///
/// A special type of window that passes certain key presses to its parent window.
///
public class CompletionPopupWindow: Window {

  ///
  /// Processes key presses relevant to the code completion popover, and passes any others to the
  /// parent window.
  ///
  public override func onKeyEvent(_ keyEvent: KeyEvent) -> Bool {
    let didConsume = keyEvent.keyType == .downArrow
                  || keyEvent.keyType == .upArrow
                  || keyEvent.keyType == .enter
                  || keyEvent.keyType == .return

    if didConsume {
      _ = super.onKeyEvent(keyEvent)
    } else {
      _ = parentWindow?.onKeyEvent(keyEvent)
    }

    return true
  }
}
