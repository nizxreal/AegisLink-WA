# WA Node Auth App

Aplikasi Flutter untuk Android dengan integrasi Google Login, aktivasi Token (1 token = 1 akun Google + WhatsApp), dan panel admin untuk manajemen token.

## Ringkasan
- Frontend (Flutter): Login Google, masukkan token, menu utama (pair/start Node WhatsApp), dashboard admin di dalam app (PC).
- Backend (Node.js + SQLite): validasi token, binding, manajemen admin via API lokal/eksternal.

## Build & Run di Android

### 1️⃣ Di PC (rekomendasi untuk rilis)

#### Backend (Node.js)
```bash
cd backend
npm install
node server.js
```
Expose dengan ngrok (`ngrok http 3000`) untuk akses internet.

#### Frontend (Flutter)
```bash
cd frontend
flutter clean
flutter pub get
flutter build apk --release
```
APK jadi di `frontend/build/app/outputs/flutter-apk/app-release.apk`. Upload ke GitHub Releases.

### 2️⃣ Di HP (Android) — opsional (debug/cepat)

#### Backend di Termux
```bash
apt update && apt install -y npm
cd /sdcard/wa_auth_app/backend
npm install
node server.js
```

#### Frontend (Flutter) di HP (emulator/physical device)
```bash
cd /sdcard/wa_auth_app/frontend
flutter clean
flutter pub get
flutter run --debug
```

### 3️⃣ Instal & Jalankan di HP
Transfer `app-release.apk` ke HP → Instal (izinkan instalasi dari sumber tidak dikenal) → Buka.

### 4️⃣ Admin Panel (PC)
Buka `http://localhost:3000/api/admin/tokens` (atau ngrok HTTPS) untuk:

- `POST /api/admin/tokens` → buat token baru.
- `GET /api/admin/tokens` → list token (terikat/bebas).
- `DELETE /api/admin/tokens/:token` → hapus token.

## Cara Download APK di GitHub

1. Buka repo GitHub (`wa-auth-app`).
2. Buka **Releases** tab.
3. Download file `app-release.apk` dari rilis terbaru (atau rilis manual).
4. Instal di HP Android (izinkan instalasi dari sumber tidak dikenal).

## Cara Upload APK ke GitHub Releases (di PC)

```bash
cd /d/Arfalindo/wa_auth_app
# Push repo (origin sudah diatur)
git add -A
git commit -m "Upload APK release"
git push origin main
# Di GitHub UI, buat rilis baru / edit rilis, upload frontend/build/app/outputs/flutter-apk/app-release.apk
```


## File Utama

- `backend/server.js`: Express API + SQLite token.
- `backend/package.json`: dependensi.
- `frontend/lib/main.dart`: Flutter UI (Login Google → Screen Token → Menu Utama → Admin Screen).
- `frontend/pubspec.yaml`: Flutter dependencies.
- `frontend/README.md`: (opsional) penjelasan build per-platform.
- `.gitignore`: token.db, APK, IDE artifacts.

## Fitur Android Utama
- Google Sign-In (OAuth lokal di HP).
- SharedPreferences untuk session token.
- Material Design UI (dark navy + orange).
- Komponen admin di dalam app untuk mengoperasikan backend dari PC.

## Catatan
- Token unik untuk satu orang, satu akun Google, satu session WA.
- Pairing WA: saat ini placeholder (notifikasi). Implementasikan server WhatsApp lokal (Node Baileys / Termux) di backend.
- Semua state disimpan di HP (offline-first). Backend opsional, hanya digunakan untuk validasi token.

