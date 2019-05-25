//
//  HighlightingConfiguration.swift
//  StrideLib
//
//  Created by pmacro  on 07/03/2019.
//

import Foundation
import Highlighter
import Suit

struct HighlightingConfiguration: Codable {
  
  public static var `default`: HighlightingConfiguration {
    switch Appearance.current {
      case .light:
        return HighlightingConfiguration.defaultLight
      case .dark:
        return HighlightingConfiguration.defaultDark
    }
  }
  
  public static let defaultLight: HighlightingConfiguration = {
    return HighlightingConfiguration(name: "Default Light",
                                     className: 0x3F6E75,
                                     functionName: 0x000000,
                                     importName: 0x000000,
                                     identifier: 0x000000,
                                     integer: 0x000000,
                                     float: 0x000000,
                                     keyword: 0xA91FA7,
                                     string: 0xFF0000,
                                     atSign: 0x000000,
                                     selfColour: 0x000000,
                                     any: 0x000000,
                                     stringInterpolationAnchor: 0x000000,
                                     lineComment: 0x1E7503,
                                     blockComment: 0x1E7503,
                                     operatorsAndPunctuation: 0x000000,
                                     unknown: 0x000000)
  }()
  
  public static let defaultDark: HighlightingConfiguration = {
    return HighlightingConfiguration(name: "Default Dark",
                                     className: 0x5F8E95,
                                     functionName: 0xFFFFFF,
                                     importName: 0xFFFFFF,
                                     identifier: 0xFFFFFF,
                                     integer: 0xFFFFFF,
                                     float: 0xFFFFFF,
                                     keyword: 0xC93FC7,
                                     string: 0xFF2222,
                                     atSign: 0xFFFFFF,
                                     selfColour: 0xFFFFFF,
                                     any: 0xFFFFFF,
                                     stringInterpolationAnchor: 0xFFFFFF,
                                     lineComment: 0x1E7503,
                                     blockComment: 0x1E7503,
                                     operatorsAndPunctuation: 0xFFFFFF,
                                     unknown: 0xFFFFFF)
  }()

  
  public let name: String
  
  public var className: Colour?
  public var functionName: Colour?
  public var importName: Colour?
  public var identifier: Colour?
  public var integer: Colour?
  public var float: Colour?
  public var keyword: Colour?
  public var string: Colour?
  public var atSign: Colour?
  public var selfColour: Colour?
  public var `any`: Colour?
  public var stringInterpolationAnchor: Colour?
  public var lineComment: Colour?
  public var blockComment: Colour?
  public var operatorsAndPunctuation: Colour?
  public var unknown: Colour?
  
  public func colour(for token: Token) -> Colour {
    let colour: Color
    let defaultColour = Colour.darkTextColor
    
    switch token.tokenType {
      case .className:
        colour = self.className ?? defaultColour
      case .functionName:
        colour = self.functionName ?? defaultColour
      case .importName:
      colour = self.importName ?? defaultColour
      case .identifier:
        colour = self.identifier ?? defaultColour
      case .integer:
        colour = self.integer ?? defaultColour
      case .float:
        colour = float ?? defaultColour
      case .keyword:
        colour = keyword ?? defaultColour
      case .string:
        colour = string ?? defaultColour
      case .atSign:
        colour = atSign ?? defaultColour
      case .`self`:
        colour = selfColour ?? defaultColour
      case .any:
        colour = any ?? defaultColour
      case .stringInterpolationAnchor:
        colour = stringInterpolationAnchor ?? defaultColour
      case .lineComment:
        colour = lineComment ?? defaultColour
      case .blockComment:
        colour = blockComment ?? defaultColour
      case .operatorsAndPunctuation:
        colour = operatorsAndPunctuation ?? defaultColour
      case .unknown, .newLine:
        colour = unknown ?? defaultColour
    }

    return colour
  }
}
