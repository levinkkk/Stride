//
//  RecentProjects.swift
//  StrideLib
//
//  Created by pmacro  on 04/03/2019.
//

import Foundation

public struct RecentProjects: Codable {
  
  private var projects: [Project] = []
  
  private static let saveFileURL: URL =
          FileManager.strideConfigURL.appendingPathComponent("RecentProjects")
  
  public var count: Int {
    return projects.count
  }
  
  public subscript (index: Int) -> Project {
    return projects[index]
  }
  
  public static func load() -> RecentProjects {
    if let data = FileManager.default.contents(atPath: saveFileURL.path),
      let loadedObject = try? JSONDecoder().decode(RecentProjects.self, from: data) {
      return loadedObject
    }
    return RecentProjects()
  }
  
  public mutating func add(project: Project) {
    if let idx = projects.firstIndex(of: project) {
      projects.remove(at: idx)
    }
    
    projects.insert(project, at: 0)
    save()
  }
  
  @discardableResult
  private func save() -> RecentProjects {
    do {
      let data = try JSONEncoder().encode(self)
      let path = RecentProjects.saveFileURL.deletingLastPathComponent().path
      
      if !FileManager.default.fileExists(atPath: path) {
        try FileManager.default.createDirectory(atPath:
                                                path,
                                                withIntermediateDirectories: true,
                                                attributes: nil)
      }
      
      FileManager.default.createFile(atPath: RecentProjects.saveFileURL.path,
                                     contents: data,
                                     attributes: nil)
    } catch let error {
      print(error)
    }
    
    return self
  }
}
