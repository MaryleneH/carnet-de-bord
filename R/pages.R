# Rendu des pages : ces fonctions lisent les registres (data/seances.yml,
# data/mesures.yml) et produisent du Markdown Pandoc. Aucun chiffre n'y est
# écrit à la main : chaque valeur vient du registre des mesures, avec sa source.

source(if (file.exists("R/valider.R")) "R/valider.R" else "../../R/valider.R", encoding = "UTF-8")
source(if (file.exists("R/calculs.R")) "R/calculs.R" else "../../R/calculs.R", encoding = "UTF-8")

CLASSES_ETAT <- c(
  "fait" = "etat-fait", "en cours" = "etat-en-cours", "à planifier" = "etat-a-planifier",
  "prévu" = "etat-prevu", "préparé" = "etat-prepare", "en attente" = "etat-en-attente"
)

# Chiffres clés de l'accueil, par identifiant du registre.
CHIFFRES_CLES <- c(
  "tokens-lus-max", "vitesse-lecture", "debit-ecriture",
  "ratio-ecriture-lecture", "dimension-embeddings", "wilson-un-essai"
)

# ── Accès aux registres ──────────────────────────────────────────────────────

# Lecture et validation à chaque rendu : une donnée invalide arrête le rendu.
charger <- function(dossier = "data") valider_tout(dossier)

trouver <- function(liste, id, quoi) {
  for (x in liste) if (identical(x$id, id)) return(x)
  stop(sprintf("%s introuvable : %s", quoi, id), call. = FALSE)
}
mesure <- function(d, id) trouver(d$mesures, id, "mesure")
seance <- function(d, id) trouver(d$seances, id, "séance")

ordonner <- function(ss) ss[order(vapply(ss, function(s) as.numeric(s$numero), numeric(1)))]
seances_labo <- function(d) ordonner(Filter(function(s) identical(s$projet, "labo"), d$seances))
seances_internes <- function(d) Filter(function(s) identical(s$projet, "interne"), d$seances)
derniere_seance <- function(d) {
  faites <- Filter(function(s) s$statut == "fait", seances_labo(d))
  faites[[length(faites)]]
}
prochaine_seance <- function(d) Filter(function(s) s$statut != "fait", seances_labo(d))[[1]]

# ── Petits éléments ──────────────────────────────────────────────────────────

badge <- function(statut) sprintf("[%s]{.badge-etat .%s}", statut, CLASSES_ETAT[[statut]])

remplacer_references <- function(texte, d) {
  for (id in references(texte)) {
    texte <- gsub(paste0("{", id, "}"), format_valeur(mesure(d, id)), texte, fixed = TRUE)
  }
  texte
}

titre_complet <- function(s) if (is.null(s$sous_titre)) s$titre else paste0(s$titre, " : ", s$sous_titre)
titre_lien <- function(s) {
  if (is.null(s$lien)) titre_complet(s) else sprintf("[%s](%s)", titre_complet(s), s$lien)
}

surtitre_seance <- function(s) {
  quand <- if (!is.null(s$date)) date_longue(s$date) else "date à planifier"
  sprintf("Séance %d · Laboratoire · %s", as.integer(s$numero), quand)
}

duree_texte <- function(s, d) {
  if (is.null(s$duree)) "à compléter" else format_valeur(mesure(d, s$duree), avec_unite = TRUE)
}

liste_md <- function(items) paste0("- ", items, collapse = "\n")

# Définition Pandoc dont le contenu est une liste à puces.
definition_liste <- function(items) {
  if (length(items) == 0) return(":   à compléter")
  paste0(":   - ", items[[1]], paste0("\n    - ", items[-1], collapse = ""))
}

livrables_de <- function(s, d) {
  vapply(s$livrables, remplacer_references, character(1), d = d, USE.NAMES = FALSE)
}

