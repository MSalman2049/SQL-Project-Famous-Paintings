# List all the paintings that are not displayed in any museums? There are over 5000 paintings so we would need to increase the limit.
select work_id, name from work
where museum_id is null
limit 6000;

## Are there museums without any paintings? - We can create a CTE to point out which museums are not included int the work section using a Right JOIN and querry
## of that to get the list of empty museums.
with Empty_museums as
(select distinct(w.museum_id) as Musuems_with_paintings, m.museum_id, m.name
from work w
Right join museum m
	ON m.museum_id = w.museum_id)
select museum_id, name
from Empty_museums
where Musuems_with_paintings is null;
# the above question can also be answered using a substring in the where statement.
select * from museum m
	where not exists (select 1 from work w
					 where w.museum_id=m.museum_id);

## How many paintings have an asking price of more than their regular price?
-- We would need to use the product_size table to extract the asking price (sale_price) and the regular price.
select count(*) from product_size
where sale_price > regular_price;

-- Identify the paintings whose asking price is less than 50% of its regular price
select * from product_size
where regular_price/2 > sale_price;

-- OR can also be put this way
select * 
	from product_size
	where sale_price < (regular_price*0.5);
    
-- Which canva size costs the most? - since there is only 1 entry for size_id 79 and its also not specified in the
-- canvas_size, we'll have to use size_id 4896  and obtain the relevant information. An average of the regular price would be the best indicator.
select ps.size_id, cs.*, AVG(ps.regular_price)
from product_size ps
JOIN canvas_size cs on ps.size_id = cs.size_id
Group by ps.size_id, cs.size_id, cs.width, cs.height, cs.label
Order by AVG(ps.regular_price) desc
Limit 1;

-- Delete duplicate records from work, product_size, subject and image_link tables
select *, count(url)
from image_link
group by work_id, url, thumbnail_small_url, thumbnail_large_url
having count(url)>1
;
delete from image_link
where work_id IN (select work_id From 
(SELECT *,
  ROW_NUMBER() OVER (
    PARTITION BY work_id 
    ORDER BY 
      work_id
  ) AS row_num 
FROM 
  image_link) as il1
Where row_num >1);

-- Identify the museums with invalid city information in the given dataset 
select * from museum 
where city regexp '^[0-9].*';

-- Update rows with incorrect day of the week.
select distinct(day) 
from museum_hours;
Update museum_hours mh
set mh.day = 'Thursday'
where mh.day = 'Thusday';

-- Fetch the top 10 most famous painting subject
select count(subject), subject
from subject
Group by subject
Order by count(subject) desc
limit 10;

-- Identify the museums which are open on both Sunday and Monday. Display museum name, city.
select distinct m.name as museum_name, m.city
from museum m
JOIN museum_hours mh on m.museum_id=mh.museum_id
Where day = 'Sunday' and Exists
(select mh2.museum_id
from museum_hours mh2 
where mh2.museum_id = mh.museum_id and  mh2.day = 'Monday') 
;		

-- How many museums are open every single day? -- Use a CTE to create a table for a new column for with occurence of each museum. If the
-- rownumber for the museum_id is over 6, that would imply that the museum is open for 7 days a week. Querry off the CTE to get the names of the museums with 
-- rownumber higher than 6.
With DaysOpen as (SELECT *,
  ROW_NUMBER() OVER (
    PARTITION BY museum_id 
    ORDER BY 
      day)
   AS Days_Open
from museum_hours)
select D.museum_id, m.name  
from DaysOpen D
JOIN museum m on d.museum_id = m.museum_id
Where Days_Open > 6;

select * from museum_hours;

-- Which are the top 5 most popular museum? (Popularity is defined based on most no of paintings in a museum)
select m.name, w.museum_id, count(w.museum_id)
from work w
Join museum m on w.museum_id=m.museum_id
where w.museum_id is not null
group by w.museum_id, m.name
order by count(w.museum_id) desc
limit 5;

-- Who are the top 5 most popular artist? (Popularity is defined based on most no of paintings done by an artist)
select a.full_name, w.artist_id, count(w.artist_id)
from work w
join artist a on a.artist_id = w.artist_id
where w.artist_id is not null
group by w.artist_id, a.full_name
order by count(w.artist_id) desc
limit 5;

-- Display the 3 least popular canva sizes
select ps.size_id, cs.label, count(ps.size_id) as Number_of_Paintings
from product_size ps
join canvas_size cs on cs.size_id = ps.size_id
group by ps.size_id, cs.label
order by count(ps.size_id) asc
limit 3;

# Which museum is open for the longest during a day. Dispay museum name, state and hours open and which day?
With hours_open_cte as (select museum_id, day, time_format((STR_TO_DATE( close,  '%l:%i:%p' ) - STR_TO_DATE( open,  '%l:%i:%p' )), '%H:%i:%s') as hours_open
from museum_hours
order by hours_open desc
limit 1)
select m.name as 'Museum Name', m.state, HO.hours_open, HO.day
from hours_open_cte HO
join museum m on HO.museum_id=m.museum_id;


