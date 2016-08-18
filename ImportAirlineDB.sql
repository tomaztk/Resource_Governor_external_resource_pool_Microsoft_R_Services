USE master
GO

DROP DATABASE IF EXISTS RevoTestDB;
CREATE DATABASE RevoTestDB
GO
ALTER DATABASE [RevoTestDB] SET RECOVERY SIMPLE WITH NO_WAIT
GO
USE RevoTestDB;
GO
DROP TABLE IF EXISTS AirlineDemoSmallImport, AirlineDemoSmall;
GO
CREATE TABLE AirlineDemoSmallImport(
	ArrDelay varchar(100) NOT NULL, -- we start with varchar because missing values are coded as 'M'
	CRSDepTime float NOT NULL,
	DayOfWeek varchar(12) NOT NULL -- +2 for the quotes; 
)
GO

CREATE TABLE AirlineDemoSmall(
	ArrDelay int NULL,
	CRSDepTime float NOT NULL,
	DayOfWeek varchar(10) NOT NULL
		CONSTRAINT CHK_DOW CHECK(DayOfWeek IN ('Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'))
)
GO

BULK INSERT AirlineDemoSmallImport
FROM 'C:\Program Files\Microsoft SQL Server\MSSQL13.SQLSERVER2016RC3\R_SERVICES\library\RevoScaleR\SampleData\AirlineDemoSmall.csv'
WITH (
	FIELDTERMINATOR = ',',
	ROWTERMINATOR = '\n',
	FIRSTROW = 2 -- Skip header
)
GO
IF (SELECT COUNT(*) FROM dbo.AirlineDemoSmallImport) <> 600000
BEGIN
	RAISERROR('Not all rows were imported.', 20, -1) WITH LOG
END
GO
INSERT INTO dbo.AirlineDemoSmall(ArrDelay, CRSDepTime, DayOfWeek)
SELECT 
	CASE ArrDelay
		WHEN 'M' THEN NULL
		ELSE CONVERT(int, ArrDelay)
	END,
	CRSDepTime,
	REPLACE(DayOfWeek, '"', '')
FROM dbo.AirlineDemoSmallImport
GO
-- (600000 row(s) affected)
-- (600000 row(s) affected)

