import Foundation
import WebKit

class OracleXBridgeHandler: NSObject, WKScriptMessageHandler {

    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        guard message.name == SdkConstants.bridgeName else { return }

        guard let body = message.body as? [String: Any],
              let action = body["action"] as? String else {
            Logger.w("Bridge message ignored: invalid format")
            return
        }

        switch action {
        case "close":
            handleClose()
        case "error":
            handleError(body)
        case "openExternal":
            handleOpenExternal(body)
        case "campaignDrawerIsOpen":
            handleCampaignDrawerIsOpen(body)
        case "campaignModalIsOpen":
            handleCampaignModalIsOpen(body)
        case "isAppInstalled":
            handleIsAppInstalled(body)
        case "isCommonPageOpen":
            handleIsCommonPageOpen(body)
        default:
            Logger.w("Bridge message ignored: unknown action '\(action)'")
        }
    }

    private func handleClose() {
        Logger.d("Bridge close received")
        if OracleXManager.shared.isModalOpen {
            Logger.d("Close: modal is open, closing modal")
            OracleXManager.shared.campaignModalClose()
        } else if OracleXManager.shared.isDrawerOpen {
            Logger.d("Close: drawer is open, closing drawer")
            OracleXManager.shared.campaignDrawerClose()
        } else if OracleXManager.shared.isCommonPageOpen {
            Logger.d("Close: common page is open, closing common page")
            OracleXManager.shared.commonPageClose()
        } else {
            Logger.d("Close: closing WebView")
            OracleXManager.shared.closeOracleX()
        }
    }

    private func handleOpenExternal(_ body: [String: Any]) {
        guard let urlString = body["data"] as? String else {
            Logger.w("openExternal ignored: no URL provided")
            return
        }
        Logger.d("Bridge openExternal received: \(urlString)")
        OracleXManager.shared.openExternalURL(urlString)
    }

    private func handleCampaignDrawerIsOpen(_ body: [String: Any]) {
        let isOpen = body["data"] as? Bool ?? false
        Logger.d("Bridge campaignDrawerIsOpen received: \(isOpen)")
        OracleXManager.shared.onCampaignDrawerIsOpen(isOpen)
    }

    private func handleCampaignModalIsOpen(_ body: [String: Any]) {
        let isOpen = body["data"] as? Bool ?? false
        Logger.d("Bridge campaignModalIsOpen received: \(isOpen)")
        OracleXManager.shared.onCampaignModalIsOpen(isOpen)
    }

    private func handleIsCommonPageOpen(_ body: [String: Any]) {
        let isOpen = body["data"] as? Bool ?? false
        Logger.d("Bridge isCommonPageOpen received: \(isOpen)")
        OracleXManager.shared.onCommonPageIsOpen(isOpen)
    }

    private func handleIsAppInstalled(_ body: [String: Any]) {
        guard let appInfo = body["data"] as? String, !appInfo.isEmpty else {
            Logger.w("isAppInstalled ignored: no appInfo provided")
            return
        }
        Logger.d("Bridge isAppInstalled received: \(appInfo)")
        OracleXManager.shared.checkAppInstalled(appInfo)
    }

    private func handleError(_ body: [String: Any]) {
        let dataStr = body["data"] as? String ?? ""
        var message = "Unknown error"

        if let data = dataStr.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            message = json["message"] as? String ?? message
        }

        Logger.d("Bridge error received: \(message)")
        OracleXManager.shared.notifyError(
            ErrorCode.webError.toOracleXError(detail: message)
        )
    }
}
