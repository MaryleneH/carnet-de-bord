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

test_that("aucun nombre n'est tapé à la main dans le tableau de bord et les séances", {
  pages <- c("index.qmd", file.path("seances", list.files(file.path(racine, "seances"), "\\.qmd$")))
  for (p in pages) {
    expect_false(grepl("[0-9]", texte_redige(file.path(racine, p))), info = p)
  }
})

test_that("aucune page ne parle d'un projet interne", {
  d <- charger(dossier_data)
  rendu <- paste(page_tableau_de_bord(d), cartes_seances(d), page_seance(d, "labo-01"), plan_du_cours(d))
  expect_false(grepl("intern", rendu, ignore.case = TRUE))
  expect_false(grepl("deux projets", rendu, ignore.case = TRUE))
  pages <- c("index.qmd", "methode.qmd", "cours/index.qmd", file.path("seances", list.files(file.path(racine, "seances"), "\\.qmd$")))
  for (p in pages) {
    expect_false(grepl("intern", texte_redige(file.path(racine, p)), ignore.case = TRUE), info = p)
  }
})

test_that("les titres du cours ne laissent deviner aucun autre projet", {
  # Titre et sous-titre de chaque chapitre : repris dans la barre latérale, le plan et le fil d'Ariane.
  for (f in list.files(file.path(racine, "cours"), "\\.(md|qmd)$", full.names = TRUE)) {
    texte <- paste(readLines(f, encoding = "UTF-8", warn = FALSE), collapse = "\n")
    entete <- regmatches(texte, regexpr("(?s)^---\n.*?\n---\n", texte, perl = TRUE))
    expect_false(any(grepl("intern|extern|deux projets", entete, ignore.case = TRUE)), info = basename(f))
  }
})

test_that("la vue d'ensemble montre l'avancement, pas les résultats techniques des séances", {
  d <- charger(dossier_data)
  vue <- vue_ensemble(d)
  for (titre in c("Séances faites", "Jalons atteints", "Concepts vus", "Temps de travail", "Où j'en suis")) {
    expect_match(vue, titre, fixed = TRUE)
  }
  techniques <- Filter(function(m) !grepl("^duree-", m$id), d$mesures)
  for (m in techniques) {
    expect_false(grepl(format_valeur(m, avec_unite = TRUE), vue, fixed = TRUE), info = m$id)
  }
})

test_that("les indicateurs sont calculés depuis les données", {
  d <- charger(dossier_data)
  labo <- seances_labo(d)
  vue <- indicateurs(d)
  expect_match(vue, sprintf("[%d]{.indicateur-valeur} [sur %d]", length(seances_faites(d)), length(labo)), fixed = TRUE)
  vus <- sum(niveaux_concepts(d$concepts) != "non vu")
  expect_match(vue, sprintf("[%d]{.indicateur-valeur} [sur %d]", vus, nrow(d$concepts)), fixed = TRUE)
  expect_equal(heures_faites(d), sum(vapply(seances_faites(d), function(s) mesure(d, s$duree)$valeur, numeric(1))))
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

test_that("les résultats de la séance citent leur source dans le cours", {
  d <- charger(dossier_data)
  rendu <- page_seance(d, "labo-01")
  expect_match(rendu, "(/cours/seance-01-cours.md#annexe-a)", fixed = TRUE)
  expect_match(rendu, "(/cours/seance-01-cours.md#annexe-b)", fixed = TRUE)
})

test_that("le plan et l'avancement du cours viennent des données", {
  d <- charger(dossier_data)
  labo <- seances_labo(d)
  redigees <- seances_redigees(d)
  plan <- plan_du_cours(d)
  for (s in labo) expect_match(plan, titre_complet(s), fixed = TRUE)
  for (s in redigees) expect_match(plan, sprintf("](%s)", s$cours), fixed = TRUE)
  avancement <- avancement_cours(d)
  expect_match(avancement, sprintf("[%d]{.indicateur-valeur}", length(redigees)), fixed = TRUE)
  expect_match(avancement, sprintf(" sur %d]{.indicateur-total}", length(labo)), fixed = TRUE)
  expect_match(vue_ensemble(d), "Plan complet du cours", fixed = TRUE)
})

test_that("les icônes du site existent, aux bonnes tailles", {
  # largeur et hauteur d'un PNG : octets 17 à 24 de l'en-tête
  taille_png <- function(f) {
    o <- as.integer(readBin(f, "raw", 24))
    c(sum(o[17:20] * 256^(3:0)), sum(o[21:24] * 256^(3:0)))
  }
  icones <- file.path(racine, "icones")
  expect_true(file.exists(file.path(icones, "favicon.svg")))
  expect_identical(taille_png(file.path(icones, "favicon-32.png")), c(32, 32))
  expect_identical(taille_png(file.path(icones, "apple-touch-icon.png")), c(180, 180))
})
