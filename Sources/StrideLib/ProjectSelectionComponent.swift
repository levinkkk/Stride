//
//  ProjectSelectionComponent.swift
//  StrideLib
//
//  Created by pmacro on 03/03/2019.
//

import Foundation
import Suit

public class ProjectSelectionComponent: CompositeComponent {
  
  var recentProjectsListComponent: RecentProjectListComponent!
  var recentProjectsLabelBackground: View?
  
  let newProjectButton = Button(ofType: .default)
  let importProjectButton = Button(ofType: .default)

  public override func viewDidLoad() {
    super.viewDidLoad()
    setupMenu()    
    
    view.flexDirection = .row
    view.set(padding: 10~, for: .all)
    
    let columnView = View()
    view.add(subview: columnView)
    columnView.flexDirection = .row

    configureNewProjectOptions(columnView)
    configureRecentProjectsView(columnView)

    // TODO Suit needs to support telling us when a component is fully loaded and visible.
    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1) {
      if FirstRun.isFirstRun() {
        PreferencesComponent.launch()
        FirstRun.markAsRun()
      }
    }
  }
  
  func setupMenu() {
    let menu = Menu()
    let applicationMenuItem = MenuItem(title: "Application")
    applicationMenuItem.add(subItem: MenuItem(title: "Preferences...",
                                              keyEquivalent: ",") {
                                                PreferencesComponent.launch()
    })
    
    applicationMenuItem.add(subItem: MenuItem(title: "Quit", keyEquivalent: "q", action: {
      Application.shared.terminate()
    }))

    menu.add(item: applicationMenuItem)
    view.window.menu = menu
  }
  
  public override func updateAppearance(style: AppearanceStyle) {
    view.background.color = .backgroundColor
    recentProjectsLabelBackground?.background.color = .backgroundColor

    // On Linux don't try to use a unified titlebar as the button tinting isn't quite
    // all there to support varying background colors.
    #if os(macOS)
    view.window.titleBarHeight = 22.5
    view.window.titleBar?.background.color = .backgroundColor
    #endif
    
    recentProjectsListComponent.view
      .superview?.background
      .color = style == .light ? .lightTextAreaBackgroundColor
                               : .darkTextAreaBackgroundColor
    
    recentProjectsListComponent.view
      .superview?.background.color = .textAreaBackgroundColor
    
    newProjectButton.set(foregroundColor: .textColor, forState: .unfocused)
    importProjectButton.set(foregroundColor: .textColor, forState: .unfocused)

    switch style {
    case .light:
      importProjectButton.set(foregroundColor: .darkerGray, forState: .pressed)
      newProjectButton.set(foregroundColor: .darkerGray, forState: .pressed)
    case .dark:
      importProjectButton.set(foregroundColor: .lighterGray, forState: .pressed)
      newProjectButton.set(foregroundColor: .lighterGray, forState: .pressed)
    }
  }
  
  func configureRecentProjectsView(_ parent: View) {
    let recentProjectsView = View()
    
    recentProjectsView.flexDirection = .column
    recentProjectsView.height = 100%
    recentProjectsView.width = 60%
    parent.add(subview: recentProjectsView)
    
    let titleLabel = Label(text: "Recent Projects")
    titleLabel.set(margin: 5~, for: .left)
    titleLabel.font = Font.ofType(.system, category: .mediumLarge, weight: .thin)
    titleLabel.height = 30~
    titleLabel.verticalArrangement = .center
    
    titleLabel.background.color = .clear
    
    let titleLabelWrapper = View()
    titleLabelWrapper.height = 30~
    
    titleLabelWrapper.background.color = .clear
    
    titleLabelWrapper.add(subview: titleLabel)
    recentProjectsLabelBackground = titleLabelWrapper
    
    recentProjectsView.add(subview: titleLabelWrapper)
    
    recentProjectsListComponent = RecentProjectListComponent()
    recentProjectsListComponent.listView?.highlightingBehaviour = .single
    configure(child: recentProjectsListComponent)
    
    recentProjectsListComponent.view.flex = 1
    recentProjectsView.add(subview: recentProjectsListComponent.view)
    recentProjectsListComponent.reload()
    
    recentProjectsListComponent.listView?.isSelectable = true
    recentProjectsListComponent.listView?.onSelection = { [weak self] (indexPath, cell) in
      if let project = self?.recentProjectsListComponent.recentProjects[indexPath.item] {
        self?.open(projectUrl: project.url)
      }
    }
    
    recentProjectsListComponent.listView?.onHighlight = { (indexPath, cell) in
      guard let cell = cell as? ProjectCell else { return }
      cell.isHighlighted = true
      cell.updateAppearance(style: Appearance.current)
    }
    
    recentProjectsListComponent.listView?.onRemoveHighlight = { (indexPath, cell) in
      guard let cell = cell as? ProjectCell else { return }
      cell.isHighlighted = false
      cell.updateAppearance(style: Appearance.current)
    }
  }
  
  func open(projectUrl: URL) {
    let rootComponent = RootComponent(projectPath: projectUrl.path)
    let projectWindow = Window(rootComponent: rootComponent, frame: CGRect(x: 0,
                                                                           y: 0,
                                                                           width: 800,
                                                                           height: 600),
                               hasTitleBar: true)
    Application.shared.add(window: projectWindow)
    projectWindow.makeMain()
    projectWindow.center()
    view.window?.close()
  }
  
  func configureNewProjectOptions(_ parent: View) {
    let newProjectsView = View()
    newProjectsView.flexDirection = .column
    newProjectsView.height = 100%
    newProjectsView.width = 40%
    parent.add(subview: newProjectsView)
    
    if let bannerPath = Bundle.main.path(forAsset: "stride_banner", ofType: "png") {
      let bannerImage = Image(filePath: bannerPath)
      let imageView = ImageView()
      imageView.image = bannerImage
      imageView.height = 80~
      imageView.width = 95%      
      newProjectsView.add(subview: imageView)
    }
        
    newProjectButton.title = "Create New Project"
    newProjectButton.set(margin: 20~, for: .left)
    newProjectButton.set(margin: 10~, for: .top)
    newProjectButton.titleLabel.font = Font.ofType(.system, category: .mediumLarge, weight: .bold)
    
    newProjectButton.height = 30~
    newProjectButton.width = 95%
    newProjectButton.onPress = {
      let projectWindow = Window(rootComponent: NewProjectComponent(),
                                 frame: CGRect(x: 0, y: 0, width: 250, height: 300))
      projectWindow.titleBarHeight = 22
      projectWindow.center()
      Application.shared.add(window: projectWindow)
    }

    importProjectButton.title = "Import Project"
    importProjectButton.set(margin: 20~, for: .left)
    importProjectButton.set(margin: 5~, for: .top)
    importProjectButton.titleLabel.font = Font.ofType(.system, category: .mediumLarge, weight: .bold)
    
    importProjectButton.height = 30~
    importProjectButton.width = 95%
    importProjectButton.onPress = {
      FileBrowser.open(fileOfType: ["Package.swift"],
                       onSelection: { [weak self] urls in
        if let url = urls.first {
          self?.open(projectUrl: url)
        }
      })
    }
        
    newProjectsView.add(subview: newProjectButton)
    newProjectsView.add(subview: importProjectButton)
  }
}

