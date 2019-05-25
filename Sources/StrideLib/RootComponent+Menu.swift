//
//  RootComponent+Menu.swift
//  StrideLib
//
//  Created by pmacro on 10/05/2019.
//

import Foundation
import Suit

extension RootComponent {

  ///
  /// Setup the app menu.
  ///
  func setupApplicationMenu() {
    let menu = Menu()
    let applicationMenuItem = MenuItem(title: "Application")
    applicationMenuItem.add(subItem: MenuItem(title: "Preferences...",
                                              keyEquivalent: ",") {
                                                PreferencesComponent.launch()
    })
    
    applicationMenuItem.add(subItem: MenuItem(title: "Quit",
                                              keyEquivalent: "q",
                                              action: {
                                                Application.shared.terminate()
    }))

    menu.add(item: applicationMenuItem)

    setupFileMenu(in: menu)
    setupEditMenu(in: menu)
    setupFindMenu(in: menu)
    setupNavigateMenu(in: menu)
    setupProductMenu(in: menu)

    view.window.menu = menu
  }

  ///
  /// Create the "File" menu.
  ///
  func setupFileMenu(in parent: Menu) {
      let fileMenuItem = MenuItem(title: "File")

    let closeTabMenuItem = MenuItem(title: "Close Tab",
                                    keyEquivalent: "w") { [weak self] in
                                      if self?.editorComponent.closeCurrent() == false {
                                        self?.view.window.close()
                                      }
    }

    fileMenuItem.add(subItem: closeTabMenuItem)

    let revertMenuItem = MenuItem(title: "Revert",
                                  keyEquivalent: "r", keyEquivalentModifiers: [.shift]) { [weak self] in
                                    self?.editorComponent.activeEditorComponent?.revert()
    }

    fileMenuItem.add(subItem: revertMenuItem)

    let quickOpenMenuItem = MenuItem(title: "Quick Open",
                                     keyEquivalent: "o",
                                     keyEquivalentModifiers: [.shift]) { [weak self] in
      guard let `self` = self else { return }
      self.quickOpenComponent = QuickOpenComponent(projectViewModel: self.viewModel)
      self.quickOpenComponent?.onSelection = { url in
        self.editorComponent.open(url: url, using: self.viewModel.languageClient)
      }
      self.quickOpenComponent?.show(in: self.view.window)
    }

    fileMenuItem.add(subItem: quickOpenMenuItem)
    parent.add(item: fileMenuItem)
  }

  ///
  /// Create the "Edit" menu.
  ///
  func setupEditMenu(in parent: Menu) {
    let editMenuItem = MenuItem(title: "Edit")

    let cutMenuItem = MenuItem(title: "Cut",
                               keyEquivalent: "x") { [weak self] in
                                if let textArea = self?.view.window?.focusedView as? TextAreaView {
                                  textArea.cut()
                                }
    }

    editMenuItem.add(subItem: cutMenuItem)

    let copyMenuItem = MenuItem(title: "Copy",
                                keyEquivalent: "c") { [weak self] in
                                  if let textArea = self?.view.window?.focusedView as? TextAreaView {
                                    textArea.copy()
                                  }
    }

    editMenuItem.add(subItem: copyMenuItem)

    let pasteMenuItem = MenuItem(title: "Paste",
                                 keyEquivalent: "v") { [weak self] in
                                  if let textArea = self?.view.window?.focusedView as? TextAreaView {
                                    textArea.paste()
                                  }
    }

    editMenuItem.add(subItem: pasteMenuItem)

    let selectAllMenuItem = MenuItem(title: "Select All",
                                     keyEquivalent: "a") { [weak self] in
                                      if let textArea = self?.view.window?.focusedView as? TextAreaView {
                                        textArea.selectAll()
                                      }
    }

    editMenuItem.add(subItem: selectAllMenuItem)

    let formatMenuItem = MenuItem(title: "Format File",
                                  keyEquivalent: "f",
                                  keyEquivalentModifiers: [.shift]) { [weak self] in
                                    self?.editorComponent.activeEditorComponent?.format()
    }

    editMenuItem.add(subItem: formatMenuItem)
    parent.add(item: editMenuItem)
  }

  ///
  /// Create the "Find" menu.
  ///
  func setupFindMenu(in parent: Menu) {
    let findMenuItem = MenuItem(title: "Find")
    findMenuItem.add(subItem: MenuItem(title: "Find",
                                       keyEquivalent: "f",
                                       action: { [weak self] in
                                        self?.editorComponent.activeEditorComponent?.toggleFindView()
    }))

    parent.add(item: findMenuItem)
  }

  ///
  /// Create the "Navigate" menu.
  ///
  func setupNavigateMenu(in parent: Menu) {
    let navigateMenuItem = MenuItem(title: "Navigate")
    navigateMenuItem
      .add(subItem: MenuItem(title: "Go Back",
                             keyEquivalent: String(FunctionKeyCharacters.leftArrow),
                             keyEquivalentModifiers: [.option],
                             action: { [weak self] in
                              self?.editorComponent.goBack()
      }))

    navigateMenuItem
      .add(subItem: MenuItem(title: "Go Forward",
                             keyEquivalent: String(FunctionKeyCharacters.rightArrow),
                             keyEquivalentModifiers: [.option],
                             action: { [weak self] in
                              self?.editorComponent.goForward()
      }))

    parent.add(item: navigateMenuItem)
  }

  ///
  /// Create the "Product" menu.
  ///
  func setupProductMenu(in parent: Menu) {
    let productMenuItem = MenuItem(title: "Product")

    let buildAndRunMenuItem = MenuItem(title: "Run", keyEquivalent: "r") { [weak self] in
      self?.buildAndRun()
    }

    let cleanMenuItem = MenuItem(title: "Clean", keyEquivalent: "k") { [weak self] in
      self?.clean()
    }

    let updateMenuItem = MenuItem(title: "Update", keyEquivalent: "u") { [weak self] in
      self?.update()
    }

    let resetMenuItem = MenuItem(title: "Reset", keyEquivalent: "r", keyEquivalentModifiers: [.shift, .option]) { [weak self] in
      self?.reset()
    }

    productMenuItem.add(subItem: buildAndRunMenuItem)
    productMenuItem.add(subItem: cleanMenuItem)
    productMenuItem.add(subItem: updateMenuItem)
    productMenuItem.add(subItem: resetMenuItem)

    parent.add(item: productMenuItem)
  }
}
