import XCTest
import SuitTestUtils
import LanguageClient
@testable import Suit
@testable import StrideLib

final class EditorTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
//        XCTAssertEqual(Editor().text, "Hello, World!")
    }
  
  func testEditorPerformance() {
    let editorComponent = EditorComponent(with: LanguageClient())
    let root = window.rootComponent as! CompositeComponent
    
    root.add(component: editorComponent)
    
    populate(textArea: editorComponent.editorView,
             withNumberOfLines: 30000,
             lineLength: 120)
    
    measure {
      editorComponent.editorView.insert(text: "Hello",
                                        at: editorComponent.editorView.state.text.startIndex)
    }
  }

    static var allTests = [
        ("testExample", testExample),
    ]
}
