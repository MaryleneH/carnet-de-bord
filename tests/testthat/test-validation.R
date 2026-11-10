source(if (file.exists("R/valider.R")) "R/valider.R" else "../../R/valider.R", encoding = "UTF-8")

dossier_data <- if (dir.exists("data")) "data" else "../../data"
dossier_fixtures <- if (dir.exists("tests/testthat/fixtures")) "tests/testthat/fixtures" else "fixtures"

# Copie la fixture dans un mini projet : data/ pour les données, cours/ pour le
# chapitre que la séance 1 déclare. Rend le dossier data/.
copier_fixture_valide <- function() {
  projet <- tempfile("fixture-")
  dir <- file.path(projet, "data")
  dir.create(dir, recursive = TRUE)
  file.copy(list.files(dossier_fixtures, full.names = TRUE), dir)
  dir.create(file.path(projet, "cours"))
  writeLines(c("---", "title: \"Séance 1\"", "---"), file.path(projet, "cours", "seance-01-cours.md"))
  dir
}
chapitre_fixture <- function(dir, fichier) file.path(dirname(dir), "cours", fichier)

# Modifie un fichier YAML de la copie : f reçoit et rend la structure lue.
modifier_yaml <- function(dir, fichier, f) {
  chemin <- file.path(dir, fichier)
  yaml::write_yaml(f(yaml::read_yaml(chemin)), chemin)
  dir
}

derniere <- function(x) length(x$seances)

test_that("les données publiées sont valides", {
  expect_invisible(valider_tout(dossier_data))
})

test_that("le jeu de fixtures valide passe", {
  expect_invisible(valider_tout(copier_fixture_valide()))
})

test_that("seul le laboratoire figure dans le carnet", {
  dir <- modifier_yaml(copier_fixture_valide(), "seances.yml", function(x) {
    x$seances[[1]]$projet <- "interne"
    x
  })
  expect_error(valider_tout(dir), "Confidentialité")

  dir <- modifier_yaml(copier_fixture_valide(), "seances.yml", function(x) {
    x$seances[[length(x$seances) + 1]] <- list(id = "autre", projet = "autre", titre = "Autre", statut = "prévu")
    x
  })
  expect_error(valider_tout(dir), "Confidentialité")
})

test_that("aucun texte ne mentionne un autre projet", {
  dir <- modifier_yaml(copier_fixture_valide(), "seances.yml", function(x) {
    x$seances[[1]]$objectif <- "Comparer avec la cible interne"
    x
  })
  expect_error(valider_tout(dir), "Confidentialité")
})

test_that("aucun chiffre hors registre dans les textes", {
  dir <- modifier_yaml(copier_fixture_valide(), "seances.yml", function(x) {
    x$seances[[1]]$objectif <- "Un taux de 87 % mesuré"
    x
  })
  expect_error(valider_tout(dir), "chiffre hors registre")

  dir <- modifier_yaml(copier_fixture_valide(), "seances.yml", function(x) {
    x$seances[[1]]$livrables[[1]] <- "Une valeur {mesure-inconnue}"
    x
  })
  expect_error(valider_tout(dir), "mesure inconnue")

  # le code, les numéros et les références au registre sont permis
  expect_false(chiffre_hors_registre("Erreur `404`, EcoDef n° 273, {tokens-lus-max} tokens"))
  expect_true(chiffre_hors_registre("environ 4,8 caractères par token"))
})

test_that("chaque mesure a une valeur et une source précise", {
  dir <- modifier_yaml(copier_fixture_valide(), "mesures.yml", function(x) {
    x$mesures[[1]]$source <- NULL
    x
  })
  expect_error(valider_tout(dir), "source précise")

  dir <- modifier_yaml(copier_fixture_valide(), "mesures.yml", function(x) {
    x$mesures[[1]]$valeur <- "trois"
    x
  })
  expect_error(valider_tout(dir), "valeur numérique")

  dir <- modifier_yaml(copier_fixture_valide(), "mesures.yml", function(x) {
    x$mesures[[2]]$id <- x$mesures[[1]]$id
    x
  })
  expect_error(valider_tout(dir), "en double")

  dir <- modifier_yaml(copier_fixture_valide(), "mesures.yml", function(x) {
    x$tableaux[[1]]$lignes[[1]] <- x$tableaux[[1]]$lignes[[1]][-1]
    x
  })
  expect_error(valider_tout(dir), "autant de cellules")
})

test_that("statut, date et durée des séances sont cohérents", {
  dir <- modifier_yaml(copier_fixture_valide(), "seances.yml", function(x) {
    x$seances[[1]]$statut <- "terminé"
    x
  })
  expect_error(valider_tout(dir), "statut hors liste")

  dir <- modifier_yaml(copier_fixture_valide(), "seances.yml", function(x) {
    x$seances[[1]]$date <- "2026-13-40"
    x
  })
  expect_error(valider_tout(dir), "date invalide")

  dir <- modifier_yaml(copier_fixture_valide(), "seances.yml", function(x) {
    x$seances[[1]]$date <- NULL
    x
  })
  expect_error(valider_tout(dir), "date et une durée")

  dir <- modifier_yaml(copier_fixture_valide(), "seances.yml", function(x) {
    x$seances[[1]]$duree <- "duree-inconnue"
    x
  })
  expect_error(valider_tout(dir), "absent de mesures.yml")
})

test_that("le plan du cours et la barre latérale citent les mêmes chapitres", {
  # un chapitre déclaré existe
  dir <- copier_fixture_valide()
  file.remove(chapitre_fixture(dir, "seance-01-cours.md"))
  expect_error(valider_tout(dir), "chapitre introuvable")

  # un chapitre présent dans cours/ est déclaré par sa séance
  dir <- copier_fixture_valide()
  file.create(chapitre_fixture(dir, "seance-02-cours.md"))
  expect_error(valider_tout(dir), "non déclaré")

  # le chapitre de la séance N s'appelle seance-NN-cours.md
  dir <- modifier_yaml(copier_fixture_valide(), "seances.yml", function(x) {
    x$seances[[2]]$cours <- "/cours/seance-01-cours.md"
    x
  })
  expect_error(valider_tout(dir), "doit être /cours/seance-02-cours.md", fixed = TRUE)

  # le plan du cours n'est pas un chapitre
  dir <- copier_fixture_valide()
  file.create(chapitre_fixture(dir, "index.qmd"))
  expect_invisible(valider_tout(dir))

  expect_identical(chemin_chapitre(10), "/cours/seance-10-cours.md")
})

test_that("les règles des concepts restent appliquées", {
  dir <- copier_fixture_valide()
  concepts <- readr::read_csv(file.path(dir, "concepts.csv"), col_types = readr::cols(.default = "c"), na = character())
  concepts$pratique_le[[1]] <- "2026-11-01"
  readr::write_csv(concepts, file.path(dir, "concepts.csv"), na = "")
  expect_error(valider_tout(dir), "pratique")

  d <- lire_tout(copier_fixture_valide())
  expect_identical(d$concepts$vu_le[[1]], "")
})
