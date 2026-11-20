# cineva_flutter

Aplikasi Cineva (streaming films) — versi Flutter dari `cineva-mobile` (React Native, sudah tidak dipakai).

Butuh backend LK21 API berjalan di `localhost:8080` (folder `lk21-api`):

```
cd lk21-api
npm install
npm run build
npm start
```

## Setup Supabase Auth

Login, register, dan sesi pengguna memakai Supabase Auth. Password tidak pernah disimpan di tabel aplikasi.

1. Buat project di [Supabase](https://supabase.com/dashboard).
2. Buka **SQL Editor**, lalu jalankan file:
   `supabase/migrations/20261030000000_create_profiles.sql`
3. Salin `.env.example` menjadi `.env`, lalu isi:
   - `SUPABASE_URL` — Project URL
   - `SUPABASE_PUBLISHABLE_KEY` — publishable key (atau `SUPABASE_ANON_KEY` untuk project lama)
   - `GEMINI_API_KEY` — key untuk tab AI
4. Untuk login langsung setelah register, buka **Authentication → Providers → Email** dan nonaktifkan **Confirm email**. Jika fitur konfirmasi email tetap aktif, pengguna harus membuka link konfirmasi dari inbox sebelum bisa login.

Migration tersebut membuat tabel `public.profiles`, trigger profil otomatis setelah signup, dan RLS agar pengguna hanya bisa membaca/mengubah profilnya sendiri.

## Menjalankan (emulator Android)

Jalankan dari PowerShell:

```powershell
flutter run --dart-define-from-file=.env --dart-define=API_URL=http://10.0.2.2:8080
```

`10.0.2.2` = alamat PC dari dalam emulator Android. Untuk HP fisik, ganti dengan IP LAN PC (mis. `http://192.168.1.5:8080`). HP dan PC harus berada di jaringan Wi-Fi yang sama.

## Menjalankan (HP fisik via USB)

Pastikan USB debugging aktif dan HP terdeteksi oleh `flutter devices`, lalu:

```powershell
flutter run -d <device-id> --dart-define-from-file=.env --dart-define=API_URL=http://<IP-LAN-PC>:8080
```

## Build APK

```powershell
flutter build apk --debug --dart-define-from-file=.env --dart-define=API_URL=http://10.0.2.2:8080
```

## Catatan

- `cineva-mobile/` (React Native) sudah dihapus — seluruh fitur di-port ke proyek ini.
- `.env` berisi rahasia dan tidak di-track git (lihat `.gitignore`). Jangan pernah memakai service-role/secret key Supabase di aplikasi Flutter.
- Bookmark, riwayat tontonan, dan chat AI masih disimpan secara lokal di perangkat. Yang terhubung ke Supabase saat ini adalah akun, sesi login, dan profil pengguna.
