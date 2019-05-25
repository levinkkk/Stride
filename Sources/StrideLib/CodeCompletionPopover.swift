//
//  CodeCompletionPopover.swift
//  Editor
//
//  Created by pmacro on 23/06/2018.
//

import Foundation
import Suit
import LanguageClient
import PromiseKit

///
/// A component that displays a list of code completion items.
///
public class CodeCompletionPopover: ListComponent {
  weak var editorView: EditorView?

  var completionItems: [CompletionItem]?
  var filteredCompletionItems: [CompletionItem]?

  let languageClient: LanguageClient
  let uri: URL
  var initialDocumentPosition = 0

  /// The possible states the CodeCompletionPopover can be in.
  enum State {
    case created
    case open
    case closed
    case pendingResults
    case hasResults
  }

  var state: State = .created

  var triggerCharacterString: String {
    return editorView?.triggerKeyEvents.compactMap { $0.characters }.joined() ?? ""
  }

  var filterString: String? {
    if let editorView = editorView,
      let currentPosition = editorView.positionIndex,
      let triggerPosition = findTriggerPosition(from: currentPosition),
      currentPosition > triggerPosition {
      let range = (triggerPosition..<currentPosition)
        .clamped(to: editorView.state.text.range)
      let string = editorView.state.text.buffer[range]

      if !string.isEmpty {
        return string.trimmingCharacters(in: CharacterSet(charactersIn: triggerCharacterString))
          .trimmingCharacters(in: .whitespacesAndNewlines)
      }
    }
    return nil
  }

  init(uri: URL,
       editorView: EditorView,
       languageClient: LanguageClient,
       triggeredManually: Bool) {
    self.uri = uri
    self.languageClient = languageClient
    self.initialDocumentPosition = editorView.position ?? 0

    super.init()
    self.editorView = editorView
  }

  func findTriggerPosition(from offset: String.Index) -> String.Index? {
    if let editorView = editorView {

      if offset == editorView.state.text.startIndex { return offset }

      let previousCharacterIndex = editorView.state.text.index(before: offset)
      let previousCharacter = editorView.state.text.buffer[previousCharacterIndex..<offset]

      let triggerCharacters = editorView.triggerKeyEvents.compactMap {
        return $0.modifiers == nil || $0.modifiers?.isEmpty == true
          ? $0.characters : nil
      }

      if previousCharacter.trimmingCharacters(in: .whitespaces).isEmpty
        || triggerCharacters.contains(String(previousCharacter)) {
        return offset
      }

      guard let line = editorView.convertOffsetToLinePosition(offset)?.line,
            let lineStart = editorView.state.text.rangeOfLine(line)?.lowerBound else {
        return nil
      }

      var winner = offset

      for triggerCharacter in triggerCharacters {
        if let character = triggerCharacter.last {
          if let candidate = editorView.state.text.index(of: character,
                                                         startingAt: offset,
                                                         searchDirection: .left) {
            winner = max(lineStart, min(candidate, winner))
          }
        }
      }

      return winner
    }

    return nil
  }

  func requestCompletion() -> PMKFinalizer? {
    if let startIdx = editorView?.state.text.startIndex,
      let endIdx = editorView?.state.text.endIndex,
      let idx = editorView?.state.text.buffer.index(startIdx,
                                                    offsetBy: initialDocumentPosition,
                                                    limitedBy: endIdx) {
      return requestCompletion(atPosition: idx)
    }
    
    return nil
  }

  func requestCompletion(atPosition position: String.Index) -> PMKFinalizer? {
    state = .pendingResults

    guard let pos = editorView?.convertOffsetToUTF16LinePosition(position) else {
      return nil
    }

    let params = TextDocumentPositionParams(
      textDocument: TextDocumentIdentifier(uri: uri.absoluteString),
      position: Position(line: pos.line - 1, character: pos.column))

    let message = CompletionRequest(params: params)
    return languageClient.send(message: message,
                               responseType: CompletionResult.self)
      .done { [weak self] completionResponse in
        self?.state = .hasResults
        self?.completionItems = completionResponse.items
        self?.filterAndDisplayCachedCompletionItems()
      }
      .catch { [weak self] _ in
        self?.close()
    }
  }

  func filterAndDisplayCachedCompletionItems() {
    applyCompletionItemsFilter()

    guard let filteredCompletionItems = filteredCompletionItems,
      !filteredCompletionItems.isEmpty else {
        if state != .pendingResults && state != .hasResults {
          close()
        }
        return
    }

    display()
  }

  func applyCompletionItemsFilter() {
    filteredCompletionItems = completionItems

    if let filter = filterString, !filter.isEmpty {
      filteredCompletionItems?.filter(using: filter)
    }

    if filteredCompletionItems?.isEmpty != false {
      close()
    }
  }

