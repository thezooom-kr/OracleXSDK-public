import UIKit
import WebKit

class OracleXWebViewController: UIViewController {

    var webView: WKWebView!
    private var activityIndicator: UIActivityIndicatorView!
    private let bridgeHandler = OracleXBridgeHandler()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        OracleXManager.shared.activeViewController = self

        setupWebView()
        setupActivityIndicator()

        guard NetworkUtil.isNetworkAvailable else {
            Logger.e(ErrorCode.networkNotAvailable.defaultMessage)
            OracleXManager.shared.notifyError(ErrorCode.networkNotAvailable.toOracleXError())
            activityIndicator.stopAnimating()
            return
        }

        guard let request = OracleXManager.shared.buildOracleXRequest() else {
            Logger.e("Invalid oraclex URL")
            return
        }

        Logger.d("Loading URL (POST): \(request.url?.absoluteString ?? "")")
        webView.load(request)
    }

    private func setupWebView() {
        let contentController = WKUserContentController()
        contentController.add(bridgeHandler, name: SdkConstants.bridgeName)

        // JS 래퍼 주입 (Android 호환 Bridge)
        let bridgeJS = OracleXManager.shared.buildBridgeWrapperJS()
        let bridgeScript = WKUserScript(
            source: bridgeJS,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: true
        )
        contentController.addUserScript(bridgeScript)

        let config = WKWebViewConfiguration()
        config.userContentController = contentController

        webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        webView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(webView)
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupActivityIndicator() {
        activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.hidesWhenStopped = true
        view.addSubview(activityIndicator)

        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        activityIndicator.startAnimating()
    }

    deinit {
        webView?.configuration.userContentController.removeScriptMessageHandler(
            forName: SdkConstants.bridgeName
        )
        OracleXManager.shared.activeViewController = nil
    }
}

// MARK: - WKNavigationDelegate

extension OracleXWebViewController: WKNavigationDelegate {

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }

        let scheme = url.scheme ?? ""

        // non-http schemes → system handler
        if scheme != "http" && scheme != "https" {
            OracleXManager.shared.openExternalURL(url.absoluteString)
            decisionHandler(.cancel)
            return
        }

        // external domain → In-App Browser (SFSafariViewController)
        if !OracleXManager.shared.isInternalURL(url) {
            OracleXManager.shared.openExternalURL(url.absoluteString)
            decisionHandler(.cancel)
            return
        }

        // internal domain → WebView에서 로드
        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        activityIndicator.startAnimating()
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        activityIndicator.stopAnimating()

        // 내부 도메인일 때만 NativeData 주입
        if let url = webView.url, OracleXManager.shared.isInternalURL(url) {
            let js = OracleXManager.shared.buildNativeDataJS()
            if !js.isEmpty {
                webView.evaluateJavaScript(js) { _, error in
                    if let error = error {
                        Logger.w("NativeData injection failed: \(error.localizedDescription)")
                    } else {
                        Logger.d("NativeData injected")
                    }
                }
            }
        }
    }

    func webView(
        _ webView: WKWebView,
        didFail navigation: WKNavigation!,
        withError error: Error
    ) {
        activityIndicator.stopAnimating()
        Logger.e("WebView load error: \(error.localizedDescription)")
        OracleXManager.shared.notifyError(
            ErrorCode.webviewLoadFailed.toOracleXError(detail: error.localizedDescription)
        )
    }

    func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation!,
        withError error: Error
    ) {
        activityIndicator.stopAnimating()
        Logger.e("WebView provisional navigation error: \(error.localizedDescription)")
        OracleXManager.shared.notifyError(
            ErrorCode.webviewLoadFailed.toOracleXError(detail: error.localizedDescription)
        )
    }

    func webView(
        _ webView: WKWebView,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        // iOS 기본 인증서 검증에 위임 — 잘못된/만료된 인증서는 시스템이 거부
        completionHandler(.performDefaultHandling, nil)
    }
}

