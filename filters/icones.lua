-- Icônes de repli du site, déclarées dans l'en-tête de chaque page.
-- L'icône principale, icones/favicon.svg, est déclarée par `favicon` dans _quarto.yml ;
-- ces deux PNG servent aux navigateurs qui n'affichent pas une icône SVG et à
-- l'écran d'accueil d'un téléphone. Ils se régénèrent avec scripts/icones.sh.
-- quarto.project.offset mène de la page à la racine du site (« . » ou « .. »).

function Meta(meta)
  local racine = quarto.project.offset or "."
  quarto.doc.include_text("in-header", string.format(
    '<link rel="icon" href="%s/icones/favicon-32.png" sizes="32x32" type="image/png">\n' ..
    '<link rel="apple-touch-icon" href="%s/icones/apple-touch-icon.png">',
    racine, racine
  ))
  return meta
end
