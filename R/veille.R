# Page Veille : les liens de data/veille.yml, rangés par thème.
# Produit du Markdown Pandoc (les fiches) et un peu de HTML (recherche et
# filtres). veille/filtre.js rend la recherche et les filtres actifs ; sans
# JavaScript, la page reste une liste complète, rangée par thème.
# Aucun nombre n'est écrit à la main : les compteurs viennent des données.

# Couleur d'un thème sans couleur choisie : la palette du cours, dans l'ordre.
PALETTE_THEMES <- c("bleu", "vert", "violet", "orange", "gris")

domaine <- function(url) sub("^www\\.", "", hote_url(url))

couleur_theme <- function(t, rang) {
  ou_sinon(t$couleur, PALETTE_THEMES[[(rang - 1) %% length(PALETTE_THEMES) + 1]])
}

majuscule <- function(x) paste0(toupper(substring(x, 1, 1)), substring(x, 2))

# Texte sûr dans du Markdown (titres, mots-clés) et dans du HTML (filtres).
echapper_md <- function(x) gsub("([\\\\`*_\\[\\]<>])", "\\\\\\1", x, perl = TRUE)
# Dans le HTML brut, Pandoc ne pose pas l'apostrophe typographique : on la pose ici.
echapper_html <- function(x) {
  x <- gsub("&", "&amp;", x, fixed = TRUE)
  x <- gsub("<", "&lt;", x, fixed = TRUE)
  x <- gsub(">", "&gt;", x, fixed = TRUE)
  x <- gsub("\"", "&quot;", x, fixed = TRUE)
  gsub("'", "’", x, fixed = TRUE)
}

# Liens d'un thème, du plus récent au plus ancien (à date égale, par titre).
liens_du_theme <- function(liens, id) {
  ll <- Filter(function(l) identical(l$theme, id), liens)
  if (length(ll) < 2) return(ll)
  dates <- vapply(ll, function(l) l$ajoute_le, character(1))
  titres <- vapply(ll, function(l) l$titre, character(1))
  ll[order(dates, titres, decreasing = c(TRUE, FALSE), method = "radix")]
}

# Thèmes qui ont au moins un lien, dans l'ordre du fichier, avec leur couleur.
themes_garnis <- function(v) {
  garnis <- list()
  for (i in seq_along(v$themes)) {
    t <- v$themes[[i]]
    t$couleur <- couleur_theme(t, i)
    t$liens <- liens_du_theme(v$liens, t$id)
    if (length(t$liens) > 0) garnis[[length(garnis) + 1]] <- t
  }
  garnis
}

style_theme <- function(t) sprintf("--c-theme: var(--c-%s)", t$couleur)

nombre_liens <- function(n) paste(n, pluriel(n, "lien"))

# ── Fiche d'un lien ──────────────────────────────────────────────────────────

fiche_lien <- function(l, t) {
  meta <- c(
    sprintf("[%s]{.veille-domaine}", domaine(l$url)),
    sprintf("[%s]{.veille-type}", majuscule(l$type)),
    if (identical(l$langue, "en")) "[en anglais]{.veille-langue}"
  )
  lien <- sprintf(
    # espace insécable dans le texte caché : rien de souligné après le titre
    "[[%s]{.veille-titre-texte}[ (s'ouvre dans un nouvel onglet)]{.visually-hidden}](%s){%s}",
    echapper_md(l$titre), l$url, if (identical(l$langue, "en")) "hreflang=\"en\"" else ""
  )
  mots <- if (length(l$mots_cles) > 0) {
    paste(sprintf("[%s]{.veille-mot}", echapper_md(l$mots_cles)), collapse = " ")
  } else ""
  paste0(
    "::: {.veille-lien data-theme=\"", t$id, "\"}\n\n",
    "[", paste(meta, collapse = " "), "]{.veille-meta}\n\n",
    "### ", lien, " {.veille-titre}\n\n",
    "::: {.veille-resume}\n\n", l$resume, "\n\n:::\n\n",
    if (!is.null(l$pourquoi)) {
      paste0("::: {.veille-pourquoi}\n\n[Pourquoi je le garde]{.veille-pourquoi-titre} ", l$pourquoi, "\n\n:::\n\n")
    } else "",
    "::: {.veille-pied}\n\n",
    if (nzchar(mots)) paste0("[", mots, "]{.veille-mots} ") else "",
    sprintf("[Ajouté le %s]{.veille-date}", date_longue(l$ajoute_le)), "\n\n",
    ":::\n\n",
    ":::\n\n"
  )
}

