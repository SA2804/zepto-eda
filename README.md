# 🛒 Zepto E-Commerce Data Analysis

This project presents an end-to-end **Exploratory Data Analysis (EDA)** and **SQL-based Business Insight Extraction** on a dataset resembling product listings from an e-commerce platform Zepto. The goal is to uncover critical insights into pricing, discounting, inventory health, and category performance that can drive better business decisions.

---

## Phase 1: 📊 Exploratory Data Analysis

### 📦 Overview

The first half of the project focuses on Exploratory Data Analysis (EDA) on the Zepto Inventory dataset using Python, Pandas, and Seaborn. The goal is to extract actionable insights, perform data cleaning, engineer new features, and visualize key patterns before integrating the dataset into a SQL database.

---

The Jupyter Notebook performs the following:

### 🧹 Data Wrangling

- Loaded the dataset from **Kaggle** and read it into a **Pandas DataFrame**.
- Ensured proper encoding (`cp1252`) to resolve Unicode errors during import.
- Inspected dataset structure, column types, and memory usage:
  - Total entries: `3732` 
  - Features: `9` (includes pricing, category, availability, and weight details)

---

###  Data Cleaning
- Removed duplicates, checked for missing values ( if any can be either imputed - [Unknown for categorical , Mean/Median/Mode for numerical cols ] or removed )
- Converted `outOfStock` from string to integer to meet mySQL expectations
- Normalized prices (e.g., converted paise to INR)


### Plots using Seaborn 
- Distribution of MRP, Discount % using histplot
- Category-wise product counts using countplot
- Out-of-stock distribution and boxplots

---


## Phase 2: 💼 SQL-Based Data Exploration and Business Insights

## 🗃️ Database & Table Setup

```sql
CREATE DATABASE zepto_inventory;
USE zepto_inventory;

CREATE TABLE zepto (
    sku_id SERIAL PRIMARY KEY,
    category VARCHAR(120),
    name VARCHAR(120) NOT NULL,
    mrp INT,
    discountPercent INT,
    availableQuantity INT,
    discountedSellingPrice INT,
    weightInGms INT,
    outOfStock BOOL,
    quantity INT
);
```

---

## 🔍 Data Exploration

### 1. Total Row Count
```sql
SELECT COUNT(*) FROM zepto_inventory.zepto;
```

### 2. Sample Preview
```sql
SELECT * FROM zepto LIMIT 10;
```

### 3. NULL Value Check
```sql
SELECT * FROM zepto 
WHERE name IS NULL 
   OR mrp IS NULL 
   OR discountPercent IS NULL 
   OR availableQuantity IS NULL 
   OR weightInGms IS NULL 
   OR outOfStock IS NULL 
   OR quantity IS NULL;
```

### 4. Unique Product Categories
```sql
SELECT DISTINCT(category) FROM zepto ORDER BY category;
```

### 5. Stock Availability Distribution
```sql
SELECT outOfStock, COUNT(sku_id) 
FROM zepto 
GROUP BY outOfStock;
```

### 6. Product Occurrence Count
```sql
SELECT name, COUNT(sku_id) 
FROM zepto 
GROUP BY name;
```

### 7. Products with Max and Min Occurrence

#### Maximum
```sql
WITH res1 AS (
    SELECT name, COUNT(name) AS ct 
    FROM zepto 
    GROUP BY name 
),
res2 AS (
    SELECT MAX(ct) AS maxx FROM res1
)
SELECT name FROM res1, res2 WHERE ct = maxx;
```

#### Minimum
```sql
WITH res1 AS (
    SELECT name, COUNT(name) AS ct 
    FROM zepto 
    GROUP BY name
),
res2 AS (
    SELECT MIN(ct) AS minn FROM res1
)
SELECT name, minn 
FROM res1 
JOIN res2 ON res1.ct = res2.minn;
```

---

## Data Cleaning

### 8. Detect Invalid Pricing
```sql
SELECT * 
FROM zepto 
WHERE mrp = 0 OR discountedSellingPrice = 0;
```

#### Remove Specific Corrupt Row
```sql
DELETE FROM zepto WHERE sku_id = 3601;
```

### 9. Convert Paise to Rupees
```sql
ALTER TABLE zepto 
MODIFY mrp DECIMAL(10,2),
MODIFY discountedSellingPrice DECIMAL(10,2);

SET SQL_SAFE_UPDATES = 0;

UPDATE zepto 
SET mrp = mrp / 100.0, 
    discountedSellingPrice = discountedSellingPrice / 100.0;
```

---

## 💼 Business Insights

### 10.1 Top 10 Best-Value Products by Category (Based on Discount %)
```sql
WITH res1 AS (
    SELECT category, name AS bestValueProducts, discountPercent,
           DENSE_RANK() OVER(PARTITION BY category ORDER BY discountPercent DESC, name) AS ranky 
    FROM zepto
)
SELECT * FROM res1 WHERE ranky <= 10;
```

### 10.2 Top 10 High-MRP Products That Are Out of Stock
```sql
SELECT category, name, mrp,
       CASE WHEN outOfStock = 1 THEN "True" ELSE "False" END AS outOfStock
FROM zepto 
WHERE outOfStock = 1 
ORDER BY mrp DESC 
LIMIT 10;
```

### 10.3 Estimated Revenue Per Category
```sql
SELECT 
  category,
  COUNT(*) AS total_products,
  SUM(discountedSellingPrice * availableQuantity) AS estimated_revenue
FROM zepto
WHERE availableQuantity > 0
GROUP BY category
ORDER BY estimated_revenue DESC;
```

### 10.4 High-MRP Products with Minimal Discounts
```sql
SELECT * 
FROM zepto 
WHERE mrp > 500 AND discountPercent < 10 
ORDER BY mrp DESC;
```

### 10.5 Top 5 Categories by Average Discount Percent
```sql
SELECT category,
       ROUND(AVG(discountPercent), 2) AS avgDiscountPercent
FROM zepto 
GROUP BY category 
ORDER BY avgDiscountPercent DESC 
LIMIT 5;
```

### 10.6 Price Per Gram for Products Above 100g
```sql
SELECT category, name, 
       ROUND(discountedSellingPrice / weightInGms, 2) AS pricePerGram
FROM zepto 
WHERE weightInGms > 100
ORDER BY pricePerGram;
```

### 10.7 Weight Distribution Category
```sql
SELECT name, weightInGms,
       CASE 
           WHEN weightInGms < 1000 THEN 'Low'
           WHEN weightInGms = 1000 THEN 'Medium'
           WHEN weightInGms > 1000 THEN 'High'
       END AS weightDist
FROM zepto;
```

### 10.8 Total Inventory Weight per Category (in KGs)
```sql
SELECT category, 
       ROUND(SUM(weightInGms * availableQuantity) / 1000, 2) AS weight_per_cat_in_kgs
FROM zepto 
GROUP BY category 
ORDER BY category;
```

---

## Summary

This SQL-based pipeline delivers full-circle:
- **Data Exploration**
- **Cleaning**
- **Transformation**
- **Insight Generation**


---

**Author: Shamim Ahamed S**  
**Date:** July 2025
