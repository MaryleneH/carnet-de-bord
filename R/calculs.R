semaine_iso <- function(date) {
  format(as.Date(date), "%G-W%V")
}

heures_par_semaine_projet <- function(journal) {
  if (nrow(journal) == 0) {
    return(dplyr::tibble(semaine = character(), projet = character(), heures = numeric()))
  }

  journal |>
    dplyr::mutate(
      date = as.Date(date),
      semaine = format(date, "%G-W%V"),
      duree_h = as.numeric(duree_h)
    ) |>
    dplyr::group_by(semaine, projet) |>
    dplyr::summarise(heures = sum(duree_h), .groups = "drop")
}

etape_en_cours <- function(plan, colonne_etape = "etape") {
  non_faites <- plan |>
    dplyr::filter(.data$etat != "Fait")

  if (nrow(non_faites) == 0) {
    tail(plan[[colonne_etape]], 1)
  } else {
    non_faites[[colonne_etape]][[1]]
  }
}

etapes_en_cours <- function(plan_labo) {
  dplyr::tibble(
    projet = "labo",
    etape = etape_en_cours(plan_labo)
  )
}

wilson <- function(succes, n, z = 1.959964) {
  p <- succes / n
  denominateur <- 1 + (z^2 / n)
  centre <- (p + (z^2 / (2 * n))) / denominateur
  demi_largeur <- z * sqrt((p * (1 - p) / n) + (z^2 / (4 * n^2))) / denominateur

  c(
    centre = centre,
    borne_basse = pmax(0, centre - demi_largeur),
    borne_haute = pmin(1, centre + demi_largeur)
  )
}

ajouter_wilson <- function(mesures) {
  if (nrow(mesures) == 0) {
    return(
      dplyr::tibble(
        date = as.Date(character()),
        serveur = character(),
        modele = character(),
        indicateur = character(),
        succes = integer(),
        n = integer(),
        commentaire = character(),
        taux = numeric(),
        borne_basse = numeric(),
        borne_haute = numeric()
      )
    )
  }

  mesures |>
    dplyr::mutate(
      date = as.Date(date),
      succes = as.integer(succes),
      n = as.integer(n)
    ) |>
    dplyr::rowwise() |>
    dplyr::mutate(
      taux = succes / n,
      borne_basse = wilson(succes, n)[["borne_basse"]],
      borne_haute = wilson(succes, n)[["borne_haute"]]
    ) |>
    dplyr::ungroup()
}
