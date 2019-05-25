//
//  NewProjectComponent.swift
//  StrideLib
//
//  Created by pmacro on 21/03/2019.
//

import Foundation
import Suit
import SPMClient
import RxSwift

public class NewProjectComponent: CompositeComponent {
  
  enum NewProjectType: Int {
    case library
    case executable
    case suit
    
    var isExecutable: Bool {
      return self == .executable || self == .suit
    }
  }
  
  var createCommandResponse: ResponseReader?
  let nameInputView = TextInputView()
  var projectType: NewProjectType = .library

  public override func viewDidLoad() {
    super.viewDidLoad()
    view.flexDirection = .column
    
    let titleLabel = Label(text: "Create New Project")
    titleLabel.font = .ofType(.system, category: .large, weight: .light)
    titleLabel.width = 100%
    titleLabel.height = 20~
    titleLabel.set(margin: 10~, for: .left)
    titleLabel.set(margin: 10~, for: .top)
    titleLabel.set(margin: 5~, for: .bottom)
    view.add(subview: titleLabel)

    addProjectNameUI()
    addProjectTypeUI()
    addButtons()
  }
  
  func addProjectNameUI() {
    let wrapper = generateRowWrapper()
    
    let nameLabel = Label(text: "Name")
    nameLabel.height = 20~
    nameLabel.flex = 1
    wrapper.add(subview: nameLabel)
    
    nameInputView.height = 30~
    nameInputView.width = 150~
    nameInputView.makeKeyView()
    wrapper.add(subview: nameInputView)
    view.add(subview: wrapper)
  }
  
  func addProjectTypeUI() {
    let wrapper = generateRowWrapper()

    let typeLabel = Label(text: "Type")
    typeLabel.height = 20~
    typeLabel.flex = 1
    typeLabel.background.color = .clear
    wrapper.add(subview: typeLabel)
    
    let projectTypeDropdown = Dropdown()
    projectTypeDropdown.items = ["Library", "Executable", "Suit App"]
    projectTypeDropdown.onSelect = { [weak self] index in
      self?.projectType = NewProjectType(rawValue: index) ?? .library
    }
    
    projectTypeDropdown.height = 20~
    projectTypeDropdown.width = 150~
    wrapper.add(subview: projectTypeDropdown)
    
    view.add(subview: wrapper)
  }
  
  func addButtons() {
    let wrapper = View()
    wrapper.width = 100%
    wrapper.flex = 1
    wrapper.flexDirection = .rowReverse
    wrapper.alignItems = .flexEnd
    
    let createButton = Button(ofType: .rounded)
    createButton.title = "Create"
    createButton.width = 80~
    createButton.height = 21~
    createButton.set(margin: 5~, for: .right)
    createButton.set(margin: 5~, for: .bottom)
    createButton.onPress = { [weak self] in
      self?.createProject()
    }
    
    wrapper.add(subview: createButton)
    
    let cancelButton = Button(ofType: .rounded)
    cancelButton.title = "Cancel"
    cancelButton.width = 80~
    cancelButton.height = 21~
    cancelButton.set(margin: 5~, for: .right)
    cancelButton.set(margin: 5~, for: .bottom)
    cancelButton.onPress = { [weak self] in
      self?.view.window.close()
    }
    
    wrapper.add(subview: cancelButton)
    view.add(subview: wrapper)
  }
  
  func generateRowWrapper() -> View {
    let wrapper = View()
    wrapper.width = 100%
    wrapper.set(padding: 10~, for: .left)
    wrapper.set(padding: 10~, for: .right)
    wrapper.set(padding: 10~, for: .top)
    wrapper.height = 30~
    wrapper.flexDirection = .row
    return wrapper
  }
  
  func createProject() {
    let projectName = nameInputView.state.text.buffer
    
    guard projectName.trimmingCharacters(in: .whitespacesAndNewlines).count > 0 else {
      view.window.displayMessage(withTitle: "Error",
                                 content: "Please provide a project name.")
      return
    }
    
    FileBrowser.selectDirectory(onSelection: { [weak self] urls in
      if let directory = urls.first {
        self?.createProject(in: directory, withName: projectName)
      }
    }, onCancel: nil)
  }
  
  func createProject(in directory: URL, withName name: String) {
    print("Creating project in: \(directory)")
    
    let projectDir = directory.appendingPathComponent(name)
    
    do {
      try FileManager.default.createDirectory(at: projectDir,
                                              withIntermediateDirectories: true,
                                              attributes: nil)
      
      guard let languageConfig = LanguageConfiguration.for(languageNamed: "Swift"),
            let swiftHome = languageConfig.compilerHomeDirectory,
        let client = SPMClient(projectDirectory: projectDir,
                               swiftHomePath: swiftHome,
                               ensuringProjectExists: false)
      else {
        throw ProjectError.invalidConfiguration(message: "No language found")
      }
      
      switch projectType {
        case .library:
          createCommandResponse = client.createPackage(ofType: .library, name: name)
        case .executable, .suit:
          createCommandResponse = client.createPackage(ofType: .executable, name: name)
      }
      
      createCommandResponse?.onComplete = { [weak self] result in
        guard let `self` = self else { return }
        
        if self.projectType == .suit {
          do {
            try SuitAppPackageTemplate.create(in: projectDir, withName: name)
          } catch let error {
            self.view.window.displayMessage(withTitle: "Unexpected Error",
                                            content: error.localizedDescription)
          }
        }
        
        let newProject = Project(name: name,
                                 url: projectDir.appendingPathComponent("Package.swift"),
                                 primaryLanguage: "Swift",
                                 hasExecutable: self.projectType.isExecutable)
        
        var recentProjects = RecentProjects.load()
        recentProjects.add(project: newProject)

        self.view.window.close()
      }
      
    } catch let error {
      view.window.displayMessage(withTitle: "Unexpected Error",
                                 content: error.localizedDescription)
    }
  }
}
