# Rendu des pages : ces fonctions lisent les données (data/seances.yml,
# data/mesures.yml, data/concepts.csv) et produisent du Markdown Pandoc.
# Aucun nombre n'y est écrit à la main : chacun est lu ou calculé dans les
# données, et le tableau de bord indique de quel fichier il vient.

source(if (file.exists("R/valider.R")) "R/valider.R" else "../../R/valider.R", encoding = "UTF-8")
source(if (file.exists("R/calculs.R")) "R/calculs.R" else "../../R/calculs.R", encoding = "UTF-8")

URL_DEPOT <- "https://github.com/MaryleneH/carnet-de-bord/blob/main/"

CLASSES_ETAT <- c(
  "fait" = "etat-fait", "en cours" = "etat-en-cours", "à planifier" = "etat-a-planifier",
  "prévu" = "etat-prevu", "en attente" = "etat-en-attente",
  "rédigé" = "etat-redige", "à venir" = "etat-a-venir",
  "non vu" = "niveau-non-vu", "vu" = "niveau-vu", "pratiqué" = "niveau-pratique",
  "maîtrisé" = "niveau-maitrise"
)

# ── Accès aux données ────────────────────────────────────────────────────────

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
seances_faites <- function(d) Filter(function(s) s$statut == "fait", seances_labo(d))
derniere_seance <- function(d) {
  faites <- seances_faites(d)
  faites[[length(faites)]]
}
prochaine_seance <- function(d) Filter(function(s) s$statut != "fait", seances_labo(d))[[1]]
# Séances dont le chapitre de cours est rédigé (champ cours de seances.yml).
seances_redigees <- function(d) Filter(function(s) !is.null(s$cours), seances_labo(d))
seance_numero <- function(d, numero) Filter(function(s) s$numero == numero, seances_labo(d))[[1]]

# Niveau de chaque concept : le plus haut atteint.
niveaux_concepts <- function(cc) {
  ifelse(cc$maitrise_le != "", "maîtrisé",
    ifelse(cc$pratique_le != "", "pratiqué", ifelse(cc$vu_le != "", "vu", "non vu"))
  )
}
semaine_des_concepts <- function(d) {
  vapply(as.integer(sub("^J", "", d$concepts$etape)), function(n) as.integer(seance_numero(d, n)$semaine), integer(1))
}

heures_faites <- function(d) {
  faites <- Filter(function(s) !is.null(s$duree), seances_faites(d))
  sum(vapply(faites, function(s) mesure(d, s$duree)$valeur, numeric(1)))
}

# ── Petits éléments ──────────────────────────────────────────────────────────

# En français, zéro et un sont au singulier.
pluriel <- function(n, singulier, forme_plurielle = paste0(singulier, "s")) {
  if (n <= 1) singulier else forme_plurielle
}

badge <- function(statut) sprintf("[%s]{.badge-etat .%s}", statut, CLASSES_ETAT[[statut]])

sans_guillemets <- function(x) gsub('"', "", x, fixed = TRUE)

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

# Source d'un résultat de séance, avec un lien vers la partie du cours citée.
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

# Source d'un indicateur du tableau de bord : le fichier de données, sur le dépôt.
source_fichier <- function(fichier) sprintf("[Source : [%s](%s%s)]{.source}", fichier, URL_DEPOT, fichier)

# ── Composants du tableau de bord ────────────────────────────────────────────

barre_progression <- function(libelle, valeur, total) {
  part <- if (total > 0) 100 * valeur / total else 0
  sprintf(
    '[]{.progression role="progressbar" aria-label="%s" aria-valuemin="0" aria-valuemax="%d" aria-valuenow="%d" style="--part: %s%%"}',
    libelle, as.integer(total), as.integer(valeur), format(round(part, 1), nsmall = 1)
  )
}

