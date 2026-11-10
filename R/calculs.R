# Calculs et mise en forme des nombres à la française.

ESPACE_FINE <- " "       # espace fine insécable : milliers, avant % ; ! ?
ESPACE_INSECABLE <- " "  # espace insécable : entre un nombre et son unité

MOIS <- c(
  "janvier", "février", "mars", "avril", "mai", "juin", "juillet", "août",
  "septembre", "octobre", "novembre", "décembre"
)

# Intervalle de confiance de Wilson pour une proportion (chapitre 13 du cours).
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

# « 10 novembre 2026 », « 1er mars 2027 », sans dépendre de la locale.
date_longue <- function(x) {
  d <- as.Date(as.character(x))
  jour <- as.integer(format(d, "%d"))
  paste(if (jour == 1) "1er" else jour, MOIS[as.integer(format(d, "%m"))], format(d, "%Y"))
}

EXPOSANTS <- c(
  "-" = "⁻", "0" = "⁰", "1" = "¹", "2" = "²", "3" = "³",
  "4" = "⁴", "5" = "⁵", "6" = "⁶", "7" = "⁷", "8" = "⁸", "9" = "⁹"
)

# 5.18e-5 → « 5,18 × 10⁻⁵ »
format_scientifique <- function(v) {
  exposant <- floor(log10(abs(v)))
  mantisse <- format(signif(v / 10^exposant, 3), decimal.mark = ",", trim = TRUE)
  chiffres <- strsplit(as.character(exposant), "")[[1]]
  paste0(mantisse, ESPACE_INSECABLE, "×", ESPACE_INSECABLE, "10", paste(EXPOSANTS[chiffres], collapse = ""))
}

# 52697 → « 52 697 » (espace fine insécable) ; 0.838 → « 0,838 ».
format_nombre <- function(x) {
  vapply(x, function(v) {
    if (v != 0 && abs(v) < 1e-3) {
      return(format_scientifique(v))
    }
    format(v, big.mark = ESPACE_FINE, decimal.mark = ",", scientific = FALSE, trim = TRUE, digits = 15)
  }, character(1), USE.NAMES = FALSE)
}

# Valeur d'une mesure du registre : « ≈ 156 », « 4,6 à 4,9 », « 20,7 % à 100 % ».
# Avec l'unité si demandé : « 52 697 tokens ».
format_valeur <- function(m, avec_unite = FALSE) {
  v <- format_nombre(m$valeur)
  pourcent <- identical(m$unite, "%")
  if (pourcent) v <- paste0(v, ESPACE_FINE, "%")
  texte <- if (length(v) == 2) paste(v[[1]], "à", v[[2]]) else v
  if (isTRUE(m$approx)) texte <- paste0("≈", ESPACE_INSECABLE, texte)
  if (avec_unite && !pourcent && nzchar(m$unite)) texte <- paste0(texte, ESPACE_INSECABLE, m$unite)
  texte
}
