//
//  CodeHighlighter.swift
//  StrideLib
//
//  Created by pmacro  on 05/03/2019.
//

import Foundation
import PromiseKit
import Highlighter

///
/// A code highlighter that runs invokes an external highlighting process for Swift code.
///
public class CodeHighlighter {
  let baseURL: URL
  let highlighterURL: URL
  
  let backgroundQueue = DispatchQueue(label: "HighlightingBackgroundQueue")
  
  var process: Process?
  var requestId = 0
  
  public enum CodeHighlighterError: Error {
    case unknown
  }
  
  public init?() {
    if let executableURL = Bundle.main.executableURL {
      self.baseURL = executableURL.deletingLastPathComponent()
    } else {
      let directory: String = FileManager.default.currentDirectoryPath
      self.baseURL = URL(fileURLWithPath: directory)
    }
    
    highlighterURL = baseURL.appendingPathComponent("HighlighterRunner")
    
    print("Using HighlighterRunner at path: \(highlighterURL.path)")
    
    guard FileManager.default.fileExists(atPath: highlighterURL.path) else {
      return nil
    }
  }
 
  ///
  /// Runs highlighting against `file`, returning an array of `Token` items in a promise.
  ///
  public func run(on file: URL) -> Promise<[Token]> {
    requestId += 1
    // Keep track of the ID so we can tell within the queue if the operation is the most
    // recent, because if it's not we can perform an early exit when there is a high volume
    // of highlighting requests.
    let thisId = requestId
    
    // Another early-exit strategy.
    if self.process?.isRunning == true {
      self.process?.terminate()
      self.process = nil
    }
    
    return Promise<[Token]>() { resolver in
      backgroundQueue.async { [weak self] in
        guard let `self` = self, thisId == self.requestId else {
          resolver.reject(CodeHighlighterError.unknown)
          return
        }
        
        self.process = Process()
        self.process?.currentDirectoryPath = self.baseURL.path
        self.process?.executableURL = self.highlighterURL
        self.process?.arguments = [file.path]
        
        let output = Pipe()
        self.process?.standardOutput = output
        self.process?.launch()
        
        let data = output.fileHandleForReading.readDataToEndOfFile()
        
        do {
          let tokens = try JSONDecoder().decode([Token].self, from: data)
          resolver.fulfill(tokens)
        } catch let error {
          resolver.reject(error)
        }
      }
    }
  }
}
