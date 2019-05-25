//
//  RootComponent.swift
//  Editor
//
//  Created by pmacro on 15/06/2018.
//

import Foundation
import Suit
import SPMClient
import LanguageClient
import RxSwift

public struct ErrorMessage {
  let title: String
  let message: String
}

public class ProjectViewModel {
  
  /// The active project.
  var project = BehaviorSubject<Project?>(value: nil)
  
  /// The language client used by the opened project.
  var languageClient = LanguageClient()
  
  var errors = BehaviorSubject<ErrorMessage?>(value: nil)

  ///
  /// Loads the project from the provided URL and passes it to the sourceList component.
  ///
  func loadProject(from url: URL) {
    Project.from(url: url).done { [weak self] in
      ProjectIndex.index(for: $0).build()
      self?.project.on(.next($0))
      self?.configureLanguageClient(forProject: $0)
      
      var recentProjects = RecentProjects.load()
      recentProjects.add(project: $0)
      }.catch({ [weak self] error in
        self?.errors.on(.next(ErrorMessage(title: "Unable To Load Project",
                                          message: "The project at: \"\(url.path)\" could not be loaded.")))
      })
  }
  
  ///
  /// Try to connect to the language server.
  ///
  func configureLanguageClient(forProject project: Project) {
    
    if project is SwiftProject {
      let languageName = project.primaryLanguage
      if let config = LanguageConfiguration.for(languageNamed: languageName),
        let compilerDir = config.compilerHomeDirectory {
        languageClient.environmentVariables["SOURCEKIT_TOOLCHAIN_PATH"]  = compilerDir.path
        //languageClient.environmentVariables["SOURCEKIT_LOGGING"] = "3"
      } else {
        print("Warning: no Swift directory configured, code completion and other smart features may not work correctly.")
      }
    }
    
    languageClient.connect(withSourceRoot: project.url
                                            .deletingLastPathComponent()
                                            .path)
      .catch { error in
        self.errors.on(.next(ErrorMessage(title: "Unable to connect to Language Server",
                                          message: error.localizedDescription)))
    }
  }

}

///
/// The root component of the Stride editor.  This component is responsible for
/// creating and laying out the different components that make up the editor, such as
/// the project file list, the code editor etc.
///
public class RootComponent: CompositeComponent {
  /// Wraps the editorComponent and outputComponent so they can be vertically
  /// resized together.
  let containerComponent = CompositeComponent()
  
  /// The component that contains the tabbed code editors.
  let editorComponent = TabbedEditorComponent()
  
  /// Displays the project files.
  var sourceListComponent: SourceListComponent?
  
  /// Displays build, run output etc.
  let outputComponent = OutputComponent()
  
  /// The component that is shown in a popover when trying to find a file.
  var quickOpenComponent: QuickOpenComponent?
  
  /// The URL of the opened project.
  var projectURL: URL
  
  var viewModel = ProjectViewModel()
  
  ///
  /// Creates a new editor for the provided project path.
  ///
  /// - parameter projectPath: the path to a project file.
  public required init(projectPath: String) {
    // If the path is a file, use its directory.
    self.projectURL = URL(fileURLWithPath: projectPath)
    super.init()
  }
  
  ///
  /// Style the component according to the active AppearanceStyle.
  ///
  public override func updateAppearance(style: AppearanceStyle) {
    super.updateAppearance(style: style)
    editorComponent.view.background.color = .textAreaBackgroundColor
    view.background.color = .backgroundColor
  }
  
  ///
  /// Setup the component hierarchy once this component's view has loaded.
  ///
  public override func viewDidLoad() {
    super.viewDidLoad()
    
    // As this component is the root, we have some general application tasks.
    setupApplicationMenu()
    configureTitleBar()

    /*
     Next, we need to layout the child components.
     
     A rough guide to the component layout:
     
     |-------------------------------------|
     |               | ------------------  |
     |               ||                  | |
     |               ||                  | |
     |  sourceList   ||  editorComponent | |
     |   Component   ||                  | |
     |               ||                  | |
     |               ||------------------| |
     |               ||  outputComponent | |
     |               |-------------------- |
     |-------------------------------------|
    */
    
    // sourceListComponent and containerComponent should be vertically side-by-side.
    view.flexDirection = .row
    
    if let sourceList = createSourceListComponent() {
      add(component: sourceList)
      self.sourceListComponent = sourceList
    }
    
    // Load the project after the sourceList has been created since the sourceList needs to
    // be given the project.
    viewModel.loadProject(from: projectURL)

    // We want a vertical "grabber" that allows the user to resize the width of the editor.
    let sourceListDivider = DividerComponent(orientation: .vertical)
    sourceListDivider.onGrab = { [weak self] value in
      if let width = self?.sourceListComponent?.view.frame.width {
        self?.sourceListComponent?.view.width = (width + value)~
      }
    }
    
    add(component: sourceListDivider)
    add(component: containerComponent)
    
    // Create the editor and build output section.
    //
    containerComponent.view.width = 100%
    containerComponent.view.flex = 1
    containerComponent.view.flexDirection = .column
    containerComponent.add(component: editorComponent)
    editorComponent.view.flex = 1
    editorComponent.view.height = 100%
    containerComponent.add(component: outputComponent)
  }
  
