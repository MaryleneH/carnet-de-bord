#!/usr/bin/env bash
# Régénère les icônes PNG du site à partir de icones/favicon.svg.
# Nécessite rsvg-convert (paquet librsvg2-bin sous Debian et Ubuntu, librsvg avec Homebrew).
set -euo pipefail
cd "$(dirname "$0")/.."

# Repli pour les navigateurs qui n'affichent pas une icône SVG.
rsvg-convert -w 32 -h 32 icones/favicon.svg -o icones/favicon-32.png

# Écran d'accueil d'un téléphone : un carré plein, que le système arrondit lui-même.
rsvg-convert -w 180 -h 180 -b "#1F3864" icones/favicon.svg -o icones/apple-touch-icon.png

echo "Icônes régénérées : icones/favicon-32.png, icones/apple-touch-icon.png"
