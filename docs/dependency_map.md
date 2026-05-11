# Peta Dependensi (Dependency Map)

Dokumen ini memetakan relasi antara komponen UI (Visual), proses Service (Backend/OS), dan pustaka pihak ketiga (Packages) dalam bentuk diagram alir dependensi.

---

## 1. Peta Ketergantungan Paket (Package Dependencies Map)

Diagram berikut menunjukkan package `pubspec.yaml` utama mana yang menyokong layar tertentu.

```mermaid
graph TD
    A[main.dart]
    
    %% Bagian Dependencies UI
    A --> UI[UI / Theme Layer]
    UI -->|google_fonts| Font[Google Fonts]
    UI -->|lottie| Anim[Animasi Vector]
    UI -->|cupertino_icons| Icon[Icons iOS/Apple]
    
    %% Bagian Backend & Service
    A --> SV[Services Layer]
    SV -->|firebase_core| FBC[Firebase Initialization]
    SV -->|firebase_database| FBD[Firebase Realtime DB]
    
    %% Bagian OS Integration
    SV -->|flutter_local_notifications| NOTIF[Notifikasi OS Native]
    SV -->|flutter_timezone & timezone| TZ[Konversi Zona Waktu]
    
    %% Bagian Persistence
    A --> DB[Data Layer]
    DB -->|shared_preferences| LDB[Penyimpanan Lokal/Cache]
```

---

## 2. Peta Dependensi Logika Aplikasi (Internal Structure)

Visualisasi bagaimana logika antar file berjalan ketika pengguna menambah jadwal obat (Flow of Control):

```mermaid
sequenceDiagram
    participant User
    participant App as TambahJadwalScreen
    participant Notification as NotificationService
    participant Beranda as BerandaScreen
    participant DB as SharedPreferences
    participant Firebase as FirebaseScheduleService

    User->>App: Input (Nama, Waktu, Dosis)
    App->>Notification: scheduleDailyNotification(ID, Nama, Waktu)
    Notification-->>App: Alarm Terdaftar di OS
    App-->>Beranda: Mengembalikan Data Objek (JSON Map)
    Beranda->>Beranda: Menambah Objek ke array 'todaySchedule'
    Beranda->>Beranda: Memanggil _saveSchedule()
    Beranda->>DB: Menyimpan String Cache
    Beranda->>Firebase: saveSchedule(todaySchedule)
    Firebase-->>Beranda: Berhasil Terunggah (Cloud)
```

---

## 3. Komponen Silang (Cross-cutting Concerns)

Dalam arsitektur software, ada elemen yang memotong secara diagonal ke seluruh struktur aplikasi:

1.  **State Re-rendering (`setState`):** Tidak digambarkan sebagai dependensi spesifik file, namun merambat ke seluruh _Screen_. Jika sebuah input diubah di satu _Screen_, _Screen_ tersebut langsung memanggil render ulang.
2.  **Singleton Pattern (Instance global):**
    *   File `notification_service.dart` menggunakan `NotificationService.instance`.
    *   File `firebase_schedule_service.dart` menggunakan `FirebaseScheduleService.instance`.
    Hal ini memungkinkan komponen UI apa saja (`BerandaScreen` maupun `TambahJadwalScreen`) dapat langsung mengeksekusi layanan eksternal tersebut dari memori yang sama tanpa perlu mendeklarasikan objek `new` (atau inisialisasi awal) berkali-kali di setiap layar yang dapat membuang *RAM* dan membuat bocor memori (*memory leak*).
