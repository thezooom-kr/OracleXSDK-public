import Foundation

enum SdkConstants {
    static let sdkVersion = "1.6.7"
    static let platform = "IOS"
    static let bridgeName = "OracleXBridge"
    static let logTag = "OracleXSDK"
    // WebView URL (환경별)
    static let baseURLDirect     = "https://badongsch2.cafe24.com/thezooom/sample5.html"
    static let baseURLStaging    = "https://webview.oraclink.dev"
    static let baseURLProduction = "https://webview.oraclink.com"

    // 에러 리포트 EP (환경별)
    static let errorReportURLDirect     = "https://badongsch2.cafe24.com/thezooom/error-report.php"
    static let errorReportURLStaging    = "https://media-api.oraclink.dev/error-report"
    static let errorReportURLProduction = "https://media-api.oraclink.com/error-report"

    static let maxUserIdLength = 128
}
