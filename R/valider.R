source(if (file.exists("R/lire.R")) "R/lire.R" else "../../R/lire.R")

# ── Règles du carnet ─────────────────────────────────────────────────────────

STATUTS_LABO <- c("fait", "à planifier", "prévu")
STATUTS_POINTS <- c("en attente", "fait")

# Le carnet ne parle que du laboratoire.
MESSAGE_CONFIDENTIALITE <- paste(
  "Confidentialité : seul le laboratoire figure dans le carnet,",
  "et aucun texte ne mentionne d'autre projet"
)

MOTIF_ID <- "^[a-z0-9]+(-[a-z0-9]+)*$"

ou_sinon <- function(a, b) if (is.null(a)) b else a

arreter_regle <- function(fichier, ou, regle) {
  stop(sprintf("%s, %s : %s", fichier, ou, regle), call. = FALSE)
}

# ── Chiffres et références au registre ───────────────────────────────────────

# Identifiants de mesures cités dans un texte sous la forme {identifiant}.
references <- function(texte) {
  trouves <- regmatches(texte, gregexpr("\\{[a-z0-9-]+\\}", texte))[[1]]
  gsub("[{}]", "", trouves)
}

# Vrai si le texte contient un chiffre qui ne vient pas du registre : on retire
# le `code`, les numéros (n° 273) et les références {identifiant}.
chiffre_hors_registre <- function(texte) {
  reste <- gsub("`[^`]*`", "", texte)
  reste <- gsub("\\{[a-z0-9-]+\\}", "", reste)
  reste <- gsub("n°\\s*[0-9]+", "", reste)
  grepl("[0-9]", reste)
}

# Tous les textes affichés d'une séance du laboratoire.
textes_libres <- function(s) {
  c(
    s$titre, s$sous_titre, s$objectif, unlist(s$livrables),
    unlist(lapply(s$incidents, function(i) c(i$incident, i$cause, i$correction))),
    vapply(s$commits, function(co) ou_sinon(co$message, ""), character(1)),
    unlist(s$a_cocher),
    unlist(lapply(s$points_en_attente, function(p) c(p$intitule, p$detail))),
    s$jalon$critere,
    s$journal$fait, unlist(s$journal$appris), s$journal$suite
  )
}

# ── Registre des mesures ─────────────────────────────────────────────────────

valider_source <- function(src, fichier, ou) {
  ok <- is.list(src) && is.numeric(src$seance) && length(src$seance) == 1 &&
    is.character(src$partie) && length(src$partie) == 1 && nzchar(src$partie)
  if (!ok) {
    arreter_regle(fichier, ou, "source précise manquante (séance et partie du cours)")
  }
}

valider_registre <- function(d) {
  f <- "mesures.yml"
  ids <- character()
  for (m in d$mesures) {
    ou <- sprintf("mesure '%s'", ou_sinon(m$id, "?"))
    if (!is.character(m$id) || !grepl(MOTIF_ID, m$id)) arreter_regle(f, ou, "identifiant invalide")
    if (m$id %in% ids) arreter_regle(f, ou, "identifiant en double")
    ids <- c(ids, m$id)
    if (!is.character(m$libelle) || !nzchar(m$libelle)) arreter_regle(f, ou, "libellé manquant")
    if (!is.numeric(m$valeur) || !(length(m$valeur) %in% 1:2)) {
      arreter_regle(f, ou, "valeur numérique ou intervalle [basse, haute] attendu")
    }
    if (length(m$valeur) == 2 && m$valeur[[1]] > m$valeur[[2]]) {
      arreter_regle(f, ou, "intervalle inversé")
    }
    if (!is.character(m$unite)) arreter_regle(f, ou, "unité manquante")
    valider_source(m$source, f, ou)
  }

  for (fo in d$formules) {
    ou <- sprintf("formule '%s'", ou_sinon(fo$id, "?"))
    if (!is.character(fo$texte) || !nzchar(fo$texte)) arreter_regle(f, ou, "texte manquant")
    valider_source(fo$source, f, ou)
  }

  for (t in d$tableaux) {
    ou <- sprintf("tableau '%s'", ou_sinon(t$id, "?"))
    valider_source(t$source, f, ou)
    n <- length(t$colonnes)
    if (n == 0) arreter_regle(f, ou, "colonnes manquantes")
    for (ligne in t$lignes) {
      if (length(ligne) != n) arreter_regle(f, ou, "une ligne n'a pas autant de cellules que de colonnes")
    }
    inconnues <- setdiff(references(ou_sinon(t$note, "")), ids)
    if (length(inconnues) > 0) arreter_regle(f, ou, sprintf("mesure inconnue : {%s}", inconnues[[1]]))
  }

  ids
}

