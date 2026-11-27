---
title: "Écart au plan"
subtitle: "Dire ce qui a changé par rapport à ce qui était prévu, et pourquoi"
date: 2026-11-27
toc: true
toc-depth: 3
---

*Ce cours montre, sur un cas réel, ce qu'est un écart au plan et comment le déclarer : ici, un défaut de l'instrument de mesure, découvert pendant une campagne. Il reprend le [chapitre 6 du cours de la séance 2](/cours/seance-02-cours.md#chapitre-6), « Lancer, surveiller, déclarer un écart ».*

*« Le plan » est le plan préenregistré du banc de fiabilité du laboratoire : pour chaque cas, la question, la mesure et la règle de décision, écrites et datées par un commit avant la première mesure. Le [chapitre 4 du même cours](/cours/seance-02-cours.md#chapitre-4), « Écrire avant de mesurer », explique ce préenregistrement et ce qu'il protège.*

## Ce que nous avons fait

- **Lancer la campagne** en arrière-plan, puis suivre son avancement :

```bash
nohup python3 -m banc --campagne 2026-11-22-gemma4-26b-moe > banc.log 2>&1 &
tail -f banc.log
```

- **Remarquer une anomalie en lisant `banc.log`** : toutes les lignes de la consigne `termine_par` étaient en échec.
- **Regarder les réponses elles-mêmes** dans le journal : elles s'arrêtaient au milieu d'une phrase.
- **Compter les fins de réponse** (`finish_reason`) consigne par consigne.
- **Déclarer l'écart** dans `banc/PLAN.md`, avec ses chiffres, avant d'ouvrir le rapport (commit `c08fb6d`).

## Pourquoi déclarer un écart

Quand une condition échoue à 100 %, la première question n'est pas « le modèle est-il mauvais ? », mais « la réussite était-elle possible ? ». Un instrument peut échouer en silence : chaque vérificateur peut être juste, et une condition de la mesure rendre la réussite impossible.

Une fois le problème vu, deux tentations sont à écarter : corriger le code en silence, ou ignorer la consigne. Le préenregistrement impose une troisième voie : **déclarer l'écart**, avec sa cause et sa preuve, et présenter les deux lectures.

## Comment ça marche

**Le suivi.** `nohup … &` détache le banc du terminal : fermer l'onglet ne l'arrête pas. Chaque ligne de `banc.log` a la forme `[137/584] consignes/en/mots_max/sujet07 : réussi (envoyé)` : le rang de l'essai, le cas, la condition, l'item, l'issue, et « envoyé » au serveur ou « relu » dans le journal.

**Le diagnostic.** Chaque réponse du serveur porte un champ `finish_reason` : `stop` quand le modèle a fini de lui-même, `length` quand le plafond de tokens l'a coupé, `tool_calls` quand il demande un outil ([chapitre 12 du cours de la séance 2](/cours/seance-02-cours.md#chapitre-12)). Les réponses `termine_par` finissaient par `length` : la requête plafonnait la réponse à 300 tokens (`max_tokens=300` dans `banc/cas_consignes.py`), alors que la demande, « Explique… à un lecteur non spécialiste », appelait un long exposé. Le modèle n'atteignait jamais la fin, donc ne pouvait pas écrire « Fin de la réponse. ».

> **Définition.** Un **écart au plan** est un changement, ou un défaut découvert, par rapport à ce qui avait été préenregistré. On le déclare dans le plan, avec sa date, sa cause, sa preuve et la façon dont on lira les résultats.

**La correction, pour plus tard.** On ne peut pas simplement remplacer 300 par 1 500 dans le code : la requête changerait, donc son empreinte, et la campagne du jour ne se rejouerait plus. On ajoutera un paramètre réglable, qui garde 300 par défaut.

**Où sont les résultats.** Une campagne produit trois choses : le rapport lisible, `mesures/<campagne>/rapport_banc.md` ; le détail de chaque essai, `mesures/<campagne>/resultats.json` ; et, dans `journal/appels.jsonl`, chaque requête avec la réponse brute du serveur.

## Ce que nous avons observé

<!-- largeurs: 30,25,45 -->
| Consigne | Réponses coupées | Conséquence pour la mesure |
| --- | --- | --- |
| `termine_par` | 40 sur 40 | non mesurable dans cette campagne |
| `mot_interdit` | 40 sur 40 | vérifiée sur le seul début des réponses |
| `sans_markdown` | 20 sur 40 | même biais, plus faible |
| `commence_par` | 40 sur 40 | sans effet : le début est visible |
| `mots_max`, `liste_trois` | aucune | mesures propres |

L'écart a été écrit dans le plan avant la lecture du rapport, avec ces chiffres.

## La question posée pendant la séance

*Où trouver les résultats de la campagne ?*

Dans `mesures/2026-11-22-gemma4-26b-moe/rapport_banc.md`, à ouvrir dans VS Code avec l'aperçu Markdown (Ctrl+Maj+V) : une section par cas. La confusion venait de l'ordre du programme, qui faisait « comprendre » les cas avant de « lire » leurs résultats. Nous l'avons simplifié : un cas à la fois, on lit sa section du rapport, on l'interprète, on la confronte aux paris. Lire les résultats ne faussait rien : règles et paris étaient datés par un commit depuis la veille.

## Pièges et bonnes pratiques

- **Conclure d'un taux nul sans se demander si la réussite était possible.** Regarder `finish_reason` avant d'accuser le modèle.
- **Coller deux fois un bloc qui écrit un fichier.** Le script de l'écart s'est exécuté deux fois ; son `assert` l'a empêché d'écrire l'écart en double.
- **Préparer des fichiers, puis relancer un bloc de commit.** Les mesures, déjà préparées, sont parties dans le commit `2e91e81` avec un message inexact, et le contrôle de la clé lancé ensuite portait sur une différence vide : il ne prouvait rien. Nous l'avons refait sur tout l'historique : `git log -p | grep -cF "${LLM_CLE:?}"` affiche 0.

> **À retenir.** Devant un 0 %, se demander d'abord si 100 % était possible. Un défaut d'instrument se déclare, avec sa preuve, avant de lire les résultats ; il ne se corrige pas en silence.

## Pour vérifier que vous avez compris

1. Que signifient `stop`, `length` et `tool_calls` dans `finish_reason` ?
2. Pourquoi ne peut-on pas corriger le plafond de 300 tokens directement dans `cas_consignes.py` ?

Les réponses sont [à la fin de ce cours](#corrige).

## Références

- **Georges, Buytaert et Eeckhout (2007)**, *Statistically Rigorous Java Performance Evaluation* (OOPSLA) : une mesure de performance n'est fiable que si l'on contrôle et déclare ses conditions.
- **Biderman et al. (2024)** : des détails d'exécution, comme le plafond de tokens ou le format de requête, suffisent à changer un résultat d'évaluation.

## Corrigé des questions {#corrige}

1. `stop` : le modèle a fini de lui-même ; `length` : le plafond de tokens l'a coupé ; `tool_calls` : il demande l'exécution d'un outil.
2. Changer le plafond change la requête, donc son empreinte : les appels de la campagne du 22 novembre ne seraient plus retrouvés, et la campagne ne se rejouerait plus. On ajoute un paramètre, avec 300 par défaut.
