source(if (file.exists("R/pages.R")) "R/pages.R" else "../../R/pages.R", encoding = "UTF-8")

racine <- if (file.exists("_quarto.yml")) "." else "../.."

# Un dossier notions/ d'essai : chaque fichier reçoit l'en-tête donné, ligne par ligne.
dossier_notions <- function(fichiers) {
  dossier <- file.path(tempfile("notions-"), "notions")
  dir.create(dossier, recursive = TRUE)
  for (nom in names(fichiers)) {
    writeLines(c("---", fichiers[[nom]], "---", "", "Le cours."), file.path(dossier, nom), useBytes = TRUE)
  }
  dossier
}

trois_notions <- function() {
  dossier_notions(list(
    "intervalle-de-wilson.md" = c("title: \"Intervalle de Wilson\"", "subtitle: \"Lire un taux sur peu d'essais\"", "date: 2026-11-23"),
    "ecart-au-plan.md" = c("title: \"Écart au plan\"", "date: 2026-11-22"),
    "adr.qmd" = c("title: \"ADR\"", "subtitle: \"Consigner une décision\"", "date: 2026-11-25"),
    "index.qmd" = c("title: \"Notions\"")
  ))
}

test_that("la rubrique liste les cours de notions, rangés par nom de fichier", {
  notions <- lire_notions(trois_notions())
  expect_silent(valider_notions(notions))
  # le sommaire n'est pas une notion
  expect_identical(vapply(notions, function(n) n$fichier, character(1)), c("adr.qmd", "ecart-au-plan.md", "intervalle-de-wilson.md"))
  # même donnés dans le désordre, les cours reviennent dans l'ordre de la barre latérale
  page <- page_notions(list(notions = rev(notions)))
  expect_lt(regexpr("[ADR]", page, fixed = TRUE), regexpr("[Écart au plan]", page, fixed = TRUE))
  expect_lt(regexpr("[Écart au plan]", page, fixed = TRUE), regexpr("[Intervalle de Wilson]", page, fixed = TRUE))
  # chaque carte mène à son cours et donne sa date ; le sous-titre est facultatif
  expect_match(page, "## [Intervalle de Wilson](/notions/intervalle-de-wilson.md)", fixed = TRUE)
  expect_match(page, "Lire un taux sur peu d'essais", fixed = TRUE)
  expect_match(page, "[Ajouté le 22 novembre 2026]{.carte-surtitre}", fixed = TRUE)
  # le compteur vient du dossier
  expect_match(page, sprintf("[%d notions]", length(notions)), fixed = TRUE)
})

test_that("l'ordre des notions est celui de la barre latérale", {
  # Quarto range la barre latérale par nom de fichier, sans l'extension : le tiret
  # passe avant les chiffres, les chiffres avant les lettres, et un nom court avant sa suite.
  noms <- c("graphe-oriente.md", "graphe.qmd", "a2.md", "graphe-d-etats.md", "ab.md", "a-z.md", "a.md")
  rangees <- notions_triees(lapply(noms, function(f) list(fichier = f)))
  expect_identical(
    vapply(rangees, function(n) n$fichier, character(1)),
    c("a.md", "a-z.md", "a2.md", "ab.md", "graphe.qmd", "graphe-d-etats.md", "graphe-oriente.md")
  )
})

test_that("sans cours de notion, la page le dit", {
  vide <- lire_notions(dossier_notions(list("index.qmd" = "title: \"Notions\"")))
  expect_length(vide, 0)
  page <- page_notions(list(notions = vide))
  expect_match(page, "Aucun cours de notion", fixed = TRUE)
  expect_false(grepl("grille-cartes", page, fixed = TRUE))
  # un dossier absent vaut un dossier vide
  expect_length(lire_notions(file.path(tempfile("absent-"), "notions")), 0)
})

test_that("un cours de notion s'annonce par un nom simple, un titre et une date", {
  valide <- c("title: \"Idempotence\"", "date: 2026-11-25")
  expect_silent(valider_notions(lire_notions(dossier_notions(list("idempotence.md" = valide)))))
  expect_error(valider_notions(lire_notions(dossier_notions(list("Idempotence.md" = valide)))), "nom du fichier")
  expect_error(valider_notions(lire_notions(dossier_notions(list("mes notes.md" = valide)))), "nom du fichier")
  expect_error(valider_notions(lire_notions(dossier_notions(list("idempotence.md" = "date: 2026-11-25")))), "titre manquant")
  expect_error(valider_notions(lire_notions(dossier_notions(list("idempotence.md" = "title: \"Idempotence\"")))), "date manquante")
  expect_error(valider_notions(lire_notions(dossier_notions(list("idempotence.md" = c("title: \"Idempotence\"", "date: 2026-13-40"))))), "date manquante ou invalide")
  expect_error(
    valider_notions(lire_notions(dossier_notions(list("outil.md" = c("title: \"Un outil interne\"", "date: 2026-11-25"))))),
    "Confidentialité"
  )
  # deux fichiers de même nom donneraient la même page
  expect_error(
    valider_notions(lire_notions(dossier_notions(list("idempotence.md" = valide, "idempotence.qmd" = valide)))),
    "porte déjà ce nom"
  )
})

test_that("la rubrique publiée est valide et sa page se construit", {
  d <- charger(file.path(racine, "data"))
  page <- page_notions(d)
  expect_match(page, "par notion", fixed = TRUE)
  expect_false(grepl("intern", page, ignore.case = TRUE))
  # une carte par cours du dossier, et une seule
  cours <- setdiff(list.files(file.path(racine, "notions"), "\\.(md|qmd)$"), "index.qmd")
  expect_identical(lengths(regmatches(page, gregexpr("{.carte .carte-notion}", page, fixed = TRUE))), length(cours))
  for (f in cours) expect_match(page, paste0("](/notions/", f, ")"), fixed = TRUE, info = f)
})

test_that("aucun nombre n'est écrit à la main dans le texte de la rubrique", {
  # Le texte fixe de la page n'en contient pas : le titre d'un cours, lui, est libre.
  expect_false(grepl("[0-9]", page_notions(list(notions = list()))))
  avec <- page_notions(list(notions = list(list(fichier = "top-p.md", titre = "Top-p à 0,9", resume = NULL, date = "2026-11-26"))))
  sans_carte <- sub("(?s)::: \\{\\.carte \\.carte-notion\\}.*?\n:::\n", "", avec, perl = TRUE)
  expect_false(grepl("[0-9]", sub("\\[[0-9]+ notions?\\]", "", sans_carte)))
})
