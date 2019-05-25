//
//  OutputComponent.swift
//  StrideLib
//
//  Created by pmacro  on 14/03/2019.
//

import Foundation
import Suit

public class OutputComponent: CompositeComponent {

  let outputDivider = DividerComponent(orientation: .horizontal)
  let buildOutputComponent = BuildOutputComponent()
  let runOutputComponent = BuildOutputComponent()
  
  let runOutputButton = Button()
  let buildOutputButton = Button()
  let showHideButton = Button()

  private var isHidden = false

  public override func viewDidLoad() {
    super.viewDidLoad()
    view.flexDirection = .column

    add(component: outputDivider)
    outputDivider.view.height = 25~

    // Handle build output.
    //
    if let imagePath = Bundle.main.path(forAsset: "build_output",
                                        ofType: "png") {
      let image = Image(filePath: imagePath)
      buildOutputButton.set(image: image,
                            forState: .unfocused)
      buildOutputButton.set(image: image,
                            forState: .focused)
    }
    
    if let imagePath = Bundle.main.path(forAsset: "build_output_pressed",
                                        ofType: "png") {
      let image = Image(filePath: imagePath)
      buildOutputButton.set(image: image,
                            forState: .pressed)
    }
    
    buildOutputButton.width = 15~
    buildOutputButton.height = 15~

    buildOutputButton.onPress = { [weak self] in
      self?.showBuildOutput()
    }

    // Handle run output.
    //
    if let imagePath = Bundle.main.path(forAsset: "run_output",
                                        ofType: "png") {
      let image = Image(filePath: imagePath)
      runOutputButton.set(image: image,
                            forState: .unfocused)
      runOutputButton.set(image: image,
                            forState: .focused)
    }
    
    if let imagePath = Bundle.main.path(forAsset: "run_output_pressed",
                                        ofType: "png") {
      let image = Image(filePath: imagePath)
      runOutputButton.set(image: image,
                          forState: .pressed)
    }
  
    runOutputButton.width = 15~
    runOutputButton.height = 15~
    runOutputButton.set(margin: 5~, for: .left)
    runOutputComponent.startMessage = "Running...\n"

    runOutputButton.onPress = { [weak self] in
      self?.showRunOutput()
    }

    outputDivider.view.set(padding: 10~, for: .left)
    outputDivider.view.alignItems = .center
    outputDivider.view.flexDirection = .row
    
    let buttonGroup = ButtonGroup()
    buttonGroup.flex = 1
    buttonGroup.height = 100%
    buttonGroup.flexDirection = .row
    buttonGroup.alignItems = .center
    buttonGroup.add(button: buildOutputButton)
    buttonGroup.add(button: runOutputButton)
    
    outputDivider.view.add(subview: buttonGroup)
    
    func setShowHideButtonImage(named: String) {
      if let imagePath = Bundle.main.path(forAsset: named,
                                          ofType: "png") {
        let image = Image(filePath: imagePath)
        showHideButton.set(image: image, forState: .unfocused)
        showHideButton.set(image: image, forState: .focused)
        showHideButton.set(image: image, forState: .pressed)
      }
    }
    
    setShowHideButtonImage(named: "shown_bottom")
    showHideButton.width = 12~
    showHideButton.height = 12~
    showHideButton.set(margin: 10~, for: .right)
    showHideButton.onPress = {
      self.view.animate(duration: 0.25,
                        changes: {
        if self.isHidden {
          self.view.height = 100~
        } else {
          self.view.height = self.outputDivider.view.frame.height~
        }
        self.isHidden.toggle()
                          
        setShowHideButtonImage(named: self.isHidden ? "hidden_bottom"
                                                    : "shown_bottom")
      })
    }
    outputDivider.view.add(subview: showHideButton)
    
    view.height = outputDivider.view.height
    view.width = 100%

    outputDivider.onGrab = { [weak self] value in
      guard let `self` = self else { return }
      
      let height = self.view.frame.height
      self.view.height = max(self.outputDivider.view.frame.height,
                             (height - value))~
    }
    
    // The default state on load.
    buildOutputButton.press()
    isHidden = true
  }

  private func showBuildOutput() {
    if isHidden {
      showHideButton.press()
    }
    removeAllExcept(component: outputDivider)
    add(component: buildOutputComponent)
    buildOutputComponent.view.width = 100%
    buildOutputComponent.view.flex = 1
    view.window.rootView.invalidateLayout()
    view.forceRedraw()
  }

  private func showRunOutput() {
    if isHidden {
      showHideButton.press()
    }

    removeAllExcept(component: outputDivider)
    add(component: runOutputComponent)
    runOutputComponent.view.width = 100%
    runOutputComponent.view.flex = 1
    view.forceRedraw()
  }

  public override func updateAppearance(style: AppearanceStyle) {
    super.updateAppearance(style: style)
    view.background.color = .textAreaBackgroundColor
    outputDivider.view.background.color = .backgroundColor
  }
}
