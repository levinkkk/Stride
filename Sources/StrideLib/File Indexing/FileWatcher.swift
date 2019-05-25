//
//  FileWatcher.swift
//  StrideLib
//
//  Created by pmacro  on 28/03/2019.
//

#if os(macOS) || os(iOS)
import Foundation

class FileWatcher {
  
  private let fileDescriptor: CInt
  private let source: DispatchSourceProtocol
  
  deinit {
    self.source.cancel()
    close(fileDescriptor)
  }
  
  init(URL: URL, eventHandler: @escaping () -> Void) {
    self.fileDescriptor = open(URL.path, O_EVTONLY)
    self.source = DispatchSource
      .makeFileSystemObjectSource(fileDescriptor: self.fileDescriptor,
                                       eventMask: .all,
                                           queue: .global())
    self.source.setEventHandler {
      eventHandler()
    }
    self.source.resume()
  }
}
#endif
