//
//  EditorView.swift
//  Editor
//
//  Created by pmacro on 23/06/2018.
//

import Foundation
import Suit
import LanguageClient

public protocol EditorViewDelegate {
  func didPress(triggerKey: KeyEvent)
  func didInsert(text: String, at: String.Index)
  func willDelete(characterCount: Int, at: String.Index)
  func didDelete(characterCount: Int, at: String.Index)
  func requestGoToDefinition()
}

public class EditorView: TextAreaView {
  
  public var delegate: EditorViewDelegate?
  var diagnostics: [Int: [Diagnostic]] = [:]
  var pressedModifierKeys: Set<KeyModifiers> = []
  
  #if os(macOS) || os(iOS)
  let resolveKey: KeyModifiers = .command
  #else
  let resolveKey: KeyModifiers = .control
  #endif
  
  var inResolveMode = false
  
  public required init() {
    super.init()
    showGutter = true
    readOnly = false
    
    renderer.indicatesCurrentLine = true
    renderer.add(decorator: { [weak self] lineNumber, lineBox, graphics in
      self?.renderDiagnostics(on: lineNumber, in: lineBox, using: graphics)
    })
    
    renderer.gutterWidth += 10
    
    renderer.add(gutterDecorator: { [weak self] lineNumber, lineBox, graphics in
      
      guard let `self` = self,
            let diagnostics = self.diagnostics[lineNumber - 1] else { return }
      
      let diagnostic = diagnostics.mostSevere
      
      graphics.set(color: self.colorForSeverity(diagnostic?.severity ?? .error))

      let errorMarkerRect = CGRect(x: lineBox.origin.x + 5,
                                   y: lineBox.origin.y + ((lineBox.height - 8) / 2),
                                   width: 8,
                                   height: 8)
      
      graphics.draw(roundedRectangle: errorMarkerRect, cornerRadius: 8)
      graphics.fill()
    })
  }
  
  func colorForSeverity(_ severity: DiagnosticSeverity) -> Color {
    switch severity {
    case .error:
      return .red
    case .warning:
      return .orange
    case .hint:
      return .green
    case .information:
      return .blue
    }
  }

  func renderDiagnostics(on line: Int, in rect: CGRect, using graphics: Graphics) {
    
    if let relevantDiagnostics = diagnostics[line - 1] {
      for diagnostic in relevantDiagnostics {
        
        var line = rect
        line.size.height = 0.5
        
        // Attempt to get the exact part of the line in error.  The fallback is to mark the
        // while line in error.
        if let offset = convertToOffset(line: diagnostic.range.start.line + 1,
                                        column: diagnostic.range.start.character) {
          line.origin = location(forIndex: offset)
          
          if diagnostic.range.end == diagnostic.range.start {
            line.size.width = 7.5
          } else if let endOffset = convertToOffset(line: diagnostic.range.end.line + 1,
                                                    column: diagnostic.range.end.character) {
            line.size.width = location(forIndex: endOffset).x - line.origin.x
          }
          
          // Fallback to roughly the width of one character
          line.size.width = max(7.5, line.size.width)
        }
        
        graphics.set(color: colorForSeverity(diagnostic.severity ?? .error))
        line = line.offsetBy(dx: 0, dy: rect.height - 2)
        graphics.draw(rectangle: line)
        graphics.fill()
      }
    }
  }
    
  public func convertToOffset(line: Int, column: Int) -> String.Index? {
    guard let lineRange = state.text.rangeOfLine(line) else { return nil }
    
    if column > state.text.distance(from: lineRange.lowerBound, to: lineRange.upperBound) {
      return nil
    }
    
    return state.text.index(lineRange.lowerBound, offsetBy: column)
  }
  
  public override func didResignAsKeyView() {
    super.didResignAsKeyView()
    pressedModifierKeys = []
  }
  
