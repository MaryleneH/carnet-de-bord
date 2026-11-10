# Pré-rendu (lancé par Quarto avant chaque rendu du site) : écrit la date de
# mise à jour dans _variables.yml, que lit le pied de page. C'est la date du
# dernier commit, ou à défaut celle du jour. Fichier généré, ignoré par Git.

source("R/calculs.R", encoding = "UTF-8")

date_commit <- tryCatch(
  suppressWarnings(system2("git", c("log", "-1", "--format=%cs"), stdout = TRUE, stderr = FALSE)),
  error = function(e) character()
)
if (length(date_commit) != 1 || !grepl("^\\d{4}-\\d{2}-\\d{2}$", date_commit)) {
  date_commit <- format(Sys.Date())
}

con <- file("_variables.yml", open = "w", encoding = "UTF-8")
writeLines(sprintf('maj: "%s"', date_longue(date_commit)), con)
close(con)
