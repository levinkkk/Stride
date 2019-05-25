//
//  RxSuit.swift
//  StrideLib
//
//  Created by pmacro on 10/05/2019.
//

import Foundation

// Copies of functions internal to RxSwift, which are unavailable to RxSuit (an unofficial
// bandwagon-jumping-on project).

func rxFatalError(_ lastMessage: String) -> Never  {
  // The temptation to comment this line is great, but please don't, it's for your own good. The choice is yours.
  fatalError(lastMessage)
}

func rxFatalErrorInDebug(_ lastMessage: @autoclosure () -> String, file: StaticString = #file, line: UInt = #line) {
  #if DEBUG
  fatalError(lastMessage(), file: file, line: line)
  #else
  print("\(file):\(line): \(lastMessage())")
  #endif
}
