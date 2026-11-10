# Carnet de bord

Ce dépôt publie un tableau de bord personnel Quarto pour suivre deux projets en parallèle :
- **Laboratoire** (public)
- **Produit** (interne, informations masquées)

## Ajouter une séance au journal

Éditez `data/journal.csv` et ajoutez une ligne :
- `date` au format `AAAA-MM-JJ`
- `projet` = `labo` ou `produit`
- `etape` = `J1..J15` (labo) ou `P0..P5` (produit)
- `duree_h` > 0 et <= 10
- si `projet=produit`, laisser `fait`, `appris` et `suite` vides

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

Pour chaque ligne où `projet=produit` dans `journal.csv`, les colonnes `fait`, `appris` et `suite` doivent être vides. Sinon la validation échoue avec :

> Confidentialité : pas de texte libre pour le projet interne

Le fichier `data/mesures.csv` accepte uniquement les serveurs `albert` et `sspcloud`.

## Publication

La publication se fait automatiquement sur push vers `main` via `.github/workflows/publish.yml`.

Adresse du site : `https://maryleneh.github.io/carnet-de-bord/`
