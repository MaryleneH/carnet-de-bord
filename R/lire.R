lire_csv_strict <- function(path, colonnes_attendues) {
  donnees <- readr::read_csv(
    file = path,
    show_col_types = FALSE,
    col_types = readr::cols(.default = readr::col_character())
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

lire_tout <- function(dossier = "data") {
  list(
    journal = lire_csv_strict(
      file.path(dossier, "journal.csv"),
      c("date", "projet", "etape", "duree_h", "fait", "appris", "suite")
    ),
    plan_labo = lire_csv_strict(
      file.path(dossier, "plan_labo.csv"),
      c("etape", "semaine", "objectif", "livrable", "critere", "etat", "date_fin")
    ),
    plan_produit = lire_csv_strict(
      file.path(dossier, "plan_produit.csv"),
      c("etape", "intitule", "duree_prevue_sem", "etat", "date_debut", "date_fin")
    ),
    jalons = lire_csv_strict(
      file.path(dossier, "jalons.csv"),
      c("jalon", "projet", "critere", "date_prevue", "etat", "date_atteinte")
    ),
    concepts = lire_csv_strict(
      file.path(dossier, "concepts.csv"),
      c("concept", "etape", "vu_le", "pratique_le", "maitrise_le")
    ),
    mesures = lire_csv_strict(
      file.path(dossier, "mesures.csv"),
      c("date", "serveur", "modele", "indicateur", "succes", "n", "commentaire")
    )
  )
}
