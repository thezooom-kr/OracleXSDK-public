import Foundation

public struct OracleXError {
    public let code: Int
    public let message: String
    public let detail: String?

    public init(code: Int, message: String, detail: String? = nil) {
        self.code = code
        self.message = message
        self.detail = detail
    }
}
