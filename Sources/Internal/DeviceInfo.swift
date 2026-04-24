import Foundation
import UIKit
import AdSupport

/// SDK가 자동 수집하는 디바이스 정보
enum DeviceInfo {

    /// OS 버전 (예: "17.2.1")
    static var osVersion: String {
        UIDevice.current.systemVersion
    }

    /// 하드웨어 모델 식별자 (예: "iPhone14,5")
    static var model: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        return withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                String(cString: $0)
            }
        }
    }

    /// IDFA — ATT 미허용 또는 iOS 14+ 제한 시 zeros 반환
    static var idfa: String {
        ASIdentifierManager.shared().advertisingIdentifier.uuidString
    }
}
