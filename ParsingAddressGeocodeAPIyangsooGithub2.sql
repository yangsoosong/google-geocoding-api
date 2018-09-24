USE efront_excel_data


TRUNCATE TABLE util_parse_address_yangsoo
-- Used old procedure to insert new data from manager_address table to util_parse_address table
INSERT INTO util_parse_address_yangsoo (address_id, original_address, address_1, address_2, address_3, city, [state], zip, country, xmlCode)
	SELECT	
			manager_address_id AS address_id
			,[address] AS original_address
			,SUBSTRING([address],1,CHARINDEX(char(13)+char(10),[address])) AS address_1
			,'' AS address_2
			,'' AS address_3
			,'' AS city
			,'' AS [state]
			,'' AS zip
			,'' AS country
			,'' AS xmlCode
	FROM  [efront_star].DBO.manager_address
	WHERE [address] is not null
		and rtrim(ltrim(replace(replace(address,char(13),' '),char(10),' '))) <> ''
		and rtrim(ltrim(replace(replace(address,char(13),' '),char(10),' '))) <> 'none specified'
		and rtrim(ltrim(replace(replace(address,char(13),' '),char(10),' '))) <> 'TBD'
		and rtrim(ltrim(replace(replace(address,char(13),' '),char(10),' '))) <> 'Unknown'
		and rtrim(ltrim(replace(replace(address,char(13),' '),char(10),' '))) <> 'somewhere'
		and rtrim(ltrim(replace(replace(address,char(13),' '),char(10),' '))) <> 'TBC'
		and rtrim(ltrim(replace(replace(address,char(13),' '),char(10),' '))) <> 'N/A'
		and rtrim(ltrim(replace(replace(address,char(13),' '),char(10),' '))) <> '?'
		and rtrim(ltrim(replace(replace(address,char(13),' '),char(10),' '))) <> 'Address TBC'
		and rtrim(ltrim(replace(replace(address,char(13),' '),char(10),' '))) <> 'To Be Determined'
		and rtrim(ltrim(replace(replace(address,char(13),' '),char(10),' '))) <> 'TBC'
		and rtrim(ltrim(replace(replace(address,char(13),' '),char(10),' '))) <> 'Not provided'
		and rtrim(ltrim(replace(replace(address,char(13),' '),char(10),' '))) <> 'No listed address'
		and [address] not like 'Do not contact Absolute Managers directly%'
		and [address] not like 'No address listed to date%'


-- Drop temp table if already exists
DROP TABLE IF EXISTS #Temp

/* 
USE temporary table (#Temp) to copy table from manager_address and then deleted the row in #Temp table every time I update the row.
*/
-- Instead of selecting all, select number that does not exceed 2500 request per day --SELECT *
-- Table to grab data with rownumber
; WITH MySelectedRows AS (
    SELECT ROW_NUMBER() OVER (ORDER BY address_id) as RowNumber, *
    FROM util_parse_address_yangsoo2
)
-- Grab desired rows with RowNumber
SELECT *  
INTO #Temp
FROM MySelectedRows
where country in ('jp', 'kr')
--WHERE RowNumber BETWEEN 1 AND 10

/*
-- Select every rows from address table
select *
into #temp
from util_parse_address
where address_id = 566
*/


-- Declare input and output variables
DECLARE @Address as nvarchar(100),
	@City as varchar(25),
	@State as varchar(2),
	@PostalCode as varchar(10),
	@Country varchar(40),
	@County varchar(40),
	@CountAddress int

-- Set temporary variable @Id to refer selected manager_address_id.
DECLARE @Id int

-- create temp table to store xml response results(in order to avoid xml length limit error)
IF OBJECT_ID('tempdb..#xml') IS NOT NULL DROP TABLE #xml
	CREATE TABLE #xml ( yourXML XML )
	
