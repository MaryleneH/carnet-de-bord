# Carnet de bord

Ce dépôt publie un tableau de bord personnel Quarto pour suivre deux projets en parallèle :
- **Laboratoire** (public)
- **Projet interne** : aucun détail publié ici

## Ajouter une séance au journal

Éditez `data/journal.csv` et ajoutez une ligne :
- `date` au format `AAAA-MM-JJ`
- `projet` = `labo`
- `etape` = `J1..J15`
- `duree_h` > 0 et <= 10

## Valider et prévisualiser en local

1. Restaurer les paquets :
   ```r
   renv::restore()
   ```
2. Valider les données :
   ```r
   source("R/valider.R")
   valider_tout("data")
   ```
3. Lancer les tests :
   ```r
   testthat::test_dir("tests/testthat")
   ```
4. Rendre le tableau de bord :
   ```bash
   quarto render index.qmd
   ```

## Règle de confidentialité

Le site est public.

Le projet interne n'apparaît dans aucune donnée publique : toute ligne de `journal.csv` ou de `jalons.csv` qui ne concerne pas le laboratoire fait échouer la validation avec :

> Confidentialité : seul le laboratoire figure dans les données publiques

Le fichier `data/mesures.csv` accepte uniquement les serveurs `albert` et `sspcloud`.

## Publication

La publication se fait automatiquement à chaque push sur `main` (ou à la demande depuis l'onglet **Actions** → *Run workflow*) via `.github/workflows/publish.yml`, en deux jobs :

1. **build** : valide les données, lance les tests, rend le site Quarto dans `_site/` et l'envoie comme artefact GitHub Pages ;
2. **deploy** : publie cet artefact sur GitHub Pages (environnement `github-pages`).

Le site est déployé directement depuis GitHub Actions : il n'y a **pas de branche `gh-pages`** et le site rendu n'est jamais commité dans le dépôt.

Prérequis, à faire une seule fois : dans **Settings → Pages → Build and deployment**, choisir **Source : GitHub Actions**.

Adresse du site : `https://maryleneh.github.io/carnet-de-bord/`
