# State Management & Persistence

Dokumen ini menjelaskan bagaimana status (state) dikelola selama aplikasi berjalan, dan bagaimana status tersebut disimpan secara permanen agar tidak hilang saat aplikasi ditutup.

---

## 1. Native State Management (`setState`)

Aplikasi Smart Medicine Tracker tidak menggunakan *third-party State Management* seperti BLoC, Provider, Riverpod, atau GetX. Pengelolaan status antarmuka ditangani secara eksklusif menggunakan **`StatefulWidget`** dan pemanggilan **`setState()`**.

### A. Lokasi State Utama
Pusat dari *state* aplikasi ini berada di dalam variabel-variabel lokal milik class `_BerandaScreenState` (`beranda_screen.dart`):

```dart
String userName = "Pengguna";
List<Map<String, dynamic>> todaySchedule = [];
```
Variabel `todaySchedule` menyimpan status daftar jadwal (aktif/belum), dan setiap kali isi *List* ini berubah (ditambah atau dihapus), perintah `setState()` dipanggil agar Flutter menggambar ulang (Re-build) tampilan.

### B. Mengapa Menggunakan `setState`?
Untuk aplikasi berskala kecil yang memiliki sedikit interaksi antar halaman, mem-pass data via `Navigator` dan merender ulang halaman dengan `setState()` sudah sangat cukup dan efisien. Penambahan BLoC atau Riverpod hanya akan memperpanjang waktu pengembangan (Over-engineering).

---

## 2. Local State Persistence (Penyimpanan Lokal)

Karena `setState()` bersifat *volatile* (data akan musnah di memori (RAM) jika aplikasi di-kill (ditutup paksa) dari *recent apps*), maka diperlukan media penyimpanan statis di sisi OS, yakni **`shared_preferences`**.

Package `shared_preferences` membungkus penyimpanan XML (*Android*) atau NSUserDefaults (*iOS*) dalam format *Key-Value pair* asinkronus.

### A. Alur Membaca Data (Load)
Saat `BerandaScreen` pertama kali dimuat (`initState`), ia akan memanggil fungsi `_loadUserData()` dan `_loadSchedule()`:
1. Membaca `String` JSON dari memori perangkat (Kunci: `'schedule'`).
2. Melakukan proses *Decoding* (`jsonDecode`) dari String teks mentah menjadi objek `List<dynamic>`.
3. Memasukkannya ke dalam variabel `todaySchedule` dan menjalankan `setState`.

### B. Alur Menyimpan Data (Save)
Fungsi vital ini berada di `_saveSchedule()`. Fungsi ini dipicu **setiap kali** terjadi modifikasi array (Tambah obat / Hapus obat).
1. `jsonEncode` mengubah objek `List` di RAM menjadi tipe String murni.
2. `prefs.setString('schedule', stringTersebut)` menyimpannya secara permanen ke memori ponsel.
3. Fungsi ini secara otomatis juga merangkap tugasnya untuk mengirim salinan list tersebut ke **Firebase** via layanan eksternal.

---

## 3. Batasan / Utang Teknis (Technical Debt)

Manajemen state seperti ini rentan terhadap beberapa isu jika skalanya diperbesar:
1. **Pemisahan Logika (Separation of Concern):** Proses decoding, pengolahan JSON, sinkronisasi Cloud, dan fungsi re-render UI (`setState`) menumpuk pada satu file/class yang sama (`beranda_screen.dart`), menjadikannya rentan sebagai *God Object* (lebih dari 500 baris kode untuk satu layar).
2. **Performa:** Merender ulang **seluruh** `BerandaScreen` dengan `setState` hanya untuk merubah satu status di kartu jadwal (misal: tombol status dari 'Belum' menjadi 'Sudah') kurang efisien. Penggunaan state lokal di level komponen (`StatefulWidget` terpisah khusus untuk tombol) atau library pendukung (seperti *ValueNotifier*) akan lebih menghemat *frame render*.
