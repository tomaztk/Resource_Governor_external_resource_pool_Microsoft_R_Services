/*

** Author: Tomaz Kastrun
** Web: http://tomaztsql.wordpress.com
** Twitter: @tomaz_tsql
** Created: 18.08.2016; Ljubljana
** Resource governor and external resource pool for Microsoft R Services
** R and T-SQL

*/

USE [RevoTestDB];
GO



CREATE TABLE AirlineDemoSmall(
	 ArrDelay varchar(100) NOT NULL
	,CRSDepTime float NOT NULL
	,[DayOfWeek] varchar(12) NOT NULL  
)
GO


-- this file should be at your location! so no need to download it
BULK INSERT AirlineDemoSmall
FROM 'C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\R_SERVICES\library\RevoScaleR\SampleData\AirlineDemoSmall.csv'
WITH (
	FIELDTERMINATOR = ',',
	ROWTERMINATOR = '\n',
	FIRSTROW = 2 -- Skip header
)



EXECUTE  sp_execute_external_script
				 @language = N'R'
				,@script = N'
							library(RevoScaleR)
							f <- formula(as.numeric(ArrDelay) ~ as.numeric(DayOfWeek) + CRSDepTime)
							s <- system.time(mod <- rxLinMod(formula = f, data = AirLine))
							OutputDataSet <-  data.frame(system_time = s[3]);' -- Get Elapsed time from System.time function
				,@input_data_1 = N'SELECT * FROM AirlineDemoSmall'
				,@input_data_1_name = N'AirLine'
-- WITH RESULT SETS UNDEFINED
WITH RESULT SETS 
			((
				 Elapsed_time FLOAT
			));


SELECT * FROM sys.resource_governor_resource_pools WHERE name = 'default'  
SELECT * FROM sys.resource_governor_external_resource_pools WHERE name = 'default'  


ALTER RESOURCE POOL [default] WITH (max_memory_percent = 60, max_cpu_percent=90);  
ALTER EXTERNAL RESOURCE POOL [default] WITH (max_memory_percent = 40, max_cpu_percent=10);  
ALTER RESOURCE GOVERNOR reconfigure;  


-- Enable Resource Governor
ALTER RESOURCE GOVERNOR RECONFIGURE;  
GO  

-- Default value
ALTER EXTERNAL RESOURCE POOL [default] 
WITH (AFFINITY CPU = AUTO)
GO


ALTER EXTERNAL RESOURCE POOL RService_Resource_Pool  
WITH (  
     MAX_CPU_PERCENT = 1  
    ,MAX_MEMORY_PERCENT = 1 
	,MAX_PROCESSES  = 2
);  


CREATE WORKLOAD GROUP R_workgroup WITH (importance = medium) USING "default", 
EXTERNAL "RService_Resource_Pool";  

ALTER RESOURCE GOVERNOR WITH (classifier_function = NULL);  
ALTER RESOURCE GOVERNOR reconfigure;  

USE master  
GO  
CREATE FUNCTION RG_Class_function()  
RETURNS sysname  
WITH schemabinding  
AS  
BEGIN  
    IF program_name() in ('Microsoft R Host', 'RStudio') RETURN 'R_workgroup';  
    RETURN 'default'  
    END;  
GO  

ALTER RESOURCE GOVERNOR WITH  (classifier_function = dbo.RG_Class_function);  
ALTER RESOURCE GOVERNOR reconfigure;  
go 



ALTER RESOURCE GOVERNOR RECONFIGURE;  
GO  


-- We will run same query
-- and check for CPU consumption using Resource Monitor
EXECUTE  sp_execute_external_script
				 @language = N'R'
				,@script = N'
							library(RevoScaleR)
							f <- formula(as.numeric(ArrDelay) ~ as.numeric(DayOfWeek) + CRSDepTime)
							s <- system.time(mod <- rxLinMod(formula = f, data = AirLine))
							OutputDataSet <-  data.frame(system_time = s[3]);' -- Get Elapsed time from System.time function
				,@input_data_1 = N'SELECT * FROM AirlineDemoSmall'
				,@input_data_1_name = N'AirLine'
-- WITH RESULT SETS UNDEFINED
WITH RESULT SETS 
			((
				 Elapsed_time FLOAT
			));







-------------------------------------------

-- CREATE LOGIN for USER MSSQLSERVER01


--EXECUTE AS LOGIN  = 'SICN-KASTRUN\MSSQLSERVER01';
--GO

--SELECT SUSER_NAME(), USER_NAME();  



--EXECUTE  sp_execute_external_script
--				 @language = N'R'
--				,@script = N'
--							library(RevoScaleR)
--							f <- formula(as.numeric(ArrDelay) ~ as.numeric(DayOfWeek) + CRSDepTime)
--							s <- system.time(mod <- rxLinMod(formula = f, data = AirLine))
--							OutputDataSet <-  data.frame(system_time = s[3]);' -- Get Elapsed time from System.time function
--				,@input_data_1 = N'SELECT * FROM AirlineDemoSmall'
--				,@input_data_1_name = N'AirLine'
---- WITH RESULT SETS UNDEFINED
--WITH RESULT SETS 
--			((
--				 Elapsed_time FLOAT
--			));




--REVERT;  
--GO