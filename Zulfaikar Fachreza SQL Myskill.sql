-- unicorn companies
-- 1. Urutkan benua berdasarkan jumlah company terbanyak. Benua mana yang memiliki unicorn paling banyak? 
SELECT
	uc.continent,
	COUNT(DISTINCT uc.company_id) AS total_per_country
FROM unicorn_companies uc
GROUP BY 1
ORDER BY 2 DESC
-- 2. Negara apa saja yang memiliki jumlah unicorn di atas 100? (Tampilkan jumlahnya)
SELECT
	uc.country,
	COUNT(DISTINCT uc.company_id) AS total_per_country
FROM unicorn_companies uc
GROUP BY 1
HAVING COUNT(DISTINCT uc.company_id) > 100
ORDER BY 2 DESC

-- 3. Industri apa yang paling besar di antara unicorn company berdasarkan total fundingnya? Berapa rata-rata valuasinya?
select industry, SUM(funding) as total_funding, avg(valuation) as avg_valuation
from unicorn_industries
left join unicorn_funding
on unicorn_industries.company_id = unicorn_funding.company_id
group by 1
order by 2 desc
-- 4. Berdasarkan dataset ini, untuk industri jawaban nomor 3 berapakah jumlah company yang bergabung sebagai unicorn di tiap tahunnya di rentang tahun 2016-2022?
select extract(year from date_joined) as year_joined, count(distinct company) as total_company
from unicorn_companies 
inner join unicorn_industries 
on unicorn_companies.company_id = unicorn_industries.company_id
inner join unicorn_dates
on unicorn_companies.company_id = unicorn_dates.company_id
group by 1 
order by 1 desc
-- 5. Tampilkan data detail company (nama company, kota asal, negara dan benua asal) beserta industri dan valuasinya. Dari negara mana company dengan valuasi terbesar berasal dan apa industrinya?
-- Bagaimana dengan Indonesia? Company apa yang memiliki valuasi paling besar di Indonesia?
SELECT
	uc.*,
	ui.industry,
	uf.valuation
FROM unicorn_companies uc 
INNER JOIN unicorn_industries ui 
	ON uc.company_id = ui.company_id
INNER JOIN unicorn_funding uf 
	ON uc.company_id = uf.company_id 
--WHERE country = 'Indonesia'
ORDER BY uf.valuation DESC

-- 6. Berapa umur company tertua ketika company tersebut bergabung menjadi unicorn company? Dari negara mana company tersebut berasal?
SELECT
	uc.*,
	ud.date_joined,
	ud.year_founded,
	EXTRACT(YEAR FROM ud.date_joined) - ud.year_founded AS company_age
FROM unicorn_companies uc 
INNER JOIN unicorn_dates ud 
	ON uc.company_id = ud.company_id 
ORDER BY company_age DESC

-- 7. Untuk company yang didirikan tahun antara tahun 1960 dan 2000 (batas atas dan bawah masuk ke dalam rentang), berapa umur company tertua ketika company tersebut bergabung menjadi unicorn company (date_joined)? Dari negara mana company tersebut berasal?
SELECT
	uc.*,
	ud.date_joined,
	ud.year_founded,
	EXTRACT(YEAR FROM ud.date_joined) - ud.year_founded AS company_age
FROM unicorn_companies uc 
INNER JOIN unicorn_dates ud 
	ON uc.company_id = ud.company_id 
	AND ud.year_founded BETWEEN 1960 AND 2000
ORDER BY company_age DESC

-- 8. Ada berapa company yang dibiayai oleh minimal satu investor yang mengandung nama ‘venture’?
select count(select_investors) as total_company
from unicorn_funding
where select_investors like '%venture%'
-- Ada berapa company yang dibiayai oleh minimal satu investor yang mengandung nama:
-- -	Venture
-- -	Capital
-- -	Partner

SELECT 
	COUNT(DISTINCT CASE WHEN LOWER(select_investors) LIKE '%venture%' THEN company_id END) AS investor_venture,
	COUNT(DISTINCT CASE WHEN LOWER(select_investors) LIKE '%capital%' THEN company_id END) AS investor_capital,
	COUNT(DISTINCT CASE WHEN LOWER(select_investors) LIKE '%partner%' THEN company_id END) AS investor_partner