  public override func viewDidLoad() {
    super.viewDidLoad()
    listView?.animateSelections = false
    listView?.selectionKeys = [.enter, .return]
    listView?.isSelectable = true

    listView?.onSelection = { [weak self] (indexPath, cell) in
      guard let `self` = self, let editorView = self.editorView else { return }
      if indexPath.item < (self.filteredCompletionItems?.count ?? 0),
        let completion = self.filteredCompletionItems?[indexPath.item],
        let insertText = completion.insertText,
        let position = editorView.positionIndex {

        var text = insertText

        if let filter = self.filterString {
          if let range = text.range(of: filter) {
            text.removeSubrange(..<range.upperBound)
          }
        }

        self.close()
        editorView.insert(text: text, at: position)

        if let line = editorView.currentLine,
           let endOfLine = editorView.state.text.rangeOfLine(line)?.upperBound {
          let markers = editorView.state.text
            .rangesOfMarkers(within: position..<endOfLine)
          if let firstMarker = markers.first {
            
            let utf8 = editorView.state.text.buffer.utf8
            let start = utf8.index(utf8.startIndex, offsetBy: firstMarker.range.lowerBound)
            let end = utf8.index(start, offsetBy: firstMarker.range.count)
            editorView.select(range: start..<end)
          }
        }
      }
    }
  }

  public override func updateAppearance(style: AppearanceStyle) {
    super.updateAppearance(style: style)
    listView?.background.color = .textAreaBackgroundColor
  }

  public func close() {
    state = .closed
    view.window?.close()
  }

  public func show(at position: CGPoint, in parent: View) {
    close()
    state = completionItems?.isEmpty == true ? .open : .hasResults
    if let point = editorView?.coordinatesInWindowSpace(from: position) {
      let popup = CompletionPopupWindow(rootComponent: self,
                                        frame: CGRect(x: 0,
                                                      y: 0,
                                                      width: 500,
                                                      height: 200),
                                        hasTitleBar: false)

      Application.shared.add(window: popup, asChildOf: parent.window)
      var position = point
      let lineHeight = editorView?.dimensionsOfLine(nearest: position)?.height ?? 0
      position.y += lineHeight
      print("Displaying code completion popover at: \(position)")
      popup.move(to: position)
      self.display()
    } else {
      print("Error: failed to launch code completion popover.")
    }
  }

  public func move(to position: CGPoint, in parent: View) {
    if let point = editorView?.coordinatesInWindowSpace(from: position) {
      var pos = point
      let lineHeight = editorView?.dimensionsOfLine(nearest: position)?.height ?? 0
      pos.y += lineHeight
      listView?.window?.move(to: pos)
    }
  }

  func display() {
    let firstItemIndex = IndexPath(item: 0, section: 0)
    listView?.focusedCellIndex = firstItemIndex
    listView?.highlightedChildren = [firstItemIndex]
    reload()
  }

  public override func numberOfSections() -> Int {
    return 1
  }

  public override func numberOfItemsInSection(section: Int) -> Int {
    return filteredCompletionItems?.count ?? 0
  }

  public override func cellForItem(at indexPath: IndexPath,
                                   withState state: ListItemState) -> ListViewCell {
    let cell = CodeCompletionItemCell(frame: CGRect(x: 0, y: 0, width: 500, height: 20))

    let completionItem = filteredCompletionItems?[indexPath.item]
    
    cell.titleLabel.text = completionItem?.label ?? "null"
    
    if let returnType = completionItem?.detail, !returnType.isEmpty {
      cell.returnTypeLabel.text = returnType
    } else {
      cell.returnTypeLabel.text = "Void"
    }
    
    cell.alignItems = .center
    cell.isHighlighted = state.isHighlighted
    cell.updateAppearance(style: Appearance.current)
    cell.width = 100%
    cell.height = 20~
    return cell
  }

  public override func heightOfCell(at indexPath: IndexPath) -> CGFloat {
    return 20
  }
}

class CodeCompletionItemCell: ListViewCell {

  let titleLabel = Label()
  let returnTypeLabel = Label()
  
  override func willAttachToWindow() {
    super.willAttachToWindow()
    flexDirection = .row
    set(padding: 10~, for: .left)
    set(padding: 10~, for: .right)
    
    add(subview: titleLabel)
    titleLabel.font = .ofType(.system, category: .small)
    titleLabel.background.color = .clear
    titleLabel.verticalArrangement = .center
    titleLabel.flex = 1
    titleLabel.height = 100%

    add(subview: returnTypeLabel)
    returnTypeLabel.font = .ofType(.system, category: .small)
    returnTypeLabel.verticalArrangement = .center
    returnTypeLabel.horizontalArrangement = .right
    returnTypeLabel.width = 40%
    returnTypeLabel.height = 100%
  }

  override func updateAppearance(style: AppearanceStyle) {
    super.updateAppearance(style: style)

    background.color = isHighlighted ? .highlightedCellColor : .textAreaBackgroundColor
    titleLabel.textColor = isHighlighted ? .white : .textColor
    
    if isHighlighted {
      returnTypeLabel.textColor = .lightGray
    } else {
      returnTypeLabel.textColor = style == .dark ? .gray : .darkGray
    }
  }
}
