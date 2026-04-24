import Foundation

enum Logger {

    private static var isDebug: Bool {
        return OracleXManager.shared.isDebugMode
    }

    static func d(_ message: String) {
        guard isDebug else { return }
        print("[\(SdkConstants.logTag)][DEBUG] \(message)")
    }

    static func i(_ message: String) {
        guard isDebug else { return }
        print("[\(SdkConstants.logTag)][INFO] \(message)")
    }

    static func w(_ message: String) {
        guard isDebug else { return }
        print("[\(SdkConstants.logTag)][WARN] \(message)")
    }

    static func e(_ message: String) {
        print("[\(SdkConstants.logTag)][ERROR] \(message)")
    }
}
