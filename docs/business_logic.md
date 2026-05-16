# Logika Bisnis (Business Logic)

Dokumen ini adalah rekam jejak cara berpikir sistem secara *step-by-step* terhadap aturan dasar yang menyelimuti (business logic) proyek Smart Medicine Tracker.

---

## 1. Pembuatan ID Notifikasi (Unique ID Generation)

Saat mendaftarkan sebuah alarm ke Sistem Operasi, `flutter_local_notifications` memerlukan sebuah bilangan bulat positif (Integer) yang bertindak sebagai ID atau pengenal unik.

*   **Pentingnya ID:** Jika ada dua alarm obat yang berbeda tetapi dikirim menggunakan ID `0` yang sama, OS Android akan menganggapnya pembaruan dari satu alarm yang sama. Akibatnya, alarm lama akan tertimpa dan terhapus.
*   **Implementasi:** Di dalam `TambahJadwalScreen`, setiap kali pengguna selesai menyetel alarm dan menekan tombol simpan, kode memanggil utilitas acak (Randomize) bawaan dari pustaka `dart:math`:
```dart
int notificationId = math.Random().nextInt(100000);
```
Dengan merandom angka hingga 100 ribu, probabilitas (peluang) dua jadwal memiliki ID notifikasi yang bertabrakan akan menjadi sangat kecil (hampir nol untuk kasus penggunaan personal).

---

## 2. Kalkulasi Zona Waktu (Timezone Handling)

Mengatur alarm pada jam 08:00 terkesan mudah, tetapi OS di dalamnya memegang waktu dengan *Unix Epoch Timestamp* (berbasis UTC).

*   Oleh sebab itu, `NotificationService` memanggil pustaka `timezone`.
*   Aplikasi mendeteksi lokasi geografis pengguna melalui `flutter_timezone.getLocalTimezone()`, misalnya `Asia/Jakarta`.
*   Jadwal yang tadinya bertipe `TimeOfDay` lokal akan disuntikkan ke kalender OS dengan parameter lokal. 
```dart
// Logika yang mengubah waktu menjadi UTC untuk AlarmManager
tz.TZDateTime.local(now.year, now.month, now.day, hour, minute);
```
*   **Kasus Edge:** Apabila pengguna membuat jadwal jam "08:00 Pagi", namun saat dia memprogram alarm tersebut jarum jam dunia nyata sudah menunjuk ke "09:00 Pagi", jika tidak dikendalikan, alarm akan *error* / menolak dieksekusi (karena waktunya telah lewat). Maka, modul `NotificationService` secara otomatis akan melompatkan (shift) hari penjadwalan menjadi jam 08:00 di *keesokan harinya* (besok).

---

## 3. Logika Penghapusan Item Obat (Cancellation)

Fitur penghapusan terikat di `_BerandaScreenState` pada metode `_removeMedicine`.
1.  **Dihapus dari Tampilan Visual:** Metode memanggil array list dari memori, men-`removeAt(index)` item tersebut, lalu menyuruh UI me-render ulang dengan `setState`. (Kartu akan hilang).
2.  **Dihapus dari Storage Lokal:** Secara otomatis tersambung ke `_saveSchedule()`, list terbaru (yang sudah berkurang satu itemnya) akan dikonversi menjadi JSON String lalu menimpa versi usang di `SharedPreferences`.
3.  **Dihapus dari Cloud IoT:** JSON terbaru tersebut langsung diteruskan (forward) menimpa struktur pohon Firebase di `jadwal_obat`. Saat kotak ESP32 V3 mengecek firebase beberapa detik kemudian, kotak tersebut sudah tidak akan menemukan data jadwal yang baru saja dihapus.
4.  **Kelemahan (Technical Debt):** Pada versi ini, sistem *belum* memanggil fungsi pembatalan OS dari `NotificationService` (`flutterLocalNotificationsPlugin.cancel(id)`). ID tidak dapat dibatalkan karena tidak disimpan di array database. Oleh karena itu, notifikasi di HP tetap bisa berbunyi di masa depan meskipun jadwal visual telah dihapus.

---

## 4. Logika Perubahan Status Obat

Obat dapat memiliki status seperti "Belum Diminum" atau "Sudah Diminum".
*   Pada proyek saat ini, visual indikator `status` diatur pada saat data obat dibuat dengan format default ("Belum"). 
*   Progress bar `AdherenceRing` (Lingkaran Kepatuhan) di dalam struktur belum dihubungkan dengan komputasi dinamis dari list database. Ini menyisakan ruang bagi developer selanjutnya untuk melengkapi logika interaksi dengan membuat variabel hitung `sudah / total * 100%`.

