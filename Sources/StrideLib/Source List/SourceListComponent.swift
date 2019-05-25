//
//  SourceListComponent.swift
//  Editor
//
//  Created by pmacro on 15/06/2018.
//

import Foundation
import Suit
import SPMClient
import RxSwift

///
/// A tree component that displays files/directories from a SwiftProject.
/// This component has specific knowlegde of Swift projects and as such should be
/// refactored to work in a more generic fashion.
///
public class SourceListComponent: TreeComponent {

  /// The project root.
  var rootItem: RootTreeViewItem?
  
  /// The client used to query Swift package structures.
  var client: SPMClient?

  /// The type of callback for file selections.
  public typealias FileSelectionAction = (URL) -> Void
  
  /// A callback invoked whenever a file is selected in the tree.
  public var onSelectFile: FileSelectionAction?

  /// A list of target names that have already been processed.  This prevents
  /// circular dependencies causing problems.
  private var processedTargetNames: [String] = []
  
  /// Keep Rx tidy.
  let disposeBag = DisposeBag()
  
  ///
  /// Create a new SourceListComponent using the project information in the provided
  /// view model.
  ///
  /// - parameter projectViewModel: the view model containing project information.
  ///
  public required init(projectViewModel: ProjectViewModel) {
    super.init()

    // When the project changes, reload the contents.
    projectViewModel.project.subscribe { [weak self] next in
      self?.client = (next.element as? SwiftProject)?.client
      self?.load()
    }
    .disposed(by: disposeBag)
    
    rootItem = RootTreeViewItem()
    rootItem?.children = []
  }

  ///
  /// Load the tree's contents.
  ///
  func load() {
    guard let client = client else { return }
    
    createPackageTree(withRoot: rootItem!,
                      client: client,
                      searchDirectory: client.projectDirectory)
    reload()
  }
  
  ///
  /// Create the tree structure using the provided project information.
  ///
  func createPackageTree(withRoot root: TreeViewItem,
                         client: SPMClient,
                         searchDirectory: URL) {
    guard let package = client.generatePackageDescription(in: searchDirectory) else {
      // TODO UI error.
      print("Could not read package.")
      return
    }

    guard let products = package.products else {
      // TODO UI error.
      print("Package has no products.")
      return
    }

    let selectionAction = { [weak self] url -> Void in
      self?.onSelectFile?(url)
    }

    var productItems = [TreeViewItem]()

    defer {
      // Add all products
      root.children?.append(contentsOf: productItems)
    }

    // First, add all products targets.
    for product in products {
      // Add all the product's targets.
      for targetName in product.targets
      {
        processedTargetNames.append(targetName)
        guard let target = package.targets?.first(where: { $0.name == targetName }),
          let sourcesURL = target.sourcesURL else {
            print("Unable to find sources URL for target: \(targetName)")
            continue
        }
        let targetSourcesRoot = SourceListTreeViewItem(url: sourcesURL, title: targetName)
        targetSourcesRoot.selectionAction = selectionAction
        productItems.append(targetSourcesRoot)
      }
    }

    // Now add all dependencies.  We just group them together, not worrying about
    // which target they belong to.

    let allDependencyNames = package.targets?.compactMap {
      $0.dependencies?.compactMap { $0.name }
      }
      .flatMap{ $0 }
      .filter { !processedTargetNames.contains($0) }

    guard let dependencyNames = allDependencyNames,
      !dependencyNames.isEmpty else {
        return
    }

    let dependencyTreeItem = SourceListTreeViewItem(title: "Dependencies")
    dependencyTreeItem.children = []

    for dependencyName in dependencyNames
      where !processedTargetNames.contains(dependencyName)
    {
      processedTargetNames.append(dependencyName)
      let directory = client.projectDirectory
        .appendingPathComponent("Packages/\(dependencyName)")
      if FileManager.default.fileExists(atPath: directory.path) {
        createPackageTree(withRoot: dependencyTreeItem,
                          client: client,
                          searchDirectory: directory)
      }
    }

    if dependencyTreeItem.children?.isEmpty == false {
      root.children?.append(dependencyTreeItem)
    }
  }

  ///
  /// The project root.
  ///
  public override func getRootTreeViewItem() -> TreeViewItem? {
    return rootItem
  }  
}

extension FileManager {

  ///
  /// Load an array of file URLs representing the children of `url`.
  ///
  internal func loadFiles(at url: URL) -> [URL]? {
    return try? FileManager.default.contentsOfDirectory(at: url,
                                                        includingPropertiesForKeys: nil)
    .sorted { (first, second) -> Bool in
        return first.lastPathComponent.lowercased() < second.lastPathComponent.lowercased()
    }
    .filter { $0.lastPathComponent != ".DS_Store" }
  }
}
