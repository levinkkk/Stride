//
//  EditorComponent.swift
//  Editor
//
//  Created by pmacro on 15/06/2018.
//

import Foundation
import Suit
import Highlighter
import LanguageClient

public class EditorComponent: TextAreaComponent {
  
  public var currentURL: URL?
  var codeCompletionPopover: CodeCompletionPopover?
  weak var languageClient: LanguageClient?
  var documentVersion = 1
  
  let highlighter = CodeHighlighter()
  
  var languageConfiguration: LanguageConfiguration?
  
  /// When a language server supports full sync, it can be extremely expensive as the full
  /// document needs to be sent on each key press.  For very large documents this can destroy
  /// editor performance.  So we use this to throttle the rate of full syncs.
  var fullSyncThrottler: RepeatingTimer?
  var needsFullSync = false {
    didSet {
      if needsFullSync {
        fullSyncThrottler?.resume()
      } else {
        fullSyncThrottler?.suspend()
      }
    }
  }
  
  let backgroundQueue = DispatchQueue(label: "EditorComponentBackgroundQueue")
  
  let manualCodeCompletionTriggerKey = createPlatformKeyEvent(characters: " ",
                                                              strokeType: .down,
                                                              modifiers: [.control],
                                                              keyType: .other)
  
  public override var textAreaViewType: TextAreaView.Type {
    return EditorView.self
  }
  
  var editorView: EditorView {
    return textAreaView as! EditorView
  }
  
  public init(with languageClient: LanguageClient) {
    self.languageClient = languageClient
  }
  
  public override func viewDidLoad() {
    super.viewDidLoad()
    editorView.delegate = self
  }
  
  func readFile(at url: URL) -> String? {
    if let data = try? Data(contentsOf: url) {
      let source = data.withUnsafeBytes { buf in
        return String(decoding: buf.bindMemory(to: UInt8.self), as: UTF8.self)
      }
      
      return source
    }
    
    return nil
  }
  
  public func open(_ url: URL) {
    guard FileManager.default.fileExists(atPath: url.path),
          let string = readFile(at: url) else {
      // TODO integrate with UI error notifications once implemented
      print("Error: cannot find file at \(url.path)")
      let message = "The file at: \"\(url.path)\" cannot be found."
      view.window.displayMessage(withTitle: "Unable To Open File",
                                content: message)
      return
    }

    if let current = currentURL {
      close(current)
      editorView.embeddingScrollView?.scrollToTop()
    }
    
    currentURL = url.standardizedFileURL
    codeCompletionPopover = nil
    documentVersion = 1
    
    languageConfiguration = LanguageConfiguration.loadAll()
      .first { $0.name.lowercased() == url.pathExtension }
    
    languageClient?.register(self, forURI: url.absoluteString)
    
    if languageClient?.capabilities?.textDocumentSync.syncKind == .full {
      fullSyncThrottler = RepeatingTimer(timeInterval: 1)
      fullSyncThrottler?.resume()
      
      fullSyncThrottler?.eventHandler = { [weak self] in
        guard let `self` = self, self.needsFullSync, let currentURL = self.currentURL else {
          return
        }
                
        let contentChange = TextDocumentContentChangeEvent(range: nil,
                                                       rangeLength: nil,
                                                       text: self.textAreaView?.state.text.buffer)
        
        let documentInfo = VersionedTextDocumentIdentifier(version: 1,
                                                           uri: currentURL.absoluteString)
        let params = DidChangeTextDocumentParams(textDocument: documentInfo,
                                                 contentChanges: [contentChange])
        self.languageClient?.send(notification: DidChangeTextDocumentNotification(params: params))
        self.needsFullSync = false
      }
    }

    self.performHighlighting()

    if let textAreaView = textAreaView {
      textAreaView.position = nil
      textAreaView.state.text = StringDocument(string: string)
      textAreaView.font = Font(size: 11, family: "Menlo")

      view.window.rootView.invalidateLayout()
      scrollView.contentsDidChange()
      view.forceRedraw()
      
      textAreaView.triggerKeyEvents =
        languageClient?.capabilities?.completionProvider?.triggerCharacters?
          .map {
            return createPlatformKeyEvent(characters: $0,
                                          strokeType: .down,
                                          modifiers: nil,
                                          keyType: KeyType.other)
        }
      ?? []
      
      textAreaView.triggerKeyEvents.append(manualCodeCompletionTriggerKey)
    }

    backgroundQueue.async { [weak self] in
      guard let `self` = self,
        let notification = self.generateOpenNotification() else {
          return
      }
      self.languageClient?.send(notification: notification)
    }
  }
  
  func generateOpenNotification() -> DidOpenTextDocumentNotification? {
    guard let url = currentURL else { return nil }

    let document = TextDocumentItem(uri: url.absoluteString,
                                    languageId: "swift",
                                    version: self.documentVersion,
                                    text: editorView.state.text.buffer)
    
    return DidOpenTextDocumentNotification(textDocument: document)
  }
  