  public override func onPointerEvent(_ pointerEvent: PointerEvent) -> Bool {
    switch pointerEvent.type {
      case .click:
        if pressedModifierKeys == [resolveKey] {
          print("Requesting definition...")
          delegate?.requestGoToDefinition()
        }
        else {
          let localPoint = windowCoordinatesInViewSpace(from: pointerEvent.location)
          
          if localPoint.x < frame.origin.x + renderer.gutterWidth,
          let lineInfo = lineRectNearest(point: localPoint),
          let relevantDiagnostics = diagnostics[lineInfo.0] {

          let lineRect = lineInfo.1
          let origin = self.coordinatesInWindowSpace(from: lineRect.origin)

          DiagnosticPopoverComponent(message: relevantDiagnostics.first?.message ?? "Unknown")
            .show(in: window, 
                  withDimensions: CGRect(x: origin.x, 
                                         y: origin.y,
                                         width: 300,
                                         height: 50))
          }
        }
      default:
        break
    }
    
    return super.onPointerEvent(pointerEvent)
  }
  
  public override func onKeyEvent(_ keyEvent: KeyEvent) -> Bool {
    switch keyEvent.strokeType {
    case .down where keyEvent.modifiers?.isEmpty == false:
      keyEvent.modifiers?.forEach {
        pressedModifierKeys.insert($0)
      }
    default:
      pressedModifierKeys = []
    }

    if pressedModifierKeys == [resolveKey],
      keyEvent.characters == nil || keyEvent.characters == "" {
      inResolveMode = true
      Cursor.shared.push(type: .arrow)
    }
    else if inResolveMode {
      inResolveMode = false
      Cursor.shared.pop()
    }
    
    return super.onKeyEvent(keyEvent)
  }
  
  public override func didPress(triggerKey: KeyEvent) {
    super.didPress(triggerKey: triggerKey)
    delegate?.didPress(triggerKey: triggerKey)
  }

  open override func didInsert(text: String, at index: String.Index) {
    super.didInsert(text: text, at: index)
    delegate?.didInsert(text: text, at: index)
  }

  override open func willRemove(range: Range<String.Index>) {
    super.willRemove(range: range)
    let safeRange = range.clamped(to: state.text.startIndex..<state.text.endIndex)
    let count = state.text.distance(from: safeRange.lowerBound, to: safeRange.upperBound)
    delegate?.willDelete(characterCount: count, at: safeRange.lowerBound)
  }

  public override func didRemove(range: Range<String.Index>) {
    super.didRemove(range: range)
    let safeRange = range.clamped(to: state.text.startIndex..<state.text.endIndex)
    let count = state.text.distance(from: safeRange.lowerBound, to: safeRange.upperBound)
    delegate?.didDelete(characterCount: count, at: safeRange.lowerBound)
  }
}

extension Component {
  func show(in parent: Window, withDimensions rect: CGRect) {
    let window = Window(rootComponent: self,  
                        frame: rect,
                        hasTitleBar: false)

    Application.shared.add(window: window,
                           asChildOf: parent)
    window.applyPlatformDiagnosticsStyling()
  }
}

public class DiagnosticPopoverComponent: Component {

  let message: String

  public init(message: String) {
    self.message = message
  }

  override public func viewDidLoad() {
    super.viewDidLoad()
    view.width = 100%
    view.height = 100%
    view.background.color = .backgroundColor

    view.set(padding: 10~, for: .left)
    view.set(padding: 10~, for: .right)
    view.set(padding: 10~, for: .top)

    let label = Label(text: message)
    label.height = 100%
    label.width = 100%
    view.add(subview: label)
  }
}

extension Window {
  func applyPlatformDiagnosticsStyling() {
    #if os (macOS)
    macWindow.backgroundColor = .clear
    macWindow.isOpaque = true
    let nsWindowContentView = macWindow.contentView
    nsWindowContentView?.wantsLayer = true
    nsWindowContentView?.layer?.cornerRadius = 5
    nsWindowContentView?.layer?.masksToBounds = true
    
    // This is a hack that avoids a display issue where the background
    // outside the bounds of the rounded window corners is still visible.
    let newSize = CGSize(width: contentView.frame.size.width + 0.1,
                         height: contentView.frame.size.height + 0.1)
    
    resize(to: newSize)
    #endif
  }
}

