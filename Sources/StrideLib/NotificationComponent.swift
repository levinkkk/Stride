//
//  NotificationComponent.swift
//  Suit
//
//  Created by pmacro  on 04/04/2019.
//

import Foundation
import Suit

public class NotificationComponent: Component {
  
  let message: String
  let title: String
  
  public init(title: String, message: String) {
    self.title = title
    self.message = message
  }
  
  override open func loadView(frame: CGRect) {
    view = ScrollView(frame: frame)
  }
  
  public override func viewDidLoad() {
    super.viewDidLoad()
    
    let contentView = View()
    contentView.width = 100%
    contentView.height = 100%
    contentView.flexDirection = .column
    contentView.set(margin: 5~, for: .top)
    contentView.set(margin: 5~, for: .left)
    contentView.background.color = .backgroundColor
    view.add(subview: contentView)

    let titleLabel = Label(text: title)
    titleLabel.textColor = .red
    titleLabel.font = .ofType(.system,
                              category: .smallMedium,
                              weight: .bold)
    titleLabel.height = 20~
    titleLabel.width = 100%
    contentView.add(subview: titleLabel)
    
    let messageLabel = Label(text: message)
    messageLabel.font = .ofType(.system, category: .small)
    messageLabel.flex = 1
    messageLabel.width = 100%
    contentView.add(subview: messageLabel)
  }
  
  public func show(in parent: Window) {
    let window = NotificationWindow(rootComponent: self,
                                    frame: CGRect(x: parent.rootView.frame.width - 200,
                                      y: 0,
                                      width: 200,
                                      height: 75),
                        hasTitleBar: false)
    
    Application.shared.add(window: window,
                           asChildOf: parent)
    window.applyPlatformStyling()
    parent.bringToFront()
    window.bringToFront()
  }
}

class NotificationWindow: Window {
  
  var dismissTimer: RepeatingTimer?
  
  override func windowDidLaunch() {
    super.windowDidLaunch()
    
    dismissTimer = RepeatingTimer(timeInterval: 1.5)
    dismissTimer?.eventHandler = { [weak self] in
      DispatchQueue.main.async {
        self?.close()
        self?.dismissTimer?.suspend()
      }
    }
    dismissTimer?.resume()
  }
  
  override func onPointerEvent(_ pointerEvent: PointerEvent) -> Bool {
    if pointerEvent.type == .click {
      close()
      return true
    }
    
    return super.onPointerEvent(pointerEvent)
  }
  
  override func onKeyEvent(_ keyEvent: KeyEvent) -> Bool {
    return parentWindow?.onKeyEvent(keyEvent) ?? true
  }
  
  func applyPlatformStyling() {
    #if os (macOS)
    macWindow.backgroundColor = .clear
    macWindow.isOpaque = true
    let nsWindowContentView = macWindow.contentView
    nsWindowContentView?.wantsLayer = true
    nsWindowContentView?.layer?.cornerRadius = 5
    nsWindowContentView?.layer?.masksToBounds = true
    
    // This is a hack that avoids a display issue where the background
    // outside the bounds of the rounded window corners is still visible.
    let newSize = CGSize(width: contentView.frame.size.width + 0.1,
                         height: contentView.frame.size.height + 0.1)
    
    resize(to: newSize)
    #endif
  }
}