# Barre empilée des niveaux de compétence : maîtrisé, pratiqué, vu, non vu.
barre_niveaux <- function(niveaux) {
  total <- length(niveaux)
  segments <- c("maîtrisé" = "niveau-maitrise", "pratiqué" = "niveau-pratique", "vu" = "niveau-vu")
  morceaux <- vapply(names(segments), function(n) {
    k <- sum(niveaux == n)
    if (k == 0) return("")
    sprintf('[]{.segment .%s style="--part: %s%%"}', segments[[n]], format(round(100 * k / total, 1), nsmall = 1))
  }, character(1))
  vus <- sum(niveaux != "non vu")
  etiquette <- sprintf(
    "%d %s sur %d, dont %d %s et %d %s", vus, pluriel(vus, "vu"), total,
    sum(niveaux %in% c("pratiqué", "maîtrisé")), pluriel(sum(niveaux %in% c("pratiqué", "maîtrisé")), "pratiqué"),
    sum(niveaux == "maîtrisé"), pluriel(sum(niveaux == "maîtrisé"), "maîtrisé")
  )
  sprintf('[%s]{.barre-niveaux role="img" aria-label="%s"}', paste(morceaux, collapse = ""), etiquette)
}

legende_niveaux <- function() {
  items <- vapply(c("vu", "pratiqué", "maîtrisé"), function(n) {
    sprintf("[[]{.pastille .%s} %s]{.legende-item}", CLASSES_ETAT[[n]], n)
  }, character(1))
  paste0("[", paste(items, collapse = " "), "]{.legende}")
}

tuile <- function(libelle, valeur, total = NULL, detail = NULL, barre = NULL, source) {
  paste0(
    "::: {.indicateur}\n\n",
    "[", libelle, "]{.indicateur-libelle}\n\n",
    "[", valeur, "]{.indicateur-valeur}",
    if (!is.null(total)) paste0(" [sur ", total, "]{.indicateur-total}") else "", "\n\n",
    if (!is.null(barre)) paste0(barre, "\n\n") else "",
    if (!is.null(detail)) paste0("[", detail, "]{.indicateur-detail}\n\n") else "",
    source, "\n\n",
    ":::\n\n"
  )
}

indicateurs <- function(d) {
  labo <- seances_labo(d)
  faites <- length(seances_faites(d))
  prochaine <- prochaine_seance(d)
  jalons <- Filter(function(s) !is.null(s$jalon), labo)
  atteints <- sum(vapply(jalons, function(s) s$statut == "fait", logical(1)))
  restants <- Filter(function(s) s$statut != "fait", jalons)
  niveaux <- niveaux_concepts(d$concepts)
  vus <- sum(niveaux != "non vu")
  pratiques <- sum(niveaux %in% c("pratiqué", "maîtrisé"))
  maitrises <- sum(niveaux == "maîtrisé")
  paste0(
    "::: {.indicateurs}\n\n",
    tuile(
      "Séances faites", faites, length(labo),
      sprintf("prochaine : séance %d, %s", as.integer(prochaine$numero), prochaine$statut),
      barre_progression("Séances faites", faites, length(labo)), source_fichier("data/seances.yml")
    ),
    tuile(
      "Jalons atteints", atteints, length(jalons),
      if (length(restants) > 0) {
        sprintf("prochain : %s, à la séance %d", restants[[1]]$jalon$id, as.integer(restants[[1]]$numero))
      },
      barre_progression("Jalons atteints", atteints, length(jalons)), source_fichier("data/seances.yml")
    ),
    tuile(
      "Concepts vus", vus, nrow(d$concepts),
      sprintf("dont %d %s et %d %s", pratiques, pluriel(pratiques, "pratiqué"), maitrises, pluriel(maitrises, "maîtrisé")),
      barre_niveaux(niveaux), source_fichier("data/concepts.csv")
    ),
    tuile(
      "Temps de travail", paste0(format_nombre(heures_faites(d)), ESPACE_INSECABLE, "h"), NULL,
      sprintf("en %d %s", faites, pluriel(faites, "séance")), NULL, source_fichier("data/mesures.yml")
    ),
    ":::\n\n"
  )
}

# Parcours : les séances du plan, par semaine, avec les jalons.
point_parcours <- function(s) {
  etat <- s$statut
  aide <- sans_guillemets(sprintf("Séance %d : %s (%s)", as.integer(s$numero), titre_complet(s), etat))
  point <- sprintf(
    '[%d[ : %s]{.visually-hidden}]{.point .%s title="%s"}',
    as.integer(s$numero), etat, CLASSES_ETAT[[etat]], aide
  )
  if (!is.null(s$lien)) point <- sprintf("[%s](%s){.lien-point}", point, s$lien)
  jalon <- if (!is.null(s$jalon)) {
    sprintf(' [%s]{.jalon title="%s"}', s$jalon$id, sans_guillemets(paste0("Jalon ", s$jalon$id, " : ", s$jalon$critere)))
  } else ""
  paste0(point, jalon)
}

