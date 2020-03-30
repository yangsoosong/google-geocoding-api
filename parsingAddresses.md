
power point?
# Parsing addresses using [Google Geocoding API](https://developers.google.com/maps/documentation/geocoding/intro)

## Parsing process
1. How to populate original addresses
2. Get the response from google
3. store xml file from google to temporary table
4. parse address accordingly

## Issues
>I will show you some example of Japanese address that are not wrongly formatted

It adds level of complexisty
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

Percentages of US addresses

Can’t use edited formatted address as we are not allowed to manipulate formatted addresses according to their policy.

Country code to full country name?


suite -> just return the original address?

chinese character -> https://gis.stackexchange.com/questions/63516/google-maps-api-how-to-get-the-street-name-in-multiple-languages

First thoughts when encountered the code(get some from original notes) ->
Geocode algorithm?
There are ones only with street name and our current procedure does not catch it.
Way to go through addresses data and insert it to procedure(nested select??)

Outsourcing the task could be an option. We can send it to the Google (or Yahoo or 3rd party) geocoder. The geocoder will return not only the latitude and longitude of location(which we are not interested in), however, also a rich parsing of the address with the information we need to parse the addresses.
