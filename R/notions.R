# Rubrique Notions : un cours par notion, rangé dans le dossier notions/.
# La page liste les cours présents, d'après l'en-tête de chaque fichier :
# déposer un fichier dans le dossier suffit à l'y ajouter.
# Aucun nombre n'est écrit à la main : le compteur vient du dossier.

# Même ordre que la barre latérale : Quarto la range par nom de fichier, sans
# l'extension. Le tri par octets donne ce résultat quelle que soit la langue du système.
notions_triees <- function(notions) {
  if (length(notions) < 2) return(notions)
  noms <- tools::file_path_sans_ext(vapply(notions, function(n) n$fichier, character(1)))
  notions[order(noms, method = "radix")]
}

# La date vient d'abord : une carte qui s'ouvrirait par son titre deviendrait
# une section, et perdrait son cadre.
carte_notion <- function(n) {
  paste0(
    "::: {.carte .carte-notion}\n\n",
    "[Ajouté le ", date_longue(n$date), "]{.carte-surtitre}\n\n",
    "## [", echapper_md(n$titre), "](/notions/", n$fichier, ")\n\n",
    if (!is.null(n$resume)) paste0(n$resume, "\n\n") else "",
    ":::\n\n"
  )
}

page_notions <- function(d) {
  notions <- notions_triees(d$notions)
  n <- length(notions)
  intro <- paste0(
    "::: {.notions-intro}\n\n",
    "Les [cours des séances](/cours/index.qmd) suivent le fil du laboratoire : chaque chapitre raconte une étape. ",
    "Cette rubrique range les connaissances autrement, par notion : un cours autonome sur une idée, ",
    "à relire sans refaire toute une séance.\n\n",
    ":::\n\n"
  )
  if (n == 0) {
    return(paste0(
      intro,
      "::: {.notions-vide}\n\n",
      "Aucun cours de notion n'est encore en ligne. Les premiers arriveront ici, au fil des séances.\n\n",
      ":::\n\n"
    ))
  }
  paste0(
    intro,
    "[", n, " ", pluriel(n, "notion"), "]{.niveaux-total}\n\n",
    "::: {.grille-cartes}\n\n", paste(vapply(notions, carte_notion, character(1)), collapse = ""), ":::\n\n"
  )
}
