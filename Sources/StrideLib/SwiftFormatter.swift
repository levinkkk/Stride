//
//  Formatter.swift
//  StrideLib
//
//  Created by pmacro on 13/03/2019.
//

import Foundation

public class SwiftFormatter {
  static public func format(file: URL, languageConfiguration: LanguageConfiguration) {
    let process = Process()

    guard let swiftFormat = languageConfiguration.compilerHomeDirectory?.appendingPathComponent("/usr/bin/swift-format") else {
      return
    }

    process.executableURL = swiftFormat
    process.arguments = [file.path,
                         "-in-place",
                         "-indent-switch-case",
                         "-indent-width",
                         "2"]
    process.launch()
    process.waitUntilExit()
  }
}
