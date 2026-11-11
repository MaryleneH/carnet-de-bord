source(if (file.exists("R/pages.R")) "R/pages.R" else "../../R/pages.R", encoding = "UTF-8")
source(if (file.exists("R/veille.R")) "R/veille.R" else "../../R/veille.R", encoding = "UTF-8")

racine <- if (file.exists("_quarto.yml")) "." else "../.."
dossier_fixtures <- if (dir.exists("tests/testthat/fixtures")) "tests/testthat/fixtures" else "fixtures"

test_that("chaque lien est rangé sous son thème, du plus récent au plus ancien", {
  d <- lire_tout(dossier_fixtures)
  page <- page_veille(d)
  for (l in d$veille$liens) {
    expect_match(page, sprintf("](%s)", l$url), fixed = TRUE)
    expect_match(page, l$titre, fixed = TRUE)
    expect_match(page, l$resume, fixed = TRUE)
  }
  # un thème sans lien n'apparaît pas
  expect_false(grepl("Thème sans lien", page, fixed = TRUE))
  # thèmes dans l'ordre du fichier, liens les plus récents d'abord
  expect_lt(regexpr("## Thème A", page, fixed = TRUE), regexpr("## Thème B", page, fixed = TRUE))
  expect_lt(regexpr("Lien récent", page, fixed = TRUE), regexpr("Lien ancien", page, fixed = TRUE))
})

test_that("les compteurs de la page viennent des données", {
  d <- lire_tout(dossier_fixtures)
  page <- page_veille(d)
  expect_match(
    page,
    "[3 liens]{.veille-chiffre} · [2 thèmes]{.veille-chiffre} · [dernier ajout le 5 novembre 2026]{.veille-chiffre}",
    fixed = TRUE
  )
  expect_match(page, "## Thème A [2 liens]{.veille-compte}", fixed = TRUE)
  expect_match(page, "## Thème B [1 lien]{.veille-compte}", fixed = TRUE)
  # filtres : tous les liens, puis chaque thème garni avec son nombre de liens
  expect_match(page, "data-theme=\"tous\" aria-pressed=\"true\"", fixed = TRUE)
  expect_match(page, "Tous les thèmes</span><span class=\"veille-filtre-compte\">3<", fixed = TRUE)
  expect_match(page, "Thème A</span><span class=\"veille-filtre-compte\">2<", fixed = TRUE)
})

test_that("une page anglaise est annoncée et la recherche est accessible", {
  d <- lire_tout(dossier_fixtures)
  page <- page_veille(d)
  expect_match(page, "(https://example.org/recent){hreflang=\"en\"}", fixed = TRUE)
  expect_match(page, "[en anglais]{.veille-langue}", fixed = TRUE)
  expect_match(page, "s'ouvre dans un nouvel onglet", fixed = TRUE)
  expect_match(page, "role=\"status\"", fixed = TRUE)
  expect_match(page, "<label class=\"veille-etiquette\" for=\"veille-recherche\">", fixed = TRUE)
})

test_that("la vraie veille est valide et sa page se construit", {
  d <- charger(file.path(racine, "data"))
  page <- page_veille(d)
  expect_match(page, "a2ui.org", fixed = TRUE)
  expect_false(grepl("intern", page, ignore.case = TRUE))
  expect_identical(domaine("https://www.example.org/a"), "example.org")
})
