//
//  Preference.swift
//  StrideLib
//
//  Created by pmacro  on 12/03/2019.
//

import Foundation

protocol Preference: Codable {
  var name: String { get }
  static var saveDirectory: URL { get }
  static var `extension`: String { get }
  func save()
}

protocol SinglePreference: Preference {
  static func load() -> Self?
}

protocol GroupPreference: Preference {
  static func loadAll() -> [Self]
}

extension Preference {
  public func save() {
    do {
      let data = try JSONEncoder().encode(self)
      let saveDirectoryPath = Self.saveDirectory.path
      
      if !FileManager.default.fileExists(atPath: saveDirectoryPath) {
        try FileManager.default.createDirectory(atPath:
          saveDirectoryPath,
                                                withIntermediateDirectories: true,
                                                attributes: nil)
      }
      
      FileManager.default.createFile(atPath: Self.saveDirectory.appendingPathComponent("\(name).\(Self.extension)").path,
                                     contents: data,
                                     attributes: nil)
    } catch let error {
      print(error)
    }
  }
}

extension SinglePreference {
  static public func load() -> Self? {
    let file = FileManager.default.loadFiles(at: Self.saveDirectory)?
                .first { $0.path.hasSuffix(Self.extension) }
    
    if let file = file, let data = FileManager.default.contents(atPath: file.path) {
      return try? JSONDecoder().decode(Self.self, from: data)
    }
    return nil
  }
}

extension GroupPreference {
  static public func loadAll() -> [Self] {
    let files = FileManager.default.loadFiles(at: Self.saveDirectory)
    
    let preferences = files?.compactMap {
      (url: URL) -> Self? in
      if url.path.hasSuffix(Self.extension),
        let data = FileManager.default.contents(atPath: url.path) {
        return try? JSONDecoder().decode(Self.self, from: data)
      }
      return nil
    }
    
    return preferences ?? []
  }
}
