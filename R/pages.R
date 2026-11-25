# Rendu des pages : ces fonctions lisent les données (data/seances.yml,
# data/mesures.yml, data/concepts.csv) et produisent du Markdown Pandoc.
# Aucun nombre n'y est écrit à la main : chacun est lu ou calculé dans les
# données, et le tableau de bord indique de quel fichier il vient.

source(if (file.exists("R/valider.R")) "R/valider.R" else "../../R/valider.R", encoding = "UTF-8")
source(if (file.exists("R/calculs.R")) "R/calculs.R" else "../../R/calculs.R", encoding = "UTF-8")
# la veille : sa page, et ses derniers liens sur le tableau de bord
source(if (file.exists("R/veille.R")) "R/veille.R" else "../../R/veille.R", encoding = "UTF-8")

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

# Pastilles : une par unité comptée (séance, jalon, concept). `pleines` donne
# la classe de chaque pastille pleine ; les suivantes, jusqu'à `total`, sont vides.
# Le nombre est écrit à côté : sans `etiquette`, les pastilles sont décoratives.
pastilles <- function(pleines, total, etiquette = NULL) {
  pips <- c(sprintf("[]{.pip .%s}", pleines), rep("[]{.pip}", max(0, total - length(pleines))))
  acces <- if (is.null(etiquette)) 'aria-hidden="true"' else sprintf('role="img" aria-label="%s"', etiquette)
  sprintf("[%s]{.pips %s}", paste(pips, collapse = ""), acces)
}

# Pastilles des niveaux de compétence : maîtrisé, puis pratiqué, puis vu.
pastilles_niveaux <- function(niveaux) {
  pleines <- unlist(lapply(c("maîtrisé", "pratiqué", "vu"), function(n) rep(CLASSES_ETAT[[n]], sum(niveaux == n))))
  vus <- sum(niveaux != "non vu")
  pratiques <- sum(niveaux %in% c("pratiqué", "maîtrisé"))
  maitrises <- sum(niveaux == "maîtrisé")
  etiquette <- sprintf(
    "%d %s sur %d, dont %d %s et %d %s", vus, pluriel(vus, "vu"), length(niveaux),
    pratiques, pluriel(pratiques, "pratiqué"), maitrises, pluriel(maitrises, "maîtrisé")
  )
  pastilles(as.character(pleines), length(niveaux), etiquette)
}

# Barre d'une grandeur continue (des heures), en part du maximum.
barre <- function(part) {
  sprintf('[[]{.barre-pleine style="--part: %s%%"}]{.barre aria-hidden="true"}', format(round(part, 1), nsmall = 1))
}

legende_niveaux <- function() {
  items <- vapply(c("vu", "pratiqué", "maîtrisé"), function(n) {
    sprintf("[[]{.pastille .%s} %s]{.legende-item}", CLASSES_ETAT[[n]], n)
  }, character(1))
  paste0("[", paste(items, collapse = " "), "]{.legende}")
}

