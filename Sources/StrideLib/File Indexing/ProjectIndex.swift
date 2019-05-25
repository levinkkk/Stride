//
//  ProjectIndexer.swift
//  StrideLib
//
//  Created by pmacro  on 28/03/2019.
//

import Foundation

///
/// Maintains an index of all files within a project.  This is a naive implementation
/// for now, which simply scans the project root's directory tree for files of types
/// we might be interested in, and then stores those URLs in memory.  Searching the index
/// is a dumb match against the file name. 
///
public class ProjectIndex {
  
  let project: Project
  
  var fileURLs = [URL]()
  
  var indexableFileTypes = ["png",
                            "gif",
                            "jpg",
                            "jpeg",
                            "sh",
                            "text",
                            "txt",
                            "c",
                            "h",
                            "m",
                            "mm",
                            "swift",
                            "js"]
  
  private static var projectIndexes = [Project: ProjectIndex]()
  
  public init(project: Project) {
    self.project = project
  }
  
  public static func index(for project: Project) -> ProjectIndex {
    if let index = ProjectIndex.projectIndexes[project] {
      return index
    }
    
    let index = ProjectIndex(project: project)
    ProjectIndex.projectIndexes[project] = index
    return index
  }
  
  public func build() {
    print("Building project index...")
    let start = Date()

    let rootDirectory = project.url.hasDirectoryPath
                      ? project.url
                      : project.url.deletingLastPathComponent()
    buildIndex(in: rootDirectory)
    print("Built project index in: \(Date().timeIntervalSince(start))s")
  }
  
  public func findFiles(matching pattern: String) -> [URL] {
    var results = [URL]()
    
    for url in fileURLs {
      if url.lastPathComponent.lowercased().contains(pattern.lowercased()) {
        results.append(url)
      }
    }
    
    return results.sorted {
      $0.scoreOfMatch(against: pattern) < $1.scoreOfMatch(against: pattern)
    }
  }
  
  private func buildIndex(in directory: URL) {
    guard let subPaths = try? FileManager.default
                        .contentsOfDirectory(at: directory,
                                             includingPropertiesForKeys: nil,
                                             options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants]) else {
      return
    }
    
    for url in subPaths {
      if url.isFileURL, indexableFileTypes.contains(url.pathExtension) {
        fileURLs.append(url)
      } else {
        buildIndex(in: url)
      }
    }
  }
}

extension URL {
  
  func scoreOfMatch(against searchTerm: String) -> Int {
    if lastPathComponent.hasPrefix(searchTerm) {
      return 1
    }
    
    if lastPathComponent.lowercased().hasPrefix(searchTerm.lowercased()) {
      return 2
    }
    
    return 10
  }
}