  ///
  /// Setup the title bar, adding all relevant buttons etc.
  ///
  func configureTitleBar() {
    guard let titleBar = view.window.titleBar else { return }
    
    let buildAndRunButton = Button(ofType: .titleBarButton)

    if let imagePath = Bundle.main.path(forAsset: "arrow_right",
                                        ofType: "png") {
      let image = Image(filePath: imagePath)
      buildAndRunButton.set(image: image, forState: .unfocused)
      buildAndRunButton.set(image: image, forState: .pressed)
      buildAndRunButton.set(image: image, forState: .focused)

      #if os(Linux)
      buildAndRunButton.imageView.useImageAsMask = true
      buildAndRunButton.imageView.tintColor = .lightGray
     #endif

      buildAndRunButton.justifyContent = .center
      buildAndRunButton.alignContent = .center
      buildAndRunButton.imageView.width = 15~
    }
    
    buildAndRunButton.set(margin: 5~, for: .left)
    titleBar.additionalContentView.add(subview: buildAndRunButton)
    buildAndRunButton.onPress = { [weak self] in
      self?.buildAndRun()
    }
    
    let stopButton = Button(ofType: .titleBarButton)
    
    if let imagePath = Bundle.main.path(forAsset: "stop",
                                        ofType: "png") {
      let image = Image(filePath: imagePath)
      stopButton.set(image: image, forState: .unfocused)
      stopButton.set(image: image, forState: .pressed)
      stopButton.set(image: image, forState: .focused)
      
      #if os(Linux)
      stopButton.imageView.useImageAsMask = true
      stopButton.imageView.tintColor = .lightGray
      #endif
      stopButton.justifyContent = .center
      stopButton.alignContent = .center
      stopButton.imageView.width = 15~
    }

    stopButton.set(margin: 5~, for: .left)
    titleBar.additionalContentView.add(subview: stopButton)
    stopButton.onPress = { [weak self] in
      self?.stopProcess()
    }
  }
  
  ///
  /// Create the source list component, which displays the project source files.
  ///
  func createSourceListComponent() -> SourceListComponent? {
    let sourceListComponent = SourceListComponent(projectViewModel: viewModel)
    
    sourceListComponent.onSelectFile = { [weak self] url in
      guard let `self` = self, !url.hasDirectoryPath else {
        return
      }
        
      self.editorComponent.open(url: url,
                                using: self.viewModel.languageClient)
    }
      
    sourceListComponent.view.width = 200~
    sourceListComponent.view.height = 100%
    
    return sourceListComponent
  }
  
  ///
  /// Clean the project.
  ///
  func clean() {
    // TODO Swift specific.
    guard let swiftProject = try? viewModel.project.value() as? SwiftProject else {
        return
    }
    
    outputComponent.buildOutputComponent.startMessage = "Cleaning...\n"
    outputComponent.buildOutputButton.press()
    outputComponent.buildOutputComponent.responseReader = swiftProject.client?.clean()
  }
  
  ///
  /// Update the project.
  ///
  func update() {
    // TODO Swift specific.
    guard let swiftProject = try? viewModel.project.value() as? SwiftProject else {
      return
    }

    outputComponent.buildOutputComponent.startMessage = "Updating...\n"
    outputComponent.buildOutputButton.press()
    outputComponent.buildOutputComponent.responseReader = swiftProject.client?.update()
  }

  ///
  /// Reset the project.
  ///
  func reset() {
    // TODO Swift specific.
    guard let swiftProject = try? viewModel.project.value() as? SwiftProject else {
      return
    }

    outputComponent.buildOutputComponent.startMessage = "Resetting...\n"
    outputComponent.buildOutputButton.press()
    outputComponent.buildOutputComponent.responseReader = swiftProject.client?.reset()
  }

  ///
  /// Build and run the project.
  ///
  func buildAndRun() {
    stopProcess()

    // TODO Swift specific.
    guard let swiftProject = try? viewModel.project.value() as? SwiftProject else {
      return
    }

    outputComponent.buildOutputComponent.startMessage = "Building...\n"
    outputComponent.buildOutputButton.press()
    outputComponent.buildOutputComponent.responseReader = swiftProject.client?.build()
    
    guard swiftProject.hasExecutable == true else {
      return
    }
    
    outputComponent.buildOutputComponent.responseReader?.onComplete = { [weak self] endedWithError in
      guard let `self` = self else { return }
      
      if endedWithError {
        self.view.window.displayMessage(withTitle: "Build Failed",
                                        content: "Please check the build log for details.")
      } else {
        self.outputComponent.runOutputButton.press()
        self.outputComponent.runOutputComponent.responseReader = swiftProject.client?.run()
      }
    }
  }
  
  ///
  /// Stops any processes started by Stride.
  ///
  func stopProcess() {
    // TODO Swift specific.
    guard let swiftProject = try? viewModel.project.value() as? SwiftProject else {
      return
    }

    swiftProject.client?.terminateAll()
  }
}
