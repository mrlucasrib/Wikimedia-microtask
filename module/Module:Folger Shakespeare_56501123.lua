-- This module's function lookup table, used by the calling context
local p = {}

function p.main(frame)
  local pframe = frame:getParent()

  cfg = mw.loadData('Module:Folger Shakespeare/configuration');

  local play  = cfg.aliases[pframe.args[1]] or ''
  local act   = pframe.args[2] or ''
  local scene = pframe.args[3] or ''

  local line = ''
  local line_given = false
  local ftln_given = false
  if pframe.args['ftln'] then
    line = pframe.args['ftln']
    ftln_given = true
  elseif pframe.args[4] then
    line = pframe.args[4]
    line_given = true
  else
    -- Both line_given and ftln_given will be false.
  end

  local display_line = line
  if mw.ustring.match(line, '^%s*%d+[-–]%d+%s*$') then
    line = mw.ustring.match(line, '^%s*(%d+)[-–]%d+%s*$')
  elseif mw.ustring.match(line, '^%s*%d+%s*$') then
    line = mw.ustring.match(line, '^%s*(%d+)%s*$')
  else
    -- Gotta figure out how to signal an error to the user.
  end

  local location
  if ftln_given then
    location = mw.ustring.format('ftln-%04d', line)
  elseif line_given then
    location = mw.ustring.format('line-%d.%d.%d', act, scene, line)
  else
    location = mw.ustring.format('line-%d.%d.%d', act, scene, 0)
  end

  local url = mw.ustring.format(cfg.url_pattern, play, location)

  local   id = play .. act .. '_' .. scene .. '_' .. display_line
  local name = 'FOOTNOTE' .. id

  local play_name = cfg.names[play].title

  local location_link = ''
  if ftln_given then
    location_link = mw.ustring.format(cfg.ftln_format, url, display_line)
  else
    location_link = mw.ustring.format(cfg.location_format, url, act, scene, display_line)
  end
  local cite = '\'\'' .. play_name .. '\'\', ' .. location_link

  local result = frame:extensionTag{
    name = 'ref',
    args = {name = name},
    content = cite,
  };
  return result;
end

return p