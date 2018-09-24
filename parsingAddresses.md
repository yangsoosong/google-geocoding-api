# Parsing addresses using [Google Geocoding API](https://developers.google.com/maps/documentation/geocoding/intro)

## First thoughts


>There are addresses input by user that has only street name and our current procedure is not able to correctly parse those.
<br />
There must be algorithm that already exists to parse addresses with free text input.
<br />
Outsourcing the task could be a good option. We can send address to the Google(or Yahoo or 3rd party) geocoder.
<br />
The geocoders return rich parsing of the address with the information we need to parse the addresses.

<!--<p align ="center"><img src="/screenShots/xmlExample.PNG"></p>-->
![xml example](/screenShots/xmlExample.PNG)

## Parsing process

### 1. Populate original addresses to desired temp table
#### Use old script to insert new Data from manager.address table
![our custom routine](/screenShots/customRoutine.PNG)
#### Create temp table to hold only selected rows.
![creatingTempTable](/screenShots/creatingTempTable.PNG)
#### Declare input and output variables
![declare variables](/screenShots/declareVariables.PNG)
#### Create XML temp table and run while loop for entire table.
![c](/screenShots/createXMLtempTableRunWhileLoop.PNG)

### 2. Get the response from google
#### Create Web API url with `Google Geocoding API Key`
![Create WEB API url](/screenShots/BuildAPIurl.PNG)
#### Generate OAUTH request
![generate OAUTH request](/screenShots/generateOauthRequest.PNG)

### 3. store xml result from google to temporary table and parse xml accordingly
#### Capture Response and start parsing
![capture response](/screenShots/parsingWestern.PNG)
#### Capture Response and start parsing(for JP/KR addresses) due to different return types
differences between Western / other addresses
* US/Western addresses -> (premise), {street number} {route} (subpremise)
* Korea/Japan addresses -> (subpremise) <sublocality_level_3> <sublocality_level_4> <sublocality_level_2>, <sublocality_level_1>, (locality)
![capture response](/screenShots/caputreResponse.PNG)
##### Before
>some example of Japanese addresses that are falsely parsed
![capture response](/screenShots/previousJapan.PNG)
##### after
![capture response](/screenShots/improvedJapan.PNG)

#### Catch missing cases and populate in the table(return original/formatted addresses) -> about 113 address out of 8618
![capture response](/screenShots/missingCasesUpdateTable.PNG)

## Current status
Confident that about 90% of 90% of addresses are correctly parsed.
![number of addresses per country](/screenShots/numberOfAddressPerCountry.PNG)

## issues
#### (solved ones)
Some challenges I had with -> duplicate addresses for some address(previous one oevrriding when next one is null, solved by resetting the response value)
xml length -> response is only 8000 characters long and it had limit thus returning null value

	- when there is zero_result from google, just put original address
	- replace carriage counter from database to single space
	- length of xml was limited in sql(sauthrequest) -> store in a table


#### (unsolved ones)
few address(137) in 11 countries(country in ('cn', 'jp', 'hk', 'ro','eg','vn','ru','bh','th','ma','ae') contain native characters

some of the address(113) were not accepted by google(zero_results / invalid request)
![not accepted requests](/screenShots/notAcceptedRequests.PNG)


## Questions
**Do we want to return native characters in the address?**

**Do we want to parse the addresses differently between Western / other addresses?**
It adds level of complexity to analyze addresses for each country and parse them differently..
- Western(US, France, German, etc.) -> (premise), <street_number> <route_> (subpremise)
- Korea / Japan -> (subpremise) <sublocality_level_3> <sublocality_level_4> <sublocality_level_2>, <sublocality_level_1>, (locality)
- Russia?? Egypt??

We also have an option of getting formatted addresses from google but that will include city, state, zipcode and country in address field.
<br>
On the other hand, we cannot use edited formatted address as we are not allowed to manipulate formatted addresses according to the Google's policy.


*single asterisks*

_single underscores_

**double asterisks**

__double underscores__

Use the `printf()` function.

![Alt text](/path/to/img.jpg)

<p>This is a normal paragraph:</p>

<pre><code>This is a code block.
</code></pre>
Small offset values zero result