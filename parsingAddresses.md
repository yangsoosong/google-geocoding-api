# Parsing addresses using [Google Geocoding API](https://developers.google.com/maps/documentation/geocoding/intro)

| Country        | Number of Addresses           |
| ------------- |:-------------:|
| US      | 4602 		 |
| GB      | 757      |
| HK      | 266      |
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
#### Create Web API url
![Create WEB API url](/screenShots/BuildAPIurl.PNG)
#### Generate OAUTH request
![generate OAUTH request](/screenShots/generateOauthRequest.PNG)

### 3. store xml result from google to temporary table and parse xml accordingly
#### Capture Response and start parsing
![capture response](/screenShots/parsingWestern.PNG)
#### Capture Response and start parsing(for JP/KR addresses) due to different return types
differences between Western / other addresses
* US/Western addresses -> (premise), {street number} {route} (subpremise)
* Korea/Japan addresses -> (subpremise) <sublocality_level_3> <sublocality_level_4> <sublocality_level_2>, <sublocality_level_1>, <locality>
![capture response](/screenShots/caputreResponse.PNG)
##### Before
![capture response](/screenShots/previousJapan.PNG)
##### after
![capture response](/screenShots/improvedJapan.PNG)

#### Catch missing cases and populate in the table(return original/formatted addresses) -> about 113 address out of 8618
![capture response](/screenShots/missingCasesUpdateTable.PNG)

## Current status
Confident that about 90% of 90% of addresses are correctly parsed.

![number of addresses per country](/screenShots/numberOfAddressPerCountry.PNG)

## issues
Some challenges I had with -> duplicate addresses for some address(previous one oevrriding when next one is null, solved by resetting the response value)
xml length -> response is only 8000 characters long and it had limit thus returning null value

some of the address(137) from some countries(country in ('ro','eg','vn','ru','bh','th','ma','ae') contain native characters

some of the address(113) were not accepted by google(zero_results / invalid request)
![not accepted requests](/screenShots/notAcceptedRequests.PNG)


## Questions
>I will show you some example of Japanese address that are not wrongly formatted

Returning native characters from the address

differences between Western / other addresses
- (premise), <street number> <route> (subpremise)
- (subpremise) <sublocality_level_3> <sublocality_level_4> <sublocality_level_2>, <sublocality_level_1>, <locality>

We have option of getting formatted addreess from google but that will include city, state, zipcode and country in address field.


It adds level of complexisty


Percentages of US addresses(4602/8618)

Can’t use edited formatted address as we are not allowed to manipulate formatted addresses according to their policy.

Country code to full country name?

chinese character -> https://gis.stackexchange.com/questions/63516/google-maps-api-how-to-get-the-street-name-in-multiple-languages









First thoughts when encountered the code(get some from original notes) ->
Geocode algorithm?
There are ones only with street name and our current procedure does not catch it.
Way to go through addresses data and insert it to procedure(nested select??)


Parsing address

	- when there is zero_result from google, just put original address
	- replace carriage counter from database to single space
	- length of xml was limited in sql(sauthrequest) -> store in a table

make the loop so that  untill there is no more null value for address_1

Outsourcing the task could be an option. We can send it to the Google (or Yahoo or 3rd party) geocoder. The geocoder will return not only the latitude and longitude of location(which we are not interested in), however, also a rich parsing of the address with the information we need to parse the addresses.




*single asterisks*

_single underscores_

**double asterisks**

__double underscores__

test

Use the `printf()` function.

![Alt text](/path/to/img.jpg)

<p>This is a normal paragraph:</p>

<pre><code>This is a code block.
</code></pre>
Small offset values zero result


This is [an example](http://example.com/ "Title") inline link.

[This link](http://example.net/) has no title attribute.
