# Struktur Antarmuka Pengguna (UI)

Aplikasi ini menggunakan desain yang bersih, cerah (Clean UI), dan berpusat pada komponen berbasis kartu (Card-Based Design). Berikut adalah dekonstruksi arsitektural dari tampilan visual proyek ini.

---

## 1. Tema Terpusat (AppTheme)

Aplikasi ini mengisolasi semua pengaturan estetika dalam satu file global: `lib/theme/app_theme.dart`.

*   **Warna:** Palet utamanya adalah gradasi warna Biru dan Tosca (`primaryColor`, `secondaryColor`) untuk menciptakan kesan tenang (khas aplikasi medis). Background diset ke putih bersih (`backgroundColor`) dengan *surface* abu-abu terang.
*   **Tipografi:** Memanfaatkan `google_fonts` untuk mengunduh dan merender jenis huruf secara asinkron. Ini menghindari aplikasi berukuran raksasa akibat memendam puluhan file `.ttf`. TextTheme di-override untuk menetapkan standar `headline`, `title`, dan `body`.
*   **Keuntungan:** Jika desain perusahaan berubah (misal dari biru ke hijau), perubahan cukup dilakukan pada beberapa baris heksadesimal di file ini, maka seluruh aplikasi (tombol, card, appbar) akan otomatis berubah warnanya tanpa mengubah komponen di setiap halaman.

---

## 2. Struktur `BerandaScreen`

Ini adalah halaman utama aplikasi yang memiliki elemen berlapis (Layering).

*   **CustomScrollView & Slivers:** Bukannya menggunakan `ListView` biasa, aplikasi ini menggunakan *Slivers* (`SliverToBoxAdapter`). Ini memberikan kemampuan transisi skroling (scrolling) yang jauh lebih mulus dan elegan, terutama saat komponen bagian atas disapu ke bawah (Appbar collapse effect).
*   **Header (Greeting Section):** Berisi nama pengguna (`userName`) yang ditarik dari *SharedPreferences*.
*   **AdherenceRing (Widget):** Komponen visual radial melingkar (progress bar bulat) yang terletak di bagian atas, bertugas untuk menunjukkan indikator kepatuhan (seberapa banyak obat yang belum diminum vs sudah diminum).
*   **Daftar Obat (List View):** Berisi perulangan rendering komponen `MedicineScheduleCard`.

---

## 3. Komponen Kustom Utama (Widgets)

Komponen-komponen modular ini dipisah ke dalam folder `lib/widgets` agar layar utama tidak penuh sesak (Cluttered).

### A. `MedicineScheduleCard`
*   **Fungsi:** Sebuah kartu putih berikan bayangan (shadow) halus yang merepresentasikan 1 jadwal obat.
*   **Fitur Dalamnya:**
    *   **Ikon Tipe Obat:** Menggambarkan wujud fisik obat (misal ikon suntikan, botol sirup, atau pil) menggunakan ikon bawaan.
    *   **Info Waktu:** Label jam besar (contoh "14:00").
    *   **Tombol Hapus:** Tombol ikon tempat sampah (trash) berwarna merah. Jika ditekan, ia memicu *callback function* (`onDelete`) menuju layar induk (`BerandaScreen`) agar jadwal tersebut dibuang dari RAM dan memori ponsel.

### B. `QuickStatCard`
*   **Fungsi:** Kotak informasi persegi berukuran kecil yang biasanya diletakkan berjejer horizontal (secara baris) di bawah profil pengguna, berfungsi memberikan metrik cepat, seperti jumlah dosis harian.

### C. `AdherenceRing`
*   **Fungsi:** Widget yang menggunakan `CustomPaint` (kemungkinan via integrasi statis atau dependency grafik) untuk merender garis pinggir melingkar (Circular Progress Indicator) dengan persentase di tengahnya. 

---

## 4. `TambahJadwalScreen`

Layar interaktif yang memfokuskan pengguna pada input data (Data Entry).

*   **Pola Pengisian:** Menggunakan bidang teks (TextField) standar `Material` untuk nama, jumlah (dosis), dan deskripsi obat.
*   **Pemilih Waktu (TimePicker):** Mengandalkan widget bawaan sistem operasi Flutter (`showTimePicker`). Fitur ini menghasilkan interaksi pemilihan jam digital atau analog yang memunculkan dialog ber-animasi. Saat jam diset, jam akan diubah wujudnya (*formatting*) menjadi string (seperti `"08:30"`) sebelum akhirnya dikonversi menjadi objek JSON untuk dipulangkan ke layer `BerandaScreen`.
*   **Pemilihan Ikon Tipe Obat:** Memfasilitasi list horizontal untuk memilih "kapsul", "tablet", dsb, menyuntikkan data tipe (string) untuk digunakan merender ikon nanti pada kartu di layar utama.
