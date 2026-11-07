# Nik AI — Pure Native Voice Assistant (iOS)

Aplikasi mobile iOS 100% native (Pure Voice-Only, tanpa chat bubble biasa) yang terhubung langsung ke domain **`https://nik.5nod.com`** (Hermes AI Orchestrator). 

Nik beroperasi layaknya asisten suara manusia atau Siri/ChatGPT Voice mode: cukup katakan **"Hai Nik"** atau sentuh bola neural di layar untuk mulai mengobrol dan mengendalikan server, otomasi WhatsApp, Telegram, video Remotion, dan tugas lainnya.

---

## Fitur Utama v2.0
- **Pure Voice Experience (Zero Chat Bloat)**: Tidak ada kolom teks atau chat bubble. Antarmuka full-screen OLED murni dengan Dynamic Glowing Neural Orb yang bereaksi secara real-time terhadap intensitas suara Anda.
- **Wake Word Detection ("Hai Nik")**: Mendengarkan kata sandi aktivasi *"Hai Nik"* / *"Hey Nik"* / *"Nik"* secara otomatis untuk mengaktifkan sesi bicara.
- **Acoustic Haptics & Chimes**: Dilengkapi feedback haptic Apple Taptic Engine dan subtle audio chime saat mendengarkan dan merespons.
- **Direct Domain Integration**: Terhubung otomatis ke **`https://nik.5nod.com`** via Cloudflare & SSL Let's Encrypt tanpa perlu setting IP manual.
- **Sideload Ready**: Dirancang khusus untuk ditandatangani (*sign*) dengan sertifikat pribadi Anda (`.p12` & `.mobileprovision`) melalui **ESign**, **Scarlet**, **AltStore**, atau **Sideloadly**.
- **Automated CI/CD**: Kompilasi `.ipa` otomatis menggunakan runner macOS terbaru di GitHub Actions.

---

## Cara Pasang di iPhone

1. Buka tab **[Releases](https://github.com/curls1337/devcurl-ios-app/releases)**.
2. Unduh file **`DevCurlAI.ipa`** (Nik AI) versi terbaru ke iPhone Anda.
3. Buka file `.ipa` di **ESign** atau aplikasi signer pilihan Anda.
4. Sign dengan sertifikat iOS pribadi Anda, lalu tap **Install**.
5. Buka **Nik AI** di Homescreen iPhone, berikan izin mikrofon & speech saat pertama kali dibuka.
6. Cukup panggil **"Hai Nik"** atau sentuh bola di layar untuk mulai berbicara!
