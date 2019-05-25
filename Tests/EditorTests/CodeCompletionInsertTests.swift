//
//  CodeCompletionInsertTests.swift
//  StrideTests
//
//  Created by pmacro  on 15/03/2019.
//

import XCTest
import SuitTestUtils
@testable import Suit
@testable import StrideLib

final class CodeCompletionInsertTests: XCTestCase {
  
  public func rangesOfMarkers(in string: String) -> [Range<String.Index>] {
    var searchRange = string.startIndex..<string.endIndex
    var results = [Range<String.Index>]()
    
    while let result = string.range(of: #"\$\{.*?\}"#,
                              options: .regularExpression,
                              range: searchRange) {
      results.append(result)
      if result.upperBound < searchRange.upperBound {
        searchRange = result.upperBound..<searchRange.upperBound
      } else {
        break
      }
    }
    
    return results
  }
  
  func testNone() {
    let text = "blah(foo: bar)"
    XCTAssert(rangesOfMarkers(in: text).count == 0)
  }
  
  func testSingle() {
    let text = ".nilVariable(variable: ${1:value})"
    let ranges = rangesOfMarkers(in: text)
    XCTAssert(ranges.count == 1)
    
    if let range = ranges.first {
      XCTAssert(text[range] == "${1:value}")
    }
  }
  
  func testMultiple() {
    let text = "call(me: ${1:value}, something: ${2:value})"
    let ranges = rangesOfMarkers(in: text)
    XCTAssert(ranges.count == 2)
    
    if let range = ranges[safe: 0] {
      XCTAssert(text[range] == "${1:value}")
    }
    
    if let range = ranges[safe: 1] {
      XCTAssert(text[range] == "${2:value}")
    }
  }
}
