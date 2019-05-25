//
//  TestUtils.swift
//  StrideTests
//
//  Created by pmacro on 28/02/2019.
//

import Foundation
import SPMClient
import StrideLib
import XCTest

struct SampleCode {
  let packageRoot: URL
  let sourcesRoot: URL
}

func createSampleCodeDirectory(withFilenames filenames: [String]) throws -> SampleCode {
  let temp = FileManager.default.temporaryDirectory
  
  let packageURL = temp.appendingPathComponent("TestSources")
  try FileManager.default.createDirectory(at: packageURL, withIntermediateDirectories: true, attributes: nil)
  let packageFileContents = """
                              // swift-tools-version:4.2
                              // The swift-tools-version declares the minimum version of Swift required to build this package.

                              import PackageDescription

                              let package = Package(
                                  name: "TestSources",
                                  products: [
                                    .executable(
                                        name: "TestSources",
                                        targets: ["TestSources"])
                                  ],
                                  targets: [.target(name: "TestSources")]
                                )
                              """
  
  let packageFile = packageURL.appendingPathComponent("Package.swift")
  FileManager.default.createFile(atPath: packageFile.path,
                                 contents: packageFileContents.data(using: .utf8),
                                 attributes: nil)
  
  let sourcesDir = packageURL.appendingPathComponent("Sources/TestSources")
  try FileManager.default.createDirectory(at: sourcesDir,
                                          withIntermediateDirectories: true,
                                          attributes: nil)
  
  filenames.forEach {
    let sampleCodePath = sourcesDir.appendingPathComponent($0)
    // "swift build" doesn't generate the index needed for code completion unless there's
    // something to build, so the files have to have contents.
    FileManager.default.createFile(atPath: sampleCodePath.path,
                                   contents: "func test(){}".data(using: .utf8),
                                   attributes: nil)
  }
  
  guard let swiftHomePath = LanguageConfiguration
    .for(languageNamed: "Swift")?.compilerHomeDirectory else {
      fatalError("Swift environment not set.")
  }
  
  let client = SPMClient(projectDirectory: packageURL, swiftHomePath: swiftHomePath)
  let responseReader = client?.build()
  
  responseReader?.onNewResponse = { response in
      print(response)
  }
  
  var waitTime = 30
  
  while responseReader?.isFinished != true, waitTime > 0 {
    print("Waiting for SampleCode build completion...")
    Thread.sleep(forTimeInterval: 1)
    waitTime -= 1
  }
  
  return SampleCode(packageRoot: packageURL, sourcesRoot: sourcesDir)
}
