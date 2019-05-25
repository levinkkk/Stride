//
//  CodeCompletionTests.swift
//  EditorTests
//
//  Created by pmacro  on 28/02/2019.
//

import Foundation
import XCTest
import SuitTestUtils
import LanguageClient
@testable import Suit
@testable import StrideLib

final class CodeCompletionTests: XCTestCase {

  let backgroundQueue = DispatchQueue(label: "CompletionTestQueue")

  var editorComponent: EditorComponent!
  var editorView: EditorView!
  var sampleCode: SampleCode!
  var languageClient: LanguageClient!
  
  func createEditorView() -> EditorView {
    return createView(ofType: EditorView.self)
  }
  
  override func setUp() {
    createApplication(with: window)
    
    guard let sampleCode = try? createSampleCodeDirectory(withFilenames: ["main.swift"]) else {
      XCTFail("Unable to create SampleCode")
      return
    }
    
    self.sampleCode = sampleCode
    let connectionExpectation = XCTestExpectation(description: "Language server connection expectation.")
    
    languageClient = LanguageClient()
    let config = LanguageConfiguration.loadAll().first!
    languageClient.startServer(atPath: config.languageServerExecutable!.path,
                               sourcePath: sampleCode.packageRoot.path)
      .ensure { connectionExpectation.fulfill() }
      .cauterize()
    
    wait(for: [connectionExpectation], timeout: 5)
    XCTAssert(languageClient.capabilities != nil, "Expected response from language server.")
    
    editorComponent = EditorComponent(with: languageClient)
    SuitTestUtils.load(component: editorComponent, in: window)
    XCTAssertNotNil(editorComponent.editorView, "EditorView was unexpectedly nil.")
    
    editorView = editorComponent.editorView
    _ = editorView.ensureGraphics()

  }
  
  override func tearDown() {
    window.childWindows.forEach { $0.close() }
  }
  
  ///
  /// Test that completion items are shown when completion is manually invoked at a valid location.
  ///
  func testSimpleCompletion() {
    let documentURL = sampleCode.sourcesRoot.appendingPathComponent("main.swift")
    editorComponent.open(documentURL)
    
    Thread.sleep(forTimeInterval: 1)
    
    XCTAssert(!isCompletionPopoverShown(),
              "Expected completion popover to be closed")
    
    editorView.position = editorView.state.text.count
    _ = editorView.onKeyEvent(TestKeyEvent(withCharacters: "\nlet string = \"\".",
                                           strokeType: .down,
                                           modifiers: nil,
                                           keyType: .other))

    editorView.position = editorView.state.text.count

    Thread.sleep(forTimeInterval: 1)
    
    editorComponent.didPress(triggerKey: editorComponent.manualCodeCompletionTriggerKey)
    XCTAssert(isCompletionPopoverShown(),
              "Expected completion popover to be visible")

    XCTAssert(hasSomeCompletionItems())
  }
  
  func testCompletionAfterEdit() {
    let documentURL = sampleCode.sourcesRoot.appendingPathComponent("main.swift")
    editorComponent.open(documentURL)

    Thread.sleep(forTimeInterval: 1)
    editorView.position = editorView.state.text.count

    _ = editorView.onKeyEvent(newLineKey)
    _ = editorView.onKeyEvent(newLineKey)

    editorView.position = editorView.position! - 1
    
    _ = editorView.onKeyEvent(characterKey("1"))
    _ = editorView.onKeyEvent(characterKey("2"))
    _ = editorView.onKeyEvent(characterKey("3"))
    _ = editorView.onKeyEvent(characterKey("."))
//    _ = editorView.onKeyEvent(newLineKey)

//    editorView.position = editorView.state.text.index(before: editorView.position!)
//    _ = editorView.onKeyEvent(editorComponent.manualCodeCompletionTriggerKey)

    Thread.sleep(forTimeInterval: 1)

    XCTAssert(isCompletionPopoverShown(),
              "Expected completion popover to be visible")

    XCTAssert(hasSomeCompletionItems(containing: "byteSwapped"), "Couldn't find completion item.  Source text: \(editorView.state.text.buffer)")
  }
  
  func testCompletionFiltering() {
    let documentURL = sampleCode.sourcesRoot.appendingPathComponent("main.swift")
    editorComponent.open(documentURL)
    
    Thread.sleep(forTimeInterval: 1)
    editorView.position = editorView.state.text.count

    _ = editorView.onKeyEvent(newLineKey)
    _ = editorView.onKeyEvent(characterKey("1"))
    _ = editorView.onKeyEvent(characterKey("."))
    
    XCTAssert(completionPopover()?.filterString == nil)
    
    _ = editorView.onKeyEvent(characterKey("b"))
    XCTAssert(completionPopover()?.filterString == "b")
    _ = editorView.onKeyEvent(characterKey("y"))
    XCTAssert(completionPopover()?.filterString == "by")
    _ = editorView.onKeyEvent(characterKey("t"))
    XCTAssert(completionPopover()?.filterString == "byt")

    _ = editorView.onKeyEvent(deleteKey)
    XCTAssert(completionPopover()?.filterString == "by")
    _ = editorView.onKeyEvent(deleteKey)
    XCTAssert(completionPopover()?.filterString == "b")
    _ = editorView.onKeyEvent(deleteKey)
    XCTAssert(completionPopover()?.filterString == nil)
  }
  
  func testStressEdits() {
    let documentURL = sampleCode.sourcesRoot.appendingPathComponent("main.swift")
    editorComponent.open(documentURL)
    
    Thread.sleep(forTimeInterval: 1)
    editorView.position = editorView.state.text.count

    for _ in 0..<5 {
      for _ in 0..<10 {
        _ = editorView.onKeyEvent(characterKey("."))
        print(editorView.state.text.buffer)
        _ = editorView.onKeyEvent(deleteKey)
        print(editorView.state.text.buffer)
      }
      
      for _ in 0..<100 {
        _ = editorView.onKeyEvent(deleteKey)
        print(editorView.state.text.buffer)
      }
      
      _ = editorView.onKeyEvent(characterKey("."))
      print(editorView.state.text.buffer)

      XCTAssert(languageClient.rpc.isRunning)
    }
  }

  func hasSomeCompletionItems(containing: String? = nil) -> Bool {
    let codeCompletionExpectation = XCTestExpectation(description: "Code completion expectation.")
    var wasFulfilled = false
    let popover = completionPopover()
    
    backgroundQueue.async {
      while popover?.state != .hasResults { Thread.sleep(forTimeInterval: 1) }
      
      if let completionItems = popover?.completionItems,
        !completionItems.isEmpty {
        
        // Return if the filter matches no results.
        if let filterText = containing {
          print("FILTER COUNT: \(completionItems.filter({$0.filterText?.contains(filterText) == true}).count)")

          if completionItems.first(where: { ($0.filterText ?? $0.label)
            .contains(filterText) }) == nil {
            return
          }
        }
        
        wasFulfilled = true
        codeCompletionExpectation.fulfill()
      }
    }
    
    wait(for: [codeCompletionExpectation], timeout: 5)
    return wasFulfilled
  }
  
  func isCompletionPopoverShown() -> Bool {
    let state = editorComponent.codeCompletionPopover?.state
    return state != nil && state != .closed
  }
  
  func completionPopupWindow() -> CompletionPopupWindow? {
    return Application.shared.mainWindow
      .childWindows.compactMap { $0 as? CompletionPopupWindow }
      .first
  }
  
  func completionPopover() -> CodeCompletionPopover? {
    return editorComponent.codeCompletionPopover
  }
  
}
