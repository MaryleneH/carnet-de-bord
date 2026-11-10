source("R/calculs.R")
source("R/lire.R")

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

test_that("le dashboard se rend avec journal et mesures vides", {
  skip_if(Sys.which("quarto") == "", "quarto non disponible")

  status <- system2("quarto", c("render", "index.qmd"))
  expect_equal(status, 0)
})
