# cineva_flutter

Aplikasi Cineva (streaming films) — versi Flutter dari `cineva-mobile` (React Native, sudah tidak dipakai).

Butuh backend LK21 API berjalan di `localhost:8080` (folder `lk21-api`):

```
cd lk21-api
npm install
npm run build
npm start
```

## Menjalankan (emulator Android)

API key Gemini tertanam di `.env` (`GEMINI_API_KEY`, jangan di-commit). Jalankan dari PowerShell:

```powershell
$key = (Get-Content .env | Where-Object { $_ -match "^GEMINI_API_KEY=" }).Split("=",2)[1].Trim()
flutter run --dart-define=API_URL=http://10.0.2.2:8080 --dart-define=GEMINI_API_KEY=$key
```

`10.0.2.2` = alamat PC dari dalam emulator Android. Untuk HP fisik, ganti dengan IP LAN PC (mis. `http://192.168.1.5:8080`).

## Build APK

```powershell
$key = (Get-Content .env | Where-Object { $_ -match "^GEMINI_API_KEY=" }).Split("=",2)[1].Trim()
flutter build apk --debug --dart-define=API_URL=http://10.0.2.2:8080 --dart-define=GEMINI_API_KEY=$key
```

## Catatan

- `cineva-mobile/` (React Native) sudah dihapus — seluruh fitur di-port ke proyek ini.
- `.env` berisi rahasia dan tidak di-track git (lihat `.gitignore`).