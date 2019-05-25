//
//  Config.swift
//  StrideLib
//
//  Created by pmacro  on 04/03/2019.
//

import Foundation

extension FileManager {
  
  public static var strideConfigURL: URL = {
    let home = FileManager.default.homeDirectoryForCurrentUser
    let config = home.appendingPathComponent(".stride_configuration", isDirectory: true)
    return config
  }()
  
}
