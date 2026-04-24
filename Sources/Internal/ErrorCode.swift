import Foundation

enum ErrorCode: Int {
    case invalidAppKey = 1001
    case invalidUserId = 1002
    case sdkNotInitialized = 1003
    case sdkAlreadyInitialized = 1004
    case webviewLoadFailed = 2001
    case webviewRenderError = 2002
    case webviewSSLError = 2003
    case networkNotAvailable = 3001
    case networkTimeout = 3002
    case bridgeNotAvailable = 4001
    case bridgeMessageParseError = 4002
    case webError = 5001

    var defaultMessage: String {
        switch self {
        case .invalidAppKey: return "유효하지 않은 앱 키입니다."
        case .invalidUserId: return "유효하지 않은 사용자 ID입니다."
        case .sdkNotInitialized: return "SDK가 초기화되지 않았습니다."
        case .sdkAlreadyInitialized: return "SDK가 이미 초기화되었습니다."
        case .webviewLoadFailed: return "오퍼월 페이지를 불러올 수 없습니다."
        case .webviewRenderError: return "오퍼월 화면 표시 중 오류가 발생했습니다."
        case .webviewSSLError: return "보안 연결에 실패했습니다."
        case .networkNotAvailable: return "네트워크 연결을 확인해 주세요."
        case .networkTimeout: return "네트워크 연결 시간이 초과되었습니다."
        case .bridgeNotAvailable: return "Bridge 연결에 실패했습니다."
        case .bridgeMessageParseError: return "Bridge 메시지 처리 중 오류가 발생했습니다."
        case .webError: return "웹 오류가 발생했습니다."
        }
    }

    func toOracleXError(detail: String? = nil) -> OracleXError {
        return OracleXError(code: rawValue, message: defaultMessage, detail: detail)
    }
}
