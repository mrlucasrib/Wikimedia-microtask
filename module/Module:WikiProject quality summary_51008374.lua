-- This module's function lookup table, used by the calling context
local p = {}

-- Extract article counts from the WP 1.0 quality categories for a WikiProject
-- Returns a wikitext prose description of the numbers.
-- 
-- TODO:
-- * The output is hardcoded, which is inflexible. Move out to calling template?
-- * Need to evaluate if all relevant QA Class categories are handled.
-- * Bad input leads to nonsensical output. Should default to reasonable nil values.
function p.qstats(frame)

  -- Determine the WikiProject for which to grab stats.
  local topic
  if frame.args.topic then -- Use the argument provided.
    topic = frame.args.topic
  elseif frame.args[1] then -- Specialcase use the first (only) positional argument
    topic = frame.args[1]
  else -- By default grab the calling context's title as the topic.
    -- Get the name of the calling page and extract everything after "WikiProject ".
    local title = mw.title.getCurrentTitle()
    topic = string.sub(title.rootText, 13, -1)
  end

  -- WP 1.0 category names follow the pattern "<class>-Class <topic> articles".
  local cSuffix = "-Class " .. topic .. " articles"

  -- Get the article counts for each handled class.
  local qFA    = mw.site.stats.pagesInCategory("FA"    .. cSuffix, "pages")
  local qGA    = mw.site.stats.pagesInCategory("GA"    .. cSuffix, "pages")
  local qA     = mw.site.stats.pagesInCategory("A"     .. cSuffix, "pages")
  local qB     = mw.site.stats.pagesInCategory("B"     .. cSuffix, "pages")
  local qC     = mw.site.stats.pagesInCategory("C"     .. cSuffix, "pages")
  local qStart = mw.site.stats.pagesInCategory("Start" .. cSuffix, "pages")
  local qStub  = mw.site.stats.pagesInCategory("Stub"  .. cSuffix, "pages")
  local qList  = mw.site.stats.pagesInCategory("List"  .. cSuffix, "pages")
  local qFL    = mw.site.stats.pagesInCategory("FL"    .. cSuffix, "pages")

  -- Sum of all class article counts; i.e. all articles in scope of the WikiProject.
  local total = qFA + qGA + qA + qB + qC + qStart + qStub + qList + qFL

  -- Sum of featured content (FA + FL).
  local qFeatured = qFA + qFL

  -- Calculate numerical and percentage proportion of articles at FA or FL level.
  local pnFeatured = total / (qFA + qFL)
  local ppFeatured = (100 / total) * (qFA + qFL)

  -- Calculate numerical and percentage proportion of articles at GA level.
  local pnGood = total / qGA
  local ppGood = (100 / total) * qGA

  -- Calculate numerical and percentage proportion of articles at FA, FL, and GA level.
  local pnForG = total / (qFA + qGA + qFL)
  local ppForG = (100 / total) * (qFA + qGA + qFL)

  -- Create the wikitext output and return it to the calling template.
  local format = [=[There are '''%d''' articles within the scope of the %s project. Currently the project has '''%d''' [[WP:FA|Featured articles]] and [[WP:FL|lists]], or 1 out of every %d articles in the project (%.1f%%). It also has '''%d''' [[WP:GA|Good articles]]: 1 out of every %d articles (%.1f%%). Thus, one in '''%d''' articles in the project is rated GA or higher (%.1f%%).]=]
  return mw.ustring.format(format, total, topic, qFeatured, pnFeatured, ppFeatured, qGA, pnGood, ppGood, pnForG, ppForG)
end

return p