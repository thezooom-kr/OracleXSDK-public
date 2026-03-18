# OracleX SDK — iOS 연동 가이드

**SDK 버전: v1.6.4** | 최소 지원: iOS 13.0

---

## 1. SDK 설치 (Swift Package Manager)

1. Xcode → **File → Add Package Dependencies**
2. URL 입력: `https://github.com/thezooom-OracleX/OracleXSDK-public`
3. Version: `v1.6.4`

---

## 2. SDK 초기화

앱 시작 시 1회 호출합니다 (`AppDelegate.didFinishLaunching` 또는 `ViewController.viewDidLoad()` 권장).

```swift
import OracleXSDK

OracleXSDK.shared.initialize(
    config: OracleXConfig(
        channelUuid: "발급받은_채널_UUID",
        channelUserId: "사용자_고유_ID",
        // env: .staging,  // 테스트 서버 사용 시 (기본값: .production)
        options: OracleXOptions(debug: false)
    )
)
```

---

## 3. 오퍼월 열기

```swift
OracleXSDK.shared.openOracleX()
```

---

## 4. 에러 처리

```swift
OracleXSDK.shared.setErrorListener { error in
    print("에러 [\(error.code)]: \(error.message)")
}
```

### 에러 코드

| 코드 | 설명 | 대응 |
|------|------|------|
| 1001 | 유효하지 않은 채널 UUID | channelUuid 확인 |
| 1002 | 유효하지 않은 사용자 ID | channelUserId 확인 (최대 128자) |
| 1003 | SDK 미초기화 | initialize() 먼저 호출 |
| 2001 | WebView 로드 실패 | 재시도 안내 |
| 3001 | 네트워크 없음 | 네트워크 확인 안내 |

---

## 5. 전체 예시

```swift
import UIKit
import OracleXSDK

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        OracleXSDK.shared.setErrorListener { error in
            print("에러 [\(error.code)]: \(error.message)")
        }

        OracleXSDK.shared.initialize(
            config: OracleXConfig(
                channelUuid: "your_channel_uuid",
                channelUserId: getCurrentUserId(),
                options: OracleXOptions(debug: true)
            )
        )
    }

    @IBAction func openOracleX(_ sender: Any) {
        OracleXSDK.shared.openOracleX()
    }
}
```

---

## 6. 앱 심사 참고사항

| 항목 | 내용 |
|------|------|
| IDFA | SDK가 자동 수집 — ATT 미허용 시 zeros 반환 |
| ATT | **매체사 앱**에서 `ATTrackingManager.requestTrackingAuthorization` 호출 필요 |
| NSUserTrackingUsageDescription | Info.plist에 추적 목적 문구 필수 |
| 표현 | "포인트", "리워드"만 사용 (현금/캐시 금지) |
| ATS | SDK는 HTTPS만 사용 (별도 설정 불필요) |
