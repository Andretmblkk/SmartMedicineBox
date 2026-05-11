# Data Flow Diagram (DFD)

Berikut adalah visualisasi aliran data proyek Smart Medicine Tracker. DFD sangat penting untuk melihat batasan sistem serta interaksi aktor eksternal ke dalam sistem kita.

---

## 1. DFD Level 0 (Konteks Diagram)

Ini adalah pandangan tingkat tertinggi dari aplikasi (Helicopter View). Sistem aplikasi Smart Medicine Tracker diletakkan di tengah sebagai sebuah proses tunggal yang besar.

```mermaid
graph TD
    %% Entitas Eksternal
    USER((Pengguna Pasien))
    OS((Android / iOS OS))
    IOT((IoT Device ESP8266/ESP32))
    
    %% Proses Utama
    SYS[Sistem Smart Medicine Tracker]
    
    %% Flow
    USER -- Menginput Jadwal Obat --> SYS
    USER -- Menginput Data Diri --> SYS
    
    SYS -- Menampilkan Daftar Obat --> USER
    SYS -- Mengirim Popup Notifikasi/Alarm --> OS
    SYS -- Mengirim Sinyal JSON Realtime --> IOT
    
    IOT -- Fisik: Memutar Motor Servo Kotak Obat --> USER
```

---

## 2. DFD Level 1 (Dekomposisi Proses)

Ini adalah pembongkaran sistem menjadi subsistem fungsi. Proses dipecah berdasarkan modul atau fitur utama.

```mermaid
graph LR
    %% Entitas Eksternal
    USER((User))
    IOT((IoT Device))
    OS((OS AlarmManager))
    
    %% Data Stores (Penyimpanan)
    DS1[(Local Cache SharedPreferences)]
    DS2[(Cloud Firebase Realtime DB)]
    
    %% Proses Detail (Lingkaran/Kotak di DFD)
    P1(1.0 Manajemen Profil)
    P2(2.0 Manajemen Jadwal Obat)
    P3(3.0 Sinkronisasi IoT)
    P4(4.0 Penjadwalan Alarm OS)
    
    %% Flow Profil
    USER -- Input Nama --> P1
    P1 -- Simpan Nama --> DS1
    DS1 -- Render Nama Header --> P1
    
    %% Flow Jadwal Obat
    USER -- Isi Form Dosis & Jam --> P2
    P2 -- Simpan ke Daftar Lokal JSON --> DS1
    DS1 -- Render Daftar UI --> P2
    
    %% Flow IoT & DB Cloud
    P2 -- Memicu (Trigger) --> P3
    P3 -- Push Seluruh List JSON --> DS2
    DS2 -- Read (Membaca API Berkala) --> IOT
    
    %% Flow Notifikasi
    P2 -- Ekstrak Waktu --> P4
    P4 -- Daftarkan Task Background --> OS
```

---

## 3. Penjelasan Proses DFD

1.  **Proses 1.0 (Manajemen Profil):** Berjalan pada saat pengguna pertama kali membuka aplikasi. Mengecek *Data Store 1 (Lokal)* untuk eksistensi *key* `userName`. Jika null, memanggil dialog. Jika ada, melanjutkannya ke render teks.
2.  **Proses 2.0 (Manajemen Jadwal Obat):** Merupakan interaksi konstan setiap harinya di halaman utama dan halaman `TambahJadwalScreen`. Tempat terjadinya CRUD data jadwal.
3.  **Proses 3.0 (Sinkronisasi IoT):** Sepenuhnya berjalan tanpa sentuhan tangan *(under the hood)*. Ketika Proses 2.0 sukses memodifikasi *Data Store 1*, fungsi ini aktif dan meneruskan beban yang sama ke *Data Store 2 (Cloud)*. IoT Device (ESP8266) bertugas pasif hanya menarik data tersebut terus-menerus (Polling).
4.  **Proses 4.0 (Penjadwalan Alarm OS):** Menerjemahkan masukan format Waktu UI (Jam dan Menit dari tipe `TimeOfDay`) menjadi format mesin `TZDateTime` (Timezone Unix) dan mendelegasikan tanggung jawab pemunculan banner notifikasi ke *OS Alarm Manager*.
