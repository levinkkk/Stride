//
//  FirstRun.swift
//  StrideLib
//
//  Created by pmacro  on 12/03/2019.
//

import Foundation

struct FirstRun: SinglePreference {
  static var `extension`: String = "flag"
  
  var name: String = "hasRunOnce"
  
  static var saveDirectory: URL {
    return FileManager.strideConfigURL
  }
  
  static func isFirstRun() -> Bool {
    return FirstRun.load() == nil
  }
  
  static func markAsRun() {
    FirstRun().save()
  }
}
