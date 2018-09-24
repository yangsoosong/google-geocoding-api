# Parsing addresses using [Google Geocoding API](https://developers.google.com/maps/documentation/geocoding/intro)


## First thoughts
>There are addresses input by user that has only street name and our current procedure is not able to correctly parse those. There must be algorithm that already exists to parse addresses with *free text input*.
<br />
Outsourcing the task could be a good option. We can send address to the Google(or Yahoo or 3rd party) geocoder.
<br />
The geocoders return rich parsing of the address with the information we need to parse the addresses.
<br />

#### Example of **XML** file from Google Geocoding API
<!--<p align ="center"><img src="/screenShots/xmlExample.PNG"></p>-->
![xml example](/screenShots/xmlExample.png)


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
![Create WEB API url](/screenShots/BuildGoogleAPIurl.PNG)
#### Generate OAUTH request
![generate OAUTH request](/screenShots/generateOauthRequest.PNG)

### 3. store xml result from google to temporary table and parse xml accordingly
#### Capture Response and start parsing
![capture response](/screenShots/parsingWestern.PNG)

- Western(US, France, German, etc.) -> (premise), <street_number> <route_> (subpremise) : `767(street_number) 5th Avenue(route) #45th Floor(subpremise)`
![not accepted requests](/screenShots/USExample.PNG)
- Korea / Japan -> (subpremise) <sublocality_level_3> <sublocality_level_4> <sublocality_level_2>, <sublocality_level_1>, (locality) :
`203(premise) Hoehyeon-dong(sublocality_level_2), Jung-gu(sublocality_level_1)`
![not accepted requests](/screenShots/KoreaExample.PNG)

#### Continue parsing(for JP/KR addresses) but differently due to different address formats
![capture response](/screenShots/caputreResponse.PNG)
##### Before
>some example of Japanese addresses that are falsely parsed
![capture response](/screenShots/previousJapan.PNG)
##### after
![capture response](/screenShots/improvedJapan.PNG)

#### Catch missing cases and populate in the table(return original/formatted addresses)
![capture response](/screenShots/missingCasesUpdateTable.PNG)

## Current status
![number of addresses per country](/screenShots/numberOfAddressPerCountry.PNG)
Confident that about 90% of 85% of addresses are correctly parsed. (We currently hold total of 8618 addresses to parse in our system.)



## Challenges
Some *challenges* I had with:
<br>
1% of the addresses(113) were not accepted by google(zero_results / invalid request) : User put random values / wrong info / google not responding
![not accepted requests](/screenShots/notAcceptedRequests.PNG)

	- When zero_result / invalid request from google
		-> Replace carriage return from database to single space
		-> just put original address from database for unresponsive ones
	- previous address overriding when next one is null
		-> store xml in a temporary table
	- few address(137) in 11 countries
		(country in ('cn', 'jp', 'hk', 'ro','eg','vn','ru','bh','th','ma','ae')
		contain native characters
		-> Restructure @Address value type to nvarchar instead of varchar
	- and more..


## Questions
**Do we want to return native characters in the address?**
<br/>
From Geocoding documentation:
>The geocoder does its best to provide a street address that is readable for both the user and locals. To achieve that goal, it returns street addresses in the local language, transliterated to a script readable by the user if necessary, observing the preferred language. All other addresses are returned in the preferred language. Address components are all returned in the same language, which is chosen from the first component.

>The preferred language has a small influence on the set of results that the API chooses to return, and the order in which they are returned. The geocoder interprets abbreviations differently depending on language, such as the abbreviations for street types, or synonyms that may be valid in one language but not in another. For example, utca and tér are synonyms for street in Hungarian.

**Do we want to parse the addresses differently for every country?**
<br />
It adds level of complexity to analyze addresses for each country and parse them differently..
- Western(US, France, German, etc.) -> (premise), <street_number> <route_> (subpremise) : `767(street_number) 5th Avenue(route) #45th Floor(subpremise)`
![not accepted requests](/screenShots/USExample.PNG)
- Korea / Japan -> (subpremise) <sublocality_level_3> <sublocality_level_4> <sublocality_level_2>, <sublocality_level_1>, (locality) :
`203(premise) Hoehyeon-dong(sublocality_level_2), Jung-gu(sublocality_level_1)`
![not accepted requests](/screenShots/KoreaExample.PNG)
- Russia?? Egypt??

We also have an option of getting **formatted addresses** from google but that will include city, state, zipcode and country in address field.
<br>
On the other hand, we cannot use edited formatted address as we are not *allowed* to manipulate formatted addresses according to the Google's policy.

<pre><code>This is a code block. Total of 8618 addresses.
https://maps.googleapis.com/maps/api/geocode/xml?sensor=false&address=Ginza%20Kagayaki%20Bldg.%205F,%201-15-8,%20Ginza,%20Chuo-ku,%20104-0061%20Tokyo,%20Japan&key=AIzaSyAWWLT180oTl-EyZR3Wj7kwua7lfJ1jiR0&language=us
</code></pre>
