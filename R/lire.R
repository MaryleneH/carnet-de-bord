# Lecture des données du carnet : registre des séances, registre des mesures
# (chiffres sourcés, formules, tableaux), suivi des concepts et veille.

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
    veille = list(themes = veille$themes, liens = lapply(veille$liens, normaliser_lien))
  )
}
