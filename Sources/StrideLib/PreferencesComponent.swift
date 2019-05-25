//
//  PreferencesComponent.swift
//  Stride
//
//  Created by pmacro  on 08/03/2019.
//

import Foundation
import Suit

public class PreferencesComponent: Component {
  
  var swiftConfiguration: LanguageConfiguration?
  let swiftHomePathLabel = Label()
  let languageServerPathLabel = Label()

  static func launch() {
    let window = Window(rootComponent: PreferencesComponent(),
                        frame: CGRect(x: 0,
                                      y: 0,
                                      width: 400,
                                      height: 400))
    Application.shared.add(window: window)
    window.center()    
  }
  
  public override func viewDidLoad() {
    super.viewDidLoad()
    
    swiftConfiguration = LanguageConfiguration.loadAll().first {
      $0.name.lowercased() == "swift"
    }
    
    if swiftConfiguration == nil {
      swiftConfiguration = LanguageConfiguration(name: "Swift")
    }
    
    addAppearanceSetting()
    addSwiftHomeSetting()
    addSwiftLSPSetting()
  }
  
  func addAppearanceSetting() {
    let contentView = generateRow()
    view.add(subview: contentView)
    
    let label = Label(text: "Application Appearance")
    label.background.color = .clear
    
    let dropdown = Dropdown()
    dropdown.items = ["System Default", "Light", "Dark"]
    dropdown.onSelect = { selectedIndex in
      switch selectedIndex {
      case 1:
        Appearance.current = .light
      case 2:
        Appearance.current = .dark
      default:
        Appearance.current = AppearancePreference.findSystemDefault()
                              ?? Appearance.current
      }
      
      let preference = AppearancePreference()
      preference.value = Appearance.current
      preference.save()
    }
    
    label.width = 200~
    dropdown.width = 150~
    label.height = 20~
    dropdown.height = 20~
    
    contentView.add(subview: label)
    contentView.add(subview: dropdown)
  }
  
  func addSwiftHomeSetting() {
    let contentView = generateRow()
    contentView.height = 20~
    view.add(subview: contentView)

    let label = Label(text: "Swift Toolchain")
    label.width = 200~
    label.height = 20~
    label.background.color = .clear
    contentView.add(subview: label)
    
    update(pathLabel: swiftHomePathLabel)
    swiftHomePathLabel.font = .ofType(.system,
                                      category: .verySmall,
                                      weight: .ultraLight)
    swiftHomePathLabel.width = 90%
    swiftHomePathLabel.set(margin: 5~, for: .top)
    swiftHomePathLabel.height = 20~
    swiftHomePathLabel.alignSelf = .center
    swiftHomePathLabel.background.color = .clear
    view.add(subview: swiftHomePathLabel)
    
    let fileBrowser = Button(ofType: .rounded)
    fileBrowser.width = 30~
    fileBrowser.height = 20~
    fileBrowser.title = "..."
    
    #if os(macOS)
    fileBrowser.onPress = {
      FileBrowser.open(fileOfType: [".xctoolchain"],
                       onSelection: { [weak self] (selectedUrls) in
        self?.swiftConfiguration?.compilerHomeDirectory = selectedUrls.first
        self?.swiftConfiguration?.save()
                        
        if let label = self?.swiftHomePathLabel {
          self?.update(pathLabel: label)
        }
      })
    }
    #else
    fileBrowser.onPress = {
      FileBrowser.open(fileOfType: ["/swift"],
                       onSelection: { [weak self] (selectedUrls) in
                        let swiftHome = selectedUrls.first?
                          .deletingLastPathComponent() // /swiftc
                          .deletingLastPathComponent() // /bin
                          .deletingLastPathComponent() // /usr
                        self?.swiftConfiguration?.compilerHomeDirectory = swiftHome
                        self?.swiftConfiguration?.save()
                        if let label = self?.swiftHomePathLabel {
                          self?.update(pathLabel: label)
                        }
        })
    }

    #endif
    contentView.add(subview: fileBrowser)
  }
  
  func update(pathLabel: Label) {
    let isSet = swiftConfiguration?.compilerHomeDirectory != nil
    pathLabel.text = swiftConfiguration?.compilerHomeDirectory?.path ?? "None Selected"
    pathLabel.textColor = isSet ? .textColor : .red
  }
  
  func addSwiftLSPSetting() {
    let contentView = generateRow()
    contentView.height = 20~
    view.add(subview: contentView)
    
    let label = Label(text: "Swift Language Server")
    label.width = 200~
    label.height = 20~
    label.background.color = .clear
    contentView.add(subview: label)
    
    update(lspLabel: languageServerPathLabel)
    languageServerPathLabel.font = .ofType(.system,
                                           category: .verySmall,
                                           weight: .ultraLight)
    languageServerPathLabel.width = 90%
    languageServerPathLabel.set(margin: 5~, for: .top)
    languageServerPathLabel.height = 40~
    languageServerPathLabel.alignSelf = .center
    languageServerPathLabel.background.color = .clear
    view.add(subview: languageServerPathLabel)
    
    let fileBrowser = Button(ofType: .rounded)
    fileBrowser.width = 30~
    fileBrowser.height = 20~
    fileBrowser.title = "..."
    
    fileBrowser.onPress = {
      FileBrowser.open(fileOfType: ["sourcekit-lsp"],
                       onSelection: { [weak self] (selectedUrls) in
                        self?.swiftConfiguration?.languageServerExecutable = selectedUrls.first
                        self?.swiftConfiguration?.save()
                        
                        if let label = self?.languageServerPathLabel {
                          self?.update(lspLabel: label)
                        }
      })
    }
    contentView.add(subview: fileBrowser)
  }

  func update(lspLabel: Label) {
    let isSet = swiftConfiguration?.languageServerExecutable != nil
    lspLabel.text = swiftConfiguration?.languageServerExecutable?.path
                  ?? "None Selected (Requires Restart)"
    lspLabel.textColor = isSet ? .textColor : .red
  }
  
  func generateRow() -> View {
    let contentView = View()
    contentView.height = 20~
    contentView.width = 90%
    contentView.set(margin: 10~, for: .top)
    contentView.alignSelf = .center
    contentView.flexDirection = .row
    return contentView
  }
  
  public override func updateAppearance(style: AppearanceStyle) {
    super.updateAppearance(style: style)
    
    view.background.color = style == .light ? .lighterGray
                                            : .darkerGray
    update(lspLabel: languageServerPathLabel)
    update(pathLabel: swiftHomePathLabel)
  }
}