# Carte d'indicateur : un grand nombre, sa suite (« sur 15 », « h »), des
# pastilles, un détail et la source. `phare` met la carte en avant.
tuile <- function(libelle, valeur, suite = NULL, detail = NULL, pips = NULL, source, phare = FALSE) {
  paste0(
    "::: {.indicateur", if (phare) " .phare" else "", "}\n\n",
    "[", libelle, "]{.indicateur-libelle}\n\n",
    "[", valeur, "]{.indicateur-valeur}",
    if (!is.null(suite)) paste0(" [", suite, "]{.indicateur-total}") else "", "\n\n",
    if (!is.null(pips)) paste0(pips, "\n\n") else "",
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
      "Séances faites", faites, paste("sur", length(labo)),
      sprintf("prochaine : séance %d, %s", as.integer(prochaine$numero), prochaine$statut),
      pastilles(rep("plein", faites), length(labo)), source_fichier("data/seances.yml"),
      phare = TRUE
    ),
    tuile(
      "Jalons atteints", atteints, paste("sur", length(jalons)),
      if (length(restants) > 0) {
        sprintf("prochain : %s, à la séance %d", restants[[1]]$jalon$id, as.integer(restants[[1]]$numero))
      },
      pastilles(rep("plein", atteints), length(jalons)), source_fichier("data/seances.yml")
    ),
    tuile(
      "Concepts vus", vus, paste("sur", nrow(d$concepts)),
      sprintf("dont %d %s et %d %s", pratiques, pluriel(pratiques, "pratiqué"), maitrises, pluriel(maitrises, "maîtrisé")),
      pastilles_niveaux(niveaux), source_fichier("data/concepts.csv")
    ),
    tuile(
      "Temps de travail", format_nombre(heures_faites(d)), "h",
      sprintf("en %d %s", faites, pluriel(faites, "séance")), NULL, source_fichier("data/mesures.yml")
    ),
    ":::\n\n"
  )
}

# Escalier des séances : une marche par séance, de plus en plus haute, et un
# palier avec son drapeau à chaque jalon. Tout vient de data/seances.yml.
ICONE_DRAPEAU <- paste0(
  '<svg class="drapeau-icone" viewBox="0 0 24 40" aria-hidden="true" focusable="false">',
  '<path class="drapeau-mat" d="M19 39V3"/><path class="drapeau-fanion" d="M19 4H5l4 5.5L5 15h14z"/></svg>'
)

# Hauteur d'une marche, en part de la plus haute.
part_escalier <- function(rang, total) format(round(100 * rang / total, 2), nsmall = 2)

marche <- function(s, rang, total) {
  etat <- s$statut
  aide <- sans_guillemets(sprintf("Séance %d : %s (%s)", as.integer(s$numero), titre_complet(s), etat))
  contenu <- sprintf("[%d]{.marche-no}[ : %s, %s]{.visually-hidden}", as.integer(s$numero), titre_complet(s), etat)
  if (!is.null(s$lien)) contenu <- sprintf("[%s](%s){.marche-lien}", contenu, s$lien)
  sprintf(
    '::: {.marche .%s role="listitem" style="--part: %s%%" title="%s"}\n\n%s\n\n:::\n\n',
    CLASSES_ETAT[[etat]], part_escalier(rang, total), aide, contenu
  )
}

palier <- function(s, rang, total) {
  atteint <- s$statut == "fait"
  aide <- sans_guillemets(paste0("Jalon ", s$jalon$id, " : ", s$jalon$critere))
  sprintf(
    '::: {.marche .palier%s role="listitem" style="--part: %s%%" title="%s"}\n\n[%s[%s]{.palier-nom}[ : jalon%s, %s]{.visually-hidden}]{.drapeau}\n\n:::\n\n',
    if (atteint) " .jalon-atteint" else "", part_escalier(rang, total), aide,
    ICONE_DRAPEAU, s$jalon$id, if (atteint) " atteint" else "", s$jalon$critere
  )
}

