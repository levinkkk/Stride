//
//  BuildOutputComponent.swift
//  StrideLib
//
//  Created by pmacro on 14/03/2019.
//

import Foundation
import Suit
import SPMClient

public class BuildOutputComponent: TextAreaComponent {

  var responseReader: ResponseReader? {
    didSet {
      handleNewResponseReader()
    }
  }

  var startMessage = "Building...\n"

  public override func viewDidLoad() {
    super.viewDidLoad()

    if let textAreaView = textAreaView {
      textAreaView.insets = EdgeInsets(left: 5, right: 0, top: 0, bottom: 0)
      textAreaView.font = Font(size: 11, family: "Menlo")
    }
  }

  func handleNewResponseReader() {
    clear()
    startReading()
  }

  func clear() {
    textAreaView?.deleteAll()
    view.forceRedraw()
  }

  func startReading() {
    if let textAreaView = textAreaView {
      textAreaView.insert(text: startMessage,
                          at: textAreaView.state.text.endIndex)
    }

    responseReader?.onNewResponse = { [weak self] responseString in
      print(responseString)
      guard let `self` = self else { return }

      DispatchQueue.main.sync {
        self.textAreaView?.insert(text: responseString,
                                  at: self.textAreaView!.state.text.endIndex)
        self.scrollToBottom()
      }
    }
  }
}
