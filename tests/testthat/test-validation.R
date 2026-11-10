source(if (file.exists("R/lire.R")) "R/lire.R" else "../../R/lire.R")
source(if (file.exists("R/valider.R")) "R/valider.R" else "../../R/valider.R")

test_that("valider.R se source depuis tests/testthat", {
  expect_no_error(source("../../R/valider.R", local = new.env(parent = globalenv())))
})

copier_fixture_valide <- function() {
  dir <- tempfile("fixture-")
  dir.create(dir)
  fichiers <- c("journal.csv", "plan_labo.csv", "plan_produit.csv", "jalons.csv", "concepts.csv", "mesures.csv")
  for (f in fichiers) {
    file.copy(file.path("tests/testthat/fixtures", f), file.path(dir, f), overwrite = TRUE)
  }
  dir
}

test_that("le jeu de fixtures valide passe", {
  dir <- copier_fixture_valide()
  expect_invisible(valider_tout(dir))
})

test_that("les champs vides restent des chaînes vides", {
  dir <- copier_fixture_valide()
  d <- lire_tout(dir)
  expect_identical(d$concepts$vu_le[[1]], "")
  expect_identical(d$concepts$pratique_le[[1]], "")
  expect_identical(d$concepts$maitrise_le[[1]], "")
})

test_that("chaque règle clé déclenche une erreur dédiée", {
  # colonnes exactes
  dir <- copier_fixture_valide()
  writeLines("a,b\n1,2", file.path(dir, "journal.csv"))
  expect_error(valider_tout(dir), "Colonnes invalides")

  # date valide ou vide
  dir <- copier_fixture_valide()
  writeLines(
    c(
      "date,projet,etape,duree_h,fait,appris,suite",
      "2026-99-01,labo,J1,1,fait,appris,suite"
    ),
    file.path(dir, "journal.csv")
  )
  expect_error(valider_tout(dir), "Date invalide")

  # états autorisés
  dir <- copier_fixture_valide()
  plan <- readr::read_csv(file.path(dir, "plan_labo.csv"), show_col_types = FALSE)
  plan$etat[[1]] <- "Terminé"
  readr::write_csv(plan, file.path(dir, "plan_labo.csv"), na = "")
  expect_error(valider_tout(dir), "État hors liste autorisée")

  # étapes complètes labo
  dir <- copier_fixture_valide()
  plan <- readr::read_csv(file.path(dir, "plan_labo.csv"), show_col_types = FALSE)
  plan$etape[[15]] <- "J16"
  readr::write_csv(plan, file.path(dir, "plan_labo.csv"), na = "")
  expect_error(valider_tout(dir), "J1 à J15")

  # fait => date de fin
  dir <- copier_fixture_valide()
  plan <- readr::read_csv(file.path(dir, "plan_produit.csv"), show_col_types = FALSE)
  plan$etat[[1]] <- "Fait"
  plan$date_fin[[1]] <- ""
  readr::write_csv(plan, file.path(dir, "plan_produit.csv"), na = "")
  expect_error(valider_tout(dir), "date de fin")

  # confidentialité produit
  dir <- copier_fixture_valide()
  writeLines(
    c(
      "date,projet,etape,duree_h,fait,appris,suite",
      "2026-11-01,produit,P0,2,texte,,"
    ),
    file.path(dir, "journal.csv")
  )
  expect_error(valider_tout(dir), "Confidentialité : pas de texte libre pour le projet interne")

  # mesures serveurs autorisés
  dir <- copier_fixture_valide()
  writeLines(
    c(
      "date,serveur,modele,indicateur,succes,n,commentaire",
      "2026-11-01,autre,m1,qualite,1,10,"
    ),
    file.path(dir, "mesures.csv")
  )
  expect_error(valider_tout(dir), "albert ou sspcloud")

  # succes borné par n
  dir <- copier_fixture_valide()
  writeLines(
    c(
      "date,serveur,modele,indicateur,succes,n,commentaire",
      "2026-11-01,albert,m1,qualite,11,10,"
    ),
    file.path(dir, "mesures.csv")
  )
  expect_error(valider_tout(dir), "entre 0 et n")

  # concepts séquence des niveaux
  dir <- copier_fixture_valide()
  concepts <- readr::read_csv(file.path(dir, "concepts.csv"), show_col_types = FALSE)
  concepts$pratique_le[[1]] <- "2026-11-01"
  readr::write_csv(concepts, file.path(dir, "concepts.csv"), na = "")
  expect_error(valider_tout(dir), "pratique")
})
