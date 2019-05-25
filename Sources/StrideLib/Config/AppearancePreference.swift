//
//  AppearancePreferences.swift
//  StrideLib
//
//  Created by pmacro  on 12/03/2019.
//

import Foundation
import Suit

public class AppearancePreference: SinglePreference {

  public var name: String = "Appearance"

  public var value: AppearanceStyle?
  
  static var saveDirectory: URL {
    return FileManager.strideConfigURL
  }
  
  static var `extension`: String = "appearanceMode"
  
  public static var calculatedPreference: AppearanceStyle {
    return AppearancePreference.load()?.value
           ?? AppearancePreference.findSystemDefault()
           ?? Appearance.current
  }
  
  public static func findSystemDefault() -> AppearanceStyle? {
    #if os(macOS)
    let type = UserDefaults.standard.string(forKey: "AppleInterfaceStyle") ?? "Light"
    if type == "Dark" { return .dark }
    return .light
    #else
    return nil
    #endif
  }
}
