# Lecture des données du carnet : registre des séances, registre des mesures
# (chiffres sourcés, formules, tableaux), suivi des concepts, veille et notions.

lire_yaml <- function(chemin) {
  if (!file.exists(chemin)) {
    stop(sprintf("%s : fichier introuvable", basename(chemin)), call. = FALSE)
  }
  yaml::read_yaml(chemin, eval.expr = FALSE)
}

lire_csv_strict <- function(path, colonnes_attendues) {
  donnees <- readr::read_csv(
    file = path,
    show_col_types = FALSE,
    col_types = readr::cols(.default = readr::col_character()),
    na = character()
  )

  colonnes <- names(donnees)
  if (!identical(colonnes, colonnes_attendues)) {
    stop(
      sprintf(
        "%s ligne 1 : Colonnes invalides (attendu: %s)",
        basename(path),
        paste(colonnes_attendues, collapse = ",")
      ),
      call. = FALSE
    )
  }

  donnees
}

# Un intervalle [20.7, 100] mêle décimal et entier : yaml le lit comme une
# liste, que l'on ramène à un vecteur.
normaliser_mesure <- function(m) {
  if (is.list(m$valeur)) m$valeur <- unlist(m$valeur)
  m
}

# Un lien de veille : mots-clés en vecteur, date d'ajout en texte.
normaliser_lien <- function(l) {
  l$mots_cles <- as.character(unlist(l$mots_cles))
  if (!is.null(l$ajoute_le)) l$ajoute_le <- as.character(l$ajoute_le)
  l
}

# En-tête YAML d'une page Markdown : ce qui tient entre ses deux premières lignes « --- ».
lire_entete <- function(chemin) {
  lignes <- readLines(chemin, encoding = "UTF-8", warn = FALSE)
  bornes <- which(lignes == "---")
  if (length(bornes) < 2 || bornes[[1]] != 1 || bornes[[2]] == 2) return(list())
  entete <- yaml::yaml.load(paste(lignes[seq(2, bornes[[2]] - 1)], collapse = "\n"), eval.expr = FALSE)
  if (is.list(entete)) entete else list()
}

# Les cours de notions : un fichier par notion dans le dossier notions/, décrit
# par son en-tête (title, subtitle, date). Le sommaire de la rubrique n'en est pas un.
lire_notions <- function(dossier = "notions") {
  fichiers <- sort(setdiff(list.files(dossier, "\\.(md|qmd)$"), c("index.qmd", "index.md")), method = "radix")
  lapply(fichiers, function(f) {
    e <- lire_entete(file.path(dossier, f))
    list(
      fichier = f,
      titre = e$title,
      resume = e$subtitle,
      date = if (is.null(e$date)) NULL else as.character(e$date)
    )
  })
}

lire_tout <- function(dossier = "data") {
  registre <- lire_yaml(file.path(dossier, "mesures.yml"))
  veille <- lire_yaml(file.path(dossier, "veille.yml"))
  list(
    seances = lire_yaml(file.path(dossier, "seances.yml"))$seances,
    mesures = lapply(registre$mesures, normaliser_mesure),
    formules = registre$formules,
    tableaux = registre$tableaux,
    concepts = lire_csv_strict(
      file.path(dossier, "concepts.csv"),
      c("concept", "etape", "vu_le", "pratique_le", "maitrise_le")
    ),
    veille = list(themes = veille$themes, liens = lapply(veille$liens, normaliser_lien)),
    # le dossier notions/ est à côté du dossier des données
    notions = lire_notions(file.path(dirname(dossier), "notions"))
  )
}
