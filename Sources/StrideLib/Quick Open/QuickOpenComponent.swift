//
//  QuickOpenComponent.swift
//  StrideLib
//
//  Created by pmacro on 27/03/2019.
//

import Foundation
import Suit

public class QuickOpenComponent: CompositeComponent {
  
  let textInputView = TextInputView()
  let searchResultsComponent = ListComponent()
  
  var currentResults = [URL]()
  
  weak var parentWindow: Window?
  
  public var onSelection: ((_ url: URL) -> Void)?
  
  unowned var projectViewModel: ProjectViewModel
  
  required public init(projectViewModel: ProjectViewModel) {
    self.projectViewModel = projectViewModel
  }
  
  public override func viewDidLoad() {
    super.viewDidLoad()
    view.flexDirection = .column
    
    view.width = 100%
    view.height = 100%

    let inputSection = View()
    inputSection.flexDirection = .row
    inputSection.height = 40~
    inputSection.width = 100%
    inputSection.set(padding: 5~, for: .left)
    inputSection.background.color = .textAreaBackgroundColor
    view.add(subview: inputSection)

    if let searchIconFilePath = Bundle.main.path(forAsset: "search", ofType: "png") {
      let searchIcon = ImageView()
      searchIcon.image = Image(filePath: searchIconFilePath)
      searchIcon.useImageAsMask = true
      searchIcon.tintColor = Appearance.current == .light ? .darkGray : .lightGray
      searchIcon.height = 22~
      searchIcon.aspectRatio = 1
      searchIcon.alignSelf = .center
      
      inputSection.add(subview: searchIcon)
    } else {
      print("Missing search icon file.")
    }
    
    textInputView.flex = 1
    textInputView.height = 40~
    textInputView.font = .ofType(.system, category: .veryLarge)
    textInputView.submitsOnAnyKeyPress = true
    textInputView.background.borderSize = 0
    
    // We want these keys to be passed to the searchResultsList, not the (keyView)
    // textInputView.
    textInputView.rejectedKeys = [.upArrow, .downArrow, .enter, .return]
    textInputView.onSubmit = { [weak self] term in
      self?.search(term: term)
    }
    
    inputSection.add(subview: textInputView)
    
    let horizontalDivider = View()
    horizontalDivider.width = 100%
    horizontalDivider.height = 0.5~
    horizontalDivider.background.color = .gray
    view.add(subview: horizontalDivider)
    
    add(component: searchResultsComponent)
    searchResultsComponent.view.width = 100%
    searchResultsComponent.view.flex = 1
    searchResultsComponent.datasource = self
    
    searchResultsComponent.listView?.isSelectable = true
    searchResultsComponent.listView?.selectionKeys = [.return, .enter]

    searchResultsComponent.listView?.onSelection = {
      [weak self] (indexPath, cell) in
      guard let `self` = self else { return }
      
      if let selected = self.currentResults[safe: indexPath.item] {
        if let callback = self.onSelection {
          callback(selected)
        } else {
          print("Error: no onSelection callback defined for QuickOpenComponent")
        }
        self.view.window.close()
      }
    }    
  }
  
  public func show(in parent: Window) {
    parentWindow = parent
    
    let window = Window(rootComponent: self,
                        frame: CGRect(x: 0, 
                                      y: 0, 
                                  width: 500, 
                                  height: 300),
                        hasTitleBar: false)
    Application.shared.add(window: window, asChildOf: parent)
    window.center()
    textInputView.makeKeyView()
  }
  
  public func search(term: String) {
    print("Search term: \(term)")
    guard let project = try? projectViewModel.project.value() else {
      print("Can't search in window that doesn't have a project.")
      return
    }
    
    let index = ProjectIndex.index(for: project)
    currentResults = index.findFiles(matching: term)
    searchResultsComponent.reload()

    let firstItemIndex = IndexPath(item: 0, section: 0)
    searchResultsComponent.listView?.focusedCellIndex = firstItemIndex
    searchResultsComponent.listView?.highlightedChildren = [firstItemIndex]
  }
}

extension QuickOpenComponent: ListViewDatasource {

  public func numberOfSections() -> Int {
    return 1
  }
  
  public func numberOfItemsInSection(section: Int) -> Int {
    return currentResults.count
  }
  
  public func cellForItem(at indexPath: IndexPath, withState state: ListItemState) -> ListViewCell {
    let cell = SearchResultCell()
    cell.set(padding: 5~, for: .left)
    cell.width = 100%
    let result = currentResults[indexPath.item]
    cell.titleLabel.text = result.lastPathComponent
    cell.subtitleLabel.text = result.deletingLastPathComponent().path
    cell.isHighlighted = state.isHighlighted
    cell.updateAppearance(style: Appearance.current)
    return cell
  }
  
  public func heightOfCell(at indexPath: IndexPath) -> CGFloat {
    return 45
  }
  
}

class SearchResultCell: ListViewCell {
  
  let titleLabel = Label()
  let subtitleLabel = Label()

  override func willAttachToWindow() {
    super.willAttachToWindow()
    flexDirection = .column
    
    set(padding: 5~, for: .left)
    set(padding: 5~, for: .right)
    
    add(subview: titleLabel)
    titleLabel.font = .ofType(.system, category: .mediumLarge)
    titleLabel.background.color = .clear
    titleLabel.verticalArrangement = .center
    titleLabel.width = 100%
    titleLabel.height = 25~
    
    add(subview: subtitleLabel)
    subtitleLabel.font = .ofType(.system, category: .smallMedium)
    subtitleLabel.background.color = .clear
    subtitleLabel.verticalArrangement = .center
    subtitleLabel.width = 100%
    subtitleLabel.height = 15~
    subtitleLabel.set(margin: 5~, for: .bottom)
  }
  
  override func updateAppearance(style: AppearanceStyle) {
    super.updateAppearance(style: style)
    
    background.color = isHighlighted ? .highlightedCellColor : .textAreaBackgroundColor
    titleLabel.textColor = isHighlighted ? .white : .textColor
    subtitleLabel.textColor = .lightGray
  }
}
