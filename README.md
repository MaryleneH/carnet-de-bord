# Carnet de bord

Site Quarto **public** qui suit le **laboratoire** : un assistant d'étude statistique sourcée, construit avec le serveur de modèles du SSP Cloud, l'API Albert et des données publiques. C'est un portfolio.

Adresse du site : `https://maryleneh.github.io/carnet-de-bord/`

## Structure du site

| Page | Fichier | Contenu |
| --- | --- | --- |
| Tableau de bord | `index.qmd` | quatre onglets : **Vue d'ensemble** (indicateurs d'avancement, où j'en suis, dernière séance, prochaine étape, points en attente, compétences), **Laboratoire** (frise des séances et jalons), **Compétences** (niveau de chaque concept), **Journal** (fait, appris, suite) |
| Séances | `seances/` | une carte par séance, une page par séance faite, avec ses résultats sourcés |
| Cours | `cours/` | un cours détaillé par séance, avec table des matières |
| Méthode | `methode.qmd` | les principes du laboratoire, cités du cours |

- **Données** : `data/seances.yml` (séances et journal), `data/mesures.yml` (résultats et durées des séances, chacun avec sa source dans le cours) et `data/concepts.csv` (suivi des compétences : vu, pratiqué, maîtrisé).
- **Rendu des pages** : `R/pages.R` lit ces données, calcule les indicateurs et produit le contenu des pages.
- **Mise en forme** : un seul fichier, `styles/carnet.scss` (variables en tête, thèmes clair et sombre). Police Source Serif 4 auto-hébergée dans `styles/polices/` (licence OFL). Aucun CDN, aucune police distante.
- **Filtres Lua** (`filters/`) : encadrés du cours en callouts, typographie française (espaces insécables), tableaux défilants sur téléphone.

## Règles vérifiées à chaque rendu

`R/valider.R` arrête la validation, la CI et le rendu si l'une de ces règles est enfreinte :

- **Confidentialité** : seules les séances du laboratoire sont admises ; toute autre entrée est refusée, ainsi que toute mention d'un autre projet dans les textes.
- **Aucun chiffre sans source** : aucun nombre n'est tapé dans une page. Les indicateurs d'avancement sont calculés depuis `seances.yml` et `concepts.csv`, et le tableau de bord indique de quel fichier ils viennent. Les résultats des séances viennent de `data/mesures.yml`, où chacun a sa source (séance et partie du cours) ; dans `seances.yml`, un chiffre se cite par `{identifiant}`, et un chiffre écrit en dur est refusé. Les identifiants (`404`, numéro de commit, `ADR-001`, n° de publication) s'écrivent en `code` ou après « n° ».
- **Cohérence** : statuts autorisés, dates valides, une séance faite a une date et une durée en heures.

## Ajouter une séance

1. Ajouter les chiffres de la séance dans `data/mesures.yml`, chacun avec sa source.
2. Compléter la séance dans `data/seances.yml` (statut, date, durée, livrables, journal, incidents, points en attente).
3. Mettre à jour les niveaux des concepts dans `data/concepts.csv` (dates de vu, pratiqué, maîtrisé).
4. Ajouter le cours `cours/seance-NN-cours.md` et la page `seances/seance-NN.qmd`.

## Travailler en local

1. Restaurer les paquets :
   ```r
   renv::restore()
   ```
2. Valider les données et lancer les tests :
   ```r
   source("R/valider.R")
   valider_tout("data")
   testthat::test_dir("tests/testthat")
   ```
3. Rendre le site :
   ```bash
   quarto render
   ```
4. **Avant chaque commit**, contrôler qu'aucun terme confidentiel n'est publié :
   ```bash
   scripts/controle_public.sh
   ```
   Le script lit `~/.liste-rouge-carnet` (un terme par ligne, hors du dépôt), cherche chaque terme dans les sources et dans `_site/`, et échoue au premier terme trouvé sans jamais afficher la liste. Il sert en local seulement, pas dans la CI.

## Publication

La publication se fait automatiquement à chaque push sur `main` (ou à la demande depuis l'onglet **Actions** → *Run workflow*) via `.github/workflows/publish.yml`, en deux jobs :

1. **build** : valide les données, lance les tests, rend le site Quarto dans `_site/` et l'envoie comme artefact GitHub Pages ;
2. **deploy** : publie cet artefact sur GitHub Pages (environnement `github-pages`).

Le site est déployé directement depuis GitHub Actions : il n'y a **pas de branche `gh-pages`** et le site rendu n'est jamais commité dans le dépôt.

Prérequis, à faire une seule fois : dans **Settings → Pages → Build and deployment**, choisir **Source : GitHub Actions**.
