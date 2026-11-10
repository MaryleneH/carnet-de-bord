source(if (file.exists("R/pages.R")) "R/pages.R" else "../../R/pages.R", encoding = "UTF-8")

racine <- if (file.exists("_quarto.yml")) "." else "../.."
dossier_data <- file.path(racine, "data")

# Texte rédigé d'une page : sans l'en-tête YAML, les blocs de code et le code en ligne.
texte_redige <- function(chemin) {
  texte <- paste(readLines(chemin, encoding = "UTF-8", warn = FALSE), collapse = "\n")
  texte <- sub("(?s)^---\n.*?\n---\n", "", texte, perl = TRUE)
  texte <- gsub("(?s)```\\{r[^}]*\\}.*?```", "", texte, perl = TRUE)
  gsub("`r [^`]*`", "", texte)
}

test_that("aucun chiffre n'est tapé à la main sur l'accueil, le planning et les séances", {
  pages <- c("index.qmd", "planning.qmd", file.path("seances", list.files(file.path(racine, "seances"), "\\.qmd$")))
  for (p in pages) {
    expect_false(grepl("[0-9]", texte_redige(file.path(racine, p))), info = p)
  }
})

test_that("le projet interne n'apparaît que sous ses deux libellés génériques", {
  d <- charger(dossier_data)
  rendu <- paste(page_accueil(d), frise(d), cartes_seances(d), page_seance(d, "labo-01"), liste_cours(d))
  # Hors des deux libellés autorisés et des titres « Projet interne »,
  # le mot « interne » n'apparaît nulle part.
  reste <- rendu
  for (l in LIBELLES_INTERNES) reste <- gsub(l, "", reste, fixed = TRUE)
  reste <- gsub("## Projet interne", "", reste, fixed = TRUE)
  expect_false(grepl("intern", reste, ignore.case = TRUE))
  expect_true(grepl(LIBELLES_INTERNES[[1]], frise(d), fixed = TRUE))
  expect_true(grepl(LIBELLES_INTERNES[[2]], frise(d), fixed = TRUE))
})

test_that("une carte de séance montre date, projet, statut, durée et livrables", {
  d <- charger(dossier_data)
  carte <- carte_seance(seance(d, "labo-01"), d)
  expect_match(carte, "10 novembre 2026", fixed = TRUE)
  expect_match(carte, "Laboratoire", fixed = TRUE)
  expect_match(carte, "[fait]{.badge-etat .etat-fait}", fixed = TRUE)
  expect_match(carte, "3 h", fixed = TRUE)
  expect_match(carte, "sonde.py", fixed = TRUE)
})

test_that("chaque chiffre clé cite sa source dans le cours", {
  d <- charger(dossier_data)
  rendu <- chiffres_cles(d)
  expect_equal(lengths(regmatches(rendu, gregexpr("Source : ", rendu, fixed = TRUE))), length(CHIFFRES_CLES))
  expect_match(rendu, "(/cours/seance-01-cours.md#annexe-a)", fixed = TRUE)
})