  public func close(_ url: URL) {
    let identifier = TextDocumentIdentifier(uri: url.absoluteString)
    
    let closeNotification = DidCloseTextDocumentNotification(textDocumentIdentifier: identifier)
    self.languageClient?.send(notification: closeNotification)
  }
  
  func format() {
    guard let currentURL = currentURL,
      let languageConfiguration = languageConfiguration else { return }
    
    backgroundQueue.async {
      SwiftFormatter.format(file: currentURL,
                            languageConfiguration: languageConfiguration)
      DispatchQueue.main.async { [weak self] in
        self?.revert()
      }
    }
  }
  
  func revert() {
    guard let currentURL = currentURL else { return }
    
    close(currentURL)
    open(currentURL)
  }
  
  func performHighlighting() {
    guard let currentURL = currentURL, currentURL.path.hasSuffix(".swift") else { return }
    _ = highlighter?.run(on: currentURL).done { [weak self] tokens in
      guard let `self` = self else { return }
      
      let attributes = tokens.compactMap { (token: Token) -> TextAttribute? in
        if token.tokenType == .newLine { return nil }
        let color = HighlightingConfiguration.default.colour(for: token)
        
        // FYI Token positions are UTF8 offsets
        return TextAttribute(color: color,
                             range: token.position.start..<token.position.end)
      }
      
      DispatchQueue.main.async { [weak self] in
        self?.textAreaView?.state.text.textAttributes = attributes
        
        if let view = self?.view {
          self?.textAreaView?.window.redrawManager.redraw(view: view)
        }
      }
    }
  }
  
  public override func updateAppearance(style: AppearanceStyle) {
    super.updateAppearance(style: style)
    performHighlighting()    
  }
}

extension EditorComponent: EditorViewDelegate {
  
  public func didPress(triggerKey: KeyEvent) {
    guard let currentURL = currentURL,
      let offset = editorView.positionIndex,
      let languageClient = languageClient else { return }
    
    let isManual = triggerKey.characters == manualCodeCompletionTriggerKey.characters
                  && triggerKey.modifiers == manualCodeCompletionTriggerKey.modifiers
    
    codeCompletionPopover?.close()
    codeCompletionPopover = CodeCompletionPopover(uri: currentURL,
                                                  editorView: editorView,
                                                  languageClient: languageClient,
                                                  triggeredManually: isManual)
    
    backgroundQueue.async { [weak self] in
      self?.codeCompletionPopover?.requestCompletion()?.finally {
        if self?.codeCompletionPopover?.completionItems?.isEmpty == false {
          DispatchQueue.main.async {
            guard let editorView = self?.editorView else { return }
            let location = editorView.location(forIndex: offset)
            self?.codeCompletionPopover?.show(at: location,
                                              in: editorView)
          }
        }
      }
    }
  }
  
  public func didInsert(text: String, at position: String.Index) {
    save()
    performHighlighting()

    handleInsert(text: text, at: position)
    updateCodeCompletion()
  }
  
  private func handleInsert(text: String, at position: String.Index) {
    guard let currentURL = currentURL else { return }

    let syncKind = languageClient?.capabilities?.textDocumentSync.syncKind ?? .none
    
    var contentChange: TextDocumentContentChangeEvent?
    
    switch syncKind {
      case .full:
        needsFullSync = true
        break
      case .incremental:
        guard let startPosition = editorView.convertOffsetToUTF16LinePosition(position) else {
          return
        }
        
        let changePosition = Position(line: startPosition.line - 1,
                                      character: startPosition.column)
        
        let range = ContentRange(start: changePosition, end: changePosition)
        contentChange = TextDocumentContentChangeEvent(range: range,
                                                       rangeLength: nil,
                                                       text: text)
      
        guard let lineInfo = editorView.state.text.rangeOfLine(startPosition.line) else {
          return
        }
        
        let utf16 = editorView.state.text.buffer.utf16
        let numberOfColumns = utf16.distance(from: lineInfo.lowerBound,
                                             to: lineInfo.upperBound)
        
        assert(startPosition.column <= numberOfColumns)
      case .none:
        break
    }
    
    if let contentChange = contentChange {
      documentVersion += 1
      let documentInfo = VersionedTextDocumentIdentifier(version: documentVersion,
                                                         uri: currentURL.absoluteString)
      let params = DidChangeTextDocumentParams(textDocument: documentInfo,
                                               contentChanges: [contentChange])
      languageClient?.send(notification: DidChangeTextDocumentNotification(params: params))
    }
  }
  
