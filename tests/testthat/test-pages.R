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
  pages <- c("index.qmd", "veille/index.qmd", file.path("seances", list.files(file.path(racine, "seances"), "\\.qmd$")))
  for (p in pages) {
    expect_false(grepl("[0-9]", texte_redige(file.path(racine, p))), info = p)
  }
})

test_that("aucune page ne parle d'un projet interne", {
  d <- charger(dossier_data)
  rendu <- paste(page_tableau_de_bord(d), cartes_seances(d), page_seance(d, "labo-01"), plan_du_cours(d))
  expect_false(grepl("intern", rendu, ignore.case = TRUE))
  expect_false(grepl("deux projets", rendu, ignore.case = TRUE))
  pages <- c("index.qmd", "methode.qmd", "cours/index.qmd", "veille/index.qmd", file.path("seances", list.files(file.path(racine, "seances"), "\\.qmd$")))
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

test_that("l'escalier a une marche par séance et un palier par jalon", {
  d <- charger(dossier_data)
  labo <- seances_labo(d)
  jalons <- Filter(function(s) !is.null(s$jalon), labo)
  e <- escalier(d)
  compter <- function(motif) lengths(regmatches(e, gregexpr(motif, e, fixed = TRUE)))
  expect_equal(compter("::: {.marche "), length(labo) + length(jalons))
  expect_equal(compter("::: {.marche .palier"), length(jalons))
  expect_match(e, sprintf("--colonnes: %d", length(labo) + length(jalons)), fixed = TRUE)
  for (s in labo) expect_match(e, sprintf("[%d]{.marche-no}", as.integer(s$numero)), fixed = TRUE)
  for (s in jalons) expect_match(e, sprintf("[%s]{.palier-nom}", s$jalon$id), fixed = TRUE)
  # chaque marche est plus haute que la précédente ; la dernière atteint le sommet
  parts <- as.numeric(regmatches(e, gregexpr("(?<=--part: )[0-9.]+", e, perl = TRUE))[[1]])
  expect_false(is.unsorted(parts))
  expect_equal(max(parts), 100)
  # l'état de chaque séance colore sa marche ; une séance faite mène à sa page
  for (s in labo) {
    expect_match(e, sprintf("::: {.marche .%s role=\"listitem\" style=\"--part: %s%%\"", CLASSES_ETAT[[s$statut]], part_escalier(as.integer(s$numero), length(labo))), fixed = TRUE)
  }
  for (s in seances_faites(d)) expect_match(e, sprintf("](%s){.marche-lien}", s$lien), fixed = TRUE)
})

test_that("les jalons et les pastilles viennent des données", {
  d <- charger(dossier_data)
  labo <- seances_labo(d)
  jalons <- Filter(function(s) !is.null(s$jalon), labo)
  cartes <- cartes_jalons(d)
  for (s in jalons) {
    expect_match(cartes, sprintf("[%s]{.jalon-nom}", s$jalon$id), fixed = TRUE)
    expect_match(cartes, s$jalon$critere, fixed = TRUE)
  }
  # une pastille par unité : les pleines d'abord, puis les vides
  p <- pastilles(rep("plein", 2), 5)
  expect_identical(lengths(regmatches(p, gregexpr("[]{.pip", p, fixed = TRUE))), 5L)
  expect_identical(lengths(regmatches(p, gregexpr("[]{.pip .plein}", p, fixed = TRUE))), 2L)
  expect_match(p, "aria-hidden=\"true\"", fixed = TRUE)
  # les niveaux de compétence sont décrits pour les lecteurs d'écran
  niveaux <- c("vu", "non vu", "maîtrisé", "pratiqué", "non vu")
  pn <- pastilles_niveaux(niveaux)
  expect_match(pn, "role=\"img\" aria-label=\"3 vus sur 5, dont 2 pratiqués et 1 maîtrisé\"", fixed = TRUE)
  expect_match(pn, "[]{.pip .niveau-maitrise}[]{.pip .niveau-pratique}[]{.pip .niveau-vu}[]{.pip}[]{.pip}", fixed = TRUE)
  # l'en-tête de l'accueil compte les séances et les jalons
  entete <- entete_accueil(d, "Titre", NULL)
  expect_match(
    entete,
    sprintf("%d %s · %d %s", length(labo), pluriel(length(labo), "séance"), length(jalons), pluriel(length(jalons), "jalon")),
    fixed = TRUE
  )
  # un volet par onglet
  page <- page_tableau_de_bord(d)
  for (id in names(ONGLETS)) {
    expect_match(page, sprintf("data-bs-target=\"#%s\"", id), fixed = TRUE)
    expect_match(page, sprintf("::: {#%s .tab-pane", id), fixed = TRUE)
  }
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
})

test_that("une page de séance ne montre plus les incidents", {
  d <- charger(dossier_data)
  for (s in seances_faites(d)) {
    rendu <- page_seance(d, s$id)
    expect_false(grepl("Incidents et corrections", rendu, fixed = TRUE), info = s$id)
    expect_false(grepl("annexe-b", rendu, fixed = TRUE), info = s$id)
  }
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
