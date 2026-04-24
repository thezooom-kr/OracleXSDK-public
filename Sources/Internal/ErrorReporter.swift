import Foundation

internal enum ErrorReporter {

    /// 에러 발생 시 OracleX 서버로 자동 리포팅 (fire-and-forget)
    static func report(_ error: OracleXError) {
        guard let channelUuid = OracleXManager.shared.config?.channelUuid else { return }  // 초기화 전 에러는 미전송
        guard let url = URL(string: OracleXManager.shared.effectiveErrorURL()) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 5

        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "channelUuid",      value: channelUuid),
            URLQueryItem(name: "errorCode",        value: "\(error.code)"),
            URLQueryItem(name: "errorDetail",      value: error.detail ?? ""),
            URLQueryItem(name: "sdkVersion",       value: SdkConstants.sdkVersion),
            URLQueryItem(name: "deviceOs",         value: SdkConstants.platform),
            URLQueryItem(name: "deviceOsVersion",  value: DeviceInfo.osVersion),
            URLQueryItem(name: "deviceModel",      value: DeviceInfo.model),
            URLQueryItem(name: "timestamp",        value: "\(Int(Date().timeIntervalSince1970))"),
        ]
        request.httpBody = components.query?.data(using: .utf8)

        URLSession.shared.dataTask(with: request) { _, response, taskError in
            if let taskError = taskError {
                Logger.d("Error report failed: \(taskError.localizedDescription)")
            } else if let httpResponse = response as? HTTPURLResponse {
                Logger.d("Error reported: code=\(error.code), response=\(httpResponse.statusCode)")
            }
        }.resume()
    }
}
