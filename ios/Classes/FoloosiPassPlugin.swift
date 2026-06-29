import Flutter
import UIKit
import WebKit
import Foundation

public class FoloosiPassPlugin: NSObject, FlutterPlugin {

    private var flutterResult: FlutterResult?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "foloosi_pass", binaryMessenger: registrar.messenger())
        let instance = FoloosiPassPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        // Required so iOS forwards application(_:open:) to this plugin when
        // UAE Pass returns to the app via the configured URL scheme (foloosi://).
        registrar.addApplicationDelegate(instance)
    }

    func getUaePassTokenForCode(code: String) {

        UAEPASSNetworkRequests.shared.getUAEPassToken(code: code, completion: {
            (uaePassToken) in
            if let uaePassToken = uaePassToken, let accessToken = uaePassToken.accessToken {
                self.flutterResult!(String(accessToken))  // Remove space before !
            } else {
                self.flutterResult!(FlutterError(code: "ERROR", message: "Unable to get user token, Please try again.", details: nil))  // Remove space before !
                return
            }
        }) {
            (error) in
            self.flutterResult!(FlutterError(code: "ERROR", message: "Unable to get user token, Please try again.", details: nil))  // Remove space before !
            return
        }
    }

    func getUaePassProfileForToken(token: String) {
        UAEPASSNetworkRequests.shared.getUAEPassUserProfile(token: token, completion: {
            (userProfile) in
            if let userProfile = userProfile {
                do {
                    let userProfileData = try JSONEncoder().encode(userProfile)
                    if let userProfileString = String(data: userProfileData, encoding: .utf8) {
                        self.flutterResult!(userProfileString)  // Fix here
                    } else {
                        self.flutterResult!(FlutterError(code: "ERROR", message: "Failed to encode userProfile as JSON string", details: nil))  // Fix here
                    }
                } catch {
                    self.flutterResult!(FlutterError(code: "ERROR", message: "Failed to encode userProfile as JSON data", details: nil))  // Fix here
                }
            } else {
                self.flutterResult!(FlutterError(code: "ERROR", message: "Unable to get user profile, Please try again.", details: nil))  // Fix here
                return
            }
        }) {
            (error) in
            self.flutterResult!(FlutterError(code: "ERROR", message: "Unable to get user profile, Please try again.", details: nil))  // Fix here
            return
        }
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {

        self.flutterResult = result

        switch call.method {

        case "set_up_environment":

            guard let arguments = call.arguments as? [String: Any],
            let clientID = arguments["client_id"] as? String,
            let clientSecret = arguments["client_secret"] as? String,
            let environment = arguments["environment"] as? String,
            let redirectUri = arguments["redirect_url"] as? String,
            let state = arguments["state"] as? String,
            let scope = arguments["scope"] as? String,
            let scheme = arguments["scheme"] as? String else {
                // Remove language from here
                sendError("Invalid arguments")
                return
            }

            let env = environment == "production" ? UAEPASSEnvirnonment.production: UAEPASSEnvirnonment.staging

            UAEPASSRouter.shared.environmentConfig = UAEPassConfig(clientID: clientID, clientSecret: clientSecret, env: env)

            UAEPASSRouter.shared.spConfig = SPConfig(
                redirectUriLogin: redirectUri,
                scope: scope,
                state: state,
                successSchemeURL: scheme + "://",
                failSchemeURL: scheme + "://",
                signingScope: "urn:safelayer:eidas:sign:process:document"
            )

            sendResult(true)

        case "access_token":

            guard let arguments = call.arguments as? [String: Any],
            let code = arguments["code"] as? String else {
                sendError("Missing code")
                return
            }

            getUaePassTokenForCode(code: code)

        case "profile":

            guard let arguments = call.arguments as? [String: Any],
            let token = arguments["token"] as? String else {
                sendError("Missing token")
                return
            }

            getUaePassProfileForToken(token: token)

        case "sign_out":

            HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)

            WKWebsiteDataStore.default().fetchDataRecords(
                ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()
            ) {
                records in
                records.forEach {
                    record in
                    WKWebsiteDataStore.default().removeData(
                        ofTypes: record.dataTypes,
                        for: [record],
                        completionHandler: {
                        }
                    )
                }
            }

            UAEPASSRouter.shared.uaePassToken = nil

            sendResult(true)

        case "sign_in":

            guard let webVC = UAEPassWebViewController.instantiate() as? UAEPassWebViewController else {
                sendError("Unable to open UAE Pass screen")
                return
            }

            webVC.urlString = UAEPassConfiguration.getServiceUrlForType(serviceType: .loginURL)

            webVC.onUAEPassSuccessBlock = {
                code in
                DispatchQueue.main.async {
                    UIApplication.shared.windows.first?.rootViewController?.dismiss(animated: true)
                    self.sendResult(code)  // ✅ Just use code directly since it's String, not String?
                }
            }

            webVC.onUAEPassFailureBlock = {
                response in
                DispatchQueue.main.async {
                    UIApplication.shared.windows.first?.rootViewController?.dismiss(animated: true)
                    self.sendError(response ?? "Login failed")
                }
            }

            webVC.reloadwithURL(url: webVC.urlString)

            let nav = UINavigationController(rootViewController: webVC)
            nav.modalPresentationStyle = .fullScreen

            UIApplication.shared.windows.first?.rootViewController?.present(nav, animated: true)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    func sendResult(_ value: Any?) {
        DispatchQueue.main.async {
            guard let result = self.flutterResult else {
                return
            }
            result(value)
            self.flutterResult = nil
        }
    }

    func sendError(_ message: String) {
        DispatchQueue.main.async {
            guard let result = self.flutterResult else {
                return
            }
            result(FlutterError(code: "ERROR", message: message, details: nil))
            self.flutterResult = nil
        }
    }

    public func application(_ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {

        print("<><><><> appDelegate URL : \(url.absoluteString)")

        // ✅ SUCCESS CASE
        if url.absoluteString.contains(HandleURLScheme.externalURLSchemeSuccess()) {

            if let webViewController = UserInterfaceInfo.topViewController() as? UAEPassWebViewController {
                webViewController.forceReload()
            }

            return true
        }

        // ❌ FAILURE CASE
        if url.absoluteString.contains(HandleURLScheme.externalURLSchemeFail()) {

            guard let webViewController = UserInterfaceInfo.topViewController() as? UAEPassWebViewController else {
                return false
            }

            webViewController.dismiss(animated: true, completion: nil)
            return false
        }

        return false
    }
}
