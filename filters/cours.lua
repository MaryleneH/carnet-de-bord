-- Cours : les encadrés écrits « > **Libellé.** texte » deviennent des callouts
-- Quarto, et les chapitres et annexes reçoivent des ancres stables
-- (#chapitre-3, #annexe-a), que citent les sources du registre des mesures.

local TYPES = {
  ["À retenir"] = "note",
  ["En bref"] = "note",
  ["Attention"] = "warning",
  ["Définition"] = "tip",
  ["Formule"] = "caution",
  ["Exemple"] = "important",
}

-- Libellé d'un paragraphe qui commence par **Libellé.**, sinon nil.
local function libelle(bloc)
  if not bloc or bloc.t ~= "Para" then return nil end
  local premier = bloc.content[1]
  if not premier or premier.t ~= "Strong" then return nil end
  local texte = pandoc.utils.stringify(premier):gsub("[%.%s]+$", "")
  if TYPES[texte] then return texte end
  return nil
end

function BlockQuote(citation)
  local nom = libelle(citation.content[1])
  if not nom then return nil end

  local paragraphe = citation.content[1]
  paragraphe.content:remove(1)
  if paragraphe.content[1] and paragraphe.content[1].t == "Space" then
    paragraphe.content:remove(1)
  end

  local contenu = pandoc.List(citation.content)
  if #paragraphe.content == 0 then contenu:remove(1) end
  return pandoc.Div(contenu, pandoc.Attr("", { "callout-" .. TYPES[nom] }, { title = nom }))
end

function Header(titre)
  if titre.level ~= 2 then return nil end
  local texte = pandoc.utils.stringify(titre)
  local chapitre = texte:match("^Chapitre (%d+)")
  if chapitre then
    titre.identifier = "chapitre-" .. chapitre
    return titre
  end
  local annexe = texte:match("^Annexe (%u)")
  if annexe then
    titre.identifier = "annexe-" .. annexe:lower()
    return titre
  end
  return nil
end
