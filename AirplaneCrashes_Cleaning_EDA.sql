/****** Script for SelectTopNRows command from SSMS  ******/
SELECT TOP (1000) [Date]
      ,[Time]
      ,[Location]
      ,[Operator]
      ,[Flight #]
      ,[Route]
      ,[Type]
      ,[Registration]
      ,[cn/In]
      ,[Aboard]
      ,[Fatalities]
      ,[Ground]
      ,[Summary]
  FROM [AirplaneCrashes].[dbo].[Original]

select count(*) "Total Rows" from Original;

--Selecting all column with * is not a very good idea as it affects the performance
--This dataset has about 5300 records only

select *  from Original;

-- Some of the Time column values are in incorrect format, we need to convert them into hh:mm format (parameter 8)
select convert(varchar,Time,8) from Original

update Original
set Time='00:00'
where Time is null

commit;

select * from Original

--Some values in Time column are starting from 'c' or 'c: ' or 'c:', we need to replace them by blank/null values. Nulls could further be replaced by 00:00
update Original
set Time = ' '
where Time like 'c%'

update Original
set Time = null
where Time =' '

update Original
set Time='00:00'
where Time is null

commit;

--Date column looks to be in correct format, will do a trim to make sure there are no leading/trailing spaces
select trim(Date)  from Original

/*Location column has State/Country name in the end (after comma), we need to extract this. 
Observed that US Locations have State, while non-US locations have Country. 

We could specify country for USA as well and replace US states by USA - for now, leaving that option open
*/

select *  from Original;

select Location, trim(substring(Location,charindex(',',Location)+1,len(Location))) as State_Country
from Original

--add a new column State_Country and update with these values
alter table Original
add Extract_Loc nvarchar(40)

update Original
set Extract_Loc= trim(substring(Location,charindex(',',Location)+1,len(Location)))
					   
--Many values in Location column contain empty spaces, replace them by null
update Original
	set Location = null
where location=' '

commit;

--NULLS in column values can either be replaced by Unknown or left as NULLS

--Aboard and fatalities are listed as char, change them to int. We then create a new 'Survived' column which will be Aboard-Fatalities
alter table Original
alter column aboard int

alter table Original
alter column fatalities int

select *
from Original

alter table Original
add Survived int

Update Original
set Survived=Aboard-Fatalities

commit;

--Frequency bins (10 years) for decade wise crashes- Used CASE WHEN and CTE. Can Create as many bins as required
with Hist as
(
select 
	case	
		when Year(Date) < 1975 then 'Before 1975'
		when Year(Date) >= 1975 and Year(Date) < 1985 then '1975-1985'
		when Year(Date) >= 1985 and Year(Date) < 1995 then '1985-1995'
		when Year(Date) >= 1995 and Year(Date) < 2005 then '1995-2005'
		when Year(Date) >= 2005 and Year(Date) < 2015 then '2005-2015'
		else 'Later than 2015'
	end as Year_Bins
from Original
)
select
Year_Bins, count(Year_Bins) as Crashes_per_decade
from Hist
group by Year_Bins
order by Year_Bins

--Crashes (with people aboard/died) per year
select 
	year(Date) as Crash_Year,
	count(*) Number_of_Crashes,
	aboard,
	fatalities
from 
Original
group by year(Date),aboard,fatalities
order by year(Date)

--Which airline operator was behind the most crashes
select 
	year(Date) as Crash_Year,
	count(*) Number_of_Crashes,
	aboard,
	fatalities
from 
Original
group by year(Date),aboard,fatalities
order by year(Date)

--Fatalities per Operator: Aeroflot and US Army Air Force top the list
select
	year(Date) as Crash_Year,
	count(*) Number_of_Crashes,
 Operator
from Original
group by year(Date) ,Operator
order by Number_of_Crashes desc

-- Which operator amongst the US had the highest crashes'
select
	year(Date) as Crash_Year,
	count(*) Number_of_Crashes,
	Operator
from Original
where Operator like 'US%'
group by year(Date) ,Operator
order by Crash_Year

-- Which plane type had the highest crashes: Douglas DC-3
select	
	count(*) Number_of_Crashes,
	type
from Original
group by type
order by Number_of_Crashes desc

--The top 5 routes that caused the most plane crashes-Training saw maximum crashes, followed by SightSeeing
-- Route column has lot of blank spaces, replace those with null first, before starting to explore
update Original
set Route=null
where Route =''

commit;

select  * from Original;

select top (5)
	Route,
	count(*) Number_of_Crashes
from Original
where route is not null
group by route
order by Number_of_Crashes desc

-- Top 10 Dangerous locations
select top(10)
	location,
	count(*) Number_of_crashes
from Original
where location is not null
group by Location
order by Number_of_crashes desc

--The top 7 routes that caused the most fatalities
select top (5)
	route,
	count(Fatalities) Number_of_Fatalities
from Original
group by route
order by Number_of_Fatalities des

--The top 10 Locations that caused the most plane crashes
select top (10)
	Location,
	count(*) Number_of_Crashes
from Original
where location is not null
group by Location
order by Number_of_Crashes desc

-- Cause of crash
select
	year(Date) as Crash_Year,
	Summary
from Original
order by Crash_Year

-- When cause of crash is weather related

update Original
set Summary = trim(summary);

commit;

select
	year(Date) as Crash_Year,location,
	Summary
from Original
where Summary like '%weather%'
or Summary like '%storm%'
or Summary like '%fog%'
or Summary like '%wind%'
order by Crash_Year

-- When cause of crash is technical failure (Engine failure could be due to weather related reasons as well)
select
	year(Date) as Crash_Year,
	Summary
from Original
where Summary like '%technical%'
or Summary like '%engine%'
order by Crash_Year

--Which location saw the most crashes
select 
	year(Date) as Crash_Year,
	count(*)as Num_crashes,
	Location
from 
Original
group by year(Date) ,Location
order by Crash_Year, Num_crashes desc