section_theme <- function(t) {
  paste0(
    "::: {.veille-theme #theme-", t$id, " data-theme=\"", t$id, "\" style=\"", style_theme(t), "\"}\n\n",
    "## ", echapper_md(t$titre), " [", nombre_liens(length(t$liens)), "]{.veille-compte} {#titre-", t$id, " .veille-theme-titre}\n\n",
    if (!is.null(t$description)) paste0("[", t$description, "]{.veille-theme-description}\n\n") else "",
    paste(vapply(t$liens, fiche_lien, character(1), t = t), collapse = ""),
    ":::\n\n"
  )
}

# ── Recherche et filtres (HTML, activés par veille/filtre.js) ────────────────

bouton_filtre <- function(id, nom, n, style = NULL, actif = FALSE) {
  sprintf(
    paste0(
      "<button type=\"button\" class=\"veille-filtre\" data-theme=\"%s\" aria-pressed=\"%s\"%s>",
      "<span class=\"veille-pastille\" aria-hidden=\"true\"></span>",
      "<span class=\"veille-filtre-nom\">%s</span>",
      "<span class=\"veille-filtre-compte\">%d</span></button>"
    ),
    id, if (actif) "true" else "false",
    if (is.null(style)) "" else sprintf(" style=\"%s\"", style),
    echapper_html(nom), as.integer(n)
  )
}

outils_veille <- function(themes, total) {
  boutons <- c(
    bouton_filtre("tous", "Tous les thèmes", total, actif = TRUE),
    vapply(themes, function(t) bouton_filtre(t$id, t$titre, length(t$liens), style_theme(t)), character(1))
  )
  paste0(
    "```{=html}\n",
    "<div class=\"veille-outils\" hidden>\n",
    "<div class=\"veille-recherche\">\n",
    "<label class=\"veille-etiquette\" for=\"veille-recherche\">Rechercher</label>\n",
    "<div class=\"veille-champ\">",
    "<svg class=\"veille-loupe\" viewBox=\"0 0 24 24\" aria-hidden=\"true\" focusable=\"false\">",
    "<circle cx=\"10.5\" cy=\"10.5\" r=\"6.5\"/><path d=\"M15.5 15.5 20 20\"/></svg>",
    "<input id=\"veille-recherche\" type=\"search\" placeholder=\"Titre, mot-clé, site…\" ",
    "autocomplete=\"off\" spellcheck=\"false\" aria-describedby=\"veille-statut\">",
    "</div>\n</div>\n",
    "<div class=\"veille-filtres\" role=\"group\" aria-labelledby=\"veille-filtres-titre\">\n",
    "<p class=\"veille-etiquette\" id=\"veille-filtres-titre\">Thèmes</p>\n",
    paste(boutons, collapse = "\n"), "\n",
    "</div>\n</div>\n",
    "```\n\n"
  )
}

# ── Page ─────────────────────────────────────────────────────────────────────

page_veille <- function(d) {
  v <- d$veille
  themes <- themes_garnis(v)
  total <- length(v$liens)
  if (total == 0) return("[Aucun lien pour l'instant.]{.veille-chiffres}\n\n")
  dernier <- max(vapply(v$liens, function(l) l$ajoute_le, character(1)))
  # chaque morceau reste sur une ligne : la coupure se fait aux points médians
  chiffres <- paste(
    sprintf("[%s]{.veille-chiffre}", c(
      nombre_liens(total),
      paste(length(themes), pluriel(length(themes), "thème")),
      paste("dernier ajout le", date_longue(dernier))
    )),
    collapse = " · "
  )
  paste0(
    "[", chiffres, "]{.veille-chiffres}\n\n",
    "::: {.veille}\n\n",
    outils_veille(themes, total),
    "::: {.veille-liste}\n\n",
    "```{=html}\n<p class=\"veille-statut\" id=\"veille-statut\" role=\"status\"></p>\n```\n\n",
    paste(vapply(themes, section_theme, character(1)), collapse = ""),
    source_fichier("data/veille.yml"), "\n\n",
    ":::\n\n",
    ":::\n\n"
  )
}