escalier <- function(d) {
  labo <- seances_labo(d)
  total <- length(labo)
  marches <- unlist(lapply(seq_along(labo), function(i) {
    s <- labo[[i]]
    c(marche(s, i, total), if (!is.null(s$jalon)) palier(s, i, total))
  }))
  semaines <- vapply(labo, function(s) as.integer(s$semaine), integer(1))
  # largeur d'une semaine sous l'escalier : ses marches et ses paliers
  colonnes <- vapply(sort(unique(semaines)), function(w) {
    ss <- labo[semaines == w]
    length(ss) + sum(vapply(ss, function(s) !is.null(s$jalon), logical(1)))
  }, numeric(1))
  libelles <- sprintf("[Semaine%s%d]{.escalier-semaine}", ESPACE_INSECABLE, sort(unique(semaines)))
  legende <- paste0(
    "[[[]{.pastille .etat-fait} fait]{.legende-item} [[]{.pastille .etat-a-planifier} à planifier]{.legende-item} ",
    "[[]{.pastille .etat-prevu} prévu]{.legende-item} [[]{.pastille .palier} jalon]{.legende-item}]{.legende}"
  )
  paste0(
    "::: {.escalier}\n\n",
    sprintf(
      '::: {.escalier-marches role="list" aria-label="Les %d séances du laboratoire, une marche par séance" style="--colonnes: %d"}\n\n',
      total, length(marches)
    ),
    paste(marches, collapse = ""),
    ":::\n\n",
    sprintf(
      '::: {.escalier-semaines aria-hidden="true" style="grid-template-columns: %s"}\n\n',
      paste0(colonnes, "fr", collapse = " ")
    ),
    paste(libelles, collapse = " "), "\n\n:::\n\n",
    "::: {.escalier-pied}\n\n", legende, " ", source_fichier("data/seances.yml"), "\n\n:::\n\n",
    ":::\n\n"
  )
}

# Les jalons du plan, chacun avec son critère.
cartes_jalons <- function(d) {
  jalons <- Filter(function(s) !is.null(s$jalon), seances_labo(d))
  cartes <- vapply(jalons, function(s) {
    atteint <- s$statut == "fait"
    sprintf(
      "::: {.jalon-carte%s}\n\n[%s]{.jalon-nom} [%s]{.jalon-critere}%s\n\n:::\n\n",
      if (atteint) " .jalon-atteint" else "", s$jalon$id, s$jalon$critere,
      if (atteint) paste0(" ", badge("fait")) else ""
    )
  }, character(1))
  paste0("::: {.jalons}\n\n", paste(cartes, collapse = ""), ":::\n\n")
}

# Étiquette en tête de carte, à la couleur d'un état.
etiquette <- function(texte, etat = NULL) {
  sprintf("[%s]{.etiquette%s}", texte, if (is.null(etat)) "" else paste0(" .", CLASSES_ETAT[[etat]]))
}

# Titre d'une section de la vue d'ensemble, avec un aparté facultatif à droite.
# Le titre n'a pas de classe : Pandoc reporte sur le bloc entier les classes
# d'un titre placé en tête de bloc. Les styles ciblent « .section-tete > h2 ».
titre_section <- function(titre, apart = NULL) {
  paste0(
    "::: {.section-tete}\n\n## ", titre, "\n\n",
    if (!is.null(apart)) paste0("[", apart, "]{.section-apart}\n\n") else "",
    ":::\n\n"
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
    "::: {.carte .carte-cours}\n\n### Cours\n\n",
    "[", n, "]{.indicateur-valeur} [", pluriel(n, "séance rédigée", "séances rédigées"), " sur ", total, "]{.indicateur-total}\n\n",
    pastilles(rep("plein", n), total), "\n\n",
    if (n > 0) paste0(liste_md(chapitres), "\n\n") else "",
    if (length(suivante) > 0) {
      sprintf("[Prochain chapitre : séance %d, %s]{.indicateur-detail}\n\n", as.integer(suivante[[1]]$numero), titre_complet(suivante[[1]]))
    } else "",
    "::: {.boutons}\n\n[Plan complet du cours](/cours/index.qmd){.bouton .bouton-second}\n\n:::\n\n",
    ":::\n\n"
  )
}

resume_derniere <- function(d) {
  s <- derniere_seance(d)
  paste0(
    "::: {.carte .carte-derniere}\n\n",
    etiquette("Dernière séance", s$statut), "\n\n",
    "### ", titre_lien(s), "\n\n",
    "[", surtitre_seance(s), " · ", duree_texte(s, d), "]{.carte-surtitre}\n\n",
    if (!is.null(s$journal$fait)) paste0(remplacer_references(s$journal$fait, d), "\n\n") else "",
    sprintf("::: {.boutons}\n\n[Voir la séance](%s){.bouton} [Lire le cours](%s){.bouton .bouton-second}\n\n:::\n\n", s$lien, s$cours),
    ":::\n\n"
  )
}