-- Run while loop until there is no more row on #Temp.
WHILE (SELECT count(*) FROM #Temp) > 0
BEGIN
	-- Select the first row of #Temp and set its manager_address_id to @Id to update selected row.
	SELECT TOP 1 @Id = address_id FROM #Temp


	-- URL call to the Google Geocode API
	DECLARE @URL varchar(max)
	-- send url to server with appending original address from util_parse_address table.
	SET @URL = 'https://maps.googleapis.com/maps/api/geocode/xml?sensor=false&address=' + 
	-- Replace CARRIAGE RETURN from database with single space as carriage returns were omitted when transformed to url
	REPLACE(REPLACE(REPLACE((SELECT original_address FROM util_parse_address_yangsoo2 upa WHERE upa.address_id = @Id), char(13), ' '), char(10), ' '), CHAR(13)+CHAR(10), ' ')
		-- Need API Key here
		-- (Yangsoo's)
		+ '&YourAPI_Key here'
	SET @URL = REPLACE(@URL, ' ', '+');

	-- Generate OAUTH request.
	DECLARE @Response varchar(8000)
	DECLARE @XML xml
	DECLARE @obj int
	DECLARE @Result int
	DECLARE @HTTPStatus int
	DECLARE @ErrorMsg varchar(MAX)
	-- Set @Response to empty string to detect bug
	--SET @Response = ''

	EXEC @Result = sp_OACreate 'MSXML2.ServerXMLHttp', @Obj OUT

	BEGIN TRY
		EXEC @Result = sp_OAMethod @obj, 'open', NULL, 'GET', @URL, false
		EXEC @Result = sp_OAMethod @obj, 'setRequestHeader', NULL, 'Content-Type', 'applicatin/x-www-form-urlencoded'
		EXEC @Result = sp_OAMethod @obj, send, NULL, ''
		EXEC @Result = sp_OAGetProperty @obj, 'status', @HTTPStatus OUT
		-- Put the result directly into temp table
		INSERT #xml(yourXML)
		EXEC @Result = sp_OAGetProperty @obj, 'responseXML.xml' -- @Response OUT 
	END TRY
	BEGIN CATCH
		SET @ErrorMsg = ERROR_MESSAGE()
		SET @ErrorMsg = 'Error in spGeocode: ' + ISNULL(@ErrorMsg, 'HTTP result is: ' + CAST(@HTTPStatus AS varchar(10)))
		RAISERROR(@ErrorMsg, 16, 1, @HTTPStatus)
	END CATCH
	
	EXEC @Result = sp_OADestroy @Obj
	
	/* -- Testing error
	IF (@ErrorMSG IS NOT NULL) OR (@HTTPStatus <> 200)
	BEGIN
		SET @ErrorMsg = 'Error in spGeocode: ' + ISNULL(@ErrorMsg, 'HTTP result is: ' + CAST(@HTTPStatus AS varchar(10)))
		RAISERROR(@ErrorMsg, 16, 1, @HTTPStatus)
		RETURN
	END
	*/

	-- Attain the response from Google.
	-- pull the value from the temp table
	select @XML = yourXML from #xml 
	--select 'lenXML' = len(rtrim(convert(nvarchar(max),yourXML))), * from #xml
	truncate table #xml
	-- parse xml into parts for City, State, Postalcode, Country and County.
	SET @City = @XML.value('(/GeocodeResponse/result/address_component[type="locality"]/long_name) [1]', 'varchar(40)')
	SET @State = @XML.value('(/GeocodeResponse/result/address_component[type="administrative_area_level_1"]/short_name) [1]', 'varchar(40)')
	SET @PostalCode = @XML.value('(/GeocodeResponse/result/address_component[type="postal_code"]/short_name) [1]', 'varchar(20)')
	SET @Country = @XML.value('(/GeocodeResponse/result/address_component[type="country"]/short_name) [1]', 'nvarchar(40)')
	SET @County = @XML.value('(/GeocodeResponse/result/address_component[type="administrative_area_level_2"]/long_name) [1]', 'varchar(40)')
	
	-- OPTION 1(For Korean/Japanses addresses).
	if @country in ('jp', 'kr')
	SET @Address =
		-- building names belong to supremise in KR addresses
		CASE WHEN ((ISNULL(@XML.value('(/GeocodeResponse/result/address_component[type="subpremise"]/long_name) [1]', 'nvarchar(40)'), '')) != '')
				THEN (ISNULL(@XML.value('(/GeocodeResponse/result/address_component[type="subpremise"]/long_name) [1]', 'nvarchar(40)'), '')) + ', '
			ELSE ''
		END +
		-- insert building name in front with comma at the end if exists in xml code
		CASE WHEN ((ISNULL(@XML.value('(/GeocodeResponse/result/address_component[type="premise"]/long_name) [1]', 'nvarchar(40)'), '')) != '')
				THEN (ISNULL(@XML.value('(/GeocodeResponse/result/address_component[type="premise"]/long_name) [1]', 'nvarchar(40)'), '')) + ', ' 
			ELSE '' 
		END +
		CASE WHEN ((ISNULL(@XML.value('(/GeocodeResponse/result/address_component[type="sublocality_level_3"]/long_name) [1]', 'nvarchar(40)'), '')) != '')
				THEN (ISNULL(@XML.value('(/GeocodeResponse/result/address_component[type="sublocality_level_3"]/long_name) [1]', 'nvarchar(40)'), '')) + ', ' 
			ELSE '' 
		END +
		CASE WHEN ((ISNULL(@XML.value('(/GeocodeResponse/result/address_component[type="sublocality_level_4"]/long_name) [1]', 'nvarchar(40)'), '')) != '')
				THEN (ISNULL(@XML.value('(/GeocodeResponse/result/address_component[type="sublocality_level_4"]/long_name) [1]', 'nvarchar(40)'), '')) + ', ' 
			ELSE '' 
		END +
		CASE WHEN ((ISNULL(@XML.value('(/GeocodeResponse/result/address_component[type="sublocality_level_2"]/long_name) [1]', 'nvarchar(40)'), '')) != '')
				THEN (ISNULL(@XML.value('(/GeocodeResponse/result/address_component[type="sublocality_level_2"]/long_name) [1]', 'nvarchar(40)'), '')) + ', ' 
			ELSE '' 
		END +
		CASE WHEN ((ISNULL(@XML.value('(/GeocodeResponse/result/address_component[type="sublocality_level_1"]/long_name) [1]', 'nvarchar(40)'), '')) != '')
				THEN (ISNULL(@XML.value('(/GeocodeResponse/result/address_component[type="sublocality_level_1"]/long_name) [1]', 'nvarchar(40)'), '')) + ', ' 
			ELSE '' 
		END +
		CASE WHEN ((ISNULL(@XML.value('(/GeocodeResponse/result/address_component[type="locality"]/long_name) [1]', 'nvarchar(40)'), '')) != '')
				THEN ' ' + (ISNULL(@XML.value('(/GeocodeResponse/result/address_component[type="locality"]/long_name) [1]', 'nvarchar(40)'), '')) 
			ELSE '' 
		END

	else
	-- OPTION 2(For western addresses). Get address with appending premise, street_number, route and subpremise on Geocode.
	SET @Address =
		-- insert floor number / building name in front with comma at the end if exists in xml code
		CASE WHEN ((ISNULL(@XML.value('(/GeocodeResponse/result/address_component[type="floor"]/long_name) [1]', 'nvarchar(40)'), '')) != '')
				THEN (ISNULL(@XML.value('(/GeocodeResponse/result/address_component[type="floor"]/long_name) [1]', 'nvarchar(40)'), '')) + ', ' 
			ELSE '' 
		END +
		CASE WHEN ((ISNULL(@XML.value('(/GeocodeResponse/result/address_component[type="premise"]/long_name) [1]', 'nvarchar(40)'), '')) != '')
				THEN (ISNULL(@XML.value('(/GeocodeResponse/result/address_component[type="premise"]/long_name) [1]', 'nvarchar(40)'), '')) + ', ' 
			ELSE '' 
		END +
		ISNULL(@XML.value('(/GeocodeResponse/result/address_component[type="street_number"]/long_name) [1]', 'nvarchar(40)'), '') + ' ' +
		ISNULL(@XML.value('(/GeocodeResponse/result/address_component[type="route"]/long_name) [1]', 'nvarchar(40)'), '') + ' ' +
		-- insert # symbol in front of suite number(supremise)
		CASE WHEN ((ISNULL(@XML.value('(/GeocodeResponse/result/address_component[type="subpremise"]/long_name) [1]', 'nvarchar(40)'), '')) != '')
				THEN '#' + (ISNULL(@XML.value('(/GeocodeResponse/result/address_component[type="subpremise"]/long_name) [1]', 'nvarchar(40)'), ''))
			ELSE ''
		END

	---- OPTION 3. Get address with formated address(which includes city, state, postal code and country).
	--SET @Address = @XML.value('(/GeocodeResponse/result/formatted_address) [1]', 'nvarchar(80)')
	

		--If geocode returns ZERO_RESULTS as GEOCODERESPONSE STATUS, return original address
		IF @XML.value('(/GeocodeResponse/status) [1]', 'nvarchar(40)') = 'ZERO_RESULTS' or
			@XML.value('(/GeocodeResponse/status) [1]', 'nvarchar(40)') = 'INVALID_REQUEST'
			SET @Address = (SELECT original_address FROM util_parse_address_yangsoo2 upa WHERE upa.address_id = @Id)

		--If geocode is not successful at figuring out the address due to bad data(which has original address as TEST, only city or country name), 
		--and therefore not returning any street number, route or subpremise,
		--just return 'formated address' from the server.
		IF (RTRIM(LTRIM(@Address))) in('', '  ', NULL) --AND (@Country is not null)
			SET @Address = @XML.value('(/GeocodeResponse/result/formatted_address) [1]', 'nvarchar(80)')
	
	-- update util_parse_address table with updated values.
	UPDATE util_parse_address_yangsoo2 SET address_1 = @Address FROM util_parse_address_yangsoo2 upa where address_id = @Id;
	UPDATE util_parse_address_yangsoo2 SET city = @City FROM util_parse_address_yangsoo2 upa where address_id = @Id;
	UPDATE util_parse_address_yangsoo2 SET state = @State FROM util_parse_address_yangsoo2 upa where address_id = @Id;
	UPDATE util_parse_address_yangsoo2 SET zip = @PostalCode FROM util_parse_address_yangsoo2 upa where address_id = @Id;
	UPDATE util_parse_address_yangsoo2 SET country = @Country FROM util_parse_address_yangsoo2 upa where address_id = @Id;
	UPDATE util_parse_address_yangsoo2 SET xmlCode = CONVERT(nvarchar(max), @XML) FROM util_parse_address_yangsoo2 upa where address_id = @Id;

	-- Delete the row if the row is updated in #Temp table(address_1 is not null), if not, keep it in the table so that the row can be updated
	IF (select address_1 FROM util_parse_address_yangsoo2 upa where address_id = @Id) is not null
	DELETE #Temp where address_id = @Id
END


/* TESTing part-------------------------------------------------------------------------------------------*/

-- Check the result for the procedure
SELECT * FROM efront_excel_data.dbo.util_parse_address_yangsoo2 upa
--where country in ('ro','eg','vn','ru','bh','th','ma','ae')
where country = ''
--where address_1 like '%?%'
--where country = 'TH'

select distinct country from efront_excel_data.dbo.util_parse_address_yangsoo2 order by country
SELECT * FROM efront_excel_data.dbo.util_parse_address_yangsoo2 upa
where country is null -- = 'us'

select country ,count(*) as #_of_Addresses 
from efront_excel_data.dbo.util_parse_address_yangsoo2
group by country
order by #_of_Addresses desc

--where country in ('CN', 'JP') --AND address_1 like '%?%'
--where address_id = 13894
--where (xmlCode like '%INVALID%') or (xmlCode like '%ZERO%')
--where country is null
--where country = 'CN'
--where country = 'jp'
--where country = 'KR'
--where country in ('KR', 'JP', 'HK', 'CN')

SELECT * FROM efront_excel_data.dbo.util_parse_address_yangsoo2 upa
where country is null