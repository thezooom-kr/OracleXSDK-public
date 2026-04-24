import Foundation

public struct OracleXConfig {
    public let channelUuid: String
    public let channelUserId: String
    /// ADID/IDFA (선택) — 미전달 시 SDK가 자동 수집
    public let adid: String?
    public let options: OracleXOptions?
    /// 오퍼월 WebView URL (선택) — DIRECT env일 때만 적용
    public let customURL: String?
    /// 서버 환경 선택 (기본값: .production) — 미지정 시 상용 서버 자동 적용
    public let env: OracleXEnv

    public init(
        channelUuid: String,
        channelUserId: String,
        adid: String? = nil,
        options: OracleXOptions? = nil,
        customURL: String? = nil,
        env: OracleXEnv = .production
    ) {
        self.channelUuid = channelUuid
        self.channelUserId = channelUserId
        self.adid = adid
        self.options = options
        self.customURL = customURL
        self.env = env
    }
}
