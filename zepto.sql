CREATE DATABASE zepto_inventory;
USE zepto_inventory;

CREATE TABLE zepto(
	sku_id serial primary key,
    category varchar(120),
    name varchar(120) not null,
    mrp int,
    discountPercent int,
    availableQuantity int,
    discountedSellingPrice int,
    weightInGms int,
    outOfStock bool, -- under the hood , tinyint(1) works in action => TRUE is 1 and FALSE is 0
    quantity int
);
-- Data Exploration :

-- 1. Row Count 
SELECT COUNT(*) FROM zepto_inventory.zepto;

-- 2. Sample Data
SELECT* FROM ZEPTO LIMIT 10;

-- 3. NULL VALUES 
SELECT* FROM ZEPTO WHERE NAME IS NULL OR MRP IS NULL OR discountPercent IS NULL OR availableQuantity IS NULL 
OR weightInGms IS NULL OR outOfStock IS NULL OR QUANTITY IS NULL;

-- 4. different product categories 
SELECT DISTINCT(CATEGORY) FROM ZEPTO ORDER BY CATEGORY;

-- 5. products in stock info 
select outOfStock, count(sku_id)
from zepto group by outOfStock;

-- 6. occurrence of each product 
select name,count(sku_id) from zepto group by name;

-- 7. products which has been listed the maximum and minimum times
-- maximum number of times 
with res1 as (
select name,count(name) as ct from zepto group by name order by ct desc
),res2 as(
select max(ct) as maxx from res1
)
select name from res1,res2 where ct =maxx ;

-- minimum number of times
with res1 as (
select name,count(name) as ct from zepto group by name
),res2 as(
select min(ct) as minn from res1
)
select name,minn from res1 join res2 on res1.ct=res2.minn;

-- DATA CLEANING 

-- 8.products with price = 0
 select* from zepto where mrp = 0 or discountedSellingPrice =0; -- Cherry Blossom Liquid Shoe Polish Neutral
 delete from zepto where sku_id=3601;
 
-- 9. convert paise to rupees and modify column types :
ALTER TABLE zepto 
MODIFY mrp DECIMAL(10,2),
MODIFY discountedSellingPrice DECIMAL(10,2);

SET SQL_SAFE_UPDATES = 0;

update zepto 
set mrp = mrp/100.0,discountedSellingPrice=discountedSellingPrice/100.0; -- When you run an UPDATE or DELETE in MySQL without a WHERE clause, and it refuses to execute it due to SAFE MODE

-- 10. Business Insights 

-- 10.1  find the top 10 (TOP N) best value products category wise based on the discount percentage
with res1 as (
	select category,name as bestValueProducts,discountPercent,
	DENSE_RANK() OVER(partition by category order by discountPercent desc,name) as ranky 
	from zepto
)
select * from res1 where ranky<=10;
-- 10.2 what are the top 10 products with high mrp but are out of stock 
select 
category,name,mrp,
CASE 
	when outOfStock=1 then "True"
    else "False"
end as outOfStock
 from zepto where outOfStock=1 order by mrp desc limit 10;
 -- 10.3 calculate estimated revenue for each category 
SELECT 
  category,
  COUNT(*) AS total_products,
  SUM(discountedSellingPrice * availableQuantity) AS estimated_revenue
FROM zepto
WHERE availableQuantity > 0
GROUP BY category
ORDER BY estimated_revenue DESC;
-- 10.4 find all products where mrp > 500 and discount is less than 10% =>> they alr sell well without discounts
select* from zepto where mrp>500 and discountPercent<10 order by mrp desc;

-- 10.5 identify the top 5 cat offering the highest average discount percentage
select category,
round(avg(discountPercent),2) avgDiscountPercent
from zepto 
group by category 
order by avgDiscountPercent desc limit 5;

-- 10.6 find the price per gram for products above 100g and sort by best value 
select category,name,round(discountedSellingPrice/weightInGms,2) as pricePerGram
from zepto 
where weightInGms >100
order by pricePerGram;

-- 10.7 Group the products into categories like low , medium , bulk based on their weight in gms.->
select name,weightInGms,
case 
	when weightInGms<1000 then 'Low'
    when weightInGms=1000 then 'Medium'
    when weightInGms>1000 then 'High'
end as weightDist 
from zepto;

-- 10.8 what is the total inventory weight per category 
select category , round(sum(weightInGms*availableQuantity)/1000,2) as weight_per_cat_in_kgs
from zepto group by category order by category