parcours <- function(d) {
  labo <- seances_labo(d)
  semaines <- sort(unique(vapply(labo, function(s) as.integer(s$semaine), integer(1))))
  lignes <- vapply(semaines, function(w) {
    ss <- Filter(function(s) s$semaine == w, labo)
    paste0(
      "::: {.parcours-semaine role=\"listitem\"}\n\n",
      "[Semaine ", w, "]{.parcours-libelle} ",
      paste(vapply(ss, point_parcours, character(1)), collapse = " "), "\n\n:::\n\n"
    )
  }, character(1))
  legende <- paste0(
    "[[[]{.pastille .etat-fait} fait]{.legende-item} [[]{.pastille .etat-a-planifier} à planifier]{.legende-item} ",
    "[[]{.pastille .etat-prevu} prévu]{.legende-item} [[L]{.jalon} jalon]{.legende-item}]{.legende}"
  )
  paste0(
    "::: {.carte .bloc .bloc-parcours}\n\n### Où j'en suis\n\n",
    "::: {.parcours-corps}\n\n",
    "::: {.parcours-labo}\n\n[Séances]{.sous-libelle}\n\n",
    "::: {.parcours role=\"list\"}\n\n", paste(lignes, collapse = ""), ":::\n\n",
    legende, "\n\n:::\n\n",
    avancement_cours(d),
    ":::\n\n:::\n\n"
  )
}

# Avancement du cours, qui s'écrit séance après séance.
avancement_cours <- function(d) {
  total <- length(seances_labo(d))
  redigees <- seances_redigees(d)
  n <- length(redigees)
  suivante <- Filter(function(s) is.null(s$cours), seances_labo(d))
  chapitres <- vapply(redigees, function(s) {
    sprintf("[Séance %d : %s](%s)", as.integer(s$numero), s$titre, s$cours)
  }, character(1))
  paste0(
    "::: {.cours-avancement}\n\n[Cours]{.sous-libelle}\n\n",
    "[", n, "]{.indicateur-valeur} [", pluriel(n, "séance rédigée", "séances rédigées"), " sur ", total, "]{.indicateur-total}\n\n",
    barre_progression("Séances du cours rédigées", n, total), "\n\n",
    if (n > 0) paste0(liste_md(chapitres), "\n\n") else "",
    if (length(suivante) > 0) {
      sprintf("[Prochain chapitre : séance %d, %s]{.indicateur-detail}\n\n", as.integer(suivante[[1]]$numero), titre_complet(suivante[[1]]))
    } else "",
    "[Plan complet du cours](/cours/index.qmd)\n\n",
    ":::\n\n"
  )
}

resume_derniere <- function(d) {
  s <- derniere_seance(d)
  paste0(
    "::: {.carte .bloc}\n\n### Dernière séance\n\n",
    "[", surtitre_seance(s), " · ", duree_texte(s, d), "]{.carte-surtitre}\n\n",
    "#### ", titre_lien(s), " {.carte-titre}\n\n",
    if (!is.null(s$journal$fait)) paste0(remplacer_references(s$journal$fait, d), "\n\n") else "",
    sprintf("[Voir la séance](%s) · [Lire le cours](%s)\n\n", s$lien, s$cours),
    ":::\n\n"
  )
}

resume_prochaine <- function(d) {
  s <- prochaine_seance(d)
  paste0(
    "::: {.carte .bloc}\n\n### Prochaine étape\n\n",
    "[", surtitre_seance(s), "]{.carte-surtitre} ", badge(s$statut), "\n\n",
    "#### ", titre_lien(s), " {.carte-titre}\n\n",
    if (!is.null(s$objectif)) paste0(remplacer_references(s$objectif, d), "\n\n") else "",
    "Livrables\n", definition_liste(livrables_de(s, d)), "\n\n",
    ":::\n\n"
  )
}

point_md <- function(p) {
  texte <- paste0("**", p$intitule, "** : ", p$detail)
  if (p$detail != p$statut) texte <- paste(texte, badge(p$statut))
  texte
}

