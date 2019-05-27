//
//  main.swift
//  Editor
//
//  Created by pmacro  on 15/06/2018.
//

import Foundation
import Suit
import StrideLib

let projectPath = CommandLine.arguments.count > 1 ? CommandLine.arguments.last : nil
let window: Window
Appearance.current = AppearancePreference.calculatedPreference

if let projectPath = projectPath {
  let rootComponent =  RootComponent(projectPath: projectPath) 
  window = Window(rootComponent: rootComponent,
                  frame: CGRect(x: 0,
                                y: 0,
                                width: 800,
                                height: 600),
                  hasTitleBar: true)
} else {
  window = Window(rootComponent: ProjectSelectionComponent(),
                          frame: CGRect(x: 0,
                                        y: 0,
                                        width: 650,
                                        height: 225),
                                        hasTitleBar: true)
  window.center()
}

let app = Application.create(with: window)
app.iconPath = Bundle.main.path(forAsset: "AppIcon", ofType: "png")
app.launch()
