//
//  Label.swift
//  StrideLib
//
//  Created by pmacro on 10/05/2019.
//

import Foundation
import RxSwift
import Suit

extension Reactive where Base: Label {
  
  /// Bindable sink for `text` property.
  public var text:  Binder<String?> {
    return Binder(self.base) { label, text in
      label.text = text
      label.forceRedraw()
    }
  }
}