resume_prochaine <- function(d) {
  s <- prochaine_seance(d)
  paste0(
    "::: {.carte .carte-prochaine}\n\n",
    etiquette("Prochaine étape", s$statut), "\n\n",
    "### ", titre_lien(s), "\n\n",
    "[", surtitre_seance(s), "]{.carte-surtitre}\n\n",
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
    "::: {.carte .carte-points}\n\n### Points en attente\n\n",
    liste_md(vapply(points, point_md, character(1))), "\n\n",
    sprintf("[Clôture de la séance %d : vérifications à cocher](%s#cloture)\n\n", as.integer(s$numero), s$lien),
    ":::\n\n"
  )
}

# Ligne « libellé, pastilles ou barre, compte » (compétences, heures).
rang <- function(libelle, dessin, compte) {
  paste0("::: {.rang}\n\n[", libelle, "]{.rang-nom} ", dessin, " [", compte, "]{.rang-val}\n\n:::\n\n")
}

competences_par_semaine <- function(d) {
  niveaux <- niveaux_concepts(d$concepts)
  semaines <- semaine_des_concepts(d)
  lignes <- vapply(sort(unique(semaines)), function(w) {
    nv <- niveaux[semaines == w]
    vus <- sum(nv != "non vu")
    rang(
      paste("Semaine", w), pastilles_niveaux(nv),
      paste0("[", vus, "]{.rang-nombre} ", pluriel(vus, "vu"), " sur ", length(nv))
    )
  }, character(1))
  vus <- sum(niveaux != "non vu")
  paste0(
    titre_section(
      "Compétences, par semaine du plan",
      paste(vus, pluriel(vus, "concept vu", "concepts vus"), "sur", length(niveaux))
    ),
    "::: {.rangs}\n\n", paste(lignes, collapse = ""), ":::\n\n",
    "::: {.section-pied}\n\n", legende_niveaux(), " ", source_fichier("data/concepts.csv"), "\n\n:::\n\n"
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
    rang(
      paste("Semaine du", date_longue(l)), barre(100 * heures[[l]] / maxi),
      paste0("[", format_nombre(heures[[l]]), "]{.rang-nombre}", ESPACE_INSECABLE, "h")
    )
  }, character(1))
  paste0(
    titre_section("Heures par semaine"),
    "::: {.rangs}\n\n", paste(lignes, collapse = ""), ":::\n\n",
    "::: {.section-pied}\n\n", source_fichier("data/mesures.yml"), "\n\n:::\n\n"
  )
}

