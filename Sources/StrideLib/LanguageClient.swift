//
//  LanguageServerManager.swift
//  Editor
//
//  Created by pmacro on 23/06/2018.
//

import Foundation
import LanguageClient
import PromiseKit

extension LanguageClient {

  @discardableResult
  public func connect(withSourceRoot sourcePath: String) -> Promise<InitializeResult> {
    let config = LanguageConfiguration.loadAll()
      .first { $0.name.lowercased() == "swift" }

    guard let languageConfig = config else {
      print("Error: no configuration for language Swift.")
      return Promise<InitializeResult>(error: JSONRPCError.unknown)
    }

    if let languageServerPath = languageConfig.languageServerExecutable?.path {
      print("Starting language server: \(languageServerPath)")
      return startServer(atPath: languageServerPath,
                         sourcePath: sourcePath)
    } else {
      print("No language server executable found.")
      return Promise.init(error: JSONRPCError.processNotRunning)
    }
  }
}
