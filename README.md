# Retail Sales Analysis with SQL

Analisis data transaksi UK-based online retail (~540.000 baris, periode Des 2010 – Des 2011) menggunakan SQL murni (MySQL) untuk menjawab lima pertanyaan bisnis kunci: produk terlaris, tren penjualan, customer paling bernilai, tingkat retensi, dan pola pembelian bersamaan.

## Ringkasan

Menggunakan SQL (CTE, window function, self-join) untuk menganalisis dataset transaksi retail dari toko online UK. Temuan utama: revenue sangat bergantung pada segelintir customer besar (pola Pareto), dan retention rate bulanan hanya ~35% — dua sinyal yang mengarah ke rekomendasi program retensi customer.

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

**Temuan:** [isi produk top di beberapa bulan kunci, misal bulan puncak Nov-Des menjelang liburan]

### 2. Top 3 produk per bulan (tanpa scroll manual)
Menggunakan CTE + `ROW_NUMBER() OVER (PARTITION BY bulan ORDER BY total_terjual DESC)` untuk otomatis me-ranking produk per bulan.

**Temuan:** [isi pola musiman yang terlihat, misal produk dekorasi naik tajam di kuartal akhir tahun]

### 3. Siapa customer paling bernilai, dan berapa kontribusinya ke total revenue?
Menggunakan running total (`SUM() OVER (ORDER BY ...)`) dan grand total (`SUM() OVER ()`) untuk menghitung cumulative percentage — analisis gaya Pareto (80/20).

**Temuan:** [isi: sekitar X% customer menyumbang 80% dari total revenue]

> **Insight bisnis:** Revenue sangat terkonsentrasi pada sejumlah kecil customer besar. Kehilangan salah satu dari mereka berdampak signifikan terhadap pendapatan — perlu strategi retensi khusus untuk segmen top spender ini (misalnya akun manager dedicated, program loyalty tier tinggi).

### 4. Berapa persen customer yang belanja lagi di bulan berikutnya?
Menggunakan `LEAD()` untuk melihat bulan pembelian berikutnya per customer, lalu `CASE WHEN` untuk menandai apakah pembelian itu terjadi tepat 1 bulan setelahnya.

**Temuan: retention rate bulanan = 35.43%**

> **Insight bisnis:** Sekitar 2 dari 3 customer tidak melakukan pembelian ulang di bulan berikutnya. Ini mengindikasikan churn bulanan yang tinggi dan menjadi sinyal kuat untuk membangun program retensi — misalnya email reminder otomatis, promosi khusus untuk customer yang sudah lama tidak bertransaksi, atau program loyalty.

### 5. Produk apa yang sering dibeli bersamaan?
Menggunakan self-join pada `InvoiceNo` yang sama untuk menemukan pasangan produk yang sering muncul dalam transaksi yang sama (market basket analysis sederhana), dibatasi pada produk populer (≥100 transaksi) untuk efisiensi query.

**Temuan:** [isi pasangan produk teratas, misal produk dari satu tema/koleksi yang sama]

> **Insight bisnis:** Pasangan produk ini bisa dijadikan dasar strategi bundling atau rekomendasi cross-sell di halaman checkout, berpotensi menaikkan average order value.

## Rekomendasi Bisnis (Ringkasan)

1. **Program retensi customer** — retention rate 35% menunjukkan urgensi untuk investasi di re-engagement (email marketing, loyalty program).
2. **Fokus pada top spender** — segmen kecil customer bernilai tinggi perlu penanganan khusus mengingat kontribusinya yang besar terhadap revenue.
3. **Strategi bundling produk** — pasangan produk yang sering dibeli bersamaan bisa dijadikan paket bundle atau rekomendasi cross-sell.
4. **Perencanaan stok musiman** — pola penjualan bulanan menunjukkan lonjakan di periode tertentu; perencanaan inventori bisa disesuaikan.

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