bloc_points <- function(d) {
  s <- derniere_seance(d)
  points <- Filter(function(p) p$statut == "en attente", s$points_en_attente)
  paste0(
    "::: {.carte .bloc}\n\n### Points en attente\n\n",
    liste_md(vapply(points, point_md, character(1))), "\n\n",
    sprintf("[Clôture de la séance %d : vérifications à cocher](%s#cloture)\n\n", as.integer(s$numero), s$lien),
    ":::\n\n"
  )
}

competences_par_semaine <- function(d) {
  niveaux <- niveaux_concepts(d$concepts)
  semaines <- semaine_des_concepts(d)
  lignes <- vapply(sort(unique(semaines)), function(w) {
    nv <- niveaux[semaines == w]
    vus <- sum(nv != "non vu")
    paste0(
      "::: {.niveaux-ligne}\n\n",
      "[Semaine ", w, "]{.niveaux-libelle} ", barre_niveaux(nv),
      " [", vus, " ", pluriel(vus, "vu"), " sur ", length(nv), "]{.niveaux-compte}\n\n:::\n\n"
    )
  }, character(1))
  paste0(
    "::: {.carte .bloc}\n\n### Compétences, par semaine du plan\n\n",
    paste(lignes, collapse = ""), legende_niveaux(), "\n\n",
    source_fichier("data/concepts.csv"), "\n\n",
    ":::\n\n"
  )
}

# Heures par semaine : affichées dès qu'il y a au moins deux semaines de travail.
heures_par_semaine <- function(d) {
  faites <- Filter(function(s) !is.null(s$duree) && !is.null(s$date), seances_faites(d))
  if (length(faites) == 0) return("")
  lundi <- vapply(faites, function(s) {
    j <- as.Date(as.character(s$date))
    format(j - (as.integer(format(j, "%u")) - 1))
  }, character(1))
  heures <- tapply(vapply(faites, function(s) mesure(d, s$duree)$valeur, numeric(1)), lundi, sum)
  if (length(heures) < 2) return("")
  maxi <- max(heures)
  lignes <- vapply(names(heures), function(l) {
    paste0(
      "::: {.niveaux-ligne}\n\n[Semaine du ", date_longue(l), "]{.niveaux-libelle} ",
      sprintf('[[]{.segment .niveau-vu style="--part: %s%%"}]{.barre-niveaux}', format(round(100 * heures[[l]] / maxi, 1), nsmall = 1)),
      " [", format_nombre(heures[[l]]), ESPACE_INSECABLE, "h]{.niveaux-compte}\n\n:::\n\n"
    )
  }, character(1))
  paste0(
    "::: {.carte .bloc}\n\n### Heures par semaine\n\n", paste(lignes, collapse = ""),
    source_fichier("data/mesures.yml"), "\n\n:::\n\n"
  )
}

vue_ensemble <- function(d) {
  paste0(
    indicateurs(d),
    parcours(d),
    "::: {.colonnes-accueil}\n\n", resume_derniere(d), resume_prochaine(d), ":::\n\n",
    "::: {.colonnes-accueil}\n\n", bloc_points(d), competences_par_semaine(d), ":::\n\n",
    heures_par_semaine(d)
  )
}

# ── Onglets du tableau de bord ───────────────────────────────────────────────

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

onglet_laboratoire <- function(d) {
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
  paste0(
    "::: {.onglet-etroit}\n\n", paste(par_semaine, collapse = ""),
    source_fichier("data/seances.yml"), "\n\n:::\n\n"
  )
}

