# DevCurl AI Studio — Native iOS Mobile Client

Aplikasi mobile iOS native (Swift + UIKit + WebKit) untuk iPhone & iPad yang memungkinkan **Pak cURLdev** mengobrol, berkonsultasi, dan mengendalikan server Linux serta seluruh 12 agen otonom Hermes langsung dari genggaman.

---

## Fitur Utama
- **Native iOS UIKit Lifecycle**: Berjalan dengan `UIApplicationMain` & `SceneDelegate` standar Apple (dijamin **tidak akan pernah mental/force-close**).
- **Direct Multi-Agent Channel**: Mengobrol langsung dengan **Ubuntu Admin**, **Product Manager**, **UI/UX Designer**, **Frontend Dev**, dan agen lainnya.
- **Sideload Ready**: Dirancang khusus untuk ditandatangani (*sign*) menggunakan aplikasi seperti **ESign**, **Sideloadly**, **AltStore**, atau **Scarlet** dengan sertifikat pengembang pribadi Anda.
- **Automated GitHub Actions CI/CD**: Setiap push ke repository ini otomatis memicu mesin Mac asli (`macos-14`) di GitHub untuk meracik file `DevCurlAI.ipa` resmi.

---

## Cara Download & Sideload ke iPhone

1. Buka tab **[Releases](https://github.com/curls1337/devcurl-ios-app/releases)** di repository ini.
2. Unduh file **`DevCurlAI.ipa`** terbaru langsung ke iPhone Anda.
3. Buka file `.ipa` tersebut di **ESign**:
   - Pilih sertifikat `.p12` & `.mobileprovision` Anda.
   - Tekan **[ Sign ]**.
   - Tekan **[ Install ]**.
4. Buka aplikasi **DevCurl AI** di Homescreen iPhone Anda!