# Source d'une mesure, avec un lien vers la partie du cours citée.
cours_de_seance <- function(d, numero) {
  for (s in seances_labo(d)) if (s$numero == numero && !is.null(s$cours)) return(s$cours)
  NULL
}
ancre_partie <- function(partie) {
  if (grepl("^annexe [A-F]$", partie)) return(paste0("#annexe-", tolower(substring(partie, 8))))
  if (grepl("^chapitres? [0-9]+", partie)) {
    return(paste0("#chapitre-", sub("^chapitres? ([0-9]+).*$", "\\1", partie)))
  }
  ""
}
lien_source <- function(d, src) {
  texte <- sprintf("séance %d, %s", as.integer(src$seance), src$partie)
  cours <- cours_de_seance(d, src$seance)
  if (is.null(cours)) texte else sprintf("[%s](%s%s)", texte, cours, ancre_partie(src$partie))
}
ligne_source <- function(d, src) paste0("[Source : ", lien_source(d, src), "]{.source}")

# ── Cartes de séance ─────────────────────────────────────────────────────────

# Date, projet, statut, durée et livrables d'une séance.
corps_seance <- function(s, d, niveau = 3) {
  paste0(
    "[", surtitre_seance(s), "]{.carte-surtitre}\n\n",
    strrep("#", niveau), " ", titre_lien(s), " {.carte-titre}\n\n",
    "Statut\n:   ", badge(s$statut), "\n\n",
    "Durée\n:   ", duree_texte(s, d), "\n\n",
    "Livrables\n", definition_liste(livrables_de(s, d)), "\n\n"
  )
}

carte_seance <- function(s, d, niveau = 3) {
  paste0("::: {.carte .carte-seance}\n\n", corps_seance(s, d, niveau), ":::\n\n")
}

# ── Accueil ──────────────────────────────────────────────────────────────────

bloc <- function(titre, contenu, classe = "") {
  paste0("::: {.carte .bloc ", classe, "}\n\n## ", titre, "\n\n", contenu, ":::\n\n")
}

etat_projets <- function(d) {
  derniere <- derniere_seance(d)
  prochaine <- prochaine_seance(d)
  labo <- sprintf(
    "**Laboratoire** : semaine %d, séance %d faite, séance %d %s. %s",
    as.integer(derniere$semaine), as.integer(derniere$numero),
    as.integer(prochaine$numero), prochaine$statut, badge("en cours")
  )
  phase <- trouver(seances_internes(d), "interne-phase", "ligne interne")
  interne <- paste(phase$titre, badge(phase$statut))
  bloc("Où j'en suis", paste0(liste_md(c(labo, interne)), "\n\n"), ".bloc-etat")
}

point_md <- function(p) {
  texte <- paste0("**", p$intitule, "** : ", p$detail)
  if (p$detail != p$statut) texte <- paste(texte, badge(p$statut))
  texte
}

points_en_attente <- function(d) {
  s <- derniere_seance(d)
  points <- Filter(function(p) p$statut == "en attente", s$points_en_attente)
  paste0(
    liste_md(vapply(points, point_md, character(1))), "\n\n",
    sprintf("Clôture de la séance %d : [vérifications à cocher](%s#cloture).\n\n", as.integer(s$numero), s$lien)
  )
}

chiffres_cles <- function(d, ids = CHIFFRES_CLES) {
  cartes <- vapply(ids, function(id) {
    m <- mesure(d, id)
    unite <- if (identical(m$unite, "%")) "" else m$unite
    paste0(
      "::: {.chiffre}\n\n",
      "[", format_valeur(m), "]{.chiffre-valeur}",
      if (nzchar(unite)) paste0(" [", unite, "]{.chiffre-unite}") else "", "\n\n",
      "[", m$libelle, "]{.chiffre-libelle}\n\n",
      ligne_source(d, m$source), "\n\n",
      ":::\n\n"
    )
  }, character(1), USE.NAMES = FALSE)
  paste0("::: {.chiffres-cles}\n\n", paste(cartes, collapse = ""), ":::\n\n")
}

