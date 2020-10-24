-- Module:Zodiac date
local p = {}

function p.main( frame )
local signNumber = tonumber(frame.args[1]) or 1
local year = tonumber(frame.args[2]) or os.date("!*t").year
--<span style="color:red">red writing</span>
if (year < 2015) or (year > 2050) or ((year == 2050) and (signNumber == 10)) then
	return '<span style="color:red">Error: Only 2015-2050 '..
		'(except Capricorn 2050) are supported.</span>'
end

--Template being replaced starts with Aries, which starts at 0 deg. longitude,
--However, we want to start with Aquarius, the sign that begins in January.


local sn = {3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 1, 2}
signNumber = sn[signNumber]
year = year-2015

local zd = {
"January 20", "February 18", "March 20", "April 20", "May 21", "June 21",
"July 23", "August 23", "September 23", "October 23", "November 22", "December 22",
"January 20", "February 19", "March 20", "April 19", "May 20", "June 20",
"July 22", "August 22", "September 22", "October 22", "November 21", "December 21",
"January 19", "February 18", "March 20", "April 19", "May 20", "June 21",
"July 22", "August 22", "September 22", "October 23", "November 22", "December 21",
"January 20", "February 18", "March 20", "April 20", "May 21", "June 21",
"July 22", "August 23", "September 23", "October 23", "November 22", "December 21",
"January 20", "February 18", "March 20", "April 20", "May 21", "June 21",
"July 23", "August 23", "September 23", "October 23", "November 22", "December 22",
"January 20", "February 19", "March 20", "April 19", "May 20", "June 20",
"July 22", "August 22", "September 22", "October 22", "November 21", "December 21",
"January 19", "February 18", "March 20", "April 19", "May 20", "June 21",
"July 22", "August 22", "September 22", "October 23", "November 22", "December 21",
"January 20", "February 18", "March 20", "April 20", "May 21", "June 21",
"July 22", "August 23", "September 23", "October 23", "November 22", "December 21",
"January 20", "February 18", "March 20", "April 20", "May 21", "June 21",
"July 23", "August 23", "September 23", "October 23", "November 22", "December 22",
"January 20", "February 19", "March 20", "April 19", "May 20", "June 20",
"July 22", "August 22", "September 22", "October 22", "November 21", "December 21",
"January 19", "February 18", "March 20", "April 19", "May 20", "June 21",
"July 22", "August 22", "September 22", "October 23", "November 22", "December 21",
"January 20", "February 18", "March 20", "April 20", "May 21", "June 21",
"July 22", "August 23", "September 23", "October 23", "November 22", "December 21",
"January 20", "February 18", "March 20", "April 20", "May 21", "June 21",
"July 23", "August 23", "September 23", "October 23", "November 22", "December 22",
"January 20", "February 19", "March 20", "April 19", "May 20", "June 20",
"July 22", "August 22", "September 22", "October 22", "November 21", "December 21",
"January 19", "February 18", "March 20", "April 19", "May 20", "June 21",
"July 22", "August 22", "September 22", "October 23", "November 22", "December 21",
"January 20", "February 18", "March 20", "April 20", "May 20", "June 21",
"July 22", "August 23", "September 22", "October 23", "November 22", "December 21",
"January 20", "February 18", "March 20", "April 20", "May 21", "June 21",
"July 23", "August 23", "September 23", "October 23", "November 22", "December 22",
"January 20", "February 19", "March 20", "April 19", "May 20", "June 20",
"July 22", "August 22", "September 22", "October 22", "November 21", "December 21",
"January 19", "February 18", "March 20", "April 19", "May 20", "June 21",
"July 22", "August 22", "September 22", "October 23", "November 22", "December 21",
"January 20", "February 18", "March 20", "April 20", "May 20", "June 21",
"July 22", "August 23", "September 22", "October 23", "November 22", "December 21",
"January 20", "February 18", "March 20", "April 20", "May 21", "June 21",
"July 22", "August 23", "September 23", "October 23", "November 22", "December 22",
"January 20", "February 19", "March 20", "April 19", "May 20", "June 20",
"July 22", "August 22", "September 22", "October 22", "November 21", "December 21",
"January 19", "February 18", "March 20", "April 19", "May 20", "June 21",
"July 22", "August 22", "September 22", "October 23", "November 21", "December 21",
"January 19", "February 18", "March 20", "April 19", "May 20", "June 21",
"July 22", "August 23", "September 22", "October 23", "November 22", "December 21",
"January 20", "February 18", "March 20", "April 20", "May 21", "June 21",
"July 22", "August 23", "September 23", "October 23", "November 22", "December 22",
"January 20", "February 19", "March 20", "April 19", "May 20", "June 20",
"July 22", "August 22", "September 22", "October 22", "November 21", "December 21",
"January 19", "February 18", "March 20", "April 19", "May 20", "June 20",
"July 22", "August 22", "September 22", "October 23", "November 21", "December 21",
"January 19", "February 18", "March 20", "April 19", "May 20", "June 21",
"July 22", "August 22", "September 22", "October 23", "November 22", "December 21",
"January 20", "February 18", "March 20", "April 20", "May 21", "June 21",
"July 22", "August 23", "September 23", "October 23", "November 22", "December 22",
"January 20", "February 19", "March 19", "April 19", "May 20", "June 20",
"July 22", "August 22", "September 22", "October 22", "November 21", "December 21",
"January 19", "February 18", "March 20", "April 19", "May 20", "June 20",
"July 22", "August 22", "September 22", "October 23", "November 21", "December 21",
"January 19", "February 18", "March 20", "April 19", "May 20", "June 21",
"July 22", "August 22", "September 22", "October 23", "November 22", "December 21",
"January 20", "February 18", "March 20", "April 20", "May 21", "June 21",
"July 22", "August 23", "September 23", "October 23", "November 22", "December 21",
"January 20", "February 18", "March 19", "April 19", "May 20", "June 20",
"July 22", "August 22", "September 22", "October 22", "November 21", "December 21",
"January 19", "February 18", "March 20", "April 19", "May 20", "June 20",
"July 22", "August 22", "September 22", "October 22", "November 21", "December 21",
"January 19", "February 18", "March 20", "April 19", "May 20", "June 21",
"July 22", "August 22", "September 22", "October 23", "November 22", "December 21",
}

return zd[signNumber+12*year].." &ndash; "..zd[1+signNumber+12*year]
end

return p