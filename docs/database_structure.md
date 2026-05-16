# Struktur Database dan Penyimpanan

Aplikasi Smart Medicine Tracker menggunakan dua pilar penyimpanan utama: *SharedPreferences* (Lokal) dan *Firebase Realtime Database* (Cloud/IoT). Keduanya menggunakan representasi string JSON yang persis sama untuk mempermudah sinkronisasi.

---

## 1. Penyimpanan Lokal (SharedPreferences)

Digunakan untuk menyimpan preferensi pengguna agar tidak hilang saat HP di-_restart_ atau aplikasi ditutup. Tersimpan dalam bentuk arsip internal XML / *plists* di dalam memori internal aplikasi Android/iOS.

### A. Kunci: `userName`
*   **Tipe Data:** `String`
*   **Fungsi:** Menyimpan nama panggilan pengguna yang dimasukkan saat pop-up "Selamat Datang" pertama kali muncul.
*   **Contoh Nilai:** `"Budi Santoso"`

### B. Kunci: `schedule`
*   **Tipe Data:** `String` (hasil dari `jsonEncode(List<Map>)`)
*   **Fungsi:** Menyimpan seluruh daftar obat yang telah diinput pengguna dan belum dihapus.
*   **Contoh Nilai (String JSON mentah):**
```json
[
  {
    "name": "Paracetamol",
    "dosage": "500mg",
    "time": "08:30",
    "schedule": "Setiap Hari",
    "status": "Belum",
    "type": "Tablet"
  },
  {
    "name": "Amoxicillin",
    "dosage": "1 Kapsul",
    "time": "14:00",
    "schedule": "Setiap Hari",
    "status": "Sudah",
    "type": "Kapsul"
  }
]
```

---

## 2. Penyimpanan Cloud (Firebase Realtime Database)

Berbasis JSON Tree murni. Realtime Database Firebase hanya memiliki format seperti folder dan file objek besar (mirip struktur pohon NoSQL).

### A. Node/Direktori: `jadwal_obat`
*   **Lokasi Path:** `https://[PROJECT-ID].firebaseio.com/jadwal_obat`
*   **Fungsi:** Menyediakan titik akses (*Endpoint*) statis untuk perangkat ESP32 V3 agar bisa langsung menarik (*fetch*) satu gumpalan *array* (daftar) berisi jam berapa saja kotak obat harus bereaksi.
*   **Mekanisme Timpa (Overwrite):** Setiap kali terjadi penambahan atau pengurangan obat dari aplikasi, aplikasi Flutter akan menembakkan data list seluruhnya yang baru ke *path* ini, sehingga secara otomatis Firebase akan menimpa seluruh node.
*   **Struktur Pohon (JSON Tree Representation):**
```json
{
  "jadwal_obat": [
    {
      "dosage": "500mg",
      "name": "Paracetamol",
      "schedule": "Setiap Hari",
      "status": "Belum",
      "time": "08:30",
      "type": "Tablet"
    },
    {
      "dosage": "1 Kapsul",
      "name": "Amoxicillin",
      "schedule": "Setiap Hari",
      "status": "Sudah",
      "time": "14:00",
      "type": "Kapsul"
    }
  ]
}
```

---

## 3. Integrasi Penggunaan (*Payload untuk IoT*)

Bagi developer *hardware* (Arduino/C++), Anda hanya perlu melakukan permintaan data (`GET` HTTP atau menggunakan library Firebase ESP32 V3) ke direktori `jadwal_obat`. Selanjutnya, parser C++ JSON (`ArduinoJson`) cukup melakukan iterasi (perulangan) pada Array tersebut, dan mengekstrak nilai atribut **`time`** (misal: `"08:30"`).

**Logika IoT:** Jika variabel `time` dari Firebase cocok dengan modul *Real Time Clock (RTC)* di mikrokontroler, perintah aktuator (Servo bergerak membuka kotak) akan diaktifkan. Atribut lain seperti `"name"`, `"dosage"`, dan `"type"` dapat diabaikan atau diteruskan ke layar LCD/OLED mini pada kotak obat fisik.