page_accueil <- function(d) {
  paste0(
    "::: {.tableau-bord}\n\n",
    etat_projets(d),
    bloc("Dernière séance", corps_seance(derniere_seance(d), d, niveau = 3)),
    bloc("Prochaine étape", corps_seance(prochaine_seance(d), d, niveau = 3)),
    bloc("Points en attente", points_en_attente(d)),
    ":::\n\n",
    "## Chiffres clés {#chiffres-cles}\n\n",
    chiffres_cles(d)
  )
}

# ── Planning ─────────────────────────────────────────────────────────────────

etape_frise <- function(s, d) {
  quand <- paste0("Séance ", as.integer(s$numero), if (!is.null(s$date)) paste0(" · ", date_longue(s$date)) else "")
  livrables <- livrables_de(s, d)
  paste0(
    "::: {.frise-etape .", CLASSES_ETAT[[s$statut]], " role=\"listitem\"}\n\n",
    "[", quand, "]{.frise-quand} ", badge(s$statut), "\n\n",
    "[", titre_lien(s), "]{.frise-titre}\n\n",
    if (length(livrables) > 0) paste0("[", paste(livrables, collapse = " · "), "]{.frise-livrables}\n\n") else "",
    if (!is.null(s$jalon)) paste0("[Jalon ", s$jalon$id, " : ", s$jalon$critere, "]{.frise-jalon}\n\n") else "",
    ":::\n\n"
  )
}

frise <- function(d) {
  labo <- seances_labo(d)
  semaines <- sort(unique(vapply(labo, function(s) as.integer(s$semaine), integer(1))))
  par_semaine <- vapply(semaines, function(w) {
    etapes <- Filter(function(s) s$semaine == w, labo)
    paste0(
      "### Semaine ", w, "\n\n::: {.frise role=\"list\"}\n\n",
      paste(vapply(etapes, etape_frise, character(1), d = d), collapse = ""),
      ":::\n\n"
    )
  }, character(1))
  internes <- vapply(seances_internes(d), function(s) {
    paste0(
      "::: {.frise-etape .", CLASSES_ETAT[[s$statut]], " role=\"listitem\"}\n\n",
      "[", s$titre, "]{.frise-titre} ", badge(s$statut), "\n\n:::\n\n"
    )
  }, character(1))
  paste0(
    "::: {.planning}\n\n",
    "::: {.planning-principal}\n\n## Laboratoire\n\n", paste(par_semaine, collapse = ""), ":::\n\n",
    "::: {.planning-cote}\n\n## Projet interne\n\n::: {.frise role=\"list\"}\n\n",
    paste(internes, collapse = ""), ":::\n\n:::\n\n",
    ":::\n\n"
  )
}

# ── Séances ──────────────────────────────────────────────────────────────────

cartes_seances <- function(d) {
  ss <- Filter(function(s) s$statut != "prévu", seances_labo(d))
  paste0("::: {.grille-cartes}\n\n", paste(vapply(ss, carte_seance, character(1), d = d, niveau = 2), collapse = ""), ":::\n\n")
}

cellule <- function(x) if (is.numeric(x)) format_nombre(x) else as.character(x)

tableau_md <- function(t) {
  numerique <- vapply(seq_along(t$colonnes), function(j) {
    all(vapply(t$lignes, function(l) is.numeric(l[[j]]), logical(1)))
  }, logical(1))
  lignes <- vapply(t$lignes, function(l) {
    paste0("| ", paste(vapply(l, cellule, character(1), USE.NAMES = FALSE), collapse = " | "), " |")
  }, character(1))
  paste(c(
    paste0("| ", paste(unlist(t$colonnes), collapse = " | "), " |"),
    paste0("|", paste(ifelse(numerique, "---:", ":---"), collapse = "|"), "|"),
    lignes
  ), collapse = "\n")
}

