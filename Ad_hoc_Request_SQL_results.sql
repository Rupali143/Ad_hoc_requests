use gdb023;

# 1 Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region.

select market 
from dim_customer 
where customer = 'Atliq Exclusive' and region = 'APAC';

# 2. What is the percentage of unique product increase in 2021 vs. 2020? The final output contains these fields,
		#unique_products_2020
		#unique_products_2021
		#percentage_chg

with tbl1 as (select count(distinct(product_code)) as unique_products_2021
			 from fact_sales_monthly 
             where fiscal_year = 2021),
     tbl2 as (select count(distinct(product_code)) as unique_products_2020
			 from fact_sales_monthly 
             where fiscal_year = 2020)
             select unique_products_2020, unique_products_2021,
             round((((unique_products_2021-unique_products_2020)/(unique_products_2020))*100), 2) as percentage_chg
             from tbl1, tbl2;

# 3. Provide a report with all the unique product counts for each segment and sort them in descending order of product counts. The final output contains 2 fields,
		#segment
		#product_count
        
select segment, count(product) as 'product_count'
from dim_product 
group by segment
order by product_count desc;


# 4. Which segment had the most increase in unique products in 2021 vs 2020? The final output contains these fields,
		#segment
		#product_count_2020
		#product_count_2021
		#difference

with tbl1 as (select dp.segment, count(distinct(dp.product_code)) as product_count_2021
			 from fact_sales_monthly fmc
			 inner join dim_product dp 
 			 on dp.product_code = fmc.product_code
             where fiscal_year = 2021
             group by dp.segment),
     tbl2 as (select dp.segment, count(distinct(dp.product_code)) as product_count_2020
			 from fact_sales_monthly fmc
             inner join dim_product dp 
 			 on dp.product_code = fmc.product_code
             where fiscal_year = 2020
             group by dp.segment)
	 select tbl1.segment, product_count_2021, product_count_2020,
             (product_count_2021-product_count_2020) as difference
             from tbl1 inner join tbl2
             on tbl1.segment = tbl2.segment
             order by difference desc;


# 5. Get the products that have the highest and lowest manufacturing costs. The final output should contain these fields,
		#product_code
		#product
		#manufacturing_cost
        
select * from (select fmc.product_code, dp.product, manufacturing_cost
		from fact_manufacturing_cost as fmc
		inner join dim_product dp 
		on dp.product_code = fmc.product_code
		order by manufacturing_cost desc
		limit 1) as q1
UNION
select * from (select fmc.product_code, dp.product, manufacturing_cost
		from fact_manufacturing_cost as fmc
		inner join dim_product dp 
		on dp.product_code = fmc.product_code
		order by manufacturing_cost asc
		limit 1) as q2;


# 6. Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct for the fiscal year 2021 and in the Indian market. The final output contains these fields,
		#customer_code
		#customer
		#average_discount_percentage
        
select distinct fid.customer_code, customer, pre_invoice_discount_pct as average_discount_percentage
from dim_customer as dc
join fact_pre_invoice_deductions as fid
on dc.customer_code = fid.customer_code
where fid.fiscal_year = '2021' and dc.market = 'India'
order by fid.pre_invoice_discount_pct desc limit 5;


# 7. Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month. This analysis helps to get an idea of low and high-performing months and take strategic decisions.
#The final report contains these columns:
		#Month
		#Year
		#Gross sales Amount

select monthname(date) AS Month,  year(date) as Year,
sum((sold_quantity * gross_price)) as Gross_sales_Amount
from fact_sales_monthly as fsm
inner join fact_gross_price as fgp
on fsm.product_code = fgp.product_code
inner join dim_customer as dm
on dm.customer_code = fsm.customer_code
where dm.customer = "Atliq Exclusive"
group by Month,Year;


# 8.In which quarter of 2020, got the maximum total_sold_quantity? The final output contains these fields sorted by the 
		#total_sold_quantity,
		#Quarter
		#total_sold_quantity

select case quarter(date) 
		when 1 then 'Q1'
        when 2 then 'Q2'
        when 3 then 'Q3'
        when 4 then 'Q4' end as Quarter,
		sum(sold_quantity) as total_sold_quantity
from fact_sales_monthly where fiscal_year = '2020'
group by Quarter
order by Quarter desc;


# 9. Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution? The final output contains these fields,
		#channel
		#gross_sales_mln
		#percentage
        
with tbl1 as (select channel, gross_price, sold_quantity,
			  round(sum((sold_quantity * gross_price)/1000000),2) as gross_sales_mln
			  from fact_sales_monthly as fsm
			  inner join fact_gross_price as fgp
			  on fsm.product_code = fgp.product_code
			  inner join dim_customer as dc
			  on dc.customer_code = fsm.customer_code
			  where fsm.fiscal_year = '2021' AND fgp.fiscal_year = '2021'
			  group by channel
              order by gross_sales_mln limit 3)
select channel, gross_sales_mln,
		round(((gross_sales_mln/(select sum(gross_sales_mln) from tbl1))*100),2) as percentage
		from tbl1;


# 10. Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021? The final output contains these fields,
		#division
		#product_code
		#codebasics.io
		#product
		#total_sold_quantity
		#rank_order

with tbl1 as (select product, division, sum(sold_quantity) as total_sold_quantity, dp.product_code
			from dim_product as dp
			inner join fact_sales_monthly as fsm
			on dp.product_code = fsm.product_code
			where fiscal_year ='2021'
			group by product),
	 tbl2   as (select division, product_code, product, total_sold_quantity,
			dense_rank () over (partition by division order by total_sold_quantity desc) as rank_order 
			from tbl1)
			select * from tbl2 where rank_order<=3;




