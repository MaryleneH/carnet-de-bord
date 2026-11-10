-- Chaque tableau est placé dans un cadre qui défile horizontalement : sur
-- téléphone, un tableau large défile dans son cadre au lieu d'élargir la page.

function Table(tableau)
  return pandoc.Div({ tableau }, pandoc.Attr("", { "tableau-defilant" }))
end