# ── Registre des séances ─────────────────────────────────────────────────────

est_date_valide <- function(x) {
  x <- as.character(x)
  length(x) == 1 && grepl("^\\d{4}-\\d{2}-\\d{2}$", x) && !is.na(as.Date(x, format = "%Y-%m-%d"))
}

est_entier <- function(x) is.numeric(x) && length(x) == 1 && x == round(x) && x > 0

valider_seances <- function(seances, mesures) {
  f <- "seances.yml"
  ids_mesures <- vapply(mesures, function(m) m$id, character(1))
  unites <- setNames(vapply(mesures, function(m) m$unite, character(1)), ids_mesures)
  ids <- character()
  numeros <- integer()

  for (s in seances) {
    ou <- sprintf("séance '%s'", ou_sinon(s$id, "?"))
    if (!is.character(s$id) || !grepl(MOTIF_ID, s$id)) arreter_regle(f, ou, "identifiant invalide")
    if (s$id %in% ids) arreter_regle(f, ou, "identifiant en double")
    ids <- c(ids, s$id)

    if (!identical(s$projet, "labo")) arreter_regle(f, ou, MESSAGE_CONFIDENTIALITE)
    if (!(identical(length(s$statut), 1L) && s$statut %in% STATUTS_LABO)) {
      arreter_regle(f, ou, "statut hors liste autorisée")
    }
    if (!est_entier(s$numero) || !est_entier(s$semaine)) {
      arreter_regle(f, ou, "numéro et semaine : entiers positifs attendus")
    }
    if (s$numero %in% numeros) arreter_regle(f, ou, "numéro de séance en double")
    numeros <- c(numeros, s$numero)
    if (!is.character(s$titre) || !nzchar(s$titre)) arreter_regle(f, ou, "titre manquant")
    if (!is.null(s$date) && !est_date_valide(s$date)) arreter_regle(f, ou, "date invalide")
    if (s$statut == "fait" && (is.null(s$date) || is.null(s$duree))) {
      arreter_regle(f, ou, "une séance faite a une date et une durée")
    }
    if (!is.null(s$duree) && !(s$duree %in% ids_mesures)) {
      arreter_regle(f, ou, "durée : identifiant absent de mesures.yml")
    }
    if (!is.null(s$duree) && !identical(unites[[s$duree]], "h")) {
      arreter_regle(f, ou, "durée : la mesure citée doit être en heures (h)")
    }
    for (i in s$incidents) {
      if (!est_entier(i$chapitre)) arreter_regle(f, ou, "incident sans chapitre du cours")
    }
    for (p in s$points_en_attente) {
      if (!(identical(length(p$statut), 1L) && p$statut %in% STATUTS_POINTS)) {
        arreter_regle(f, ou, "point en attente : statut hors liste autorisée")
      }
    }

    textes <- textes_libres(s)
    if (any(grepl("intern", textes, ignore.case = TRUE))) {
      arreter_regle(f, ou, MESSAGE_CONFIDENTIALITE)
    }
    for (t in textes) {
      if (chiffre_hors_registre(t)) {
        arreter_regle(f, ou, sprintf("chiffre hors registre dans « %s » : citer une mesure par {identifiant}", t))
      }
      inconnues <- setdiff(references(t), ids_mesures)
      if (length(inconnues) > 0) arreter_regle(f, ou, sprintf("mesure inconnue : {%s}", inconnues[[1]]))
    }
  }
}

