//
//  TabbedComponent.swift
//  StrideLib
//
//  Created by pmacro  on 28/03/2019.
//

import Foundation
import Suit
import LanguageClient

public class TabbedEditorComponent: TabbedComponent {
  
  var recentFiles = [URL]()
  
  var activeEditorComponent: EditorComponent? {
    return activeComponent as? EditorComponent
  }

  var editorComponents: [EditorComponent] {
    return tabComponents.compactMap { $0 as? EditorComponent }
  }
  
  @discardableResult
  public func open(url: URL, using languageClient: LanguageClient) -> EditorComponent {

    let existingComponentIdx = tabComponents.firstIndex {
      ($0 as? EditorComponent)?.currentURL == url
    }

    if let existingComponentIdx = existingComponentIdx {
      selectTab(atIndex: existingComponentIdx)
      let editor = tabComponents[existingComponentIdx] as! EditorComponent
      editor.editorView.makeKeyView()
      return editor
    }
    
    let component = EditorComponent(with: languageClient)
    
    if let activeEditorComponent = activeEditorComponent {
      remove(component: activeEditorComponent)
    }
    
    activeComponent = component
    
    insert(component: component, withTitle: url.lastPathComponent)
    component.open(url)

    return component
  }
}

public class TabbedComponent: CompositeComponent {
  
  let tabBar = View()
  var tabComponents = [Component]()
  var activeComponent: Component?
  var activeTabIndex: Int?
  
  var numberOfTabs = 0
  
  let scrollView = ScrollView()
  
  // Store the information needed to go backwards and forwards in the tab
  // history.
  var previousTabHistory = [Int]()
  var nextTabHistory = [Int]()
  
  var tabViews: [View] {
    return tabBar.subviews
  }
  
  public override func viewDidLoad() {
    super.viewDidLoad()
    view.flexDirection = .column
    tabBar.minWidth = 100%
    tabBar.flexGrow = 1
    tabBar.flexShrink = 0
    tabBar.height = 100%
    tabBar.background.color = .backgroundColor
    tabBar.flexDirection = .row

    scrollView.flexDirection = .column
    scrollView.wrap = .noWrap
    scrollView.width = 100%
    scrollView.maxWidth = 100%
    scrollView.height = 23~
    scrollView.add(subview: tabBar)
    scrollView.showVerticalScrollbar = false
    scrollView.showHorizontalScrollbar = false
    
    view.add(subview: scrollView)
  }
  
  public func insert(component: Component, withTitle title: String) {
    tabComponents.append(component)
    
    component.view.width = 100%
    component.view.flex = 1
    
    let tabView = Button()
    tabView.flexDirection = .row
    tabView.height = 100%
    tabView.flex = 1
    tabView.minWidth = 125~
    
    tabView.background.borderSize = 0.2
    tabView.background.borderColor = .darkerGray
    tabView.alignContent = .center
    tabView.alignItems = .center
    tabView.set(padding: 5~, for: .left)

    tabView.onPress = { [weak self] in
      guard let `self` = self else { return }
      
      if let index = self.tabBar.subviews.firstIndex(of: tabView) {
        self.selectTab(atIndex: index)
      }
    }
    
    let closeButton = Button()
    closeButton.changesStateOnRollover = true
    
    if let imagePath = Bundle.main.path(forAsset: "close",
                                        ofType: "png") {
      let image = Image(filePath: imagePath)
      closeButton.set(image: image, forState: .pressed)
      closeButton.set(image: image, forState: .focused)
      closeButton.alignContent = .center
      closeButton.justifyContent = .center
      closeButton.imageView.width = 10~
    }
    
    closeButton.background.cornerRadius = 4
    closeButton.width = 15~
    closeButton.height = 15~

    var normalBackground = closeButton.background
    normalBackground.color = .clear
    var pressedBackground = closeButton.background
    pressedBackground.color = .darkerGray
    
    var focusedBackground = closeButton.background
    focusedBackground.color = .gray
    
    closeButton.set(background: normalBackground, forState: .unfocused)
    closeButton.set(background: pressedBackground, forState: .pressed)
    closeButton.set(background: focusedBackground, forState: .focused)
    
    closeButton.titleLabel.horizontalArrangement = .center
    closeButton.titleLabel.horizontalArrangement = .center
    
    closeButton.onPress = { [weak self] in
      guard let `self` = self else { return }
      if let index = self.tabBar.subviews.firstIndex(of: tabView) {
        self.removeTab(atIndex: index)
      }
    }
    
    // The titleLabel is already there, so let's reverse things so the button is laid
    // out first.
    tabView.flexDirection = .rowReverse
    
    tabView.add(subview: closeButton)
    
    tabView.titleLabel.text = title
    tabView.titleLabel.flex = 1
    tabView.titleLabel.height = 20~
    tabView.titleLabel.verticalArrangement = .center
    tabView.titleLabel.font = .ofType(.system, category: .small, weight: .light)
    tabView.titleLabel.set(margin: 5~, for: .right)
    
    add(tabView: tabView)
    selectTab(atIndex: numberOfTabs - 1)
    
    scrollView.scroll(to: CGPoint(x: -(tabBar.frame.origin.x + tabBar.frame.width),
                                  y: tabBar.frame.origin.y))    
  }
  
