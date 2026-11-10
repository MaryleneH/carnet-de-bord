source(if (file.exists("R/lire.R")) "R/lire.R" else "../../R/lire.R")

ETATS_AUTORISES <- c("À faire", "En cours", "Fait", "Coupé")

# Le projet interne n'apparaît jamais dans les données publiques.
MESSAGE_CONFIDENTIALITE <- "Confidentialité : seul le laboratoire figure dans les données publiques"

arreter_regle <- function(fichier, ligne_csv, regle) {
  stop(sprintf("%s ligne %d : %s", fichier, ligne_csv, regle), call. = FALSE)
}

est_date_valide_ou_vide <- function(x) {
  ifelse(
    x == "",
    TRUE,
    grepl("^\\d{4}-\\d{2}-\\d{2}$", x) & !is.na(as.Date(x, format = "%Y-%m-%d"))
  )
}

valider_dates_ou_vides <- function(df, colonnes, fichier) {
  for (colonne in colonnes) {
    invalides <- which(!est_date_valide_ou_vide(df[[colonne]]))
    if (length(invalides) > 0) {
      arreter_regle(fichier, invalides[[1]] + 1L, sprintf("Date invalide dans '%s'", colonne))
    }
  }
}

valider_etats <- function(df, colonne = "etat", fichier) {
  invalides <- which(!(df[[colonne]] %in% ETATS_AUTORISES))
  if (length(invalides) > 0) {
    arreter_regle(fichier, invalides[[1]] + 1L, "État hors liste autorisée")
  }
}

valider_tout <- function(dossier = "data") {
  d <- lire_tout(dossier)

  journal <- d$journal
  plan_labo <- d$plan_labo
  jalons <- d$jalons
  concepts <- d$concepts
  mesures <- d$mesures

  valider_dates_ou_vides(journal, c("date"), "journal.csv")
  valider_dates_ou_vides(plan_labo, c("date_fin"), "plan_labo.csv")
  valider_dates_ou_vides(jalons, c("date_prevue", "date_atteinte"), "jalons.csv")
  valider_dates_ou_vides(concepts, c("vu_le", "pratique_le", "maitrise_le"), "concepts.csv")
  valider_dates_ou_vides(mesures, c("date"), "mesures.csv")

  # journal.csv
  if (nrow(journal) > 0) {
    invalide_projet <- which(journal$projet != "labo")
    if (length(invalide_projet) > 0) {
      arreter_regle("journal.csv", invalide_projet[[1]] + 1L, MESSAGE_CONFIDENTIALITE)
    }

    invalide_etape <- which(!(journal$etape %in% paste0("J", 1:15)))
    if (length(invalide_etape) > 0) {
      arreter_regle("journal.csv", invalide_etape[[1]] + 1L, "Étape invalide pour ce projet")
    }

    duree <- suppressWarnings(as.numeric(journal$duree_h))
    invalide_duree <- which(is.na(duree) | duree <= 0 | duree > 10)
    if (length(invalide_duree) > 0) {
      arreter_regle("journal.csv", invalide_duree[[1]] + 1L, "'duree_h' doit être > 0 et <= 10")
    }
  }

  # plan_labo.csv
  valider_etats(plan_labo, fichier = "plan_labo.csv")
  attendu_labo <- paste0("J", 1:15)
  if (anyDuplicated(plan_labo$etape) > 0 || !setequal(plan_labo$etape, attendu_labo)) {
    arreter_regle("plan_labo.csv", 2L, "Étapes attendues: J1 à J15, uniques et complètes")
  }

  fait_sans_date_labo <- which(plan_labo$etat == "Fait" & plan_labo$date_fin == "")
  if (length(fait_sans_date_labo) > 0) {
    arreter_regle("plan_labo.csv", fait_sans_date_labo[[1]] + 1L, "Une étape 'Fait' doit avoir une date de fin")
  }

  # jalons.csv
  valider_etats(jalons, fichier = "jalons.csv")
  invalide_projet_jalon <- which(jalons$projet != "labo")
  if (length(invalide_projet_jalon) > 0) {
    arreter_regle("jalons.csv", invalide_projet_jalon[[1]] + 1L, MESSAGE_CONFIDENTIALITE)
  }

  fait_sans_date_jalon <- which(jalons$etat == "Fait" & jalons$date_atteinte == "")
  if (length(fait_sans_date_jalon) > 0) {
    arreter_regle("jalons.csv", fait_sans_date_jalon[[1]] + 1L, "Un jalon 'Fait' doit avoir une date atteinte")
  }

  # concepts.csv
  invalide_etape_concept <- which(!(concepts$etape %in% paste0("J", 1:15)))
  if (length(invalide_etape_concept) > 0) {
    arreter_regle("concepts.csv", invalide_etape_concept[[1]] + 1L, "'etape' doit être entre J1 et J15")
  }

  if (nrow(concepts) > 0) {
    for (i in seq_len(nrow(concepts))) {
      vu <- concepts$vu_le[[i]]
      pratique <- concepts$pratique_le[[i]]
      maitrise <- concepts$maitrise_le[[i]]

      if (pratique != "" && vu == "") {
        arreter_regle("concepts.csv", i + 1L, "Niveau 'pratique' interdit sans 'vu'")
      }
      if (maitrise != "" && pratique == "") {
        arreter_regle("concepts.csv", i + 1L, "Niveau 'maitrise' interdit sans 'pratique'")
      }

      if (vu != "" && pratique != "" && as.Date(pratique) < as.Date(vu)) {
        arreter_regle("concepts.csv", i + 1L, "Dates non croissantes entre vu et pratique")
      }
      if (pratique != "" && maitrise != "" && as.Date(maitrise) < as.Date(pratique)) {
        arreter_regle("concepts.csv", i + 1L, "Dates non croissantes entre pratique et maitrise")
      }
    }
  }

  # mesures.csv
  if (nrow(mesures) > 0) {
    invalide_serveur <- which(!(mesures$serveur %in% c("albert", "sspcloud")))
    if (length(invalide_serveur) > 0) {
      arreter_regle("mesures.csv", invalide_serveur[[1]] + 1L, "'serveur' doit valoir albert ou sspcloud")
    }

    succes <- suppressWarnings(as.numeric(mesures$succes))
    n <- suppressWarnings(as.numeric(mesures$n))

    invalide_n <- which(is.na(n) | n <= 0 | n %% 1 != 0)
    if (length(invalide_n) > 0) {
      arreter_regle("mesures.csv", invalide_n[[1]] + 1L, "'n' doit être un entier strictement positif")
    }

    invalide_succes <- which(is.na(succes) | succes %% 1 != 0 | succes < 0 | succes > n)
    if (length(invalide_succes) > 0) {
      arreter_regle("mesures.csv", invalide_succes[[1]] + 1L, "'succes' doit être un entier entre 0 et n")
    }
  }

  invisible(d)
}
