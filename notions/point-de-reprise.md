---
title: "Point de reprise d'un graphe d'états"
subtitle: "Ce qui est sauvegardé après chaque nœud, et ce que cela permet à la relance"
date: 2026-11-27
toc: true
toc-depth: 3
---

*Ce cours explique comment un graphe d'états survit à l'arrêt brutal de son processus : par un point de reprise, la sauvegarde de son état, et par un journal des appels au modèle. Il reprend le [chapitre 12 du cours de la séance 3](/cours/seance-03-cours.md#chapitre-12), « Tuer le processus, puis reprendre ».*

*« Notre graphe » désigne le graphe du laboratoire : trois nœuds, `rediger`, `verifier` et `valider`, qui rédigent un texte, font vérifier ses chiffres par le code, puis attendent la décision d'une personne. « L'enveloppe » est le code par lequel passent tous les appels au modèle : elle les consigne dans un journal et sait les relire. Les sauvegardes, les fils et les instantanés dont il est question ici sont présentés dans le cours [LangGraph](/notions/langgraph.md).*

## Ce que nous avons fait

**Les cinq tests.** `python3 verifier_graphe.py` démarre son propre faux serveur et travaille dans un dossier temporaire. Sa dernière ligne, « Les cinq comportements du graphe sont vérifiés. », était le critère de fin de la séance.

**La panne provoquée à la main,** sur le vrai serveur, avec la question Q2 :

```bash
GRAPHE_PANNE=rediger python3 -m graphe lancer --fil panne-q2 --question Q2; echo "code de sortie : $?"
python3 -m graphe etat --fil panne-q2
grep -c '"etiquette": "graphe/panne-q2/rediger/1"' journal/appels.jsonl
python3 -m graphe reprendre --fil panne-q2
grep -c '"etiquette": "graphe/panne-q2/rediger/1"' journal/appels.jsonl
```

**La correction de Q2.** Le texte repris contenait une erreur que le code ne pouvait pas voir. Une remarque l'a fait corriger au tour 2, puis le texte a été validé : commit `d85a22a`, « docs: panne et reprise du graphe (Q2), texte corrigé puis validé ».

## Pourquoi un point de reprise

**Une panne n'est pas une exception, c'est une certitude.** Elnozahy et ses coauteurs (2002) ont fait la synthèse des protocoles de reprise après panne. Ils reposent sur deux outils : le point de reprise (*checkpoint*), une sauvegarde de l'état à un instant donné, et la journalisation des messages reçus. Après une panne, le système recharge le dernier point de reprise, puis rejoue le journal. Notre graphe utilise exactement ces deux outils : la sauvegarde SQLite de LangGraph, et le journal des appels de l'enveloppe.

**Refaire une étape ne doit rien coûter.** Helland (2012) rappelle qu'une opération répétée doit avoir le même effet qu'une seule : c'est l'idempotence, déjà rencontrée au jour 2 ([chapitre 3 du cours de la séance 2](/cours/seance-02-cours.md#chapitre-3)). Appliquée à l'agent, elle veut dire qu'un appel au modèle relancé n'est ni payé deux fois, ni remplacé par une autre réponse.

**Provoquer la panne exprès.** Basiri et ses coauteurs (2016) décrivent l'ingénierie du chaos pratiquée chez Netflix : on provoque des pannes volontairement, en conditions contrôlées, pour vérifier que le système s'en remet. Une reprise qui n'a jamais été éprouvée n'est qu'une promesse.

## Comment ça marche

### Quand la sauvegarde est écrite

<!-- largeurs: 14,44,42 -->
| `durability` | Quand LangGraph écrit l'instantané | Ce qu'une panne fait perdre |
| --- | --- | --- |
| `"exit"` | Seulement quand l'exécution s'arrête : fin, erreur ou interruption | Tout ce qui s'est passé depuis le début de l'exécution |
| `"async"` | Pendant que l'étape suivante s'exécute (valeur par défaut) | Peut-être la dernière étape |
| `"sync"` | Avant que l'étape suivante ne commence | Rien de ce qui est fini |

Notre commande choisit `"sync"` à chaque appel. Le coût, une écriture SQLite par étape, est négligeable devant un appel au modèle. Avec `"sync"`, l'entrée et l'étape 0 sont écrites avant le premier nœud : après une panne dans `rediger`, le fil existe, et il attend `rediger`.

### La panne, puis la reprise, pas à pas

1. **`lancer`** écrit les instantanés −1 et 0, puis exécute `rediger`. L'appel au modèle part, et l'enveloppe ajoute une ligne au journal, avec la clé de l'appel.
2. **`panne("rediger")`** appelle `os._exit(3)`. Le processus meurt sur-le-champ, avant que le nœud ne rende son résultat : aucun bloc `finally`, aucun rangement, comme une coupure de courant. Pour LangGraph, le tour 1 n'a jamais eu lieu : `tours 0`, `appels 0`.
3. **`reprendre`** appelle `graphe.invoke(None, config)` : sans entrée, sur un fil existant, LangGraph recharge le dernier instantané et relance le travail inachevé, c'est-à-dire `rediger`, depuis sa première ligne.
4. **Le nœud reconstruit le même appel.** `tours` vaut toujours 0, donc `tour` vaut 1 : même étiquette, `graphe/panne-q2/rediger/1`. La question, les faits, les remarques et le brouillon viennent du même instantané : même corps de requête.
5. **Même étiquette et même corps, donc même clé.** Rappel du [chapitre 1 du cours de la séance 3](/cours/seance-03-cours.md#chapitre-1) : la clé est l'empreinte SHA-256 de l'adresse du serveur, de l'étiquette et du corps de la requête.
6. **Le journal répond à la place du modèle.** En mode reprise, l'enveloppe trouve la clé dans le journal et rend la réponse enregistrée, sans rien envoyer. Le nœud finit, l'instantané 1 est écrit, et le graphe continue jusqu'à `valider`.

La sauvegarde garde les étapes finies ; le journal garde les appels faits. Chacun couvre ce que l'autre ne voit pas.

### Les cinq tests

<!-- largeurs: 28,72 -->
| Test | Ce qu'il prouve |
| --- | --- |
| 1. Arrêt humain | Le graphe corrige seul la faute du premier jet, puis s'arrête avant `valider` |
| 2. Décisions | « corriger » puis « valider », chacune dans un nouveau processus, mènent au texte validé |
| 3. Panne dans `rediger` | Après la reprise, l'appel du tour 1 figure une seule fois dans le journal |
| 4. Panne dans `verifier` | La reprise ne relance pas la rédaction, déjà sauvegardée |
| 5. Rejeu | Serveur arrêté, sans clé, avec une sauvegarde neuve : le fil se rejoue et produit un texte validé identique, octet pour octet |

## Ce que nous avons observé

```
code de sortie : 3
Fil panne-q2 : prochain nœud ('rediger',) ; tours 0 ; anomalies 0 ; décisions [] ; appels 0
1
— Fil panne-q2 : en attente de ta décision (tour 1) —
[…]
1
```

Code de sortie 3 : le processus a bien été tué. Le fil attend `rediger`, avec `appels 0`. Le premier `grep` vaut 1 : le journal avait enregistré l'appel. Après la reprise, le texte attend la décision, et le second `grep` vaut toujours 1 : la reprise a relancé `rediger`, sans renvoyer l'appel.

**Mais le texte repris était faux, sans que le code le voie :**

> « […] Au sein de ce secteur, les paiements aux grandes entreprises privées résidentes atteignent 15,8 Md€ [F11], soit une évolution de +24,0 % [F12] par rapport à l'année précédente, et constituent 90,6 % [F15] des paiements à l'industrie. Par ailleurs, les paiements aux entreprises de taille intermédiaire (ETI) privées résidentes s'établissent à 3,3 Md€ [F13], affichant une baisse de −18,2 % [F14]. »

La phrase sur les grandes entreprises est fausse deux fois. Les 15,8 Md€ vont aux grandes entreprises privées de tous les secteurs, pas seulement de l'industrie. Et 15,8 sur 17,7 font 89,3 %, pas 90,6 %. Même avec l'arithmétique d'intervalles du [chapitre 3 du cours de la séance 3](/cours/seance-03-cours.md#chapitre-3), le rapport reste entre 88,7 % et 89,8 % : la contradiction est réelle. Le modèle a fusionné F11 et F15, exactement le piège découvert la veille dans la fiche. Comme chaque chiffre figure dans la fiche avec le bon identifiant, les six contrôles passent. C'est l'erreur de contexte décrite par Thomson et Reiter (2020), en vrai.

Le texte contenait un second défaut : « une baisse de −18,2 % », une double négation. Notre propre consigne des signes la provoque, puisqu'elle exige un signe devant chaque évolution.

La remarque nommait les deux défauts : les 15,8 Md€ ne sont pas une partie de l'industrie, et il fallait écrire « une évolution de −18,2 % ». Le tour 2 les a corrigés :

> « […] La part des paiements à l'industrie versée aux grandes entreprises est de 90,6 % [F15]. Par ailleurs, les paiements aux grandes entreprises privées résidentes atteignent 15,8 Md€ [F11], soit une évolution de +24,0 % [F12], tandis que les paiements aux entreprises de taille intermédiaire (ETI) privées résidentes s'établissent à 3,3 Md€ [F13], avec une évolution de −18,2 % [F14]. »

Une maladresse demeure : « 15,8 Md€, soit une évolution de +24,0 % ». « Soit » annonce une équivalence, alors qu'un montant n'est pas une évolution. Ce n'est pas une erreur ; le texte a été validé.

## Ce qui m'a posé problème, et ce que j'ai compris

À la question « pourquoi le second `grep` affiche-t-il 1, et pas 2 ? », j'ai répondu que le tour n'était pas relancé, puisque le processus était mort après l'appel.

C'était presque juste, mais pas tout à fait : le nœud `rediger` est bien relancé, depuis sa première ligne. Ce qui n'est pas refait, c'est l'appel au modèle. Le mécanisme tient en trois temps :

1. **Le tour 1 n'existe pas encore pour le graphe :** le processus est mort avant que `rediger` ne rende son résultat, donc l'état ne l'a jamais enregistré.
2. **La reprise reconstruit le même appel :** même tour, donc même étiquette ; même état, donc même requête ; donc même clé.
3. **Le journal répond à la place du modèle :** l'enveloppe, en mode reprise, trouve la clé et rend la réponse enregistrée.

J'ai compris la différence entre « relancer l'étape » et « refaire ses effets ». LangGraph relance l'étape ; c'est le journal qui empêche d'en refaire l'effet coûteux.

## Pièges et bonnes pratiques

- **Exporter `GRAPHE_PANNE`** au lieu de la placer devant la seule commande `lancer` : `reprendre` mourrait au même endroit.
- **Choisir `"exit"` pour aller plus vite :** une panne ferait perdre tout le fil depuis son lancement.
- **Écrire un nœud qui agit sur le monde avant `interrupt()`,** par exemple qui envoie un courriel : il le renverrait à chaque reprise.
- **Supprimer `etat/graphe.sqlite`** : les fils en cours sont perdus. Le journal, lui, reste, et chaque fil se rejoue comme au test 5.
- **Croire que le code voit les erreurs de contexte.** Il vérifie que chaque chiffre est dans la fiche, pas qu'il est attaché à la bonne grandeur.

> **À retenir.** Une reprise après panne repose sur deux outils : un point de reprise et un journal. La sauvegarde garde les étapes finies, le journal garde les appels faits : relancer une étape ne refait pas son effet coûteux. Une reprise se prouve en provoquant la panne. Et un texte qui passe tous les contrôles peut encore être faux : seule la relecture humaine l'a vu.

## Pour vérifier que vous avez compris

1. Si la panne avait eu lieu dans `verifier` (`GRAPHE_PANNE=verifier`), quel nœud la reprise aurait-elle relancé, et combien de lignes du tour 1 le journal aurait-il contenues ?
2. Imaginez que `rediger` incrémente un compteur rangé dans un fichier, hors de l'état, juste avant l'appel au modèle, et en tire le numéro de tour. Que se passerait-il à la reprise ?

Les réponses sont [à la fin de ce cours](#corrige).

## Références

- Elnozahy, E. N., Alvisi, L., Wang, Y.-M., Johnson, D. B. (2002). *A survey of rollback-recovery protocols in message-passing systems*. ACM Computing Surveys, 34(3), p. 375–408. https://doi.org/10.1145/568522.568525 — **Ce qu'on y apprend :** les points de reprise et la journalisation, les deux outils de toute reprise après panne.
- Helland, P. (2012). *Idempotence Is Not a Medical Condition*. ACM Queue, 10(4) ; repris dans Communications of the ACM, 55(5). https://queue.acm.org/detail.cfm?id=2187821 — **Ce qu'on y apprend :** pourquoi une opération répétée doit avoir le même effet qu'une seule, dans tout système qui peut tomber en panne.
- Basiri, A., Behnam, N., de Rooij, R., Hochstein, L., Kosewski, L., Reynolds, J., Rosenthal, C. (2016). *Chaos Engineering*. IEEE Software, 33(3), p. 35–41. https://doi.org/10.1109/MS.2016.60 — **Ce qu'on y apprend :** pourquoi provoquer des pannes exprès, et comment le faire sans risque.

## Corrigé des questions {#corrige}

1. Avec `"sync"`, l'instantané qui suit `rediger` était écrit avant que `verifier` ne commence. La reprise relance donc `verifier` seul, et le journal contient une seule ligne du tour 1 : c'est ce que prouve le test 4.
2. Le compteur aurait été incrémenté avant la panne. À la reprise, `rediger` lirait 2 au lieu de 1 : autre étiquette, donc autre clé. Le journal ne la trouverait pas, un second appel partirait au serveur, payé et peut-être différent, et la numérotation sauterait un tour. Une action hors de l'état, faite avant la fin du nœud, casse l'idempotence.
