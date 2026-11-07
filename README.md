# DevCurl AI Studio — Native iOS Mobile Client

Aplikasi mobile iOS native (Swift + UIKit) untuk iPhone & iPad yang memungkinkan **Pak cURLdev** mengobrol via suara (Voice Call layaknya menelepon orang lain), berkonsultasi, dan mengendalikan server Linux serta seluruh agen otonom Hermes langsung dari genggaman.

---

## Fitur Utama
- **Interactive Voice Call Mode**: Mode obrolan suara dua arah interaktif real-time layaknya panggilan telepon menggunakan native Apple `SFSpeechRecognizer` & `AVSpeechSynthesizer`.
- **Direct Voice Dictation**: Dikte suara cepat langsung ke kotak pesan via tombol mikrofon.
- **In-App Server Settings**: Konfigurasikan endpoint URL server Hermes dan API Bearer token langsung dari menu setelan aplikasi tanpa perlu recompile.
- **Native iOS UIKit Lifecycle**: Berjalan dengan `UIApplicationMain` & `SceneDelegate` standar Apple (ringan, responsif, dan hemat baterai).
- **Multi-Agent Channel**: Pilih spesialis Hermes langsung (Hermes Orchestrator, Ubuntu Admin, Video Producer, Marketing Strategist, dll.).
- **Sideload Ready**: Dirancang khusus untuk ditandatangani (*sign*) menggunakan aplikasi seperti **ESign**, **Scarlet**, **AltStore**, atau **Sideloadly** dengan sertifikat iOS pribadi Anda (`.p12` & `.mobileprovision`).
- **Automated GitHub Actions CI/CD**: Setiap push ke repository ini otomatis memicu mesin Mac asli (`macos-14`) di GitHub untuk meracik file `DevCurlAI.ipa` resmi.

---

## Cara Download & Sideload ke iPhone

1. Buka tab **[Releases](https://github.com/curls1337/devcurl-ios-app/releases)** di repository ini.
2. Unduh file **`DevCurlAI.ipa`** versi terbaru ke iPhone Anda.
3. Buka file `.ipa` tersebut di **ESign** (atau Scarlet / AltStore):
   - Pilih sertifikat `.p12` & `.mobileprovision` pribadi Anda.
   - Tekan **[ Sign ]**.
   - Tekan **[ Install ]**.
4. Buka aplikasi **DevCurl AI** di Homescreen iPhone Anda.
5. Tekan ikon **Gerigi (Settings)** di pojok kanan atas untuk memasukkan URL server Hermes Anda, atau langsung tekan ikon **Gelombang Suara / Waveform** untuk mulai Voice Call!