resultats <- function(d, s) {
  numero <- s$numero
  tableaux <- Filter(function(t) t$source$seance == numero, d$tableaux)
  blocs <- vapply(tableaux, function(t) {
    paste0(
      "### ", t$titre, "\n\n", tableau_md(t), "\n\n",
      if (!is.null(t$note)) paste0(remplacer_references(t$note, d), "\n\n") else "",
      ligne_source(d, t$source), "\n\n"
    )
  }, character(1))
  formules <- vapply(Filter(function(f) f$source$seance == numero, d$formules), function(f) {
    pente <- mesure(d, "pente-lecture")
    ordonnee <- mesure(d, "ordonnee-origine")
    paste0(
      "### ", f$titre, "\n\n",
      "::: {.callout-caution title=\"Formule\"}\n", f$texte, "\n:::\n\n",
      pente$libelle, " : ", format_valeur(pente, avec_unite = TRUE), " ; ",
      tolower(substring(ordonnee$libelle, 1, 1)), substring(ordonnee$libelle, 2), " : ",
      format_valeur(ordonnee, avec_unite = TRUE), ".\n\n",
      ligne_source(d, f$source), "\n\n"
    )
  }, character(1))
  paste0(paste(blocs, collapse = ""), paste(formules, collapse = ""))
}

incidents <- function(d, s) {
  items <- vapply(s$incidents, function(i) {
    paste0(
      "::: {.incident}\n\n",
      "**", remplacer_references(i$incident, d), "**\n\n",
      "Cause\n:   ", remplacer_references(i$cause, d), "\n\n",
      "Correction\n:   ", remplacer_references(i$correction, d), "\n\n",
      sprintf("[Chapitre %d du cours](%s#chapitre-%d){.incident-chapitre}\n\n", as.integer(i$chapitre), s$cours, as.integer(i$chapitre)),
      ":::\n\n"
    )
  }, character(1))
  paste0(
    "::: {.incidents}\n\n", paste(items, collapse = ""), ":::\n\n",
    ligne_source(d, list(seance = s$numero, partie = "annexe B")), "\n\n"
  )
}

cloture <- function(d, s) {
  commits <- vapply(s$commits, function(co) paste0("`", co$hash, "` ", co$message), character(1))
  a_cocher <- vapply(s$a_cocher, function(x) paste0("[ ] ", x), character(1), USE.NAMES = FALSE)
  points <- vapply(s$points_en_attente, point_md, character(1))
  paste0(
    "### Commits confirmés\n\n", liste_md(commits), "\n\n",
    "### À cocher\n\n", liste_md(a_cocher), "\n\n",
    "### Points en attente\n\n", liste_md(points), "\n\n",
    ligne_source(d, list(seance = s$numero, partie = "annexe C")), "\n\n"
  )
}

page_seance <- function(d, id) {
  s <- seance(d, id)
  paste0(
    "::: {.seance-entete}\n\n[", surtitre_seance(s), "]{.carte-surtitre}\n\n",
    "Statut\n:   ", badge(s$statut), "\n\n",
    "Durée\n:   ", duree_texte(s, d), "\n\n:::\n\n",
    "## Objectif {#objectif}\n\n", remplacer_references(s$objectif, d), "\n\n",
    "## Résultats {#resultats}\n\n", resultats(d, s),
    "## Incidents et corrections {#incidents}\n\n", incidents(d, s),
    "## Commits et points en attente {#cloture}\n\n", cloture(d, s),
    "## Livrable {#livrable}\n\n", liste_md(livrables_de(s, d)), "\n\n",
    if (!is.null(s$cours)) sprintf("Le détail, chapitre par chapitre, est dans le [cours de la séance](%s).\n\n", s$cours) else ""
  )
}

# ── Cours ────────────────────────────────────────────────────────────────────

liste_cours <- function(d) {
  ss <- Filter(function(s) !is.null(s$cours), seances_labo(d))
  cartes <- vapply(ss, function(s) {
    paste0(
      "::: {.carte .carte-cours}\n\n",
      "[", surtitre_seance(s), "]{.carte-surtitre}\n\n",
      "## [", s$titre, "](", s$cours, ") {.carte-titre}\n\n",
      "Le cours détaillé de la séance : chaque étape expliquée, ses résultats, ",
      "ses pièges, des questions de contrôle et une bibliographie vérifiée.\n\n",
      ":::\n\n"
    )
  }, character(1))
  paste0("::: {.grille-cartes}\n\n", paste(cartes, collapse = ""), ":::\n\n")
}
