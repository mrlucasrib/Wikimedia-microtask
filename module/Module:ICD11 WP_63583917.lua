local p = {}

local checkcode = require("Module:ICD11")._code2link -- This function is used to check if the code is in Module:ICD11, i.e. if it exists.
local errormessage = require("Module:Error").error -- This is the standard error module.

local chapter_beginning = "ICD-11 MMS Chapter"
local ICD11_chapters = {
  ["1"] = "1: Certain infectious or parasitic diseases", 
  ["2"] = "2: Neoplasms", 
  ["3"] = "3: Diseases of the blood or blood-forming organs", 
  ["4"] = "4: Diseases of the immune system", 
  ["5"] = "5: Endocrine, nutritional or metabolic diseases", 
  ["6"] = "6: Mental, behavioural or neurodevelopmental disorders", 
  ["7"] = "7: Sleep-wake disorders", 
  ["8"] = "8: Diseases of the nervous system", 
  ["9"] = "9: Diseases of the visual system", 
  ["A"] = "10: Diseases of the ear or mastoid process", 
  ["B"] = "11: Diseases of the circulatory system", 
  ["C"] = "12: Diseases of the respiratory system", 
  ["D"] = "13: Diseases of the digestive system", 
  ["E"] = "14: Diseases of the skin", 
  ["F"] = "15: Diseases of the musculoskeletal system or connective tissue", 
  ["G"] = "16: Diseases of the genitourinary system", 
  ["H"] = "17: Conditions related to sexual health", 
  ["J"] = "18: Pregnancy, childbirth or the puerperium", 
  ["K"] = "19: Certain conditions originating in the perinatal period", 
  ["L"] = "20: Developmental anomalies", 
  ["M"] = "21: Symptoms, signs or clinical findings, not elsewhere classified", 
  ["N"] = "22: Injury, poisoning or certain other consequences of external causes", 
  ["P"] = "23: External causes of morbidity or mortality", 
  ["Q"] = "24: Factors influencing health status or contact with health services", 
  ["R"] = "25: Codes for special purposes", 
  ["S"] = "26: Supplementary Chapter Traditional Medicine Conditions - Module I", 
  ["V"] = "V: Supplementary section for functioning assessment", 
  ["X"] = "X: Extension Codes"
}
-- NB: to prevent confusion, the ICD-11 MMS does not have 'I' or 'O' chapters.

local current_page = mw.title.getCurrentTitle().text

p.chapterpagelink = function(frame)
  
  local output = nil
  local input = mw.text.trim(frame.args[1]) -- Remove the white spaces from the beginning and the end of the input.
  input = string.upper(input) -- Just in case.
  
    -- If the input is empty, return emptiness.
    if input == ""
    then
      output = ""
    -- Check if the code is in Module:ICD11, i.e. if it exists.
    elseif checkcode(input)
    then
      
      local first_char = string.sub(input, 1, 1) -- Select the first character, which should be the chapter code.
      local chapter_nr_and_name = ICD11_chapters[first_char]
      
        -- If the first character belongs to a chapter, create a link.
        if chapter_nr_and_name
        then
          if ((chapter_beginning .. " " .. chapter_nr_and_name) == current_page)
          then
            -- If the code is on the current page, create an anchor link.
            output = "[[" .. "#" .. input .. "|" .. input .. "]]"
          else
            -- If the code is on another page, create a standard link.
            output = "[[" .. chapter_beginning .. " " .. chapter_nr_and_name .. "#" .. input .. "|" .. input .. "]]"
          end
        end
    
    -- If the code is not found in Module:ICD11, give an error.
    else
      output = errormessage( {message = "Code not found."} )
    end
  
  return output
  
end

return p