# ── Chapitres du cours (dossier cours/) ──────────────────────────────────────

# Chapitre de la séance n, tel que seances.yml le cite. Deux chiffres : la barre
# latérale range les chapitres par nom de fichier, donc la séance 10 après la 9.
chemin_chapitre <- function(numero) sprintf("/cours/seance-%02d-cours.md", as.integer(numero))

# Le plan et l'avancement du cours lisent le champ `cours` de seances.yml ; la
# barre latérale lit le dossier cours/. Les deux doivent dire la même chose.
valider_cours <- function(seances, dossier_cours) {
  f <- "seances.yml"
  declares <- character()
  for (s in seances) {
    if (is.null(s$cours)) next
    ou <- sprintf("séance '%s'", ou_sinon(s$id, "?"))
    attendu <- chemin_chapitre(s$numero)
    if (!identical(s$cours, attendu)) {
      arreter_regle(f, ou, sprintf("le chapitre de la séance %d doit être %s", as.integer(s$numero), attendu))
    }
    if (!file.exists(file.path(dossier_cours, basename(attendu)))) {
      arreter_regle(f, ou, sprintf("chapitre introuvable : %s", sub("^/", "", attendu)))
    }
    declares <- c(declares, basename(attendu))
  }
  # Tout fichier du dossier, sauf le plan, est un chapitre.
  chapitres <- setdiff(list.files(dossier_cours, "\\.(md|qmd)$"), c("index.qmd", "index.md"))
  oublies <- setdiff(chapitres, declares)
  if (length(oublies) > 0) {
    arreter_regle(f, sprintf("chapitre 'cours/%s'", oublies[[1]]),
                  "non déclaré : renseigner le champ cours de sa séance")
  }
}

# ── Veille (veille.yml) ──────────────────────────────────────────────────────

TYPES_LIENS <- c(
  "article", "article scientifique", "documentation", "tutoriel", "cours",
  "outil", "dépôt", "vidéo", "podcast"
)
LANGUES_LIENS <- c("fr", "en")
COULEURS_THEMES <- c("bleu", "orange", "vert", "violet", "gris")
# Suffixes réservés aux réseaux privés : un lien public n'y mène jamais.
SUFFIXES_PRIVES <- c("local", "lan", "internal", "intranet", "corp", "home", "localhost")

# Hôte d'une adresse https://hôte/chemin, en minuscules.
hote_url <- function(url) tolower(sub("^https://([^/:?#]+).*$", "\\1", url))

# Vrai si l'adresse est en https et mène à un hôte public désigné par son nom :
# ni adresse IP, ni nom de réseau privé.
est_url_publique <- function(url) {
  if (!is.character(url) || length(url) != 1 || !grepl("^https://\\S+$", url, perl = TRUE)) return(FALSE)
  hote <- hote_url(url)
  grepl("^([a-z0-9-]+\\.)+(xn--[a-z0-9-]+|[a-z]{2,})$", hote) &&
    !(sub("^.*\\.", "", hote) %in% SUFFIXES_PRIVES)
}

# Deux adresses qui ne diffèrent que par l'ancre ou la barre finale sont le même lien.
cle_url <- function(url) tolower(sub("/+$", "", sub("#.*$", "", url)))

un_parmi <- function(x, autorises) identical(length(x), 1L) && x %in% autorises

