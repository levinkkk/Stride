//
//  Project.swift
//  StrideLib
//
//  Created by pmacro  on 04/03/2019.
//

import Foundation
import PromiseKit
import SPMClient

public enum ProjectError: Error {
  case unsupportedProject
  case invalidConfiguration(message: String)
}

public class Project: Codable, Equatable, Hashable {
  
  public static func == (lhs: Project, rhs: Project) -> Bool {
    return lhs.url == rhs.url
  }
  
  public func hash(into hasher: inout Hasher) {
    hasher.combine(url)
  }
  
  public var name: String
  public var url: URL
  public var primaryLanguage: String
  
  // Can this project be executed or is it only a library.
  public var hasExecutable: Bool
  
  public init(name: String,
              url: URL,
              primaryLanguage: String,
              hasExecutable: Bool) {
    self.name = name
    self.url = url
    self.primaryLanguage = primaryLanguage
    self.hasExecutable = hasExecutable
  }
  
  public static func from(url: URL) -> Promise<Project> {
    return Promise<Project> { resolver in
      
      if url.pathExtension.lowercased() == "swift" {
        let languageConfig = LanguageConfiguration
                              .for(languageNamed: "swift")
        let compilerHome = languageConfig?.compilerHomeDirectory
        
        let client = SPMClient(projectDirectory: url.deletingLastPathComponent(),
                               swiftHomePath: compilerHome)
        
        guard let package = client?.generatePackageDescription() else {
          let message = "Unable to read package at: \(url.path)"
          resolver.reject(ProjectError
            .invalidConfiguration(message: message))
          return
        }
        
        resolver.fulfill(SwiftProject(from: package,
                                      client: client!,
                                      at: url))
      }
      
      resolver.reject(ProjectError.unsupportedProject)
    }
  }
}

public class SwiftProject: Project {
  public var client: SPMClient?
  
  public init(from package: Package, client: SPMClient, at url: URL) {
    self.client = client
    super.init(name: package.name,
               url: url,
               primaryLanguage: "swift",
               hasExecutable: package.hasExecutable)
  }
  
  required init(from decoder: Decoder) throws {
    try super.init(from: decoder)
  }
}