vue_ensemble <- function(d) {
  paste0(
    cartes_jalons(d),
    indicateurs(d),
    titre_section("Où j'en suis"),
    "::: {.duo}\n\n", resume_derniere(d), resume_prochaine(d), ":::\n\n",
    "::: {.duo}\n\n", avancement_cours(d), bloc_points(d), ":::\n\n",
    competences_par_semaine(d),
    heures_par_semaine(d),
    apercu_veille(d)
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
      "## Semaine ", w, "\n\n::: {.frise role=\"list\"}\n\n",
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
      "## Semaine ", w, "\n\n",
      "| Concept | Séance | Niveau |\n|:---|---:|:---|\n",
      paste(lignes, collapse = "\n"), "\n\n"
    )
  }, character(1))
  vus <- sum(niveaux != "non vu")
  paste0(
    "::: {.onglet-etroit}\n\n",
    "[", vus, " ", pluriel(vus, "concept vu", "concepts vus"), " sur ", nrow(cc), "]{.niveaux-total}\n\n",
    pastilles_niveaux(niveaux), "\n\n", legende_niveaux(), "\n\n",
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
      "## ", titre_lien(s), "\n\n",
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

# Les quatre vues du tableau de bord. Les boutons sont dans l'en-tête de la
# page, à côté de l'escalier ; Bootstrap, que Quarto charge déjà, affiche le
# volet du bouton choisi (data-bs-toggle="tab").
ONGLETS <- c(
  vue = "Vue d’ensemble", laboratoire = "Laboratoire", competences = "Compétences", journal = "Journal"
)

boutons_onglets <- function() {
  boutons <- vapply(seq_along(ONGLETS), function(i) {
    id <- names(ONGLETS)[[i]]
    sprintf(
      paste0(
        '<li class="nav-item" role="presentation"><button type="button" class="nav-link%s" id="onglet-%s" ',
        'data-bs-toggle="tab" data-bs-target="#%s" role="tab" aria-controls="%s" aria-selected="%s"%s>%s</button></li>'
      ),
      if (i == 1) " active" else "", id, id, id,
      if (i == 1) "true" else "false", if (i == 1) "" else ' tabindex="-1"', ONGLETS[[i]]
    )
  }, character(1))
  paste0(
    "```{=html}\n<ul class=\"nav onglets\" role=\"tablist\" aria-label=\"Vues du tableau de bord\">\n",
    paste(boutons, collapse = "\n"), "\n</ul>\n```\n\n"
  )
}

volet <- function(id, contenu, actif = FALSE) {
  sprintf(
    '::: {#%s .tab-pane%s role="tabpanel" aria-labelledby="onglet-%s" tabindex="0"}\n\n%s:::\n\n',
    id, if (actif) " .active" else "", id, contenu
  )
}

# En-tête de l'accueil : le titre, l'introduction et les onglets à gauche,
# l'escalier des séances à droite.
entete_accueil <- function(d, titre, intro) {
  labo <- seances_labo(d)
  jalons <- sum(vapply(labo, function(s) !is.null(s$jalon), logical(1)))
  paste0(
    "::: {.hero}\n\n::: {.hero-texte}\n\n",
    sprintf(
      "[Laboratoire · %d %s · %d %s]{.hero-pastille}\n\n",
      length(labo), pluriel(length(labo), "séance"), jalons, pluriel(jalons, "jalon")
    ),
    "# ", titre, " {.hero-titre}\n\n",
    if (!is.null(intro)) paste0("[", intro, "]{.intro}\n\n") else "",
    boutons_onglets(),
    ":::\n\n",
    escalier(d),
    ":::\n\n"
  )
}

page_tableau_de_bord <- function(d, titre = "Carnet de bord", intro = NULL) {
  paste0(
    entete_accueil(d, titre, intro),
    "::: {.tab-content}\n\n",
    volet("vue", vue_ensemble(d), actif = TRUE),
    volet("laboratoire", onglet_laboratoire(d)),
    volet("competences", onglet_competences(d)),
    volet("journal", onglet_journal(d)),
    ":::\n\n"
  )
}

# ── Séances ──────────────────────────────────────────────────────────────────

# Date, projet, statut, durée et livrables d'une séance.
corps_seance <- function(s, d, niveau = 3) {
  paste0(
    "[", surtitre_seance(s), "]{.carte-surtitre}\n\n",
    strrep("#", niveau), " ", titre_lien(s), "\n\n",
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
    paste0("## Semaine ", w, "\n\n::: {.frise role=\"list\"}\n\n", paste(etapes, collapse = ""), ":::\n\n")
  }, character(1))
  paste0(
    "::: {.onglet-etroit}\n\n",
    "Chaque séance du laboratoire ajoute un chapitre à ce cours, rédigé à partir de son ",
    "fichier de séance. Les séances à venir suivent le plan du laboratoire.\n\n",
    "[", n, " ", pluriel(n, "séance rédigée", "séances rédigées"), " sur ", length(labo), "]{.niveaux-total}\n\n",
    pastilles(rep("plein", n), length(labo)), "\n\n",
    paste(blocs, collapse = ""),
    source_fichier("data/seances.yml"), "\n\n:::\n\n"
  )
}
