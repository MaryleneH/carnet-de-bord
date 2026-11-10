-- Typographie française : remplace les espaces ordinaires par des espaces
-- insécables là où le français les demande, pour qu'aucun signe ne se
-- retrouve seul en début de ligne.
--   espace insécable (U+00A0) : avant « : » et « » », après « « » et « n° »,
--                               entre un nombre et le mot qui le suit (3 h) ;
--   espace fine insécable (U+202F) : avant « ; ! ? % », entre groupes de chiffres.
-- Seules les espaces entre deux mots sont touchées : le code, les adresses
-- des liens et les attributs restent intacts.

local INSECABLE = "\u{00A0}"
local FINE = "\u{202F}"

local function commence_par(s, prefixe)
  return s:sub(1, #prefixe) == prefixe
end

local function finit_par(s, suffixe)
  return #s >= #suffixe and s:sub(-#suffixe) == suffixe
end

local function espace_pour(precedent, suivant)
  if not suivant or suivant.t ~= "Str" then return nil end
  local s = suivant.text
  if commence_par(s, ":") or commence_par(s, "»") then return INSECABLE end
  if commence_par(s, ";") or commence_par(s, "!") or commence_par(s, "?") or commence_par(s, "%") then
    return FINE
  end
  if precedent and precedent.t == "Str" then
    local p = precedent.text
    if finit_par(p, "«") or finit_par(p, "n°") then return INSECABLE end
    -- 52 697, 256 000 : groupes de trois chiffres
    if p:match("^%d%d?%d?$") and s:match("^%d%d%d") then return FINE end
    -- 3 h, 10 novembre, 4 096 dimensions
    if p:match("%d$") and not s:match("^%d") and not s:match("^%p") then return INSECABLE end
  end
  return nil
end

function Inlines(elements)
  for i = 2, #elements - 1 do
    local e = elements[i]
    if e.t == "Space" or e.t == "SoftBreak" then
      local espace = espace_pour(elements[i - 1], elements[i + 1])
      if espace then elements[i] = pandoc.Str(espace) end
    end
  end
  return elements
end
