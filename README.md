# Retail Sales Analysis with SQL

Analisis data transaksi UK-based online retail (~540.000 baris, periode Des 2010 – Des 2011) menggunakan SQL murni (MySQL) untuk menjawab lima pertanyaan bisnis kunci: produk terlaris, tren penjualan, customer paling bernilai, tingkat retensi, dan pola pembelian bersamaan.

## Ringkasan

Menggunakan SQL (CTE, window function) untuk menganalisis dataset transaksi retail dari toko online UK. Temuan utama: hampir 19% revenue berasal dari transaksi tanpa CustomerID tercatat (data quality gap), retention rate bulanan hanya ~35%, dan satu produk (WORLD WAR 2 GLIDERS ASSTD DESIGNS) konsisten jadi bestseller lintas bulan — tiga sinyal yang mengarah ke rekomendasi konkret bagi tim bisnis.

## Dataset

- **Sumber:** [UCI Machine Learning Repository – Online Retail](https://archive.ics.uci.edu/dataset/352/online-retail)
- **Ukuran:** ±540.000 baris transaksi
- **Periode:** 1 Desember 2010 – 9 Desember 2011
- **Konteks:** perusahaan retail UK yang menjual barang hadiah, sebagian besar customer adalah wholesaler
- **Kolom:** InvoiceNo, StockCode, Description, Quantity, InvoiceDate, UnitPrice, CustomerID, Country

## Tools

- MySQL (via XAMPP / phpMyAdmin)
- Teknik SQL: `GROUP BY`, `JOIN`, CTE (`WITH`), window functions (`ROW_NUMBER`, `RANK`, `LEAD`, `SUM() OVER`), self-join, `CASE WHEN`, konversi tipe data & tanggal

## Pertanyaan Bisnis & Temuan

### 1. Produk apa yang paling laku tiap bulan?
Menggunakan `GROUP BY` untuk menjumlahkan quantity terjual per produk per bulan.

**Temuan:** Desember 2010, produk terlaris adalah **WORLD WAR 2 GLIDERS ASSTD DESIGNS** (5.195 unit terjual), diikuti PACK OF 72 RETROSPOT CAKE CASES (4.106) dan WHITE HANGING HEART T-LIGHT HOLDER (3.871).

### 2. Top 3 produk per bulan (tanpa scroll manual)
Menggunakan CTE + `ROW_NUMBER() OVER (PARTITION BY bulan ORDER BY total_terjual DESC)` untuk otomatis me-ranking produk per bulan.

**Temuan:** **WORLD WAR 2 GLIDERS ASSTD DESIGNS** muncul di jajaran top 3 hampir di setiap bulan yang diamati (Des 2010, Feb, Mar, Apr, Mei, Jul 2011) — bukan sekadar tren musiman sesaat, melainkan produk andalan (bestseller konsisten) sepanjang periode data. Produk lain cenderung silih berganti mengisi posisi top 3 (WHITE HANGING HEART T-LIGHT HOLDER, JUMBO BAG RED RETROSPOT, ASSORTED COLOURS SILK FAN), sementara satu produk ini bertahan.

> **Insight bisnis:** Produk yang konsisten masuk top-seller lintas bulan seperti ini adalah kandidat kuat untuk dijaga ketersediaan stoknya sepanjang tahun (bukan cuma musiman), dan bisa dijadikan produk andalan dalam campaign pemasaran.

### 3. Siapa customer paling bernilai, dan berapa kontribusinya ke total revenue?
Menggunakan running total (`SUM() OVER (ORDER BY ...)`) dan grand total (`SUM() OVER ()`) untuk menghitung cumulative percentage — analisis gaya Pareto (80/20).

**Temuan:** Baris teratas hasil query ternyata bukan satu customer spesifik — `CustomerID`-nya kosong (string kosong, bukan NULL, sehingga lolos filter awal), mewakili transaksi tanpa ID customer yang tercatat, dan menyumbang **19.08%** dari total revenue. Customer teridentifikasi dengan revenue tertinggi sebenarnya adalah **CustomerID 18102** (£223.987, 2.24% dari total revenue). Top 10 customer teridentifikasi bersama-sama menyumbang **~33.7%** dari total revenue, dan top 28 menyumbang **~42.4%**.

> **Insight bisnis:** Ada dua temuan di sini. Pertama, hampir seperlima revenue berasal dari transaksi yang tidak tercatat ID customer-nya — ini gap data quality yang perlu ditindaklanjuti tim internal (kemungkinan transaksi guest checkout, POS offline, atau bug pencatatan), karena tanpa ID, transaksi ini tidak bisa dianalisis perilakunya atau ditargetkan campaign retensi. Kedua, di antara customer yang teridentifikasi, revenue cukup terkonsentrasi pada beberapa akun besar (top 10 = ~34% revenue) — kemungkinan wholesaler, sesuai konteks dataset. Rekomendasi: (1) investigasi root cause transaksi tanpa CustomerID untuk memperbaiki proses pencatatan data, (2) bangun program retensi khusus untuk segmen top spender yang sudah teridentifikasi.

### 4. Berapa persen customer yang belanja lagi di bulan berikutnya?
Menggunakan `LEAD()` untuk melihat bulan pembelian berikutnya per customer, lalu `CASE WHEN` untuk menandai apakah pembelian itu terjadi tepat 1 bulan setelahnya.

**Temuan: retention rate bulanan = 35.43%**

> **Insight bisnis:** Sekitar 2 dari 3 customer tidak melakukan pembelian ulang di bulan berikutnya. Ini mengindikasikan churn bulanan yang tinggi dan menjadi sinyal kuat untuk membangun program retensi — misalnya email reminder otomatis, promosi khusus untuk customer yang sudah lama tidak bertransaksi, atau program loyalty.

### 5. Produk apa yang sering dibeli bersamaan? *(scope decision)*
Query ini menggunakan self-join pada `InvoiceNo` yang sama untuk menemukan pasangan produk yang sering muncul dalam transaksi yang sama (market basket analysis sederhana). Query lengkap tersedia di `queries.sql`, termasuk versi yang sudah dioptimasi dengan indexing dan pembatasan ke produk populer (≥100 transaksi).

**Catatan:** Pada dataset penuh (~540K baris), self-join ini memakan waktu eksekusi yang signifikan bahkan setelah optimasi. Diputuskan untuk tidak menjalankannya sampai selesai pada iterasi ini, memprioritaskan empat analisis lain yang lebih langsung menjawab pertanyaan bisnis inti. Query tetap didokumentasikan sebagai referensi teknik (self-join) dan potensi pengembangan lanjutan — misalnya dijalankan pada subset data atau dengan constraint tambahan (per kategori produk, per periode tertentu) untuk mempercepat eksekusi.

## Rekomendasi Bisnis (Ringkasan)

1. **Investigasi transaksi tanpa CustomerID** — hampir 19% revenue berasal dari transaksi tak teridentifikasi customer-nya; perlu ditelusuri root cause-nya di proses input data.
2. **Program retensi customer** — retention rate 35% menunjukkan urgensi untuk investasi di re-engagement (email marketing, loyalty program).
3. **Fokus pada top spender teridentifikasi** — segmen customer bernilai tinggi (mis. CustomerID 18102) perlu penanganan khusus mengingat kontribusinya yang besar terhadap revenue.
4. **Jaga ketersediaan stok produk andalan** — produk seperti WORLD WAR 2 GLIDERS ASSTD DESIGNS konsisten masuk top-seller lintas bulan; prioritaskan stok produk ini dibanding produk musiman.

## Skill Teknis yang Didemonstrasikan

- Data cleaning: menangani format tanggal yang salah baca saat import, filter data retur/invalid
- SQL JOIN & GROUP BY untuk agregasi dasar
- CTE (Common Table Expressions) bertingkat untuk memecah logika kompleks jadi tahapan yang mudah dibaca
- Window functions: `ROW_NUMBER()`, `RANK()`, `LEAD()`, `SUM() OVER()` (running total & partition)
- Self-join untuk market basket analysis
- Optimasi query (indexing, pembatasan scope) untuk menangani dataset besar

## Cara Menjalankan

1. Download dataset dari [UCI Repository](https://archive.ics.uci.edu/dataset/352/online-retail)
2. Buat database dan tabel menggunakan skrip di `queries.sql` (bagian setup)
3. Import CSV ke tabel `online_retail` (pastikan delimiter sesuai file kamu)
4. Jalankan query di `queries.sql` secara berurutan
