USE [Prod_DFEnt_v32]
GO
/****** Object:  StoredProcedure [dbo].[uspDBAVitals]    Script Date: 08/28/2007 12:06:48 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
/**********************************************************************************
*   Name:      			uspDBAVitals
*   Author:           	Bob Delamater
*   Creation Date:    	04/03/2007
*   Description:     	uspDBAVitals returns information about cpu processes 
*						as well as other vital metrics needed for SQL health.
*		     	
*   Parameters: 		None
*	Requirements:		None
*   Returns: 			None
*	Disclaimer:			Adapted from online reference. Author unknown.
*************************************************************************************/

CREATE PROCEDURE [dbo].[uspDBAVitals] AS


-- Do not lock, and don't observe locks
SET TRANSACTION ISOLATION LEVEL 
	READ UNCOMMITTED

-- Suppress Row Messages
SET NOCOUNT ON

-- Set up variables
DECLARE @System_SPIDs INT,
		@sourceLocation VARCHAR(100)

-- Store details of processes running
DECLARE @Processes TABLE
	(
		spid			SMALLINT  
		, cpu		INT
		, physical_io	BIGINT
		, dbid		SMALLINT
		, program_name	NVARCHAR(128)
		, hostname		NVARCHAR(128)
		, loginame		NVARCHAR(128)
		, status		NVARCHAR(30)
		, cmd		NVARCHAR(16)
		, blocked		SMALLINT
		, ecid		SMALLINT		
	)

-- Set variables
SET @sourceLocation = @@SERVERNAME -- Identifies the routine
	+ '.' + DB_NAME() + '.' + OBJECT_NAME(@@PROCID)
SET @System_SPIDs = 50 -- System spids are below 50


-- Store info for calculations later
INSERT    @Processes 
SELECT 		 
	spid,
	cpu,
	physical_io,
	dbid,
	program_name,
	hostname,
	loginame,
	status,
	cmd,
	blocked,
	ecid
	
FROM sys.sysprocesses
WHERE spid != @@SPID  -- Ignore current process
	AND spid > @SYSTEM_SPIDS  -- Ignore system spids

-- Calculate cpu 
SELECT
	spid,
	cpu,
	physical_io,
	dbid,
	program_name,
	hostname,
	loginame,
	status,
	cmd,
	blocked,
	ecid,
	dbo.fnDBAGetSQLBySpid(spid) AS [SQL Command]
FROM @Processes
ORDER BY cpu DESC, physical_io DESC

