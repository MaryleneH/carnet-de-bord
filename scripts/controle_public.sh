#!/usr/bin/env bash
# Contrôle de publication du carnet de bord (usage local uniquement, pas en CI).
#
# Vérifie qu'aucun terme de la liste rouge n'apparaît dans les sources du
# dépôt ni dans le site rendu (_site/). La liste rouge est hors du dépôt :
#   ~/.liste-rouge-carnet   (un terme par ligne, casse indifférente)
#
# À lancer avant chaque commit :   scripts/controle_public.sh
#
# Codes de sortie :
#   0  aucun terme trouvé
#   1  un terme trouvé (arrêt au premier)
#   2  contrôle impossible : liste absente, illisible ou vide, erreur de lecture
#
# La liste n'est jamais affichée. En cas de découverte, le script indique
# seulement le numéro du terme dans la liste et l'endroit où il apparaît.

set -euo pipefail

liste="${HOME}/.liste-rouge-carnet"

# Casse ignorée y compris pour les lettres accentuées : il faut une locale UTF-8.
for loc in C.UTF-8 C.utf8 en_US.UTF-8 fr_FR.UTF-8; do
  if locale -a 2>/dev/null | grep -qixF "$loc"; then
    export LC_ALL="$loc"
    break
  fi
done

racine="$(git -C "$(dirname "$0")" rev-parse --show-toplevel)"
cd "$racine"

if [[ ! -f "$liste" || ! -r "$liste" ]]; then
  echo "ÉCHEC : liste rouge absente ou illisible (~/.liste-rouge-carnet). Contrôle impossible." >&2
  exit 2
fi

# Termes : fins de ligne Windows et espaces en bord retirés, lignes vides ignorées.
termes=()
while IFS= read -r ligne || [[ -n "$ligne" ]]; do
  ligne="${ligne%$'\r'}"
  ligne="${ligne#"${ligne%%[![:space:]]*}"}"
  ligne="${ligne%"${ligne##*[![:space:]]}"}"
  if [[ -n "$ligne" ]]; then
    termes+=("$ligne")
  fi
done < "$liste"

if (( ${#termes[@]} == 0 )); then
  echo "ÉCHEC : la liste rouge est vide. Contrôle impossible." >&2
  exit 2
fi

# Fichiers contrôlés : sources suivies, nouveaux fichiers non ignorés, et _site/.
fichiers=()
while IFS= read -r -d '' f; do
  if [[ -f "$f" ]]; then
    fichiers+=("$f")
  fi
done < <(git ls-files -z --cached --others --exclude-standard)

if [[ -d _site ]]; then
  while IFS= read -r -d '' f; do
    fichiers+=("$f")
  done < <(find _site -type f -print0)
else
  echo "Attention : _site/ absent, seules les sources sont contrôlées (lancer quarto render d'abord)." >&2
fi

if (( ${#fichiers[@]} == 0 )); then
  echo "ÉCHEC : aucun fichier à contrôler." >&2
  exit 2
fi

# 1. Noms de fichiers. Le chemin n'est pas affiché : il contiendrait le terme.
n=0
for terme in "${termes[@]}"; do
  n=$((n + 1))
  if printf '%s\n' "${fichiers[@]}" | grep -qiF -e "$terme"; then
    echo "ÉCHEC : le terme n°${n} de la liste rouge apparaît dans un nom de fichier." >&2
    exit 1
  fi
done

# 2. Contenu des fichiers texte. Aucun chemin ne contient de terme à ce stade :
#    on peut afficher le fichier et la ligne, jamais le texte trouvé.
n=0
for terme in "${termes[@]}"; do
  n=$((n + 1))
  set +e
  trouves="$(grep -IliF -e "$terme" -- "${fichiers[@]}")"
  statut=$?
  set -e
  if (( statut == 0 )); then
    premier="${trouves%%$'\n'*}"
    num_ligne="$(grep -IinF -m 1 -e "$terme" -- "$premier" | cut -d: -f1)"
    echo "ÉCHEC : le terme n°${n} de la liste rouge apparaît dans ${premier} (ligne ${num_ligne})." >&2
    exit 1
  elif (( statut != 1 )); then
    echo "ÉCHEC : erreur de lecture pendant le contrôle. Contrôle incomplet." >&2
    exit 2
  fi
done

echo "OK : aucun des ${#termes[@]} termes de la liste rouge dans ${#fichiers[@]} fichiers (sources et _site/)."
