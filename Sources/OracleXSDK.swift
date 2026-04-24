import Foundation

public final class OracleXSDK {

    public static let shared = OracleXSDK()
    public static var version: String { SdkConstants.sdkVersion }

    /// 환경별 기본 WebView URL 반환 (샘플앱 UI에서 URL 필드 초기값 세팅용)
    public static func baseURL(for env: OracleXEnv) -> String {
        switch env {
        case .staging:    return SdkConstants.baseURLStaging
        case .direct:     return SdkConstants.baseURLDirect
        case .production: return SdkConstants.baseURLProduction
        }
    }

    private let manager = OracleXManager.shared

    private init() {}

    public func initialize(config: OracleXConfig) {
        if config.channelUuid.trimmingCharacters(in: .whitespaces).isEmpty {
            let error = ErrorCode.invalidAppKey.toOracleXError()
            Logger.e(error.message)
            manager.notifyError(error)
            return
        }

        if config.channelUserId.trimmingCharacters(in: .whitespaces).isEmpty {
            let error = ErrorCode.invalidUserId.toOracleXError()
            Logger.e(error.message)
            manager.notifyError(error)
            return
        }

        if config.channelUserId.count > SdkConstants.maxUserIdLength {
            let error = ErrorCode.invalidUserId.toOracleXError(
                detail: "channelUserId must be \(SdkConstants.maxUserIdLength) characters or less"
            )
            Logger.e(error.message)
            manager.notifyError(error)
            return
        }

        if manager.isInitialized {
            Logger.w(ErrorCode.sdkAlreadyInitialized.defaultMessage)
            return
        }

        manager.initialize(config: config)
        let maskedUuid = String(config.channelUuid.prefix(6)) + "***"
        let maskedUserId = String(config.channelUserId.prefix(3)) + "***"
        Logger.i("init completed - channelUuid: \(maskedUuid), channelUserId: \(maskedUserId)")
    }

    public func openOracleX() {
        guard manager.isInitialized else {
            let error = ErrorCode.sdkNotInitialized.toOracleXError()
            Logger.e(error.message)
            manager.notifyError(error)
            return
        }

        manager.openOracleX()
    }

    public func setErrorListener(_ listener: @escaping (OracleXError) -> Void) {
        manager.setErrorListener(listener)
    }

    public func close() {
        manager.closeOracleX()
    }

    public func campaignDrawerClose() {
        manager.campaignDrawerClose()
    }

    public func reset() {
        manager.reset()
    }
}
