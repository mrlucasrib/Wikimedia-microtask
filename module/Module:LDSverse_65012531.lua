-- This module implements the lion's share of the newly-revised-as-of-August-2020 Template:LDS.
local p = {}

-- TODO:
--	Check the verse parameter to make sure it's a number (sometimes users 
--		mistakenly include the en dash and ending verse number in this 
--		parameter, e.g., {{LDS|Alma|alma|7|11–12}}). If it isn't a number, 
--		default to citing to the chapter as a whole?
--	Take out the remaining error statements and handle errors more gracefully.
--		(As of September 2020, many have already been removed, so that's good.)
--		Functions with error statements left in them:
--			getFullBookName
--			handleOD
--			getStandardWork (only throws an error if pre-conditions not met)
--			getLectureOrdinal (only called with pcall)

--[[
	First: define bomBooks, dcBooks, pogpBooks, lofBooks, and bibleBooks
	These tables (one for each Standard Work) are the heart of the module.
	They have the following structure:
		The key is the "correct" name of the book, defined as how it is titled
			on Wikisource
		The value for each book is an array of other names it might be known by.
			Some of these are standard abbreviations, some are common typos 
			(e.g., "Revelations"), and some are included to ensure backwards 
			compatibility with the original {{LDS}} template (e.g., 1_jn).
			NB: The values do not contain capitalization variants, as those will
			be tested for in the logic (since these tables are already huge).
	
	The tables are then themselves stored in an array titled standardWorks
]]

local bomBooks = {
	["Title Page"] = {"ttl", "ttlpg", "title", "title-page", "title_page"},
	["Testimony of Three Witnesses"] = {"three", "3witnesses"},
	["Testimony of Eight Witnesses"] = {"eight", "8witnesses"},
	["1 Nephi"] = {"1-ne", "1_ne", "1ne", "1 ne"}, 
	["2 Nephi"] = {"2-ne", "2_ne", "2ne", "2 ne"}, 
	["Jacob"] = {"jac"}, 
	["Enos"] = {"en"}, 
	["Jarom"] = {"jar"},
	["Omni"] = {"omn"}, 
	["Words of Mormon"] = {"w-of-m", "wofm", "w_of_m"}, 
	["Mosiah"] = {}, 
	["Alma"] = {}, 
	["Helaman"] = {"hel"}, 
	["3 Nephi"] = {"3-ne", "3_ne", "3ne", "3 ne"}, 
	["4 Nephi"] = {"4-ne", "4_ne", "4ne", "4 ne"}, 
	["Mormon"] = {"morm", "mormon"}, 
	["Ether"] = {}, 
	["Moroni"] = {"moro", "moroni"}
}

local dcBooks = {
	["The Doctrine and Covenants"] = {"dc", "d-c", "d&c", "d & c",
		"doctrine and covenants"},
	["Official Declaration"] = {"od", "official declaration"}
}

local lofBooks = {
	["Lectures on Faith"] = {"lof", "l-o-f", "l-of-f", "loff", "lectures"}
}

local pogpBooks = {
	["Moses"] = {},
	["Abraham"] = {"abr", "fac-1", "fac1", "fac-2", "fac2", "fac-3", "fac3"},
	["JST Matthew"] = {"js-m", "jsm", "joseph smith matthew", "jst matt",
		"jst-matt", "jst-matthew", "js matthew"}, -- NB: This is a special case!
	["History"] = {"js-h", "jsh", "js history", "joseph smith history", 
		"js-hist", "js hist"},
	["Articles of Faith"] = {"a-of-f", "a_of_f", "aoff", "the articles of faith"}
}

local bibleBooks = {						-- adapted from Module: Bibleverse
	["Genesis"] = {"gen", "gn"},			-- Old Testament/Tanakh
	["Exodus"] = {"exod", "ex"},
	["Leviticus"] = {"lev", "lv"},
	["Numbers"] = {"num", "nm"},
	["Deuteronomy"] = {"deut", "dt"},
	["Joshua"] = {"josh" , "jo"},
	["Judges"] = {"judg", "jgs"},
	["Ruth"] = {"ru", "ruth"},
	["1 Samuel"] = {"1sam", "1sm", "1_sam", "1-sam", "1 sam"},
	["2 Samuel"] = {"2sam", "2sm", "2_sam", "2-sam", "2 sam"},
	["1 Kings"] = {"1kgs", "1-kgs", "1_kgs", "1 kgs"},
	["2 Kings"] = {"2kgs", "2-kgs", "2_kgs", "2 kgs"},
	["1 Chronicles"] = {"1chron", "1chr", "1-chr", "1_chr", "1 chr"},
	["2 Chronicles"] = {"2chron", "2chr", "2-chr", "2_chr", "2 chr"},
	["Ezra"] = {},
	["Nehemiah"] = {"neh"},
	["Esther"] = {"est", "esth"},
	["Job"] = {"jb"},
	["Psalms"] = {"ps", "pss", "psalm"},
	["Proverbs"] = {"prov", "prv"},
	["Ecclesiastes"] = {"eccles", "eccl", "qoheleth"},
	["Song of Solomon"] = {"songofsol", "songofsongs", "song", "songs", "sg", 
		"canticles", "canticleofcanticles", "songs of solomon"},	-- catch typos
	["Isaiah"] = {"isa", "is"},
	["Jeremiah"] = {"jer"},
	["Lamentations"] = {"lam"},
	["Ezekiel"] = {"ezek", "ez"},
	["Daniel"] = {"dan", "dn"},
	["Hosea"] = {"hos"},
	["Joel"] = {"jl"},
	["Amos"] = {"am"},
	["Obadiah"] = {"obad", "ob"},
	["Jonah"] = {"jon"},
	["Micah"] = {"mic", "mi"},
	["Nahum"] = {"nah", "na"},
	["Habakkuk"] = {"hab", "hb"},
	["Zephaniah"] = {"zeph", "zep"},
	["Haggai"] = {"hag", "hg"},
	["Zechariah"] = {"zech", "zec", "zach", "zac"},		-- catch typos
	["Malachi"] = {"mal"},
	
	["Matthew"] = {"matt", "mt"},						-- New Testament
	["Mark"] = {"mk"},
	["Luke"] = {"lk"},
	["John"] = {"jn"},
	["Acts"] = {"actsoftheapostles", "the acts", "acts of the apostles",
		"the acts of the apostles"},
	["Romans"] = {"rom", "roman"},
	["1 Corinthians"] = {"1cor", "1-cor", "1_cor", "1 cor"},
	["2 Corinthians"] = {"2cor", "2-cor", "2_cor", "2 cor"},
	["Galatians"] = {"gal"},
	["Ephesians"] = {"eph"},
	["Philippians"] = {"phil", "philip"},
	["Colossians"] = {"col"},
	["1 Thessalonians"] = {"1thess", "1thes", "1-thes", 
		"1_thes", "1-thess", "1_thess", "1 thess", "1 thes"},	-- catch typos
	["2 Thessalonians"] = {"2thess", "2thes", "2-thes", 
		"2_thes", "2-thess", "2_thess", "2 thess", "2 thes"},	-- catch typos
	["1 Timothy"] = {"1tim", "1tm", "1-tim", "1_tim", "1 tim"},
	["2 Timothy"] = {"2tim", "2tm", "2-tim", "2_tim", "2 tim"},
	["Titus"] = {"ti"},
	["Philemon"] = {"philem", "phlm"},
	["Hebrews"] = {"heb", "hebrew"},						-- catch typos
	["James"] = {"jas"},
	["1 Peter"] = {"1pet", "1pt", "1-pet", "1_pet", "1 pet"},
	["2 Peter"] = {"2pet", "2pt", "2-pet", "2_pet", "2 pet"},
	["1 John"] = {"1jn", "1-jn", "1_jn", "1 jn"},
	["2 John"] = {"2jn", "2-jn", "2_jn", "2 jn"},
	["3 John"] = {"3jn", "3-jn", "3_jn", "3 jn"},
	["Jude"] = {},
	["Revelation"] = {"rev", "apocalypse", "apoc", "rv", 
		"revelations"},										-- catch typos
}

-- This table holds the titles of the Standard Works themselves, as found on WS
local standardWorks = {
	["Book of Mormon (1981)"] = bomBooks, 
	["The Doctrine and Covenants"] = dcBooks, 
	["The Pearl of Great Price (1913)"] = pogpBooks, 
	["Bible (King James)"] = bibleBooks,
	["Lectures on Faith"] = lofBooks
}

local wsBaseURL = "[[s:"
local wsStandardWorks = "Portal:Mormonism#LDS_Standard_Works_(Scriptures)"

	-- [=======[ ...oooOOOOOOOooo... ]=======] --
-- [===========[   HELPER FUNCTIONS  ]===========] --
	-- [=======[ ...oooOOOOOOOooo... ]=======] --

--[[
	local function getFullBookName(bookParam)
	Returns the full name of a book of scripture based on the name/abbrev./alias provided
	Pre-condition: bookParam is non-nil
	
	NB: Because both Matthew in the NT and JST Matthew have just the title
		"Matthew" on Wikisource, this function returns "JST Matthew" as the full name
		of the latter, so that must be dealt with as a special case when constructing
		the actual link to Wikisource (i.e., you can't just sub that "full name" in 
		like you can for all other books!)
]]
local function getFullBookName(bookParam)

	for title,bookList in pairs(standardWorks) do
		if bookList[bookParam] then 
			return bookParam -- fully correct name provided already! Done!
		end
	end
	
-- OK so the correct full name wasn't provided to begin with, so we search
--		in more depth. First we loop through all the Standard Works and pull out
--		the bookLists (e.g., bomBookList or bibleBookList)
	for title,bookList in pairs(standardWorks) do
		-- next we loop through the bookList and do a case-insensitive compare 
		--		between the full name of each book and the book name provided
		for fullName,abbrevs in pairs(bookList) do
			if string.lower(fullName) == string.lower(bookParam) then
				-- great news, they passed in e.g. "job", which matches "Job"! Done!
				return fullName
			end
			-- ok they didn't just pass in a different-cased version of the full name
			--		so we have to do a case-insensitive compare between all the
			--		book abbreviations/aliases and the book name provided
			for i,abbrev in pairs(abbrevs) do
				-- In theory all the abbrev's should be all lowercase anyway, 
				--		but who knows if later people maintaining this code will
				--		keep that convention so we lower both strings.
				if string.lower(abbrev) == string.lower(bookParam) then
					-- found an abbreviation/alias that matches! Done!
					return fullName
				end
			end
		end
	end
	
	-- At this point we've searched, without regard to case, creed, or color,
	--	for the alleged book of scripture they provided, but it ain't here!
	error("Book <" .. bookParam .. "> not found in Standard Works", 0)
	return ""
end --function getFullBookName(bookParam)

--[[
	local function getStandardWork(bookParam)
	returns the Standard Work (as titled by Wikisource) that contains the book 
		passed in.
	Preconditions: bookName is non-nil and was returned by getFullBookName
]]
local function getStandardWork(bookName)
	
	-- check the standardWorks table for any values that have a key with the 
	-- full name of the book; if so, return the key (the title of the SW)
	for title,bookList in pairs(standardWorks) do
		if bookList[bookName] then return title end
	end
	
	error("Book <" .. bookName .. "> is not a full book name found in Standard Works", 0)
	-- pre-conditions mean that this error should never occur, aka if it does, 
	--	something went very wrong!
end

-- Preconditions: book, and chapter are non-nil
local function buildBookmark(book, chapter, verse)
	
	if string.find(book, "^Section") then
		if verse then
			return "#" .. verse -- D&C sections just use the verse number
		else
			return "" -- if they're just citing a Section then no bookmark needed at all
		end
	end
	
	if string.find(book, "^Lecture") then
		if verse then
			return "#" .. verse -- D&C sections just use the verse number
		else
			return "" -- if they're just citing a Section then no bookmark needed at all
		end
	end
	
	if verse then
		return "#" .. chapter .. ":" .. verse
	else
		return "#chapter_" .. chapter
	end

end

local function buildFinalDisplayText(displayText, chapter, verse, endVerse, endVerseFlag)
	local t = displayText
	if chapter then t =  t .. " " .. chapter end
	if verse then
		t = t .. ":" .. verse
		if endVerse then
			if endVerseFlag then
				t = t .. endVerse
			else
				t = t .. "–" .. endVerse
			end
		end
	end
	return t
end

-- Special case for handling the Official Declarations in the D&C
-- Pre-condition: displayTextParam is non-nil
local function handleOD(displayTextParam, decNumber)
	if decNumber == "1" then
		return wsBaseURL .. "The_Doctrine_and_Covenants/Official_Declaration_1|" .. displayTextParam .. " 1]]"
	elseif decNumber == "2" then
		return "[https://www.churchofjesuschrist.org/study/scriptures/dc-testament/od/2?lang=eng " .. displayTextParam .. " 2]"
	else -- decNumber wasn't 1 or 2 (and could even be nil)
		if decNumber then
			error("No such Official Declaration: " .. decNumber, 0)
		else
			error("No official declaration number provided", 0)
		end
	end
end

-- for when the user has provided either no parameters or just one (the display 
--	text for the wikilink)
local function handleFewParams(displayTextParam)
	if not displayTextParam then
		-- no parameters provided to the template at all
		return wsBaseURL .. wsStandardWorks .. "|LDS Standard Works]]"
	end
	-- otherwise same link but displaying the text they provided
	return wsBaseURL .. wsStandardWorks .. "|" .. displayTextParam .. "]]"
end

local function removePeriods(arg)
	if arg then
		return string.gsub(arg, "%.", "")
	else
		return nil
	end
end

-- this function removes leading and trailing spaces via regex magic
local function trimSpaces(arg)
	if arg then
		return string.match(arg, "^%s*(.-)%s*$")
	else
		return nil
	end
end

-- local function extractParams(args):
--	Extracts and returns the parameters from the table of args passed in
--	Includes logic to handle the case where a user forgets to pass in bookParam
local function extractParams(args)
	local displayTextParam = trimSpaces(args[1])
	local bookParam = removePeriods(trimSpaces(args[2])) -- take out periods and spaces
	local chapterParam = trimSpaces(args[3])
	local verseParam = trimSpaces(args[4])
	local endVerseParam = trimSpaces(args[5])
	-- the 6th and 7th parameters, for footnotes and cross-references, have no
	--	use on Wikisource (and don't seem to work even on CoCJ.org, but whatever)
	--	so they are ignored
	local endVerseFlag = trimSpaces(args[8])
	
	-- handle the common mistake where someone forgets the second parameter
	--	altogether (e.g., {{LDS|Alma|7|11}}).
	--	This is done by testing whether the second parameter, which should be the
	--		name/abbrev. of the book (e.g., 1ne), is instead a number. In that case
	--		we will try assuming that the params should just be "shifted" over 1
	--		and use the display text as the bookParam and go from there, fingers crossed.
	if tonumber(args[2]) then
		-- the second parameter is a number (tonumber returns nil if there is any text in its argument)
		bookParam = removePeriods(trimSpaces(args[1])) -- use the display text and hope it's the full name of the book (or a valid abbreviation)!
		chapterParam = trimSpaces(args[2])
		verseParam = trimSpaces(args[3])
		endVerseParam = trimSpaces(args[4])
		endVerseFlag = trimSpaces(args[7])
	end
	
	return displayTextParam, bookParam, chapterParam, verseParam, endVerseParam, endVerseFlag
end

-- pre-condition: lectureNum is non-nil
local function getLectureOrdinal(lectureNum)
	if lectureNum == "1" then return "First"
	elseif lectureNum == "2" then return "Second"
	elseif lectureNum == "3" then return "Third"
	elseif lectureNum == "4" then return "Fourth"
	elseif lectureNum == "5" then return "Fifth"
	elseif lectureNum == "6" then return "Sixth"
	elseif lectureNum == "7" then return "Seventh"
	end
	
	error("Lecture on Faith number <" .. lectureNum .. "> does not exist (should be between 1 and 7)", 0)
end

	-- [=======[ ...oooOOOOOOOooo... ]=======] --
-- [===========[    MAIN FUNCTION    ]===========] --
	-- [=======[ ...oooOOOOOOOooo... ]=======] --

-- function p.main(frame)
-- This function returns a wikitext link to the cited LDS scripture on Wikisource
--	(except for Official Declaration 2, which is copyrighted, so this returns a
--	link to CoJC.org for that)
function p.main(frame)
	local args = frame:getParent().args -- the args to the template that invokes this module
	local displayTextParam, bookParam, chapterParam, verseParam, endVerseParam, endVerseFlag = extractParams(args)
	
	local wikiText = ""
	
	if not bookParam then --fewer than two parameters provided to the template
		return handleFewParams(displayTextParam)
	end
	
	local fullBookName = getFullBookName(bookParam)
	local standardWork = getStandardWork(fullBookName)
	
	if fullBookName == "Official Declaration" then
		return handleOD(displayTextParam, chapterParam)
	end
	
	wikiText = wsBaseURL .. standardWork -- start of the wikilink text
	
	-- Special case for JST Matthew (safe to do since we've already determined 
	--	which Standard Work we're linking to)
	if fullBookName == "JST Matthew" then fullBookName = "Matthew" end
	
	-- Special case for sections of the Doctrine and Covenants
	if fullBookName == "The Doctrine and Covenants" then
		if chapterParam then
			fullBookName = "Section " .. chapterParam
		else
			fullBookName = nil		-- The user has not provided a chapter (section) so this is treated as wanting to cite the D&C generally
		end
	end
	-- Special case for Lectures on Faith
	if fullBookName == "Lectures on Faith" then
		if chapterParam then
			local status, ordinal = pcall(getLectureOrdinal, chapterParam)
			if status then
				fullBookName = "Lecture " .. ordinal
			else
				fullBookName = nil -- just cite to LoF generally
				chapterParam = chapterParam .. " (invalid)" -- so user knows there was a problem
				mw.log(ordinal) -- print error message to debug console (?)
			end
		else
			fullBookName = nil		-- The user has not provided a chapter (lecture) so this is treated as wanting to cite the LoF generally
		end
	end
	
	if fullBookName then
		wikiText = wikiText .. "/" .. fullBookName
		if chapterParam then
			wikiText = wikiText .. buildBookmark(fullBookName, chapterParam, verseParam)
		end
	end
	
	wikiText = wikiText .. "|"
	wikiText = wikiText .. buildFinalDisplayText(displayTextParam, chapterParam, verseParam, endVerseParam, endVerseFlag)
	wikiText = wikiText .. "]]"		-- DON'T FORGET!!!
	return wikiText
end

-- like the name says, this just counts the number of keys (aka indexes) in a table
local function countKeys(t)
	local i = 0
	for k,v in pairs(t) do i = i+1 end
	return i
end

-- returns a (collapsed by default) wikitable listing all the aliases for every book
--	designed for use on the {{LDS}} template documentation page
function p.getBookAliasesWikiTable()
	local wikiTable = [[{| class="wikitable sortable mw-collapsible mw-collapsed"
	|+ class="nowrap" |LDS Template Book Name Aliases
	! Standard Work !! Book !! Aliases
	]]
	for sw, bookList in pairs(standardWorks) do
		wikiTable = wikiTable .. '|-\n|rowspan="' .. countKeys(bookList) .. '"|' .. sw ..  "\n"
		for book, aliases in pairs(bookList) do
			wikiTable = wikiTable .. "| " .. book .. "\n| " .. table.concat(aliases, ", ") .. "\n|-\n"
		end
	end
	wikiTable = wikiTable .. "|}"
	return wikiTable
end

return p