source(if (file.exists("R/calculs.R")) "R/calculs.R" else "../../R/calculs.R", encoding = "UTF-8")
source(if (file.exists("R/lire.R")) "R/lire.R" else "../../R/lire.R", encoding = "UTF-8")

dossier_data <- if (dir.exists("data")) "data" else "../../data"
arrondir_pourcent <- function(x) round(100 * x, 1)

test_that("intervalle de Wilson suit les valeurs attendues", {
  w_2_60 <- wilson(2, 60)
  expect_equal(arrondir_pourcent(w_2_60[["borne_basse"]]), 0.9, tolerance = 0.15)
  expect_equal(arrondir_pourcent(w_2_60[["borne_haute"]]), 11.4, tolerance = 0.15)

  w_0_100 <- wilson(0, 100)
  expect_equal(arrondir_pourcent(w_0_100[["borne_basse"]]), 0.0, tolerance = 0.15)
  expect_equal(arrondir_pourcent(w_0_100[["borne_haute"]]), 3.7, tolerance = 0.15)

  w_5_100 <- wilson(5, 100)
  expect_equal(arrondir_pourcent(w_5_100[["borne_basse"]]), 2.2, tolerance = 0.15)
  expect_equal(arrondir_pourcent(w_5_100[["borne_haute"]]), 11.2, tolerance = 0.15)
})

test_that("l'intervalle de Wilson du registre est celui que donne le calcul", {
  d <- lire_tout(dossier_data)
  m <- Find(function(m) identical(m$id, "wilson-un-essai"), d$mesures)
  w <- wilson(1, 1)
  expect_equal(arrondir_pourcent(w[["borne_basse"]]), m$valeur[[1]])
  expect_equal(100 * w[["borne_haute"]], m$valeur[[2]])
})

test_that("les nombres sont mis en forme à la française", {
  expect_identical(format_nombre(52697), "52 697")
  expect_identical(format_nombre(0.838), "0,838")
  expect_identical(format_nombre(5.18e-5), "5,18 × 10⁻⁵")
  expect_identical(format_valeur(list(valeur = c(20.7, 100), unite = "%")), "20,7 % à 100 %")
  expect_identical(format_valeur(list(valeur = 156, approx = TRUE, unite = "tokens")), "≈ 156")
  expect_identical(format_valeur(list(valeur = 3, unite = "h"), avec_unite = TRUE), "3 h")
  expect_identical(date_longue("2026-11-10"), "10 novembre 2026")
  expect_identical(date_longue("2027-03-01"), "1er mars 2027")
})

test_that("le site se rend", {
  skip_if(Sys.which("quarto") == "", "quarto non disponible")
  racine <- if (file.exists("_quarto.yml")) "." else "../.."
  status <- system2("quarto", c("render", racine))
  expect_equal(status, 0)
})