  public func willDelete(characterCount: Int, at position: String.Index) {
    guard let currentURL = currentURL, characterCount > 0 else { return }
    
    performHighlighting()
    
    let syncKind = languageClient?.capabilities?.textDocumentSync.syncKind ?? .none
    
    var contentChange: TextDocumentContentChangeEvent?
    
    switch syncKind {
    case .full:
      needsFullSync = true
      break
    case .incremental:
      let endIndex = editorView.state.text.index(position,
                                                 offsetBy: characterCount)
      
      guard let start = editorView.convertOffsetToUTF16LinePosition(position),
        let end = editorView.convertOffsetToUTF16LinePosition(endIndex) else {
          return
      }
      
      let startPosition = Position(line: start.line - 1,
                                   character: start.column)
      let endPosition = Position(line: end.line - 1,
                                   character: end.column)
      
      let range = ContentRange(start: startPosition, end: endPosition)
      contentChange = TextDocumentContentChangeEvent(range: range,
                                                     rangeLength: nil,
                                                     text: "")
    case .none:
      break
    }
    
    if let contentChange = contentChange {
      documentVersion += 1
      let documentInfo = VersionedTextDocumentIdentifier(version: documentVersion,
                                                         uri: currentURL.absoluteString)
      let params = DidChangeTextDocumentParams(textDocument: documentInfo,
                                               contentChanges: [contentChange])
      languageClient?.send(notification: DidChangeTextDocumentNotification(params: params))
    }
  }
  
  public func didDelete(characterCount: Int, at: String.Index) {
    save()
    updateCodeCompletion()
  }
  
  func updateCodeCompletion() {
    if let codeCompletionPopover = codeCompletionPopover,
           codeCompletionPopover.state != .closed
    {
      guard let editorPositionIndex = editorView.positionIndex,
            let editorPosition = editorView.position,
            codeCompletionPopover.initialDocumentPosition <= editorPosition else {
          codeCompletionPopover.close()
        return
      }
      
      codeCompletionPopover.filterAndDisplayCachedCompletionItems()
      codeCompletionPopover.move(to: editorView.location(forIndex: editorPositionIndex),
                                 in: editorView)
    } else {
      codeCompletionPopover?.close()
    }
  }
  
  func save() {
    guard let currentURL = currentURL else { return }
    FileManager.default.createFile(atPath: currentURL.standardizedFileURL.path,
                                   contents: editorView.state.text.buffer.data(using: .utf8), attributes: nil)
  }
  
  public func requestGoToDefinition() {
    guard
      let currentURL = currentURL,
      let position = editorView.positionIndex,
      let pos = editorView.convertOffsetToLinePosition(position) else {
      return
    }
    
    let params = TextDocumentPositionParams(
      textDocument: TextDocumentIdentifier(uri: currentURL.absoluteString),
      position: Position(line: pos.line - 1, character: pos.column))
    
    let message = GoToDefinitionRequest(params: params)
    languageClient?.send(message: message,
                         responseType: GoToDefinitionResult.self)
    .done { [weak self] response in
      guard let `self` = self else { return }
      
      if let firstLocation = response.locations?.first,
        let url = URL(string: firstLocation.uri) {
        
        let editorComponent: EditorComponent
        
        if url.path != currentURL.path,
           let parentComponent = self.parentComponent as? TabbedEditorComponent,
           let languageClient = self.languageClient {
            editorComponent = parentComponent.open(url: url, using: languageClient)
        } else {
          editorComponent = self
          editorComponent.open(url)
        }
        
        let range = firstLocation.range
        editorComponent.editorView.scroll(to: range.start.line + 1)

        if range.start == range.end {
          editorComponent.editorView.select(line: range.start.line + 1)
        }
        else if let lower = editorComponent.editorView.convertToOffset(line: range.start.line,
                                                       column: range.start.character),
           let upper = editorComponent.editorView.convertToOffset(line: range.end.line,
                                                       column: range.end.character) {
          editorComponent.editorView.select(range: lower..<upper)
        }
      }
      }
      .catch { _ in
        print("Unexpected error!")
    }
  }
}

extension EditorComponent: LanguageClientNotificationDelegate {
  public func receive(message: LogMessage) -> Bool {
    let title: String
    
    switch message.params.type {
      case .error:
        title = "Error"
      case .warning:
        title = "Warning"
      case .info:
        title = "Info"
      case .log:
        print("LanguageClient: \(message.params.message)")
        return true
      }
    
    view.window.displayMessage(withTitle: title, content: message.params.message)
    
    // We handled this message.
    return true
  }
  
  public func receive(diagnostics: [Diagnostic]) {
    editorView.diagnostics = diagnostics.reduce([:], { (running, current) -> [Int: [Diagnostic]] in
      var startLineDiagnostics = running[current.range.start.line] ?? []
      startLineDiagnostics.append(current)
      
      var endLineDiagnostics = running[current.range.end.line] ?? []
      endLineDiagnostics.append(current)
      
      var next = running
      next[current.range.start.line] = startLineDiagnostics
      next[current.range.end.line] = endLineDiagnostics
      return next
    })
  }
}
