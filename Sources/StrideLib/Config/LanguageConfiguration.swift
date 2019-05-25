//
//  LanguageConfiguration.swift
//  Editor
//
//  Created by pmacro  on 28/02/2019.
//

import Foundation

public struct LanguageConfiguration: Codable {
  
  public init(name: String, languageServerExecutable: URL? = nil) {
    self.name = name
    self.languageServerExecutable = languageServerExecutable
  }
  
  static var languageConfigurationFolderURL: URL = {
    return FileManager.strideConfigURL.appendingPathComponent("languages",
                                                              isDirectory: true)
  }()
  
  public var languageServerExecutable: URL?
  public var name: String
  public var compilerHomeDirectory: URL?
  
  static var saveDirectory: URL {
    return LanguageConfiguration.languageConfigurationFolderURL
  }
  
  public static func `for`(languageNamed languageName: String) -> LanguageConfiguration? {
    return LanguageConfiguration.loadAll()
            .first { $0.name.lowercased() == languageName.lowercased() }
  }
}

extension LanguageConfiguration: GroupPreference {
  static var `extension`: String = "languageConfiguration"  
}