class RecentProjectListComponent: ListComponent {

  let recentProjects: RecentProjects
  
  required override init() {
    self.recentProjects = RecentProjects.load()
    super.init()
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    if recentProjects.count > 0 {
      let firstItemIndex = IndexPath(item: 0, section: 0)
      listView?.focusedCellIndex = firstItemIndex
      listView?.highlightedChildren = [firstItemIndex]
    }
    listView?.selectionKeys = [.enter, .return]
  }
  
  public override func numberOfSections() -> Int {
    return 1
  }
  
  public override func numberOfItemsInSection(section: Int) -> Int {
    return recentProjects.count
  }
  
  public override func cellForItem(at indexPath: IndexPath,
                                   withState state: ListItemState) -> ListViewCell {
    let cell = ProjectCell()
    let project = recentProjects[indexPath.item]
    cell.titleLabel.text = project.name
    cell.subtitleLabel.text = project.url.path
    cell.width = 100%
    cell.height = 40~
    cell.updateAppearance(style: Appearance.current)
    return cell
  }
  
  public override func heightOfCell(at indexPath: IndexPath) -> CGFloat {
    return 40
  }
}

class ProjectCell: ListViewCell {
  
  let titleLabel = Label()
  let subtitleLabel = Label()
  
  override func willAttachToWindow() {
    super.willAttachToWindow()
    flexDirection = .column
        
    titleLabel.set(margin: 2~, for: .top)
    titleLabel.set(margin: 5~, for: .left)
    titleLabel.height = 50%
    titleLabel.width = 100%
    titleLabel.verticalArrangement = .top
    titleLabel.background.color = .clear
    titleLabel.font = Font.ofType(.system, category: .medium, weight: .bold)

    subtitleLabel.set(margin: 5~, for: .left)
    subtitleLabel.height = 50%
    subtitleLabel.flex = 1
    subtitleLabel.verticalArrangement = .center
    subtitleLabel.background.color = .clear
    subtitleLabel.font = Font.ofType(.system,
                                     category: .small,
                                     weight: .ultraLight)
    add(subview: titleLabel)
    add(subview: subtitleLabel)
  }
  
  override func updateAppearance(style: AppearanceStyle) {
    super.updateAppearance(style: style)

    switch style {
    case .light:
      if isHighlighted {
        background.color = .highlightedCellColor
        titleLabel.textColor = .lightTextColor
        subtitleLabel.textColor = .lightGray
      } else {
        background.color = .lightTextAreaBackgroundColor
        titleLabel.textColor = .darkTextColor
        subtitleLabel.textColor = .darkerGray
      }
    case .dark:
      if isHighlighted {
        background.color = .highlightedCellColor
        titleLabel.textColor = .lightTextColor
        subtitleLabel.textColor = .lightGray
      } else {
        background.color = .darkTextAreaBackgroundColor
        titleLabel.textColor = .lightTextColor
        subtitleLabel.textColor = .darkerGray
      }
    }
  }
}