onglet_competences <- function(d) {
  cc <- d$concepts
  niveaux <- niveaux_concepts(cc)
  semaines <- semaine_des_concepts(d)
  depuis <- ifelse(niveaux == "maîtrisé", cc$maitrise_le, ifelse(niveaux == "pratiqué", cc$pratique_le, cc$vu_le))
  tableaux <- vapply(sort(unique(semaines)), function(w) {
    i <- which(semaines == w)
    lignes <- vapply(i, function(k) {
      niveau <- badge(niveaux[[k]])
      if (nzchar(depuis[[k]])) niveau <- paste0(niveau, " [depuis le ", date_longue(depuis[[k]]), "]{.niveau-date}")
      sprintf("| %s | %s | %s |", cc$concept[[k]], sub("^J", "", cc$etape[[k]]), niveau)
    }, character(1))
    paste0(
      "### Semaine ", w, "\n\n",
      "| Concept | Séance | Niveau |\n|:---|---:|:---|\n",
      paste(lignes, collapse = "\n"), "\n\n"
    )
  }, character(1))
  vus <- sum(niveaux != "non vu")
  paste0(
    "::: {.onglet-etroit}\n\n",
    "[", vus, " ", pluriel(vus, "concept vu", "concepts vus"), " sur ", nrow(cc), "]{.niveaux-total} ",
    barre_niveaux(niveaux), "\n\n", legende_niveaux(), "\n\n",
    paste(tableaux, collapse = ""),
    source_fichier("data/concepts.csv"), "\n\n:::\n\n"
  )
}

onglet_journal <- function(d) {
  entrees <- vapply(rev(seances_faites(d)), function(s) {
    j <- s$journal
    appris <- vapply(ou_sinon(j$appris, list()), remplacer_references, character(1), d = d, USE.NAMES = FALSE)
    paste0(
      "::: {.carte .entree-journal}\n\n",
      "[", date_longue(s$date), " · séance ", as.integer(s$numero), " · ", duree_texte(s, d), "]{.carte-surtitre}\n\n",
      "### ", titre_lien(s), " {.carte-titre}\n\n",
      "Fait\n:   ", remplacer_references(ou_sinon(j$fait, "à compléter"), d), "\n\n",
      "Appris\n", definition_liste(appris), "\n\n",
      "Suite\n:   ", remplacer_references(ou_sinon(j$suite, "à compléter"), d), "\n\n",
      ":::\n\n"
    )
  }, character(1))
  paste0(
    "::: {.onglet-etroit}\n\n", paste(entrees, collapse = ""),
    source_fichier("data/seances.yml"), "\n\n:::\n\n"
  )
}

page_tableau_de_bord <- function(d) {
  paste0(
    "::: {.panel-tabset}\n\n",
    "## Vue d'ensemble\n\n", vue_ensemble(d),
    "## Laboratoire\n\n", onglet_laboratoire(d),
    "## Compétences\n\n", onglet_competences(d),
    "## Journal\n\n", onglet_journal(d),
    ":::\n\n"
  )
}

# ── Séances ──────────────────────────────────────────────────────────────────

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

# Plan du cours : les séances du plan, par semaine ; les chapitres rédigés sont liés.
plan_du_cours <- function(d) {
  labo <- seances_labo(d)
  n <- length(seances_redigees(d))
  semaines <- sort(unique(vapply(labo, function(s) as.integer(s$semaine), integer(1))))
  blocs <- vapply(semaines, function(w) {
    etapes <- vapply(Filter(function(s) s$semaine == w, labo), function(s) {
      redige <- !is.null(s$cours)
      etat <- if (redige) "rédigé" else "à venir"
      titre <- if (redige) sprintf("[%s](%s)", titre_complet(s), s$cours) else titre_complet(s)
      paste0(
        "::: {.frise-etape .", CLASSES_ETAT[[etat]], " role=\"listitem\"}\n\n",
        "[Séance ", as.integer(s$numero), if (!is.null(s$date)) paste0(" · ", date_longue(s$date)) else "",
        "]{.frise-quand} ", badge(etat), "\n\n",
        "[", titre, "]{.frise-titre}\n\n:::\n\n"
      )
    }, character(1))
    paste0("### Semaine ", w, "\n\n::: {.frise role=\"list\"}\n\n", paste(etapes, collapse = ""), ":::\n\n")
  }, character(1))
  paste0(
    "::: {.onglet-etroit}\n\n",
    "Chaque séance du laboratoire ajoute un chapitre à ce cours, rédigé à partir de son ",
    "fichier de séance. Les séances à venir suivent le plan du laboratoire.\n\n",
    "[", n, " ", pluriel(n, "séance rédigée", "séances rédigées"), " sur ", length(labo), "]{.niveaux-total} ",
    barre_progression("Séances du cours rédigées", n, length(labo)), "\n\n",
    paste(blocs, collapse = ""),
    source_fichier("data/seances.yml"), "\n\n:::\n\n"
  )
}
