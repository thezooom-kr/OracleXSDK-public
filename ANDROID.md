# OracleX SDK — Android 연동 가이드

**SDK 버전: v1.6.3** | 최소 지원: API 21 (Android 5.0)

---

## 1. SDK 설치

[GitHub Releases](https://github.com/thezooom-OracleX/OracleXSDK-public/releases/latest)에서 `OracleXSDK.aar` 다운로드 후 `app/libs/`에 복사합니다.

```kotlin
// build.gradle.kts (app 모듈)
dependencies {
    implementation(files("libs/OracleXSDK.aar"))
    implementation("androidx.appcompat:appcompat:1.6.1")
    implementation("androidx.browser:browser:1.7.0")
    implementation("com.google.android.gms:play-services-ads-identifier:18.0.1")
}
```

### AndroidManifest.xml 권한 추가

```xml
<uses-permission android:name="android.permission.INTERNET" />
<!-- Android 13+ ADID 수집 권한 -->
<uses-permission android:name="com.google.android.gms.permission.AD_ID" />
```

---

## 2. SDK 초기화

앱 시작 시 1회 호출합니다 (`Application.onCreate()` 또는 `Activity.onCreate()` 권장).

```kotlin
import com.oraclex.sdk.OracleXSDK
import com.oraclex.sdk.OracleXConfig
import com.oraclex.sdk.OracleXOptions

OracleXSDK.init(
    context = this,
    config = OracleXConfig(
        channelUuid = "발급받은_채널_UUID",
        channelUserId = "사용자_고유_ID",
        // env = OracleXEnv.STAGING, // 테스트 서버 사용 시 (기본값: PRODUCTION)
        options = OracleXOptions(debug = false)
    )
)
```

---

## 3. 오퍼월 열기

```kotlin
OracleXSDK.openOracleX()
```

---

## 4. 에러 처리

```kotlin
OracleXSDK.setErrorListener { error ->
    Log.e("OracleX", "에러 [${error.code}]: ${error.message}")
}
```

### 에러 코드

| 코드 | 설명 | 대응 |
|------|------|------|
| 1001 | 유효하지 않은 채널 UUID | channelUuid 확인 |
| 1002 | 유효하지 않은 사용자 ID | channelUserId 확인 (최대 128자) |
| 1003 | SDK 미초기화 | init() 먼저 호출 |
| 2001 | WebView 로드 실패 | 재시도 안내 |
| 3001 | 네트워크 없음 | 네트워크 확인 안내 |

---

## 5. 전체 예시

```kotlin
class MainActivity : AppCompatActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        OracleXSDK.setErrorListener { error ->
            Log.e("OracleX", "에러 [${error.code}]: ${error.message}")
        }

        OracleXSDK.init(
            context = this,
            config = OracleXConfig(
                channelUuid = "your_channel_uuid",
                channelUserId = getCurrentUserId(),
                options = OracleXOptions(debug = BuildConfig.DEBUG)
            )
        )

        findViewById<Button>(R.id.btnOracleX).setOnClickListener {
            OracleXSDK.openOracleX()
        }
    }
}
```

---

## 6. ProGuard

SDK의 `consumer-rules.pro`가 자동 적용됩니다. **별도 설정 불필요**.