FROM unicorn_funding uf 
-- 9. Ada berapa startup logistik yang termasuk unicorn di Asia? Berapa banyak startup logistik yang termasuk unicorn di Indonesia?
select count(distinct uc.company_id), count(distinct case when uc.country = 'Indonesia' then uc.company_id end)
from unicorn_companies as uc
inner join unicorn_industries as ui
on uc.company_id = ui.company_id
where ui.industry = '"Supply chain, logistics, & delivery"' and uc.continent = 'Asia'
-- 10. Tampilkan data jumlah unicorn di tiap industri dan negara asal di Asia, terkecuali tiga negara tersebut. Urutkan berdasarkan industri, jumlah company (menurun), dan negara asal.
with top3 as ( 
select uc.country, 
	count(distinct uc.company) as total_company
from unicorn_companies as uc
where uc.continent = 'Asia'
group by 1
order by 2 desc
limit 3)

select ui.industry, uc.country, count(distinct uc.company) as total_company
FROM unicorn_companies uc
INNER JOIN unicorn_industries ui
	ON uc.company_id = ui.company_id 
WHERE uc.continent = 'Asia'
AND uc.country NOT IN (
SELECT
	DISTINCT country
	FROM top3
)
GROUP BY 1,2
ORDER BY 1,3 DESC,2
-- soal no 11
WITH industry_india AS (
SELECT
	DISTINCT ui.industry 
FROM unicorn_industries ui
INNER JOIN unicorn_companies uc 
	ON uc.company_id = ui.company_id 
	WHERE uc.country = 'India' 
)
SELECT
	DISTINCT ui.industry 
FROM unicorn_industries ui
LEFT JOIN industry_india ii
	ON ui.industry = ii.industry
WHERE ii.industry IS NULL
-- 11. Amerika Serikat, China, dan India adalah tiga negara dengan jumlah unicorn paling banyak. Apakah ada industri yang tidak memiliki unicorn yang berasal dari India? Apa saja?
select distinct ui.industry
from unicorn_industries as ui
where ui.industry not in 
(
select ui2.industry
from unicorn_industries as ui2
inner join unicorn_companies as uc
on ui2.company_id = uc.company_id
where uc.country = 'India'
)
-- 12. Cari tiga industri yang memiliki paling banyak unicorn di tahun 2019-2021 dan tampilkan jumlah unicorn serta rata-rata valuasinya (dalam milliar) di tiap tahun.
WITH top_3 AS (
SELECT
	ui.industry,
	COUNT(DISTINCT ui.company_id)
FROM unicorn_industries ui 
INNER JOIN unicorn_dates ud 
	ON ui.company_id = ud.company_id 
WHERE EXTRACT(YEAR FROM ud.date_joined) IN (2019,2020,2021)
GROUP BY 1
ORDER BY 2 DESC
LIMIT 3
),

yearly_rank AS (
SELECT
	ui.industry,
	EXTRACT(YEAR FROM ud.date_joined) AS year_joined,
	COUNT(DISTINCT ui.company_id) AS total_company,
	ROUND(AVG(uf.valuation)/1000000000,2) AS avg_valuation_billion
FROM unicorn_industries ui 
INNER JOIN unicorn_dates ud 
	ON ui.company_id = ud.company_id 
INNER JOIN unicorn_funding uf 
	ON ui.company_id = uf.company_id 
GROUP BY 1,2
)

SELECT
	y.*
FROM yearly_rank y
INNER JOIN top_3 t
	ON y.industry = t.industry
WHERE y.year_joined IN (2019,2020,2021)
ORDER BY 1,2 DESC
-- soal no 13
WITH country_level AS (
SELECT
	uc.country,
	COUNT(DISTINCT uc.company_id) AS total_per_country
FROM unicorn_companies uc
GROUP BY 1
)

SELECT
	*,
	(total_per_country / SUM(total_per_country) OVER())*100 AS pct_company
FROM country_level
ORDER BY 2 DESC






	

