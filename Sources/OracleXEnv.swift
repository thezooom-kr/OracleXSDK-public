import Foundation

public enum OracleXEnv {
    /// 사용자가 직접 입력한 customURL 사용
    case direct
    /// 테스트 서버 (webview.oraclink.dev)
    case staging
    /// 상용 서버 기본값 (webview.oraclink.com)
    case production
}
