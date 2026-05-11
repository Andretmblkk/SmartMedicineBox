# Sistem Routing & Navigasi

Dokumen ini menjelaskan bagaimana perpindahan antar layar (routing) ditangani dalam aplikasi Smart Medicine Tracker.

---

## 1. Jenis Routing
Aplikasi ini menggunakan **Imperative Routing standard** bawaan Flutter (`Navigator.push`, `Navigator.pop`). Proyek ini **tidak** menggunakan library declarative routing yang kompleks seperti `go_router` atau `auto_route` karena aplikasinya hanya memiliki dua halaman utama. Tidak ada pendefinisian rute di dalam parameter `routes` pada file `main.dart`.

---

## 2. Alur Navigasi

### A. Bootstrapping ke Halaman Utama
Saat aplikasi dimulai (`main.dart`), widget `MaterialApp` secara langsung menetapkan `home` ke `BerandaScreen`.
```dart
return MaterialApp(
  // ...
  home: const BerandaScreen(),
);
```

### B. Membuka Halaman Tambah Jadwal
Ketika pengguna menekan tombol *Floating Action Button* (`+`) di pojok kanan bawah `BerandaScreen`, aplikasi mendorong (`push`) halaman `TambahJadwalScreen` ke atas tumpukan navigasi (Navigation Stack).

Pemanggilan ini menggunakan teknik `await` (Asynchronous Navigation) karena `BerandaScreen` perlu menunggu balasan data (objek obat baru) jika pengguna selesai mengisi form di layar selanjutnya.
```dart
// Di dalam _BerandaScreenState
final result = await Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const TambahJadwalScreen(),
  ),
);

// Mengecek jika pengguna benar-benar mengembalikan data (bukan sekadar menekan tombol back/kembali).
if (result != null) {
  setState(() {
    todaySchedule.add(result);
  });
  _saveSchedule();
}
```

### C. Mengembalikan Data dari Form
Pada halaman `TambahJadwalScreen`, setelah pengguna selesai mengatur nama obat, waktu, dan jumlah dosis, tombol "Simpan Jadwal" ditekan. Tombol ini tidak mendorong layar baru, melainkan menghapus (`pop`) halaman formulir dari layar dan "membawa" objek tipe `Map<String, dynamic>` (JSON) kembali ke `BerandaScreen`.

```dart
// Di dalam TambahJadwalScreen
Navigator.pop(context, {
  'name': medicineName,
  'dosage': dosage,
  'time': DateFormat('HH:mm').format(selectedTime),
  'schedule': "Setiap Hari",
  'status': 'Belum',
  'type': medicineType,
});
```

---

## 3. Kelebihan dan Kekurangan Pendekatan Ini

**Kelebihan:**
* Sangat mudah dipahami oleh developer pemula.
* Tidak memerlukan *boilerplate code* (kode kerangka) atau konfigurasi *library* eksternal tambahan.

**Kekurangan (Technical Debt):**
* Jika aplikasi nanti memiliki lebih dari 10 halaman atau memerlukan fitur *Deep Linking* (membuka aplikasi via link URL), metode `MaterialPageRoute` ini akan sulit dikelola. Harus dilakukan migrasi (refactoring) ke *Named Routes* atau `go_router`.
* Argumen (parameter) dikirim secara manual, rentan terhadap error *Type Casting* jika model datanya rumit.
