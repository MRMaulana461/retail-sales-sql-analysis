-- ============================================
-- RETAIL SALES ANALYSIS - SQL QUERIES
-- Dataset: UCI Online Retail (~540K rows)
-- ============================================

-- ============================================
-- SETUP: Buat database & tabel
-- ============================================
CREATE DATABASE IF NOT EXISTS retail_analysis;
USE retail_analysis;

CREATE TABLE IF NOT EXISTS online_retail (
    InvoiceNo   VARCHAR(20),
    StockCode   VARCHAR(20),
    Description VARCHAR(255),
    Quantity    INT,
    InvoiceDate VARCHAR(20),   -- disimpan sebagai text dulu, lihat catatan di bawah
    UnitPrice   VARCHAR(20),
    CustomerID  VARCHAR(20),
    Country     VARCHAR(100)
);

-- Catatan: InvoiceDate di source CSV berformat DD/MM/YYYY HH:MM,
-- import langsung sebagai DATETIME akan gagal. Solusi: import sebagai
-- VARCHAR dulu, lalu convert dengan STR_TO_DATE (lihat di bawah).

-- ============================================
-- FIX: Konversi InvoiceDate (text) -> datetime
-- ============================================
ALTER TABLE online_retail ADD COLUMN InvoiceDateFixed DATETIME;

UPDATE online_retail
SET InvoiceDateFixed = STR_TO_DATE(InvoiceDate, '%d/%m/%Y %H:%i');

-- Verifikasi tidak ada baris yang gagal convert
-- SELECT COUNT(*) FROM online_retail WHERE InvoiceDateFixed IS NULL;

-- Index untuk mempercepat self-join di Query 5
ALTER TABLE online_retail ADD INDEX idx_invoiceno (InvoiceNo);
ALTER TABLE online_retail ADD INDEX idx_stockcode (StockCode);


-- ============================================
-- QUERY 1: Produk terlaris per bulan
-- ============================================
SELECT
    DATE_FORMAT(InvoiceDateFixed, '%Y-%m') AS bulan,
    Description AS produk,
    SUM(Quantity) AS total_terjual
FROM online_retail
WHERE Quantity > 0
    AND CustomerID IS NOT NULL
GROUP BY bulan, produk
ORDER BY bulan, total_terjual DESC;


-- ============================================
-- QUERY 2: Top 3 produk per bulan (window function)
-- ============================================
WITH penjualan_bulanan AS (
    SELECT
        DATE_FORMAT(InvoiceDateFixed, '%Y-%m') AS bulan,
        Description AS produk,
        SUM(Quantity) AS total_terjual
    FROM online_retail
    WHERE Quantity > 0
        AND CustomerID IS NOT NULL
    GROUP BY bulan, produk
),
ranked AS (
    SELECT
        bulan,
        produk,
        total_terjual,
        ROW_NUMBER() OVER (PARTITION BY bulan ORDER BY total_terjual DESC) AS ranking
    FROM penjualan_bulanan
)
SELECT * FROM ranked WHERE ranking <= 3
ORDER BY bulan, ranking;


-- ============================================
-- QUERY 3: Top spender & kontribusi ke revenue (Pareto analysis)
-- ============================================
WITH revenue_per_customer AS (
    SELECT
        CustomerID,
        SUM(Quantity * UnitPrice) AS total_revenue
    FROM online_retail
    WHERE Quantity > 0
        AND CustomerID IS NOT NULL
    GROUP BY CustomerID
),
ranked_customer AS (
    SELECT
        CustomerID,
        total_revenue,
        RANK() OVER (ORDER BY total_revenue DESC) AS ranking,
        SUM(total_revenue) OVER (ORDER BY total_revenue DESC) AS running_total,
        SUM(total_revenue) OVER () AS grand_total
    FROM revenue_per_customer
)
SELECT
    ranking,
    CustomerID,
    total_revenue,
    running_total,
    ROUND(running_total / grand_total * 100, 2) AS cumulative_pct
FROM ranked_customer
ORDER BY ranking;


-- ============================================
-- QUERY 4: Retention rate bulanan
-- ============================================
WITH pembelian_bulanan AS (
    SELECT DISTINCT
        CustomerID,
        DATE_FORMAT(InvoiceDateFixed, '%Y-%m-01') AS bulan
    FROM online_retail
    WHERE Quantity > 0
        AND CustomerID IS NOT NULL
),
cek_retensi AS (
    SELECT
        CustomerID,
        bulan,
        LEAD(bulan) OVER (PARTITION BY CustomerID ORDER BY bulan) AS bulan_beli_berikutnya
    FROM pembelian_bulanan
),
hasil_retensi AS (
    SELECT
        CustomerID,
        bulan,
        CASE
            WHEN bulan_beli_berikutnya = DATE_ADD(bulan, INTERVAL 1 MONTH) THEN 1
            ELSE 0
        END AS retained_bulan_depan
    FROM cek_retensi
)
SELECT
    ROUND(AVG(retained_bulan_depan) * 100, 2) AS retention_rate_pct
FROM hasil_retensi;


-- ============================================
-- QUERY 5: Produk yang sering dibeli bersamaan (self-join)
-- ============================================
WITH produk_populer AS (
    SELECT StockCode
    FROM online_retail
    WHERE Quantity > 0
    GROUP BY StockCode
    HAVING COUNT(*) >= 100
)
SELECT
    a.Description AS produk_1,
    b.Description AS produk_2,
    COUNT(*) AS jumlah_dibeli_bareng
FROM online_retail a
JOIN online_retail b
    ON a.InvoiceNo = b.InvoiceNo
    AND a.StockCode < b.StockCode
WHERE a.Quantity > 0
    AND b.Quantity > 0
    AND a.StockCode IN (SELECT StockCode FROM produk_populer)
    AND b.StockCode IN (SELECT StockCode FROM produk_populer)
GROUP BY produk_1, produk_2
ORDER BY jumlah_dibeli_bareng DESC
LIMIT 20;
