import Foundation
import SafariServices
import UIKit

class OracleXManager {

    static let shared = OracleXManager()

    private(set) var isInitialized = false
    private(set) var config: OracleXConfig?

    var isDebugMode: Bool {
        return config?.options?.debug ?? false
    }

    private var errorListener: ((OracleXError) -> Void)?
    private let listenerQueue = DispatchQueue(label: "com.oraclex.sdk.listener")

    weak var activeViewController: OracleXWebViewController?
    private init() {}

    func initialize(config: OracleXConfig) {
        self.config = config
        self.isInitialized = true
    }

    func reset() {
        closeOracleX()
        listenerQueue.sync { self.errorListener = nil }
        config = nil
        isInitialized = false
        Logger.i("SDK reset completed")
    }

    func setErrorListener(_ listener: @escaping (OracleXError) -> Void) {
        listenerQueue.sync { self.errorListener = listener }
    }

    func notifyError(_ error: OracleXError) {
        ErrorReporter.report(error)

        let listener = listenerQueue.sync { self.errorListener }
        if let listener = listener {
            DispatchQueue.main.async { listener(error) }
        } else if isUserFacingError(error.code) {
            DispatchQueue.main.async {
                guard let vc = self.activeViewController ?? self.topViewController() else { return }
                let alert = UIAlertController(title: nil, message: error.message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "확인", style: .default))
                vc.present(alert, animated: true)
            }
        }
    }

    private func isUserFacingError(_ code: Int) -> Bool {
        return (2000...2999).contains(code) || (3000...3999).contains(code) || (5000...5999).contains(code)
    }

    func openOracleX() {
        if activeViewController != nil {
            Logger.w("OracleX is already open. Ignoring duplicate open request.")
            return
        }
        DispatchQueue.main.async {
            guard let topVC = self.topViewController() else {
                Logger.e("Cannot find top view controller")
                return
            }

            let oraclexVC = OracleXWebViewController()
            oraclexVC.modalPresentationStyle = .fullScreen
            topVC.present(oraclexVC, animated: true)
        }
    }

    func closeOracleX() {
        DispatchQueue.main.async {
            self.activeViewController?.dismiss(animated: true)
        }
    }

    func effectiveBaseURL() -> String {
        switch config?.env ?? .production {
        case .direct:
            return config?.customURL?.isEmpty == false ? config!.customURL! : SdkConstants.baseURLDirect
        case .staging:
            return SdkConstants.baseURLStaging
        case .production:
            return SdkConstants.baseURLProduction
        }
    }

    func effectiveErrorURL() -> String {
        switch config?.env ?? .production {
        case .staging:    return SdkConstants.errorReportURLStaging
        case .direct:     return SdkConstants.errorReportURLDirect
        case .production: return SdkConstants.errorReportURLProduction
        }
    }

    func isInternalURL(_ url: URL) -> Bool {
        guard let scheme = url.scheme, scheme == "http" || scheme == "https" else {
            return false
        }
        let host = url.host?.lowercased() ?? ""
        let effectiveHost = URL(string: effectiveBaseURL())?.host?.lowercased() ?? ""
        return host == effectiveHost
    }

    func openExternalURL(_ urlString: String) {
        guard let url = URL(string: urlString) else {
            Logger.w("openExternal ignored: invalid URL '\(urlString)'")
            return
        }

        // 모든 URL → 외부 브라우저(시스템 핸들러)로 처리
        DispatchQueue.main.async {
            UIApplication.shared.open(url, options: [:]) { success in
                if success {
                    Logger.d("Opened external URL via system browser: \(urlString)")
                } else {
                    Logger.w("Cannot handle URL: \(urlString)")
                }
            }
        }
    }

    func campaignDrawerClose() {
        evaluateJs("campaignDrawerClose()")
    }

    private(set) var isDrawerOpen: Bool = false
    private(set) var isModalOpen: Bool = false
    private(set) var isCommonPageOpen: Bool = false

    func onCampaignDrawerIsOpen(_ isOpen: Bool) {
        isDrawerOpen = isOpen
        Logger.d("Campaign drawer state changed: \(isOpen)")
    }

    func onCampaignModalIsOpen(_ isOpen: Bool) {
        isModalOpen = isOpen
        Logger.d("Campaign modal state changed: \(isOpen)")
    }

    func campaignModalClose() {
        Logger.d("campaignModalClose() called")
        evaluateJs("campaignModalClose()")
        isModalOpen = false
    }

    func onCommonPageIsOpen(_ isOpen: Bool) {
        isCommonPageOpen = isOpen
        Logger.d("Common page state changed: \(isOpen)")
    }

    func commonPageClose() {
        Logger.d("commonPageClose() called")
        evaluateJs("commonPageClose()")
        isCommonPageOpen = false
    }

    func checkAppInstalled(_ appInfo: String) {
        guard let url = URL(string: "\(appInfo)://") else {
            Logger.w("isAppInstalled: invalid scheme '\(appInfo)'")
            evaluateJs("onReceiveAppInstallStatus(false)")
            return
        }
        let isInstalled = UIApplication.shared.canOpenURL(url)
        Logger.d("App installed check '\(appInfo)': \(isInstalled)")
        evaluateJs("onReceiveAppInstallStatus(\(isInstalled))")
    }

    private func evaluateJs(_ script: String) {
        DispatchQueue.main.async {
            self.activeViewController?.webView?.evaluateJavaScript(script) { _, error in
                if let error = error {
                    Logger.w("evaluateJs failed: \(error.localizedDescription)")
                }
            }
        }
    }

    func buildOracleXRequest() -> URLRequest? {
        let urlString = effectiveBaseURL()
        guard let url = URL(string: urlString) else { return nil }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        guard let config = config else { return request }

        let timestamp = Int(Date().timeIntervalSince1970 * 1000)
        let nonce = UUID().uuidString
        let adid = config.adid ?? DeviceInfo.idfa

        let queryItems: [URLQueryItem] = [
            URLQueryItem(name: "channelUuid",     value: config.channelUuid),
            URLQueryItem(name: "channelUserId",   value: config.channelUserId),
            URLQueryItem(name: "adid",            value: adid),
            URLQueryItem(name: "timestamp",       value: "\(timestamp)"),
            URLQueryItem(name: "nonce",           value: nonce),
            // 디바이스 정보 (SDK 자동 수집)
            URLQueryItem(name: "deviceOs",        value: SdkConstants.platform),
            URLQueryItem(name: "deviceOsVersion", value: DeviceInfo.osVersion),
            URLQueryItem(name: "deviceModel",     value: DeviceInfo.model),
        ]

        Logger.d("POST params - channelUuid=\(String(config.channelUuid.prefix(6)))***, channelUserId=\(String(config.channelUserId.prefix(3)))***, adid=\(adid), deviceOs=\(SdkConstants.platform), deviceModel=\(DeviceInfo.model)")

        var components = URLComponents()
        components.queryItems = queryItems
        request.httpBody = components.query?.data(using: .utf8)
        return request
    }

    func buildNativeDataJS() -> String {
        guard let config = config else { return "" }

        let escapedUserId = config.channelUserId
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        let escapedUuid = config.channelUuid
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")

        let adid = config.adid ?? DeviceInfo.idfa
        return """
        window.OracleXNativeData = {
            channelUserId: "\(escapedUserId)",
            channelUuid: "\(escapedUuid)",
            sdkVersion: "\(SdkConstants.sdkVersion)",
            deviceOs: "\(SdkConstants.platform)",
            deviceOsVersion: "\(DeviceInfo.osVersion)",
            deviceModel: "\(DeviceInfo.model)",
            adid: "\(adid)"
        };
        """
    }

    /// Android와 동일한 window.OracleXBridge 인터페이스를 iOS에서도 제공하기 위한 JS 래퍼
    func buildBridgeWrapperJS() -> String {
        return """
        if (!window.OracleXBridge || !window.OracleXBridge._native) {
            window.OracleXBridge = {
                _native: true,
                close: function() {
                    window.webkit.messageHandlers.OracleXBridge.postMessage({action:'close'});
                },
                error: function(jsonStr) {
                    window.webkit.messageHandlers.OracleXBridge.postMessage({action:'error', data:jsonStr});
                },
                openExternal: function(url) {
                    window.webkit.messageHandlers.OracleXBridge.postMessage({action:'openExternal', data:url});
                },
                campaignDrawerIsOpen: function(open) {
                    window.webkit.messageHandlers.OracleXBridge.postMessage({action:'campaignDrawerIsOpen', data:open});
                },
                campaignModalIsOpen: function(open) {
                    window.webkit.messageHandlers.OracleXBridge.postMessage({action:'campaignModalIsOpen', data:open});
                },
                isAppInstalled: function(appInfo) {
                    window.webkit.messageHandlers.OracleXBridge.postMessage({action:'isAppInstalled', data:appInfo});
                },
                isCommonPageOpen: function(open) {
                    window.webkit.messageHandlers.OracleXBridge.postMessage({action:'isCommonPageOpen', data:open});
                }
            };
        }
        """
    }

    private func topViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first,
              let rootVC = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController
        else {
            return nil
        }

        var topVC = rootVC
        while let presented = topVC.presentedViewController {
            topVC = presented
        }
        return topVC
    }
}
