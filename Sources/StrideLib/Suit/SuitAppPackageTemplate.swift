//
//  SuitAppPackageTemplate.swift
//  StrideLib
//
//  Created by pmacro on 07/05/2019.
//

import Foundation

final class SuitAppPackageTemplate {
  
  static func create(in directory: URL,
                     withName projectName: String) throws {
    let packageFileContents = packageContents.replacingOccurrences(of: "$(APP_NAME)",
                                                               with: projectName)
    // Update the Package.swift file with our template.
    FileManager.default
      .createFile(atPath: directory.appendingPathComponent("Package.swift").path,
                  contents: packageFileContents.data(using: .utf8),
                  attributes: nil)
    
    // Create the Assets folder.
    try FileManager.default.createDirectory(at: directory.appendingPathComponent("Assets"),
                                             withIntermediateDirectories: true,
                                             attributes: nil)
    
    // Create the build script.
    //
    let buildFilePath = directory.appendingPathComponent("build.sh").path
    
    FileManager.default
      .createFile(atPath: buildFilePath,
                  contents: buildFileContents.data(using: .utf8),
                  attributes: nil)
    
    let libDir = directory.appendingPathComponent("Sources")
                          .appendingPathComponent(projectName + "Lib")

    #if os(macOS) || os(iOS)
    var attributes = try FileManager.default.attributesOfItem(atPath: buildFilePath)
    attributes[FileAttributeKey.posixPermissions] = 0o751
    try FileManager.default.setAttributes(attributes, ofItemAtPath: buildFilePath)
    #else
    chmod(buildFilePath, 0x751)
    #endif

    // Create the sources root for the AppName + "Lib" target.
    try? FileManager.default.createDirectory(at: libDir,
                                                 withIntermediateDirectories: true,
                                                 attributes: nil)

    // Create the sample component.
    FileManager.default.createFile(atPath: libDir.appendingPathComponent("MyComponent.swift").path,
                                     contents: componentContents.data(using: .utf8),
                                     attributes: nil)
      
    let mainDir = directory.appendingPathComponent("Sources")
        .appendingPathComponent(projectName)
      
    FileManager.default.createFile(atPath: mainDir.appendingPathComponent("main.swift").path,
                              contents: mainContents(projectName).data(using: .utf8),
                            attributes: nil)
  }
  
  static let packageContents =
    """
    // swift-tools-version:5.0
    // The swift-tools-version declares the minimum version of Swift required to build this package.

    import PackageDescription

    let package = Package(
    name: "$(APP_NAME)",
    platforms: [
    .macOS(.v10_13)
    ],
    products: [
    // Products define the executables and libraries produced by a package, and make them visible to other packages.

    .executable(
    name: "$(APP_NAME)",
    targets: ["$(APP_NAME)"]),
    .library(
    name: "$(APP_NAME)Lib",
    targets: ["$(APP_NAME)Lib"])
    ],
    dependencies: [
    // Dependencies declare other packages that this package depends on.
    // .package(url: /* package url */, from: "1.0.0"),
    .package(url: "https://github.com/pmacro/Suit", .branch("master"))
    ],
    targets: [
    // Targets are the basic building blocks of a package. A target can define a module or a test suite.
    // Targets can depend on other targets in this package, and on products in packages which this package depends on.
    .target(
    name: "$(APP_NAME)",
    dependencies: ["Suit", "$(APP_NAME)Lib"]),

    .target(
    name: "$(APP_NAME)Lib",
    dependencies: ["Suit"])

    ]
    )
    """
  
  static let buildFileContents =
    """
    #!/bin/bash

    if [[ "$OSTYPE" == "linux-gnu" ]]; then
      echo $(swift --version)
      YOGA_LIB_PATH=$PWD/$(find . -wholename '*/Sources/Yoga/linux*' | head -n 1)
      echo "Using Yoga in: $YOGA_LIB_PATH"

      CLIPBOARD_LIB_PATH=$PWD/$(find . -wholename '*/Sources/CClipboard' | head -n 1)
      echo "Using Clipboard in: $CLIPBOARD_LIB_PATH"

      swift build -Xlinker -lxcb-util -Xlinker -lxcb -Xlinker -lstdc++ -Xswiftc -L$YOGA_LIB_PATH -Xswiftc -L$CLIPBOARD_LIB_PATH
      EXIT_STATUS=$?
    elif [[ "$OSTYPE" == "darwin"* ]]; then
      export PATH=/Library/Developer/Toolchains/swift-latest.xctoolchain/usr/bin:$PATH
      echo $(swift --version)
      YOGA_LIB_PATH=$(find . -wholename '*/Sources/Yoga/darwin*' | head -n 1)
      echo "Using Yoga in: $YOGA_LIB_PATH"
      swift build -Xswiftc "-target" -Xswiftc "x86_64-apple-macos10.13" -Xlinker -lc++ -Xswiftc -L$YOGA_LIB_PATH
      EXIT_STATUS=$?
    else
      echo "Error: unsupported platform."
    fi

    OUTPUT_DIR=$(swift build --show-bin-path)

    echo "Installing assets into $OUTPUT_DIR"
    cp -R Assets $OUTPUT_DIR

    exit $EXIT_STATUS
    """
  
  static let componentContents =
    """
    import Foundation
    import Suit
    
    public class MyComponent: Component {
    
      override public func viewDidLoad() {
        super.viewDidLoad()
        view.background.color = .white

        let helloLabel = Label(text: "Hello, Suit 🕺🏻!")
        helloLabel.width = 100%
        helloLabel.height = 100%
        helloLabel.textColor = .textColor
        helloLabel.font = .ofType(.system, category: .verySmall)

        helloLabel.horizontalArrangement = .center
        helloLabel.verticalArrangement = .center

        helloLabel.animate(duration: 2, easing: .sineEaseIn, changes: {
          helloLabel.font.size = 90
        })

        view.add(subview: helloLabel)
      }
    }
    """
  
  static let mainContents = { (projectName: String) -> String in
    """
    import Foundation
    import Suit
    import \(projectName)Lib
    
    let window = Window(rootComponent: MyComponent(),
                        frame: CGRect(x: 0,
                                      y: 0,
                                      width: 800,
                                      height: 600),
                        hasTitleBar: true)
    
    let app = Application.create(with: window)
    app.launch()
    """
  }
}