valider_veille <- function(v) {
  f <- "veille.yml"
  ids <- character()
  for (t in v$themes) {
    ou <- sprintf("thème '%s'", ou_sinon(t$id, "?"))
    if (!is.character(t$id) || !grepl(MOTIF_ID, t$id)) arreter_regle(f, ou, "identifiant invalide")
    if (t$id %in% ids) arreter_regle(f, ou, "identifiant en double")
    ids <- c(ids, t$id)
    if (!is.character(t$titre) || !nzchar(t$titre)) arreter_regle(f, ou, "titre manquant")
    if (!is.null(t$couleur) && !un_parmi(t$couleur, COULEURS_THEMES)) {
      arreter_regle(f, ou, sprintf("couleur hors palette (%s)", paste(COULEURS_THEMES, collapse = ", ")))
    }
    if (any(grepl("intern", c(t$titre, t$description), ignore.case = TRUE))) {
      arreter_regle(f, ou, MESSAGE_CONFIDENTIALITE)
    }
  }

  vus <- character()
  for (l in v$liens) {
    ou <- sprintf("lien '%s'", ou_sinon(l$url, "?"))
    if (!est_url_publique(l$url)) arreter_regle(f, ou, "adresse https publique attendue")
    if (cle_url(l$url) %in% vus) arreter_regle(f, ou, "lien déjà présent")
    vus <- c(vus, cle_url(l$url))
    if (!is.character(l$titre) || !nzchar(l$titre)) arreter_regle(f, ou, "titre manquant")
    if (!un_parmi(l$theme, ids)) arreter_regle(f, ou, "thème inconnu")
    if (is.null(l$ajoute_le) || !est_date_valide(l$ajoute_le)) arreter_regle(f, ou, "date d'ajout invalide")
    if (!un_parmi(l$type, TYPES_LIENS)) {
      arreter_regle(f, ou, sprintf("type hors liste (%s)", paste(TYPES_LIENS, collapse = ", ")))
    }
    if (!un_parmi(l$langue, LANGUES_LIENS)) arreter_regle(f, ou, "langue : fr ou en")
    if (!is.character(l$resume) || !nzchar(l$resume)) arreter_regle(f, ou, "résumé manquant")
    if (any(grepl("intern", c(l$titre, l$resume, l$pourquoi, l$mots_cles), ignore.case = TRUE))) {
      arreter_regle(f, ou, MESSAGE_CONFIDENTIALITE)
    }
  }
}

# ── Suivi des concepts (concepts.csv) ───────────────────────────────────────

est_date_valide_ou_vide <- function(x) {
  ifelse(
    x == "",
    TRUE,
    grepl("^\\d{4}-\\d{2}-\\d{2}$", x) & !is.na(as.Date(x, format = "%Y-%m-%d"))
  )
}

valider_concepts <- function(concepts) {
  f <- "concepts.csv"
  for (colonne in c("vu_le", "pratique_le", "maitrise_le")) {
    invalides <- which(!est_date_valide_ou_vide(concepts[[colonne]]))
    if (length(invalides) > 0) {
      arreter_regle(f, sprintf("ligne %d", invalides[[1]] + 1L), sprintf("Date invalide dans '%s'", colonne))
    }
  }

  invalide_etape <- which(!(concepts$etape %in% paste0("J", 1:15)))
  if (length(invalide_etape) > 0) {
    arreter_regle(f, sprintf("ligne %d", invalide_etape[[1]] + 1L), "'etape' doit être entre J1 et J15")
  }

  for (i in seq_len(nrow(concepts))) {
    ou <- sprintf("ligne %d", i + 1L)
    vu <- concepts$vu_le[[i]]
    pratique <- concepts$pratique_le[[i]]
    maitrise <- concepts$maitrise_le[[i]]
    if (pratique != "" && vu == "") arreter_regle(f, ou, "Niveau 'pratique' interdit sans 'vu'")
    if (maitrise != "" && pratique == "") arreter_regle(f, ou, "Niveau 'maitrise' interdit sans 'pratique'")
    if (vu != "" && pratique != "" && as.Date(pratique) < as.Date(vu)) {
      arreter_regle(f, ou, "Dates non croissantes entre vu et pratique")
    }
    if (pratique != "" && maitrise != "" && as.Date(maitrise) < as.Date(pratique)) {
      arreter_regle(f, ou, "Dates non croissantes entre pratique et maitrise")
    }
  }
}

# ── Point d'entrée (appelé par la CI et à chaque rendu) ─────────────────────

valider_tout <- function(dossier = "data") {
  d <- lire_tout(dossier)
  valider_registre(d)
  valider_seances(d$seances, d$mesures)
  # le dossier cours/ est à côté du dossier des données
  valider_cours(d$seances, file.path(dirname(dossier), "cours"))
  valider_concepts(d$concepts)
  valider_veille(d$veille)
  invisible(d)
}
