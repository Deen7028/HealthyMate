import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let envPath = Bundle.main.privateFrameworksURL?
      .appendingPathComponent("App.framework/flutter_assets/.env")
    let envContents = envPath.flatMap { try? String(contentsOf: $0, encoding: .utf8) }
    let apiKeyLine = envContents?
      .split(whereSeparator: { $0.isNewline })
      .first(where: { $0.hasPrefix("GOOGLE_MAPS_API_KEY=") })
    let apiKey = apiKeyLine.map { line in
      String(line.dropFirst("GOOGLE_MAPS_API_KEY=".count))
        .trimmingCharacters(in: .whitespacesAndNewlines)
        .trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
    }
    if let apiKey, !apiKey.isEmpty {
      GMSServices.provideAPIKey(apiKey)
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