  @discardableResult
  public func removeTab(atIndex index: Int) -> Bool {
    guard index < tabComponents.count else { return  false }
    
    let component = tabComponents.remove(at: index)
    remove(component: component)
    component.view.resignAsKeyView()
    view.window.releaseFocus(on: component.view)
    
    numberOfTabs -= 1
    let tabView = tabBar.subviews[index]
    tabView.removeFromSuperview()
    
    selectTab(atIndex: index > 0 ? index - 1 : 0)
    
    reconfigureTabs()
    
    view.window.rootView.invalidateLayout()
    tabBar.width = tabViews.reduce(0) { (current, tabView) in
      return current + tabView.frame.width
    }~
    
    view.window.rootView.invalidateLayout()
    view.forceRedraw()
    return true
  }
  
  public func selectTab(atIndex index: Int) {
    selectTab(atIndex: index, recordTrail: true)
  }
  
  func selectTab(atIndex index: Int, recordTrail: Bool) {
    if index == self.activeTabIndex { return }

    let tabIndex = index < numberOfTabs ? index : numberOfTabs - 1
    guard let component = tabComponents[safe: tabIndex] else { return }
    
    if let activeComponent = activeComponent {
      activeComponent.view.resignAsKeyView()
      view.window.releaseFocus(on: activeComponent.view)
      remove(component: activeComponent)
    }
    
    if let activeIndex = activeTabIndex {
      if recordTrail {
        previousTabHistory.append(activeIndex)
      }
      tabView(atIndex: activeIndex)?.background.color = Color.darkGray.lighter()
    }
    
    tabView(atIndex: tabIndex)?.background.color = .lightGray
    
    activeComponent = component
    add(component: component)
    component.view.makeKeyView()
    view.window.focusedView = component.view

    activeTabIndex = tabIndex
    
    view.window.rootView.invalidateLayout()
    view.forceRedraw()
  }
  
  func reconfigureTabs() {
    let newTabWidth = max(125, scrollView.frame.width / CGFloat(numberOfTabs))~
    let isMinWidth = newTabWidth.value <= 150
    
    tabViews.forEach {
      $0.width = newTabWidth
      // Change the text alignment depending on how crowded the screen is.
      ($0 as? Button)?.titleLabel.horizontalArrangement = isMinWidth ? .left : .center
    }
  }
  
  public func goBack() {
    guard !previousTabHistory.isEmpty else { return }
    
    let index = previousTabHistory.removeLast()
    nextTabHistory.append(index)

    selectTab(atIndex: index, recordTrail: false)
  }
  
  public func goForward() {
    guard !nextTabHistory.isEmpty else { return }

    let index = nextTabHistory.removeLast()
    selectTab(atIndex: index)
  }
  
  public func closeCurrent() -> Bool {
    if let index = activeTabIndex {
      return removeTab(atIndex: index)
    }

    return false
  }
  
  func add(tabView: View) {
    tabBar.add(subview: tabView)
    numberOfTabs += 1
    reconfigureTabs()
    
    view.window.rootView.invalidateLayout()
    
    tabBar.width = tabViews.reduce(0) { (current, tabView) in
      return current + tabView.frame.width
    }~
    
    view.window.rootView.invalidateLayout()
    tabBar.forceRedraw()
  }
  
  func tabView(atIndex index: Int) -> View? {
    return tabBar.subviews[safe: index]
  }
}
