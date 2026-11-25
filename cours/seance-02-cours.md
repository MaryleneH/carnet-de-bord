---
title: "Séance 2 — Le banc de fiabilité"
subtitle: "Cours détaillé du laboratoire · assistant d'étude statistique sourcée"
date: 2026-11-23
toc: true
toc-depth: 2
---

22 et 23 novembre 2026 · deux demi-journées, trois heures de travail · serveur de modèles du SSP Cloud

> **En bref.** Ce document reprend la séance 2 du laboratoire étape par étape, comme un cours. La séance a mesuré, sur 584 essais, ce que le modèle sait faire de façon fiable avant de construire l'agent : produire du JSON, suivre des consignes, retrouver des nombres dans un long texte, répondre de façon stable, appeler un outil, distinguer deux montants par la recherche par le sens. Chaque chapitre dit ce que nous avons fait, puis pourquoi, comment cela fonctionne, ce que nous avons observé et quels pièges éviter. Les questions posées pendant la séance sont reformulées, avec leur réponse. Les chiffres viennent du rapport du banc et du journal des appels ; ceux tirés d'articles sont attribués à leurs auteurs.

## Comment lire ce cours

### Organisation d'un chapitre

Chaque chapitre correspond à une étape de la séance et suit le même plan :

- **Ce que nous avons fait** : l'étape, concrètement, avec la commande ou le fichier concerné.
- **Pourquoi cette étape** : le problème qu'elle résout et ce qui se passerait sans elle.
- **Comment ça marche** : le mécanisme, avec le niveau technique nécessaire pour le comprendre vraiment.
- **Ce que nous avons observé** : nos résultats, et ce qu'ils permettent ou non de conclure.
- **La question posée pendant la séance** : quand une question a été posée, elle est reformulée, puis sa réponse est développée.
- **Pièges et bonnes pratiques** : les erreurs classiques, dont celles que nous avons commises.
- **Pour vérifier que vous avez compris** : deux questions. Le corrigé est à l'annexe E.
- **Références** : deux ou trois lectures, avec ce que chacune apporte. L'annexe F les rassemble.

### Les encadrés

> **À retenir.** Les idées essentielles du chapitre.

> **Attention.** Un piège qui coûte cher s'il n'est pas vu à temps.

> **Définition.** Un terme employé pour la première fois. Le glossaire de l'annexe D les reprend tous.

> **Formule.** Un calcul, avec ses notations.

### Les références

Elles sont de trois sortes : des articles évalués par les pairs (conférences et revues), des livres de référence, et quelques prépublications arXiv ou billets techniques, signalés comme tels. Chacune est citée pour ce qu'elle apporte au chapitre.

### Le niveau attendu

Le cours suppose lu celui de la séance 1 : l'enveloppe d'appel, le journal, le rejeu, la température et la fenêtre de contexte y sont introduits. Le vocabulaire nouveau est défini au premier emploi.

## Le fil rouge

Le projet vise un assistant qui conduit une question jusqu'à une étude statistique publiable et sourcée. Une règle commande toute l'architecture : **le modèle ne calcule aucun chiffre et n'en cite aucun de mémoire**. Les chiffres viennent d'un registre de faits et sont vérifiés par un programme.

La séance 1 a établi ce que le serveur accepte, chaque capacité étant testée une fois. La séance 2 transforme ces impressions en mesures : chaque capacité est testée de dix à cinquante fois, selon un plan écrit à l'avance, pour en tirer des taux avec leur intervalle de confiance, puis des décisions d'architecture. Son critère de fin : l'`ADR-001` est écrit. Il l'est.

## Plan du cours

<!-- largeurs: 8,30,62 -->
| N° | Chapitre | La question à laquelle il répond |
| --- | --- | --- |
| 1 | Pourquoi un banc | Pourquoi mesurer nous-mêmes, plutôt que lire des classements publics ? |
| 2 | Ranger le dépôt par fonction | Comment garder la trace de chaque jour sans multiplier les copies ? |
| 3 | Une enveloppe qui tient la charge | Comment faire six cents appels sans rien perdre, ni casser le passé ? |
| 4 | Écrire avant de mesurer | Pourquoi parier sur les résultats avant de les connaître ? |
| 5 | La répétition générale | Pourquoi faire tourner le banc contre un faux serveur ? |
| 6 | Lancer, surveiller, déclarer un écart | Que faire quand l'instrument se révèle mal réglé ? |
| 7 | Lire un taux | Que vaut un taux mesuré sur dix, vingt ou cinquante essais ? |
| 8 | Cas 1 : la forme JSON | Peut-on obliger le modèle à répondre dans un format ? |
| 9 | Cas 2 : les consignes et la validité d'un test | Le modèle suit-il des consignes, et mesure-t-on les bonnes ? |
| 10 | Cas 3 : les aiguilles et les pièges | Combien de texte confier au modèle en une fois ? |
| 11 | Cas 4 : la stabilité | Obtient-on deux fois la même réponse ? |
| 12 | Cas 5 : l'appel d'outils | Le modèle va-t-il chercher le chiffre, ou le cite-t-il de mémoire ? |
| 13 | Cas 6 : les embeddings et les nombres | La recherche par le sens distingue-t-elle deux montants ? |
| 14 | L'ADR-001 | Comment passer des mesures aux décisions ? |
| 15 | Fiche bilan | Que retenir pour tous les travaux agentiques à venir ? |
| A à F | Annexes | Résultats, incidents, clôture, glossaire, corrigé, bibliographie |

## Chapitre 1 — Pourquoi un banc

### Ce que nous avons fait

Nous avons construit un banc de fiabilité : un programme, lancé par `python3 -m banc`, qui soumet au modèle six séries d'essais, toujours les mêmes, dans un ordre tiré au sort une fois pour toutes, et qui en tire un rapport chiffré, `mesures/<campagne>/rapport_banc.md`. La campagne du 22 novembre 2026 sur `gemma4-26b-moe` compte 584 essais et 684 appels, passés en onze minutes et vingt-deux secondes, sans un seul refus du serveur.

### Pourquoi cette étape

Au jour 1, chaque capacité du serveur avait été testée une fois. Un essai réussi ne dit pas si le modèle réussit 99 fois sur 100 ou 6 fois sur 10. Or l'architecture de l'agent dépend exactement de ces taux : si le modèle rend un JSON conforme 99 fois sur 100, le code peut s'en remettre au schéma ; à 60 sur 100, il faut une autre conception, avec validation et réparation à chaque étape.

Le but de la journée était donc de **chiffrer les faiblesses du modèle avant de figer l'architecture**. Chaque cas du banc prépare une décision : la forme des sorties, la quantité de texte confiée au modèle, la langue des consignes, le recours à l'outil qui consulte le registre.

### Comment ça marche : un banc d'essai et un repère

Le mot vient du **banc d'essai** des ingénieurs : une installation fixe où l'on fait tourner un moteur hors du véhicule, dans des conditions contrôlées et répétables, pour mesurer ce qu'il donne vraiment avant de le monter. L'anglais dit *benchmark* : à l'origine, un repère gravé dans la pierre par les géomètres, qui sert de référence pour mesurer les hauteurs.

Notre banc a les deux sens. C'est un dispositif d'essai fixe : mêmes items, mêmes réglages, même ordre tiré au sort, même journal. C'est aussi un repère : on relancera le même banc sur chaque nouveau modèle ou serveur, et l'on comparera.

> **Définition.** Un **banc de fiabilité** est un programme qui mesure, sur des essais toujours identiques, ce qu'un modèle réussit et à quel taux. Il se relance en une commande et se rejoue sans réseau ni clé, grâce au journal des appels.

Pourquoi ne pas se contenter des classements publics ? Ils mesurent des capacités générales, sur les tâches d'autres gens. Raji et ses coauteurs (2021) montrent qu'un benchmark ne mesure que ce que ses tâches représentent, et qu'on lui prête souvent une portée générale qu'il n'a pas. Les classements ne disent pas comment ce modèle, sur ce serveur, remplit nos fiches JSON, suit des consignes en français, retrouve des nombres dans un long contexte ou appelle un outil pour un chiffre. Et Biderman et ses coauteurs (2024) rappellent que le résultat d'une évaluation dépend de détails d'exécution : format de la requête, paramètres, serveur. Il faut donc mesurer avec nos requêtes, sur notre serveur.

### Ce que nous avons observé

Le banc a tourné de bout en bout, puis s'est rejoué à l'identique sans réseau ni clé. Il a aussi révélé un défaut de son propre réglage, au cas 2 : un banc teste l'instrument autant que le modèle (chapitre 6).

### La question posée pendant la séance

*Pourquoi parle-t-on de « banc », et à quoi sert-il ?*

Parce qu'on y fait ce qu'on fait sur un banc d'essai : on sort la pièce de son contexte d'usage pour la mesurer dans des conditions contrôlées, avant de bâtir autour d'elle. Et parce que le résultat devient un repère, qui servira à comparer chaque nouveau modèle. Un banc est un **instrument permanent**, pas une expérience faite une fois.

### Pièges et bonnes pratiques

- **Croire qu'un résultat voyage.** Le banc mesure un modèle sur un serveur à une date donnée. Un autre serveur, une autre charge ou une autre version du modèle peuvent tout changer.
- **Bâtir un banc qu'on ne peut pas relancer.** Le code, le plan et le journal vivent ensemble dans le dépôt ; une commande suffit à refaire la campagne.
- **Mesurer des tâches génériques.** Un banc ne vaut que pour les tâches qu'il imite : le chapitre 9 en donne un exemple.

> **À retenir.** Un essai ne prouve rien ; un taux sur des essais répétés, avec son intervalle, se discute. Le banc fournit ces taux, sur nos tâches et notre serveur, et il se relance à chaque changement de modèle.

### Pour vérifier que vous avez compris

1. Pourquoi un essai réussi au jour 1 ne suffit-il pas pour décider de l'architecture ?
2. Qu'apporte notre banc qu'un classement public n'apporte pas ?

### Références

- **Biderman et al. (2024)**, *Lessons from the Trenches on Reproducible Evaluation of Language Models* (prépublication arXiv) : pourquoi les résultats d'évaluation varient avec les détails d'exécution, et comment les rendre reproductibles.
- **Raji et al. (2021)**, *AI and the Everything in the Whole Wide World Benchmark* (NeurIPS, Datasets and Benchmarks) : un benchmark ne mesure que ce que ses tâches représentent.
- **Peng (2011)**, *Reproducible Research in Computational Science* (Science) : publier le code et les données avec le résultat, pour qu'il puisse être refait.

## Chapitre 2 — Ranger le dépôt par fonction

### Ce que nous avons fait

Avant la séance, le 22 novembre au matin, nous avons rangé le dépôt du laboratoire :

- un `README.md` qui sert de porte d'entrée : le but, la règle des chiffres, le tableau des jours, la commande qui rejoue le jour 1, le rôle de chaque fichier ;
- les trois questions de référence, sorties du journal vers `docs/questions.md`, car elles forment le jeu d'évaluation du laboratoire et ne changent pas d'un jour à l'autre ;
- une **étiquette** git `jour-1`, posée sur le dernier commit du jour 1 ;
- pour le jour 2, une branche `jour-2`, fusionnée dans `main` par une pull request, puis l'étiquette `jour-2`.

### Pourquoi cette étape

Le premier réflexe, pour suivre des séances, est de créer des dossiers `jour1/`, `jour2/`. C'est une fausse bonne idée : `llm.py` y serait copié puis divergerait, et le journal des appels se couperait en morceaux, alors que tout le rejeu repose sur un journal unique. Un jour n'est pas un dossier : c'est une étape de la même base de code.

### Comment ça marche : les jours vivent à trois endroits

1. **Dans git, une étiquette par jour.** `git tag -n` liste les jours ; `git switch --detach jour-1` revient à la fin du jour 1 ; `git diff jour-1 jour-2 --stat` montre tout ce que le jour 2 a changé.
2. **Dans `JOURNAL.md`, une section courte par jour** : ce qui a été fait, mesuré, décidé, et ce qui reste ouvert.
3. **Dans ce carnet**, le récit et le cours.

Le dépôt, lui, est rangé **par fonction** : `llm.py` à la racine, `banc/` pour le banc, `outils/` pour les utilitaires, `docs/` pour les décisions et les questions, `journal/` et `mesures/` pour les preuves. Un jour se lit alors comme une branche : on la crée au début (`git switch -c jour-2`), on y commite le travail, on la fusionne à la fin par une pull request, puis on pose l'étiquette.

> **Définition.** Une **étiquette** (*tag*) git est un nom fixe posé sur un commit, par exemple `jour-1`. Contrairement à une branche, elle ne bouge plus : elle marque un état du dépôt auquel on peut toujours revenir.

### Ce que nous avons observé

Le rangement n'a rien cassé : au bloc 1, le jour 1 s'est rejoué à l'identique avec la nouvelle enveloppe. Le déplacement des scripts du jour 1 vers un dossier `sondes/` a été reporté au jour 3, pour ne pas changer les commandes du programme du jour 2 en pleine séance.

### La question posée pendant la séance

*Comment organiser le dépôt pour suivre les jours de travail, l'un après l'autre ?*

En rangeant par fonction et en marquant les jours dans l'historique, pas dans l'arborescence. Les messages de commit étaient déjà bons (`feat:`, `fix:`, `docs:`, un par étape) ; il manquait une règle de rangement, un README et une trace des jours dans git.

### Pièges et bonnes pratiques

- **Fusionner une pull request en « Squash ».** Les commits du jour seraient écrasés en un seul : on perdrait la preuve que le plan a été commité avant les mesures. Il faut un commit de fusion.
- **Réécrire l'historique pour un message inexact.** Le commit `2e91e81` contient les mesures sous le message « docs: écart au plan… » ; on l'a signalé dans le journal plutôt que de réécrire un historique déjà publié.
- **Déplacer des fichiers en pleine séance.** Un déplacement change des chemins et des commandes ; il se fait seul, au début d'un jour, et se valide par rejeu.

> **À retenir.** Ranger par fonction, marquer les jours par des étiquettes, raconter les jours dans le journal. L'historique git est une preuve : on ne l'écrase pas.

### Pour vérifier que vous avez compris

1. Pourquoi des dossiers `jour1/`, `jour2/` casseraient-ils le rejeu ?
2. Pourquoi faut-il fusionner la branche du jour par un commit de fusion, et non en « Squash » ?

### Références

- **Wilson et al. (2017)**, *Good Enough Practices in Scientific Computing* (PLOS Computational Biology) : organiser un projet de recherche, ses données, son code et son suivi, avec des pratiques simples.
- **Ram (2013)**, *Git Can Facilitate Greater Reproducibility and Increased Transparency in Science* (Source Code for Biology and Medicine) : l'historique git comme trace vérifiable d'un travail scientifique.

## Chapitre 3 — Une enveloppe qui tient la charge

### Ce que nous avons fait

- **Retrouver les variables d'environnement.** Le service VS Code de la veille avait été fermé ; les variables, saisies à la main au jour 1, avaient disparu avec lui. Nous les avons rechargées par un bloc qui relit l'adresse du serveur dans `mesures/capacites.json`, pour qu'elle soit identique au caractère près, et qui fait saisir la clé sans l'afficher :

```bash
export LLM_URL="$(python3 -c "import json; print(json.load(open('mesures/capacites.json'))['serveur'])")"
export LLM_MODELE="gemma4-26b-moe"
export LLM_MODELE_EMB="qwen3-embedding-8b"
read -rsp "Clé d'API : " LLM_CLE && export LLM_CLE && echo
```

- **Déposer le paquet du jour 2** à la racine du dépôt, puis lire `git diff llm.py` avant d'accepter la nouvelle enveloppe.
- **Lancer les sept tests** de l'enveloppe, `python3 verifier_enveloppe.py`, sur le vrai serveur.
- **Rejouer le jour 1** avec la nouvelle enveloppe et vérifier que ses relevés ressortent identiques.
- **Commiter** l'enveloppe, ses tests et les trois lignes de journal qu'ils ont produites (commit `73eba0c`).

### Pourquoi cette étape

L'enveloppe de la séance 1 suffisait pour une trentaine d'appels. Le banc en fait six cents, dont certains très longs. Il lui fallait reprendre une campagne interrompue sans refaire les appels réussis, retrouver vite un appel dans un journal qui grossit, ne pas recopier dans le journal des requêtes de plusieurs centaines de milliers de caractères, et respecter les quotas d'un serveur partagé.

Mais toutes les mesures passées reposent sur ce fichier. Le changer sans prouver que le passé se rejoue, ce serait rendre invérifiables les relevés du jour 1. D'où le test de non-régression.

### Comment ça marche

**Les quatre nouveautés de l'enveloppe v2 :**

- **La reprise** (`LLM_MODE=reprise`) relit le journal et ne renvoie au serveur que les appels absents ou tombés sur un refus passager (codes 408, 429, 500, 502, 503 et 504). Relancer une campagne interrompue ne refait pas les appels réussis : l'opération est **idempotente**.
- **L'index du journal** est chargé une fois en mémoire, au lieu de relire tout le fichier à chaque appel.
- **Les requêtes longues sont résumées** dans le journal au-delà de 50 000 caractères : empreinte, taille, début et fin. La clé de l'appel, elle, est calculée sur la requête entière.
- **Le rythme** (`LLM_RYTHME`, en appels par minute) espace les envois.

Ce qui ne change pas : la formule de l'empreinte. Une requête identique donne la même clé qu'au jour 1, donc la même ligne du journal.

> **Définition.** Une opération est **idempotente** si la faire deux fois revient à la faire une fois. Relancer une campagne en mode reprise ne renvoie pas les appels déjà réussis.

**Les sept garanties vérifiées par `verifier_enveloppe.py`, et pourquoi le banc en a besoin :**

1. Même requête, même empreinte, quel que soit l'ordre des champs : sinon le rejeu ne retrouverait pas ses appels.
2. Chaque appel ajoute exactement une ligne au journal, marquée « version 2 » : aucune mesure sans trace.
3. Un refus est journalisé, puis signalé : un échec est une donnée, le banc le compte au lieu de le cacher.
4. Le rejeu redonne la même réponse, sans clé ni réseau : n'importe qui peut refaire le rapport.
5. Rejouer un appel jamais fait échoue clairement : le rejeu n'invente jamais de réponse.
6. La reprise relit au lieu de renvoyer : une campagne interrompue repart sans refaire les appels réussis.
7. Une requête longue est résumée dans le journal, et se rejoue quand même.

Les rejeux des tests 4 à 7 tournent dans un processus séparé, dont la clé a été retirée : c'est ainsi qu'on prouve que le rejeu n'en a pas besoin.

**Le test de non-régression** relance les scripts du jour 1 en mode rejeu, puis compare les relevés réécrits à la version commitée :

```bash
LLM_MODE=rejeu python3 capacites.py > /dev/null
LLM_MODE=rejeu python3 limites.py > /dev/null
git diff --exit-code mesures/ && echo "jour 1 rejoué à l'identique"
```

`LLM_MODE=rejeu`, placé devant une commande, ne vaut que pour elle. `git diff --exit-code` renvoie une erreur à la moindre différence ; le message ne s'affiche que si tout est identique.

### Ce que nous avons observé

Les sept garanties tiennent sur le vrai serveur : `Les sept comportements sont vérifiés.` Le jour 1 se rejoue à l'identique avec l'enveloppe v2.

### Pièges et bonnes pratiques

- **Une variable `export` ne vit que dans son terminal.** Elle disparaît quand on le ferme, et a fortiori avec le service. Un secret Onyxia, injecté au lancement du service, évite de tout retaper.
- **Une clé tapée en clair entre dans l'historique du shell.** `read -rsp` la lit sans l'afficher ni la conserver.
- **Dans un bloc collé, `read` doit être la dernière ligne.** Sinon, il prend la ligne collée suivante pour la clé.
- **Le contrôle de la clé doit porter sur ce qui est réellement préparé.** `git diff --staged | grep -cF "${LLM_CLE:?}"` doit afficher 0 ; le `:?` arrête la commande si la variable est vide, sans quoi le contrôle chercherait une chaîne vide et ne prouverait rien.

> **À retenir.** On ne change pas l'instrument sans prouver que le passé se rejoue. L'enveloppe v2 ajoute la reprise, l'index, le résumé des requêtes longues et le rythme, sans toucher à la formule de l'empreinte.

### Pour vérifier que vous avez compris

1. Pourquoi l'enveloppe v2 n'a-t-elle pas le droit de modifier la formule de l'empreinte ?
2. Pourquoi les rejeux des tests 4 à 7 tournent-ils dans un processus sans la clé ?

### Références

- **Helland (2012)**, *Idempotence Is Not a Medical Condition* (Communications of the ACM) : pourquoi un système qui renvoie des messages doit rendre ses opérations rejouables sans effet double.
- **Feathers (2004)**, *Working Effectively with Legacy Code* (livre, Prentice Hall) : les tests de caractérisation, qui figent le comportement existant avant toute modification.

## Chapitre 4 — Écrire avant de mesurer

### Ce que nous avons fait

Avant le premier appel de la campagne, nous avons complété le plan préenregistré `banc/PLAN.md` (serveur, modèle, nom de la campagne), écrit nos paris sur les résultats, puis commité le tout (commit `028d924`). Pour chaque cas, le plan fixe la question, l'unité d'observation, les conditions, la mesure et la règle de décision.

### Pourquoi cette étape

Trois raisons.

- **Le biais rétrospectif.** Une fois le résultat connu, on a l'impression de l'avoir prévu. Fischhoff (1975) l'a montré expérimentalement : connaître l'issue d'un événement fait surestimer la probabilité qu'on lui aurait donnée avant.
- **Les sentiers qui bifurquent.** Gelman et Loken (2014) montrent qu'un chercheur honnête, sans jamais « pêcher » consciemment, choisit ses seuils et ses comparaisons au vu des données. Avec six cas, quatre conditions et deux langues, on trouve toujours une comparaison qui semble « parler ». Une règle écrite avant la mesure ferme la plupart de ces sentiers.
- **Distinguer prédiction et explication après coup.** Nosek et ses coauteurs (2018) font du préenregistrement l'outil qui sépare la recherche qui teste des hypothèses de celle qui en génère ; les deux sont utiles, mais elles ne se lisent pas de la même façon.

### Comment ça marche

Un pari est **la valeur attendue, écrite avant la collecte**. Il a deux parties : un nombre, et une raison. Le commit le date : `git log` prouvera que le plan et les paris ont précédé la première mesure.

> **Exemple.** Avant de lancer une enquête, une statisticienne écrit : « J'attends 70 % de réponses, parce que l'an dernier on était à 72 % et que la collecte est plus courte. » Elle observe 55 %. L'écart lui dit que quelque chose a changé, et elle cherche quoi. Sans le chiffre écrit d'avance, elle aurait constaté 55 % en se disant « c'est à peu près ça ».

Un bon pari est précis et justifié, même s'il est faux. Sur la stabilité à température 0, « 10 réponses identiques sur 10, parce que le modèle choisit toujours le mot le plus probable » et « 7 sur 10, parce que le serveur regroupe les requêtes et que les arrondis peuvent faire basculer un mot » sont deux bons paris : le résultat dira lequel des deux raisonnements tient. Un pari vague, comme « ce devrait être assez stable », ne peut jamais être démenti, donc n'apprend rien.

### Ce qui m'a posé problème, et ce que j'ai compris

*Cette partie est écrite à la première personne : c'est mon expérience de la séance.*

J'ai eu du mal à comprendre la partie « paris ». La consigne demandait d'écrire mes prédictions, mais les six cas ne m'avaient pas encore été présentés : je ne savais pas sur quoi parier. J'ai cru avoir manqué une étape, et j'ai demandé s'il fallait lire ou lancer quelque chose avant de parier. Rien n'était à lancer, et rien n'était à lire : c'était voulu.

Ce qui m'a débloquée, c'est l'exemple du taux de réponse d'une enquête, puis les deux paris opposés sur la stabilité. J'ai compris que :

- **on parie avant de lancer, de tête**, sans résultat sous les yeux ;
- **un pari est un nombre et une raison** ;
- **un pari vague ne peut pas être démenti**, donc n'apprend rien ;
- **le commit date le pari** et prouve qu'il précède les mesures ;
- **ce qui instruit, c'est l'écart** entre ce que j'attendais et ce qui arrive.

J'ai écrit mes paris pour les cas 1 et 2, puis demandé ceux de Claude pour les six cas. Ils figurent dans le plan, chacun sous le nom de son auteur.

### Ce que nous avons observé

Les paris, confrontés aux résultats (les taux sont détaillés aux chapitres 8 à 13) :

<!-- largeurs: 22,20,26,32 -->
| Cas | Mon pari | Pari de Claude | Résultat |
| --- | --- | --- | --- |
| 1, schéma imposé | 90 % | 100 % | 100 % (50/50) |
| 1, mode JSON | 100 % | 96 % | 100 % (50/50) |
| 1, consigne seule | 90 % | 10 % | 0 % en lecture stricte (0/50) |
| 1, schéma contre consigne | 90 % | 100 % | 100 % (50/50) |
| 2, consignes | 100 % en français et en anglais | 85 % et 80 % | 99/100 et 100/100, hors consigne non mesurable |
| 3, contexte | — | complet jusqu'à 24 000 tokens ; 2 % de pièges | complet jusqu'à 32 000 ; 7 pièges sur 300 codes, tous à 48 000 |
| 4, stabilité | — | 27/30 ; 8/10 ; 1/10 | 30/30 ; 10/10 ; 2/10 |
| 5, outil | — | 50 % ; 100 % | 100 % ; 100 % |
| 6, embeddings | — | 100 % | 100 % (20/20) |

Ma plus grande surprise : la consigne seule, à 0 % en lecture stricte, là où j'attendais 90 %. Mes paris sur les consignes étaient meilleurs que ceux de Claude ; les siens sur la stabilité et sur l'outil étaient faux.

### Pièges et bonnes pratiques

- **Demander des paris avant d'avoir présenté les cas.** On ne peut parier que sur ce qu'on comprend : présenter d'abord chaque cas en une phrase, puis faire parier.
- **Parier par une fourchette ou un adjectif.** « Bien » ne se compare à rien ; « 90 % » se compare.
- **Ajuster une règle après avoir vu les résultats.** Si une règle se révèle mal posée, on le déclare comme un écart au plan, avec sa raison, et on présente les deux lectures.

> **À retenir.** Le plan et les paris s'écrivent avant la première mesure et se datent par un commit. C'est cette date, et non la bonne foi, qui protège la lecture des résultats.

### Pour vérifier que vous avez compris

1. Pourquoi un pari faux mais précis vaut-il mieux qu'un pari juste mais vague ?
2. Qu'est-ce qui prouve, dans le dépôt, que les paris ont été écrits avant les mesures ?

### Références

- **Nosek et al. (2018)**, *The Preregistration Revolution* (PNAS) : ce qu'est un préenregistrement, ce qu'il protège, et comment déclarer les écarts au plan.
- **Gelman et Loken (2014)**, *The Statistical Crisis in Science* (American Scientist) : le « jardin des sentiers qui bifurquent », ou comment des choix faits au vu des données produisent des résultats fragiles.
- **Fischhoff (1975)**, *Hindsight ≠ Foresight* (Journal of Experimental Psychology: Human Perception and Performance) : la démonstration expérimentale du biais rétrospectif.

## Chapitre 5 — La répétition générale

### Ce que nous avons fait

Avant la vraie campagne, nous avons fait tourner tout le banc contre un **faux serveur**, lancé dans un second terminal :

```bash
python3 outils/faux_serveur.py 8765
```

puis, dans le premier terminal :

```bash
NO_PROXY=127.0.0.1 LLM_URL=http://127.0.0.1:8765/v1 LLM_CLE=essai LLM_MODELE=modele-test \
LLM_MODELE_EMB=emb-test LLM_JOURNAL=/tmp/repetition/appels.jsonl \
python3 -m banc --campagne repetition --sortie /tmp/repetition | tail -3
```

Nous avons vérifié le cas 1 du rapport de répétition, puis arrêté le faux serveur.

### Pourquoi cette étape

Pour éprouver toute la chaîne, en quelques secondes et sans un seul appel réel : les 584 essais, les vérificateurs, les statistiques, le rapport. Une erreur de code trouvée là ne coûte rien ; trouvée après six cents vrais appels, elle coûte une campagne, et une partie du quota du jour.

Lancer tout de suite les vraies requêtes aurait mêlé deux incertitudes : on n'aurait pas su si un mauvais taux venait du modèle ou d'un défaut du banc. La répétition générale lève la seconde avant de mesurer la première.

### Comment ça marche

Le faux serveur parle le même protocole que le vrai, mais rend des réponses fabriquées et connues d'avance. Certaines sont fautives exprès : un JSON enveloppé dans une clôture Markdown, une consigne ignorée, une aiguille manquée, un piège choisi. Si le rapport montre bien ces fautes, les vérificateurs savent les détecter. Le faux serveur simule aussi un peu d'instabilité, si bien que seul le cas 4 change d'une répétition à l'autre.

> **Définition.** Un **faux serveur** est une doublure de test : un composant qui imite le vrai, avec un comportement simple et connu, pour tester le reste du système sans lui. Meszaros (2007) range ces doublures en plusieurs familles (bouchons, simulacres, faux) ; la nôtre est un faux, qui fonctionne vraiment mais de façon simplifiée.

Trois précautions dans la commande :

- les variables écrites devant `python3` ne valent que pour cette commande, si bien que les vraies variables restent intactes ;
- `LLM_JOURNAL` et `--sortie` envoient le journal et le rapport dans `/tmp`, hors du dépôt : des chiffres fabriqués ne doivent jamais se mêler aux vraies mesures ;
- `NO_PROXY=127.0.0.1` évite que la requête locale passe par un proxy.

### Ce que nous avons observé

Les chiffres attendus, au caractère près : schéma imposé 50/50, mode JSON 46/50, consigne seule 32/50 en lecture stricte et 45/50 en lecture tolérante, schéma contre consigne 50/50. L'écart sur la consigne seule venait de treize réponses que le faux serveur avait enveloppées dans une clôture : l'analyse stricte attrapait bien ce défaut.

Sa limite est apparue le jour même : **la répétition teste la plomberie, pas le comportement d'un vrai modèle.** Les réponses du faux serveur sont courtes ; elles ne pouvaient pas révéler qu'un plafond de 300 tokens couperait les réponses longues du vrai modèle (chapitre 6).

### Pièges et bonnes pratiques

- **Laisser la répétition écrire dans le vrai journal.** Ses appels fabriqués deviendraient des « preuves ». Journal et rapport vont dans `/tmp`.
- **Croire qu'une répétition réussie valide la mesure.** Elle valide l'instrument sur des réponses connues ; le comportement réel du modèle reste à découvrir.

> **À retenir.** On répète sur un faux serveur pour séparer deux questions : l'instrument fonctionne-t-il ? Que vaut le modèle ? La première se règle gratuitement, avant de payer pour la seconde.

### Pour vérifier que vous avez compris

1. Pourquoi le faux serveur rend-il des réponses fautives exprès ?
2. Pourquoi la répétition générale ne pouvait-elle pas révéler le problème des réponses coupées ?

### Références

- **Meszaros (2007)**, *xUnit Test Patterns: Refactoring Test Code* (livre, Addison-Wesley) : le vocabulaire des doublures de test, dont le faux.
- **Sculley et al. (2015)**, *Hidden Technical Debt in Machine Learning Systems* (NeurIPS) : dans un système d'apprentissage, l'essentiel du risque est dans la plomberie autour du modèle.
- **Biderman et al. (2024)** : tester l'outil d'évaluation lui-même avant de lui confier des conclusions.

## Chapitre 6 — Lancer, surveiller, déclarer un écart

### Ce que nous avons fait

- **Lancer la campagne** en arrière-plan, puis suivre son avancement :

```bash
nohup python3 -m banc --campagne 2026-11-22-gemma4-26b-moe > banc.log 2>&1 &
tail -f banc.log
```

- **Remarquer une anomalie en lisant `banc.log`** : toutes les lignes de la consigne `termine_par` étaient en échec.
- **Regarder les réponses elles-mêmes** dans le journal : elles s'arrêtaient au milieu d'une phrase.
- **Compter les fins de réponse** (`finish_reason`) consigne par consigne.
- **Déclarer l'écart** dans `banc/PLAN.md`, avec ses chiffres, avant d'ouvrir le rapport (commit `c08fb6d`).

### Pourquoi cette étape

Quand une condition échoue à 100 %, la première question n'est pas « le modèle est-il mauvais ? », mais « la réussite était-elle possible ? ». Un instrument peut échouer en silence : chaque vérificateur peut être juste, et une condition de la mesure rendre la réussite impossible.

Une fois le problème vu, deux tentations sont à écarter : corriger le code en silence, ou ignorer la consigne. Le préenregistrement impose une troisième voie : **déclarer l'écart**, avec sa cause et sa preuve, et présenter les deux lectures.

### Comment ça marche

**Le suivi.** `nohup … &` détache le banc du terminal : fermer l'onglet ne l'arrête pas. Chaque ligne de `banc.log` a la forme `[137/584] consignes/en/mots_max/sujet07 : réussi (envoyé)` : le rang de l'essai, le cas, la condition, l'item, l'issue, et « envoyé » au serveur ou « relu » dans le journal.

**Le diagnostic.** Chaque réponse du serveur porte un champ `finish_reason` : `stop` quand le modèle a fini de lui-même, `length` quand le plafond de tokens l'a coupé, `tool_calls` quand il demande un outil (chapitre 12). Les réponses `termine_par` finissaient par `length` : la requête plafonnait la réponse à 300 tokens (`max_tokens=300` dans `banc/cas_consignes.py`), alors que la demande, « Explique… à un lecteur non spécialiste », appelait un long exposé. Le modèle n'atteignait jamais la fin, donc ne pouvait pas écrire « Fin de la réponse. ».

> **Définition.** Un **écart au plan** est un changement, ou un défaut découvert, par rapport à ce qui avait été préenregistré. On le déclare dans le plan, avec sa date, sa cause, sa preuve et la façon dont on lira les résultats.

**La correction, pour plus tard.** On ne peut pas simplement remplacer 300 par 1 500 dans le code : la requête changerait, donc son empreinte, et la campagne du jour ne se rejouerait plus. On ajoutera un paramètre réglable, qui garde 300 par défaut.

**Où sont les résultats.** Une campagne produit trois choses : le rapport lisible, `mesures/<campagne>/rapport_banc.md` ; le détail de chaque essai, `mesures/<campagne>/resultats.json` ; et, dans `journal/appels.jsonl`, chaque requête avec la réponse brute du serveur.

### Ce que nous avons observé

<!-- largeurs: 30,25,45 -->
| Consigne | Réponses coupées | Conséquence pour la mesure |
| --- | --- | --- |
| `termine_par` | 40 sur 40 | non mesurable dans cette campagne |
| `mot_interdit` | 40 sur 40 | vérifiée sur le seul début des réponses |
| `sans_markdown` | 20 sur 40 | même biais, plus faible |
| `commence_par` | 40 sur 40 | sans effet : le début est visible |
| `mots_max`, `liste_trois` | aucune | mesures propres |

L'écart a été écrit dans le plan avant la lecture du rapport, avec ces chiffres.

### La question posée pendant la séance

*Où trouver les résultats de la campagne ?*

Dans `mesures/2026-11-22-gemma4-26b-moe/rapport_banc.md`, à ouvrir dans VS Code avec l'aperçu Markdown (Ctrl+Maj+V) : une section par cas. La confusion venait de l'ordre du programme, qui faisait « comprendre » les cas avant de « lire » leurs résultats. Nous l'avons simplifié : un cas à la fois, on lit sa section du rapport, on l'interprète, on la confronte aux paris. Lire les résultats ne faussait rien : règles et paris étaient datés par un commit depuis la veille.

### Pièges et bonnes pratiques

- **Conclure d'un taux nul sans se demander si la réussite était possible.** Regarder `finish_reason` avant d'accuser le modèle.
- **Coller deux fois un bloc qui écrit un fichier.** Le script de l'écart s'est exécuté deux fois ; son `assert` l'a empêché d'écrire l'écart en double.
- **Préparer des fichiers, puis relancer un bloc de commit.** Les mesures, déjà préparées, sont parties dans le commit `2e91e81` avec un message inexact, et le contrôle de la clé lancé ensuite portait sur une différence vide : il ne prouvait rien. Nous l'avons refait sur tout l'historique : `git log -p | grep -cF "${LLM_CLE:?}"` affiche 0.

> **À retenir.** Devant un 0 %, se demander d'abord si 100 % était possible. Un défaut d'instrument se déclare, avec sa preuve, avant de lire les résultats ; il ne se corrige pas en silence.

### Pour vérifier que vous avez compris

1. Que signifient `stop`, `length` et `tool_calls` dans `finish_reason` ?
2. Pourquoi ne peut-on pas corriger le plafond de 300 tokens directement dans `cas_consignes.py` ?

### Références

- **Georges, Buytaert et Eeckhout (2007)**, *Statistically Rigorous Java Performance Evaluation* (OOPSLA) : une mesure de performance n'est fiable que si l'on contrôle et déclare ses conditions.
- **Biderman et al. (2024)** : des détails d'exécution, comme le plafond de tokens ou le format de requête, suffisent à changer un résultat d'évaluation.

## Chapitre 7 — Lire un taux

### Ce que nous avons fait

Chaque taux du rapport s'écrit `k/n (pourcentage) [intervalle de Wilson à 95 %]`. Quand aucun échec n'est observé, le banc donne aussi la borne exacte du taux d'échec. Quand deux conditions portent sur les mêmes items, il les compare par un test exact de McNemar. Et l'unité de compte est toujours l'**essai**, jamais un morceau d'essai.

### Pourquoi cette étape

Nos échantillons sont petits : de dix à cinquante essais par condition. À cette taille, un pourcentage seul trompe : 10/10 et 50/50 affichent tous deux 100 %, mais ne disent pas du tout la même chose. Et la formule d'intervalle la plus enseignée échoue précisément dans nos cas, quand le taux est proche de 0 ou de 100 %.

### Comment ça marche

**L'intervalle de Wilson.** La formule « classique », dite de Wald, calcule l'écart-type avec le taux observé p̂ : quand p̂ = 100 %, il vaut zéro, et l'intervalle s'écrase. Wilson (1927) calcule l'écart-type avec le vrai taux p que l'on teste, et garde tous les p pour lesquels l'observation ne serait pas surprenante. On obtient une inéquation du second degré en p, dont les racines sont les bornes.

> **Formule.** Avec k succès sur n essais et z = 1,96 pour 95 % : centre = (k + z²/2) / (n + z²) ; demi-largeur = z / (1 + z²/n) × √( p̂(1 − p̂)/n + z²/(4n²) ). Comme z² ≈ 4, le centre vaut à peu près (k + 2)/(n + 4) : c'est comme si l'on ajoutait deux succès et deux échecs fictifs.

<!-- largeurs: 22,39,39 -->
| Observé | Wald | Wilson |
| --- | --- | --- |
| 47/50 | [87,4 % ; 100,6 %] | [83,8 % ; 97,9 %] |
| 50/50 | [100 % ; 100 %] | [92,9 % ; 100 %] |
| 19/20 | [85,4 % ; 104,6 %] | [76,4 % ; 99,1 %] |

Wald sort de l'intervalle [0 ; 1] ou s'écrase à zéro ; Wilson reste dans les bornes et devient asymétrique près des bords, comme l'incertitude réelle. Brown, Cai et DasGupta (2001) ont montré que la couverture réelle de Wald peut tomber bien sous 95 %, et recommandent Wilson pour les petits échantillons.

**La borne sans échec, ou règle de trois.** Si aucun échec n'est observé sur n essais, le taux d'échec est, au risque de 5 %, inférieur à 1 − 0,05^(1/n), soit à peu près 3/n. Hanley et Lippman-Hand (1983) l'ont popularisée sous le titre « si rien ne va mal, tout va-t-il bien ? ».

<!-- largeurs: 50,50 -->
| Essais sans échec | Le taux d'échec est probablement inférieur à |
| --- | --- |
| 10 | 25,9 % |
| 20 | 13,9 % |
| 30 | 9,5 % |
| 50 | 5,8 % |

Ces bornes sont calculées par la fonction `borne_sans_echec` de `banc/stats.py`.

**Le test exact de McNemar.** Quand deux conditions portent sur les mêmes items, chaque item sert de témoin à lui-même. Seules comptent les paires discordantes : b items où seule la première condition réussit, c où seule la seconde réussit. Sous l'hypothèse d'aucune différence, b suit une loi binomiale de paramètres b + c et ½. C'est plus puissant que de comparer deux taux indépendants (McNemar, 1947).

**L'unité d'observation.** Les six aiguilles d'un même essai du cas 3 partagent le même texte : elles ne sont pas indépendantes. Les compter comme 60 observations donnerait des intervalles faussement étroits. Hurlbert (1984) a nommé cette erreur la **pseudo-réplication**.

### La question posée pendant la séance

*Qu'est-ce que l'intervalle de Wilson ?*

Une fourchette d'incertitude autour d'un taux observé : après 47 réponses valides sur 50, quelles valeurs du vrai taux restent plausibles ? Le banc l'affiche à 95 % pour chaque taux. On le préfère à la formule de Wald parce qu'il reste juste quand l'échantillon est petit et le taux proche de 0 ou de 100 %, ce qui est exactement notre situation.

### Ce que nous avons observé

Ces outils ont changé la lecture du rapport. La consigne `mots_max`, à 19/20 en français, passe pile le seuil de la règle (19 sur 20), mais son intervalle va de 76,4 % à 99,1 % : avec 20 essais, on ne distingue pas 95 % de 80 %. Et chaque 100 % du rapport s'est lu avec sa borne : dix essais sans échec laissent un taux d'échec possible d'un quart.

### Pièges et bonnes pratiques

- **Lire 100 % comme une certitude.** C'est une absence d'échec observé, bornée par la règle de trois.
- **Comparer deux conditions par le chevauchement de leurs intervalles.** Sur les mêmes items, c'est le test de McNemar qui tranche.
- **Compter comme indépendantes des observations qui ne le sont pas.** L'unité est l'essai.

> **À retenir.** Un taux se lit avec son n et son intervalle de Wilson. Zéro échec sur n essais ne prouve qu'une borne, d'environ 3/n. Deux conditions sur les mêmes items se comparent par McNemar, sur les seules paires discordantes.

### Pour vérifier que vous avez compris

1. Pourquoi l'intervalle de Wald donne-t-il [100 % ; 100 %] pour 50/50, et que donne Wilson ?
2. Pourquoi l'unité du cas 3 est-elle l'essai, et non l'aiguille ?

### Références

- **Wilson (1927)**, *Probable Inference, the Law of Succession, and Statistical Inference* (Journal of the American Statistical Association) : l'article d'origine de l'intervalle.
- **Brown, Cai et DasGupta (2001)**, *Interval Estimation for a Binomial Proportion* (Statistical Science) : pourquoi Wald échoue et quels intervalles le remplacent.
- **Hanley et Lippman-Hand (1983)**, *If Nothing Goes Wrong, Is Everything All Right?* (JAMA) : la règle de trois.
- **McNemar (1947)**, *Note on the Sampling Error of the Difference Between Correlated Proportions or Percentages* (Psychometrika) : le test des proportions appariées.
- **Hurlbert (1984)**, *Pseudoreplication and the Design of Ecological Field Experiments* (Ecological Monographs) : l'erreur qui consiste à compter des observations dépendantes comme indépendantes.

## Chapitre 8 — Cas 1 : la forme JSON

### Ce que nous avons fait

Le banc a demandé 50 fois au modèle de remplir une fiche JSON décrivant une source statistique : producteur, thème, périodicité parmi trois valeurs, et de un à trois indicateurs avec leur unité. La même source passe dans quatre conditions :

- **`impose`** : le serveur impose le schéma (`response_format` de type `json_schema`, `strict`) ;
- **`objet`** : le serveur garantit un JSON valide, sans vérifier les champs ;
- **`consigne`** : le schéma figure seulement dans le texte de la demande ;
- **`impose_contre`** : le schéma est imposé, mais la consigne dit « ignore le schéma, réponds par une phrase ».

### Pourquoi cette étape

L'agent produira sans arrêt des objets structurés : fiches de spécification, entrées du registre de faits, plans. Dans un graphe d'états, chaque nœud passe son résultat au suivant ; un JSON mal formé casse la chaîne, ou force une boucle de réparation. Ce cas prépare la décision 1 de l'ADR : confier la forme au serveur, ou à la consigne avec validation et reprises.

### Comment ça marche

Avec `impose`, le serveur applique un **décodage contraint** : à chaque token, il interdit ceux qui sortiraient du schéma. Willard et Louf (2023) ont montré comment le faire efficacement, en compilant le schéma en automate. La forme est alors garantie, pas le fond : une valeur permise peut être fausse.

`impose_contre` distingue deux explications d'un JSON conforme : le modèle obéit, ou le serveur le contraint. Si la contrainte est réelle, une consigne contraire ne peut pas l'emporter.

Dans `banc/cas_json.py`, `diagnostic()` décide du succès : en **lecture stricte**, le texte entier doit être du JSON, et une simple clôture ```json suffit à échouer ; en **lecture tolérante**, on retire d'abord la clôture. Puis `valider()` contrôle le schéma : types, champs obligatoires, valeurs permises, aucun champ en trop. En cas d'échec, `mesurer()` fait jusqu'à deux reprises, en renvoyant au modèle son écart. Le succès retenu est la lecture stricte au premier essai.

> **Définition.** Le **décodage contraint** restreint, à chaque étape de la génération, les tokens que le modèle peut produire, pour que la sortie respecte une grammaire ou un schéma.

### Ce que nous avons observé

<!-- largeurs: 22,26,26,26 -->
| Condition | Premier essai (strict) | Lecture tolérante | Après deux reprises |
| --- | --- | --- | --- |
| `impose` | 50/50 [92,9 % ; 100 %] | 50/50 | 50/50 |
| `objet` | 50/50 [92,9 % ; 100 %] | 50/50 | 50/50 |
| `consigne` | 0/50 [0 % ; 7,1 %] | 50/50 | 0/50 |
| `impose_contre` | 50/50 [92,9 % ; 100 %] | 50/50 | — |

- Le schéma imposé l'emporte sur une consigne contraire 50 fois sur 50 : **le serveur impose réellement la forme**.
- Sans contrainte, le modèle a enveloppé son JSON dans une clôture Markdown **les 50 fois**, et l'a gardée malgré deux reprises signalant l'erreur. Le JSON à l'intérieur était juste à chaque fois (50/50 en lecture tolérante).
- `impose` contre `consigne`, sur les mêmes sources : 50 paires où seul `impose` réussit, aucune à l'inverse, p < 0,001.
- Aucun échec sur 50 essais avec le schéma imposé : le taux d'échec est inférieur à 5,8 %. La règle du plan demande 300 appels pour descendre sous 1 %.

Ces résultats rejoignent la littérature : JSONSchemaBench (Geng et al., 2025) évalue les moteurs de décodage contraint et montre qu'ils garantissent la conformité sur les schémas qu'ils couvrent, mais pas tous les schémas.

### Pièges et bonnes pratiques

- **Croire que la contrainte garantit le fond.** Elle garantit la forme ; un validateur dans le code reste nécessaire.
- **Compter sur les reprises pour corriger une habitude.** Le modèle a gardé sa clôture après deux reprises : 0/50.
- **Supposer qu'un nouveau serveur impose le schéma.** Le test `impose_contre` le vérifie en une campagne.
- **Contraindre la forme d'un raisonnement.** Tam et ses coauteurs (2024) observent qu'imposer un format peut dégrader le raisonnement : on contraint la sortie finale, pas la réflexion.

> **À retenir.** Le schéma imposé par le serveur a donné 50/50, même contre une consigne contraire ; la consigne seule, 0/50 en lecture stricte, à cause d'une clôture Markdown systématique. Décision : imposer le schéma, valider le fond dans le code.

### Pour vérifier que vous avez compris

1. Que prouve `impose_contre` que `impose` seul ne prouve pas ?
2. Pourquoi la consigne seule obtient-elle 0/50 en lecture stricte et 50/50 en lecture tolérante ?

### Références

- **Willard et Louf (2023)**, *Efficient Guided Generation for Large Language Models* (prépublication arXiv) : le décodage contraint par automate.
- **Geng et al. (2025)**, *JSONSchemaBench: A Rigorous Benchmark of Structured Outputs for Language Models* (prépublication arXiv) : ce que les moteurs de décodage contraint garantissent, et sur quels schémas.
- **Tam et al. (2024)**, *Let Me Speak Freely? A Study on the Impact of Format Restrictions on Performance of Large Language Models* (EMNLP, Industry Track) : le coût possible d'un format imposé sur le raisonnement.

## Chapitre 9 — Cas 2 : les consignes et la validité d'un test

### Ce que nous avons fait

Six consignes de forme, chacune vérifiable par une ligne de code : pas de Markdown ; 40 mots au plus ; commencer par « En résumé, » ; finir par « Fin de la réponse. » ; ne jamais écrire « données » ; exactement trois lignes commençant par « - ». Chaque consigne est testée sur 20 sujets, rédigée une fois en français et une fois en anglais, soit 240 essais. La consigne est placée dans le message système ; la demande est « Explique [sujet] à un lecteur non spécialiste. » ; la réponse doit être en français dans les deux cas.

### Pourquoi cette étape

Pour savoir quelles consignes on peut confier au modèle et lesquelles le code doit vérifier, et si la langue de la consigne compte. Le cas prépare la décision 3 de l'ADR. La règle du plan : toute consigne respectée moins de 19 fois sur 20 est reformulée, ou confiée au code.

### Comment ça marche

La méthode vient d'IFEval (Zhou et al., 2023) : des consignes vérifiables par du code, pour que le succès d'un essai ne dépende ni d'un relecteur humain ni d'un autre modèle. Dans `banc/verifs.py`, le dictionnaire `CONSIGNES` associe à chaque consigne son vérificateur. Dans `banc/cas_consignes.py`, le succès exige le vérificateur **et** une réponse en français : sans cette seconde condition, une réponse en anglais pourrait réussir une consigne par accident. Chaque couple (consigne, sujet) passe dans les deux langues : c'est un plan apparié, comparé par McNemar.

### Ce que nous avons observé

<!-- largeurs: 28,24,24,24 -->
| Consigne | En français | En anglais | Réponses terminées (fr / en) |
| --- | --- | --- | --- |
| `sans_markdown` | 20/20 | 20/20 | 5/5 et 15/15 |
| `mots_max` | 19/20 [76,4 % ; 99,1 %] | 20/20 | 19/20 et 20/20 |
| `commence_par` | 20/20 | 20/20 | aucune, sans effet |
| `termine_par` | 0/20 | 0/20 | aucune : non mesurable |
| `mot_interdit` | 20/20 | 20/20 | aucune : non conclusif |
| `liste_trois` | 20/20 | 20/20 | 20/20 et 20/20 |

- **La langue ne change rien** : sur 120 paires, aucune où seul le français réussit, une seule où seul l'anglais réussit, p = 1. Aucune réponse n'a été rédigée en anglais.
- **`termine_par` n'est pas mesurable** : ses 40 réponses ont été coupées par le plafond de 300 tokens (chapitre 6).
- **La seconde lecture**, sur les seules réponses terminées, est calculée par `outils/lecture_terminees.py`. Elle confirme les mesures propres et montre ce qui reste à vérifier.
- Une observation, pas une conclusion, car ce n'était pas une mesure prévue : avec `sans_markdown`, 15 réponses ont été coupées sous la consigne française, contre 5 sous l'anglaise.

### La question posée pendant la séance

*Ce cas mesure-t-il ce qui compte ? Ses consignes sont génériques : rien n'y est propre à une publication EcoDef.*

C'est une critique de **validité** : le cas mesure l'obéissance à des consignes génériques, pas aux consignes que l'agent recevra pour rédiger une publication statistique. Un taux sur « commence par En résumé » ne dit presque rien de ce qui importe. Raji et ses coauteurs (2021) font la même critique à l'échelle des grands benchmarks.

Décision : boucler le jour 2 en lisant ce cas avec ses deux limites, puis le refaire au début du jour 3 avec des **consignes de rédaction d'EcoDef**, toujours vérifiables par du code, sur une petite fiche de faits publics tirée de l'EcoDef n° 273 :

- aucun chiffre absent de la fiche, consigne centrale puisque c'est la règle du projet ;
- chaque chiffre suivi de son identifiant de registre ;
- les montants en Md€, avec une décimale ;
- les évolutions avec leur signe ;
- le vocabulaire de la publication ;
- une ligne finale « Source : EcoDef Statistiques n° 273. ».

Le nouveau cas aura son propre fichier, pour que la campagne du 22 novembre reste rejouable, sa section de plan et ses paris commités avant le lancement, un plafond de tokens suffisant et `finish_reason` enregistré. Ses consignes viendront de ce que n'importe qui peut lire dans les EcoDef publiés.

### Pièges et bonnes pratiques

- **Mesurer des tâches qui ne sont pas les siennes.** Un test ne vaut que pour la tâche qu'il imite.
- **Lire une consigne coupée comme une consigne ignorée.** `finish_reason` d'abord.
- **Trancher sur 20 essais un taux proche du seuil.** 19/20 a pour intervalle [76,4 % ; 99,1 %].
- **Négliger la formulation.** Sclar et ses coauteurs (2024) montrent que des détails de mise en forme de la demande, sans rapport avec la tâche, font varier fortement les résultats : une consigne se teste sous la forme exacte où l'agent la recevra.

> **À retenir.** Hors `termine_par`, non mesurable, les consignes sont respectées 99 fois sur 100 en français et 100 fois sur 100 en anglais, sans différence de langue ; `mot_interdit` n'est vérifiée que sur le début des réponses. Surtout, ces consignes ne sont pas celles de l'agent : la décision 3 reste provisoire jusqu'au cas EcoDef du jour 3.

### Pour vérifier que vous avez compris

1. Pourquoi le succès exige-t-il, en plus du vérificateur, une réponse en français ?
2. Qu'est-ce qui rend le cas 2 peu valide pour l'agent, et comment le jour 3 y remédiera-t-il ?

### Références

- **Zhou et al. (2023)**, *Instruction-Following Evaluation for Large Language Models* (prépublication arXiv) : les consignes vérifiables par code, méthode d'IFEval.
- **Sclar et al. (2024)**, *Quantifying Language Models' Sensitivity to Spurious Features in Prompt Design* (ICLR) : la sensibilité des modèles à la forme de la demande.
- **Raji et al. (2021)** : un test ne mesure que ce que ses tâches représentent.

## Chapitre 10 — Cas 3 : les aiguilles et les pièges

### Ce que nous avons fait

Le banc a fabriqué un long texte de remplissage, de 8 000 à 48 000 tokens selon les essais. Il y a caché six codes, du type « Le code actuel de l'armoire A est 4817 », à 5 %, 23 %, 41 %, 59 %, 77 % et 95 % de la longueur du texte, et six pièges : « L'ancien code de l'armoire A, abandonné, était 4871 », avec deux chiffres inversés. Puis il a demandé les six codes actuels. Dix essais par taille.

### Pourquoi cette étape

L'agent lira de longs documents et devra en tirer des nombres exacts. Or les vrais documents contiennent des nombres qui se ressemblent : le chiffre de l'an dernier, une valeur révisée. Le cas prépare la décision 2 de l'ADR : le **budget de contexte**, la quantité de texte confiée au modèle en une fois. La règle du plan : la plus grande taille où tous les essais sont complets.

### Comment ça marche

Un essai est **complet** si les six codes rendus sont justes. Le rapport compte aussi les aiguilles retrouvées à chaque profondeur, et les pièges choisis. L'unité de compte est l'essai (chapitre 7). Le piège teste la lecture du contexte : la phrase « ancien code, abandonné » le distingue clairement du code actuel, pour qui lit vraiment.

### Ce que nous avons observé

<!-- largeurs: 26,26,24,24 -->
| Tokens visés | Essais complets | Aiguilles manquées | Pièges choisis |
| --- | --- | --- | --- |
| 8 000 à 32 000 | 10/10 à chaque taille [72,2 % ; 100 %] | aucune | 0 sur 60 à chaque taille |
| 48 000 | 5/10 [23,7 % ; 76,3 %] | 4 à 77 %, 3 à 95 % | 7 sur 60 |

- Le modèle tient jusqu'à 32 000 tokens, et décroche à 48 000, uniquement en fin de texte.
- **Les sept codes manqués sont sept pièges choisis.** Le modèle n'a jamais répondu « je ne sais pas » : il a rendu l'ancien code abandonné, un nombre plausible et faux.
- Le jour 1, un code isolé avait été retrouvé à 52 697 tokens ; avec six codes et six pièges, le modèle échoue dès 48 000. C'est ce que montre RULER (Hsieh et al., 2024) : le contexte réellement utilisable est bien plus court que celui annoncé, surtout quand la tâche demande plusieurs informations à la fois.
- La règle donne un budget de 32 000 tokens. Mais dix essais sans échec bornent seulement le taux d'échec à 25,9 %.

### Pièges et bonnes pratiques

- **Juger une fenêtre de contexte sur une seule aiguille.** Elle surestime ce que le modèle exploite vraiment.
- **Croire qu'une erreur de lecture se voit.** Elle prend ici la forme d'un nombre plausible : seule une vérification par le code contre la source la détecte.
- **Tirer une loi de position de dix essais.** Liu et ses coauteurs (2024) ont décrit des pertes d'information au milieu des longs contextes ; nos erreurs se concentrent en fin de texte, à 48 000 tokens, mais dix essais ne suffisent pas à établir une règle de position.

> **À retenir.** Complet jusqu'à 32 000 tokens, une fois sur deux à 48 000 ; et chaque erreur était un piège. Budget retenu : 24 000 tokens, une taille de marge sous la valeur de la règle, et tout nombre extrait est contrôlé contre sa source.

### Pour vérifier que vous avez compris

1. Pourquoi les pièges ont-ils deux chiffres inversés, et pourquoi sont-ils annoncés comme « anciens » ?
2. Pourquoi l'erreur observée à 48 000 tokens est-elle plus dangereuse qu'un « je ne sais pas » ?

### Références

- **Hsieh et al. (2024)**, *RULER: What's the Real Context Size of Your Long-Context Language Models?* (COLM) : la taille de contexte réellement utilisable, mesurée sur des tâches à plusieurs aiguilles.
- **Liu et al. (2024)**, *Lost in the Middle: How Language Models Use Long Contexts* (Transactions of the ACL) : l'information placée au milieu d'un long contexte est moins bien exploitée.

## Chapitre 11 — Cas 4 : la stabilité

### Ce que nous avons fait

Trois requêtes à température 0, chacune répétée 10 fois : une définition en deux phrases, un résumé en une phrase, une fiche JSON. Puis une demande d'inventer un nom de ville à température 1, répétée 10 fois avec la graine 42, et 10 fois avec les graines 1 à 10.

### Pourquoi cette étape

Si l'on relance l'agent sur la même question, obtient-on le même texte ? C'est indispensable pour expliquer une publication (« pourquoi la note d'aujourd'hui diffère-t-elle de celle d'hier ? ») et pour tester l'agent : un test qui compare des sorties exige qu'elles soient stables.

### Comment ça marche

Pour chaque série, le banc compte combien de réponses sont identiques à la réponse la plus fréquente, et combien de réponses distinctes il obtient. La série « graines 1 à 10 » est le **témoin** : sans elle, « graine 42, dix fois la même réponse » ne prouverait rien, car le modèle pourrait simplement répondre toujours la même chose à cette demande.

D'où vient l'instabilité, même à température 0 ? Un serveur regroupe les requêtes par lots, et l'ordre des calculs en virgule flottante dépend de la taille du lot : les arrondis changent, et un mot peut basculer. He et Thinking Machines Lab (2025) ont décrit ce mécanisme et montré comment l'éliminer.

### Ce que nous avons observé

- À température 0 : 30 réponses identiques sur 30 [88,6 % ; 100 %], une seule réponse par requête.
- Graine 42 à température 1 : 10/10 identiques.
- Graines 1 à 10 : 9 réponses distinctes sur 10. Le hasard est bien là, et c'est la graine qui le fixe.
- Prudence : 30/30 laisse un taux d'instabilité possible de 9,5 %, et ce résultat vaut pour un dimanche après-midi, sur des réponses courtes, sur un serveur sans doute peu chargé. Ouyang et ses coauteurs (2023) ont mesuré, sur des tâches de génération de code, une non-reproductibilité forte : elle dépend de la tâche, de la longueur et des réglages.

### Pièges et bonnes pratiques

- **Reproduire un résultat publié en relançant le modèle.** On le relit dans le journal.
- **Croire qu'une graine fixe tout.** Elle fixe le tirage aléatoire, pas les arrondis d'un serveur chargé.
- **Oublier le témoin.** Sans les graines 1 à 10, la stabilité observée avec la graine 42 ne se distinguerait pas d'une réponse toujours identique.

> **À retenir.** Ce jour-là, le modèle a été parfaitement stable : 30/30 à température 0, 10/10 avec la graine 42. Règle retenue : température 0 et graine fixe pour tester l'agent ; seul le journal garantit qu'on retrouve une réponse.

### Pour vérifier que vous avez compris

1. À quoi sert la série « graines 1 à 10 » ?
2. Pourquoi une réponse peut-elle changer à température 0 ?

### Références

- **He et Thinking Machines Lab (2025)**, *Defeating Nondeterminism in LLM Inference* (billet technique) : l'origine de l'instabilité à température 0 dans les serveurs, et la façon de l'éliminer.
- **Ouyang et al. (2023)**, *LLM is Like a Box of Chocolates: the Non-determinism of ChatGPT in Code Generation* (prépublication arXiv, publiée ensuite dans ACM TOSEM) : une mesure de la non-reproductibilité sur des tâches de code.

## Chapitre 12 — Cas 5 : l'appel d'outils

### Ce que nous avons fait

Vingt questions qui appellent un chiffre : dix populations de villes et dix statistiques nationales. Le modèle dispose d'un seul outil, `consulter_registre`, décrit ainsi : « Renvoie la valeur sourcée d'un chiffre ». Les mêmes questions passent sans consigne, puis avec la consigne « Pour tout chiffre, appelle l'outil consulter_registre ; ne donne jamais un chiffre de mémoire ».

### Pourquoi cette étape

C'est le test de la règle du projet : le modèle va-t-il chercher le registre de lui-même, ou cite-t-il un chiffre de mémoire ? Le cas prépare la décision 4 de l'ADR. La règle du plan : sous 95 % d'appels spontanés, c'est le code qui décide quand consulter le registre.

### Comment ça marche

Le modèle n'exécute jamais rien lui-même. La requête décrit l'outil : son nom, son rôle, l'argument attendu. Si le modèle juge qu'il en a besoin, il ne répond pas par du texte : il renvoie une **demande d'appel**, un objet `tool_calls` qui contient le nom de la fonction et ses arguments en JSON, et `finish_reason` vaut `tool_calls`. C'est au programme d'exécuter la fonction et de renvoyer le résultat au modèle, qui rédige alors sa réponse finale.

question → modèle → demande d'appel → le code exécute → résultat → modèle → réponse

Dans `banc/cas_outil.py`, la requête part avec `tool_choice="auto"` : le modèle est libre d'appeler l'outil ou non, sans quoi on ne mesurerait rien de spontané. `classer()` lit le champ `tool_calls` : appel correct si la fonction est bien `consulter_registre` et que l'argument est un JSON valide contenant une `description` ; appel mal formé sinon ; sans demande d'appel, « chiffre de mémoire » si le texte contient un chiffre, « sans chiffre » sinon.

### Ce que nous avons observé

- 20 appels corrects sur 20, sans consigne comme avec [83,9 % ; 100 %] ; aucun appel mal formé, aucun chiffre de mémoire.
- La consigne ne change rien : p = 1. Selon la règle, le modèle peut décider quand consulter le registre.
- Une preuve, tirée du journal : à la question « Combien d'habitants compte Lyon ? », sans consigne, la réponse ne contient aucun texte, `finish_reason` vaut `tool_calls`, et la demande d'appel est `consulter_registre({"description": "nombre d'habitants de la ville de Lyon"})`.
- Prudence : vingt appels sans oubli bornent seulement le taux d'oubli à 13,9 %, sur des questions simples avec un seul outil, dont la description parle explicitement de chiffres.

### La question posée pendant la séance

*Comment s'assurer que l'outil a bien été appelé, puis utilisé ? Et comment le code le vérifie-t-il ?*

« Appelé », oui : le journal garde la réponse brute du serveur, avec sa demande d'appel, et chacun peut la relire. « Utilisé », non : le banc s'arrête à la demande d'appel. Il n'y a pas de vrai registre derrière l'outil ; le banc ne l'exécute jamais et ne renvoie aucun résultat au modèle. Il mesure la décision d'appeler et la forme de la demande, pas ce que le modèle fait du chiffre renvoyé : le recopie-t-il exactement, l'arrondit-il, le mélange-t-il avec un chiffre de mémoire ? Deux garde-fous couvrent cette seconde moitié : le contrôle par le code de chaque nombre du texte contre le registre, et le cas EcoDef du jour 3, dont la fiche de faits jouera le rôle du registre.

### Pièges et bonnes pratiques

- **Confondre demande d'appel et usage du résultat.** Ce sont deux mesures distinctes.
- **Forcer l'appel pour mesurer la spontanéité.** Avec `tool_choice="required"`, le serveur impose l'appel et le taux ne dit plus rien du modèle.
- **Confier une règle non négociable à un taux.** Même à 100 %, le contrôle des nombres reste dans le code. Huang et ses coauteurs (2024) montrent que décider *s'il faut* utiliser un outil reste un point faible des modèles.

> **À retenir.** Le modèle a demandé l'outil vingt fois sur vingt, avec ou sans consigne. Décision : il décide quand consulter le registre, et le code contrôle chaque nombre du texte final. Ce que le modèle fait du résultat reste à mesurer.

### Pour vérifier que vous avez compris

1. Que contient une demande d'appel, et qui exécute la fonction ?
2. Pourquoi le banc ne mesure-t-il pas l'usage du résultat ?

### Références

- **Schick et al. (2023)**, *Toolformer: Language Models Can Teach Themselves to Use Tools* (NeurIPS) : comment un modèle apprend à insérer des appels d'outils dans sa génération.
- **Huang et al. (2024)**, *MetaTool Benchmark for Large Language Models: Deciding Whether to Use Tools and Which to Use* (ICLR) : décider s'il faut un outil, et lequel.

## Chapitre 13 — Cas 6 : les embeddings et les nombres

### Ce que nous avons fait

Vingt phrases inventées, tirées avec une graine fixe, du type « En 2024, la région a versé 80,5 millions d'euros aux associations. ». Pour chacune, le banc compare trois variantes à la phrase de départ : une paraphrase, avec le même montant et d'autres mots ; la même phrase où seul le nombre change ; une phrase hors sujet. Les phrases et les montants sont inventés : aucun n'est une statistique.

### Pourquoi cette étape

La recherche par le sens servira à retrouver des passages dans des documents. La question est de savoir si elle distingue deux passages qui ne diffèrent que par leurs chiffres, comme une valeur provisoire et une valeur révisée.

### Comment ça marche

Un modèle d'embeddings, ici `qwen3-embedding-8b`, transforme une phrase en un vecteur de 4 096 nombres. Deux phrases de sens proche donnent des vecteurs proches ; on mesure leur proximité par le **cosinus** de l'angle entre les vecteurs : 1 pour deux vecteurs de même direction, 0 pour deux vecteurs sans rapport. Reimers et Gurevych (2019) ont popularisé cette façon de comparer des phrases.

> **Définition.** Un **embedding** est la représentation d'un texte par un vecteur de nombres, construite pour que des textes de sens proche aient des vecteurs proches.

### Ce que nous avons observé

- Cosinus médians avec la phrase de départ : 0,990 pour la phrase au montant changé, 0,942 pour la paraphrase, 0,144 pour le hors-sujet.
- Dans 20 triplets sur 20 [83,9 % ; 100 %], changer le montant déplace moins le vecteur que reformuler la phrase.
- Pour le vecteur, « 80,5 millions » et « 21,6 millions » font presque la même phrase : il voit les mots et la structure, à peine les nombres. Wallace et ses coauteurs (2019) et Thawani et ses coauteurs (2021) ont documenté cette faible représentation des nombres.
- Limite : vingt phrases d'un seul gabarit. L'écart est net et va toujours dans le même sens, mais c'est un constat qui appuie une règle, pas une étude complète.

### Pièges et bonnes pratiques

- **Rapprocher des chiffres par la recherche par le sens.** Deux passages qui ne diffèrent que par leurs nombres obtiennent un score excellent, le bon comme le mauvais.
- **Lire un cosinus élevé comme une égalité de contenu.** Il dit « même sujet, même tournure », pas « mêmes chiffres ».

> **À retenir.** La recherche par le sens trouve où chercher ; les chiffres passent par le registre, rapprochés et contrôlés par le code.

### Pour vérifier que vous avez compris

1. Pourquoi la phrase au montant changé est-elle plus proche que la paraphrase ?
2. Quel risque cela fait-il courir à un agent qui chercherait des chiffres par le sens ?

### Références

- **Reimers et Gurevych (2019)**, *Sentence-BERT: Sentence Embeddings using Siamese BERT-Networks* (EMNLP) : des embeddings de phrases comparables par le cosinus.
- **Wallace et al. (2019)**, *Do NLP Models Know Numbers? Probing Numeracy in Embeddings* (EMNLP) : ce que les embeddings retiennent, ou non, des nombres.
- **Thawani et al. (2021)**, *Representing Numbers in NLP: a Survey and a Vision* (NAACL) : un état des lieux de la représentation des nombres.

## Chapitre 14 — L'ADR-001

### Ce que nous avons fait

Nous avons transformé les six lectures du rapport en un enregistrement de décisions d'architecture, `docs/adr/0001-decisions-du-banc.md` : quatre décisions et deux règles transversales, chacune avec ses options, ses preuves et ses conséquences. Statut : accepté pour le laboratoire ; la décision 3 est provisoire.

### Pourquoi cette étape

Dans six mois, on aura oublié pourquoi l'agent impose un schéma, pourquoi il découpe ses documents, pourquoi il fait contrôler chaque nombre par le code. Sans trace, on rediscutera ces choix, ou on les défera sans savoir ce qu'ils protégeaient. Tyree et Akerman (2005) font des décisions d'architecture des objets à documenter en tant que tels, avec leurs options écartées ; Nygard (2011) en a donné la forme courte que nous utilisons.

### Comment ça marche

> **Définition.** Un **ADR** (*Architecture Decision Record*) est un court document qui consigne une décision d'architecture : son contexte, les options envisagées, la décision, ses preuves, ses conséquences, ce qu'elle ne garantit pas et quand la revoir.

Une décision bien écrite tient en une phrase à l'indicatif, qu'on peut vérifier dans le code ; ses preuves sont copiées du rapport, jamais citées de mémoire ; ses conséquences disent aussi ce qu'elle coûte.

### Ce que nous avons décidé

1. **Sortie structurée.** Toute sortie structurée du modèle passe par un schéma imposé par le serveur, puis par une validation du côté du code. Preuves : schéma imposé 50/50, même contre une consigne contraire ; consigne seule 0/50 en lecture stricte. Avant la production, 300 appels pour descendre sous 1 % d'échec.
2. **Budget de contexte.** Chaque appel reçoit au plus **24 000 tokens** ; au-delà, le code découpe les documents. La règle du plan donnait 32 000 tokens ; nous gardons une marge d'une taille, parce que dix essais sans échec bornent seulement le taux d'échec à 25,9 % et qu'au-delà du budget les erreurs sont des nombres plausibles et faux. 32 000 reste la limite haute, à atteindre après une campagne plus longue.
3. **Langue des consignes, provisoire.** Les consignes de l'agent sont rédigées en français : aucune différence mesurée entre les langues, et des réponses toujours en français. À confirmer par le cas EcoDef du jour 3.
4. **Appel d'outils.** Le modèle décide quand consulter le registre (`tool_choice` à `auto`) ; le code contrôle chaque nombre du texte final contre le registre, quel que soit le taux d'appel.

Et deux règles transversales :

- **Reproductibilité** : température 0 et graine fixe pour tester l'agent ; seul le journal garantit qu'on retrouve une réponse.
- **Recherche par le sens** : elle trouve où chercher ; les chiffres passent par le registre.

### Pièges et bonnes pratiques

- **Écrire une décision invérifiable**, comme « on utilise du JSON quand c'est possible ». Rien ne la vérifie, ni le code, ni les mesures.
- **Tordre une règle préenregistrée sans le dire.** Choisir 24 000 tokens quand la règle en mesurait 32 000 est un choix de conception légitime, à condition de l'écrire noir sur blanc, avec sa raison.
- **Laisser une conséquence contredire la décision.** Un brouillon rédigé pour 32 000 tokens disait encore « la taille prudente reste l'option de repli » ; la phrase a été mise en cohérence avant la fusion.

> **À retenir.** Un ADR transforme des mesures en décisions vérifiables, et dit quand les revoir : à chaque changement de modèle ou de serveur, au jour 3 pour les décisions 3 et 4, et avant la production pour la décision 1.

### Pour vérifier que vous avez compris

1. Qu'est-ce qui distingue une décision bien écrite d'une décision mal écrite ?
2. Pourquoi le budget retenu, 24 000 tokens, n'est-il pas une entorse au préenregistrement ?

### Références

- **Nygard (2011)**, *Documenting Architecture Decisions* (billet technique) : la forme courte des ADR.
- **Tyree et Akerman (2005)**, *Architecture Decisions: Demystifying Architecture* (IEEE Software) : documenter les décisions et les options écartées.

## Chapitre 15 — Fiche bilan : ce qu'il faut retenir pour les travaux agentiques

### Ce que nous avons fait

Nous avons relu la séance pour en tirer ce qui vaudra pour tout agent construit ensuite, quel que soit le modèle.

### Pourquoi cette étape

Un agent enchaîne des appels à un modèle, des outils et du code. Schluntz et Zhang (2024) recommandent de partir de la solution la plus simple et de n'ajouter de l'autonomie que lorsqu'elle se mesure utile. Les mesures de cette séance disent où le modèle est fiable et où le code doit prendre le relais ; ces leçons dépassent notre modèle et notre serveur.

### La fiche

**Mesurer**

1. Mesurer avant de construire ; vérifier l'instrument avant de mesurer.
2. Un test ne vaut que pour la tâche qu'il imite : mesurer avec les consignes que l'agent recevra vraiment.
3. Devant un taux nul, se demander si la réussite était possible (`finish_reason`).
4. Répéter sur un faux serveur sépare deux questions : l'instrument marche-t-il ? que vaut le modèle ?

**Écrire avant**

5. Écrire règles et paris avant les résultats, et les dater par un commit.
6. Un écart se déclare, avec sa preuve ; il ne se corrige pas en silence.
7. Un choix plus prudent que la règle s'écrit comme tel, avec sa raison.

**Tracer**

8. Tout appel est journalisé et rejouable sans réseau ni clé ; seul le journal garantit qu'on retrouve une réponse.
9. Un changement de code ne doit pas changer les résultats passés : le prouver par rejeu.
10. Ne jamais remplacer un paramètre d'une campagne passée : l'ajouter en option, avec l'ancienne valeur par défaut.
11. La clé ne sort jamais : la contrôler avant chaque commit, sur ce qui est réellement préparé.

**Lire**

12. Un taux se lit avec son n et son intervalle de Wilson ; zéro échec ne prouve qu'une borne, d'environ 3/n.
13. Sur les mêmes items, comparer par McNemar ; compter des essais, pas des morceaux d'essai.

**Concevoir**

14. Imposer la forme par le serveur, vérifier le fond par le code.
15. Quand le modèle se trompe sur un nombre, c'est avec un nombre plausible : tout nombre se contrôle contre sa source.
16. « Appelé » n'est pas « utilisé » : la demande d'outil et l'usage du résultat se mesurent séparément.
17. La recherche par le sens trouve où chercher ; elle ne rapproche pas des chiffres.

> **À retenir.** Le modèle est un composant mesuré, pas un oracle : ses forces mesurées allègent le code, ses faiblesses mesurées lui donnent du travail, et la règle des chiffres ne se délègue jamais.

### Références

- **Schluntz et Zhang (2024)**, *Building Effective Agents* (billet technique, Anthropic) : préférer des chaînes simples et composables, et ne donner d'autonomie au modèle que là où elle se justifie.
- **Sculley et al. (2015)** : dans un système qui intègre un modèle, l'essentiel du risque est dans le code qui l'entoure.

## Annexe A — Résultats bruts de la campagne

Campagne `2026-11-22-gemma4-26b-moe` : modèle `gemma4-26b-moe`, embeddings `qwen3-embedding-8b`, serveur de modèles du SSP Cloud. 584 essais et 684 appels, du 22 novembre 2026 à 15 h 01 min 49 s au même jour à 15 h 13 min 11 s (UTC) ; aucun essai refusé par le serveur. Les taux s'écrivent succès/essais (pourcentage) [intervalle de Wilson à 95 %]. Source : `mesures/2026-11-22-gemma4-26b-moe/rapport_banc.md`, qui se régénère à l'identique en mode rejeu.

### Cas 1 — Forme JSON (50 sources)

<!-- largeurs: 16,24,24,24,12 -->
| Condition | Premier essai | Lecture tolérante | Après deux reprises | Refusés |
| --- | --- | --- | --- | --- |
| impose | 50/50 (100,0 %) [92,9 % ; 100,0 %] | 50/50 (100,0 %) [92,9 % ; 100,0 %] | 50/50 (100,0 %) [92,9 % ; 100,0 %] | 0 |
| objet | 50/50 (100,0 %) [92,9 % ; 100,0 %] | 50/50 (100,0 %) [92,9 % ; 100,0 %] | 50/50 (100,0 %) [92,9 % ; 100,0 %] | 0 |
| consigne | 0/50 (0,0 %) [0,0 % ; 7,1 %] | 50/50 (100,0 %) [92,9 % ; 100,0 %] | 0/50 (0,0 %) [0,0 % ; 7,1 %] | 0 |
| impose_contre | 50/50 (100,0 %) [92,9 % ; 100,0 %] | 50/50 (100,0 %) [92,9 % ; 100,0 %] | 50/50 (100,0 %) [92,9 % ; 100,0 %] | 0 |

Comparaisons appariées (test exact de McNemar) : impose contre objet, 0 et 0, p = 1,000 ; impose contre consigne, 50 et 0, p < 0,001 ; objet contre consigne, 50 et 0, p < 0,001 ; impose contre impose_contre, 0 et 0, p = 1,000. Réponses enveloppées dans une clôture Markdown : 50.

### Cas 2 — Consignes vérifiables (20 sujets par consigne et par langue)

<!-- largeurs: 22,30,30,18 -->
| Consigne | Rédigée en français | Rédigée en anglais | McNemar |
| --- | --- | --- | --- |
| sans_markdown | 20/20 (100,0 %) [83,9 % ; 100,0 %] | 20/20 (100,0 %) [83,9 % ; 100,0 %] | p = 1,000 |
| mots_max | 19/20 (95,0 %) [76,4 % ; 99,1 %] | 20/20 (100,0 %) [83,9 % ; 100,0 %] | p = 1,000 |
| commence_par | 20/20 (100,0 %) [83,9 % ; 100,0 %] | 20/20 (100,0 %) [83,9 % ; 100,0 %] | p = 1,000 |
| termine_par | 0/20 (0,0 %) [0,0 % ; 16,1 %] | 0/20 (0,0 %) [0,0 % ; 16,1 %] | p = 1,000 |
| mot_interdit | 20/20 (100,0 %) [83,9 % ; 100,0 %] | 20/20 (100,0 %) [83,9 % ; 100,0 %] | p = 1,000 |
| liste_trois | 20/20 (100,0 %) [83,9 % ; 100,0 %] | 20/20 (100,0 %) [83,9 % ; 100,0 %] | p = 1,000 |

Toutes consignes confondues : 120 paires ; 0 où seul le français réussit, 1 où seul l'anglais réussit ; p = 1,000. Réponses rédigées en anglais malgré la demande : 0 et 0.

Réponses coupées par le plafond de 300 tokens (`finish_reason` égal à `length`), sur 40 réponses par consigne : `commence_par` 40, `mot_interdit` 40, `termine_par` 40, `sans_markdown` 20, `mots_max` 0, `liste_trois` 0. Sur les seules réponses terminées (`outils/lecture_terminees.py`) : `liste_trois` 20/20 et 20/20 ; `mots_max` 19/20 et 20/20 ; `sans_markdown` 5/5 et 15/15.

### Cas 3 — Plusieurs aiguilles et des nombres pièges (10 essais par taille)

<!-- largeurs: 11,11,21,8,8,8,8,8,8,9 -->
| Tokens visés | Tokens lus, médiane | Essais complets | 5 % | 23 % | 41 % | 59 % | 77 % | 95 % | Pièges |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 8 000 | 8 190 | 10/10 (100,0 %) [72,2 % ; 100,0 %] | 10/10 | 10/10 | 10/10 | 10/10 | 10/10 | 10/10 | 0/60 |
| 16 000 | 16 081 | 10/10 (100,0 %) [72,2 % ; 100,0 %] | 10/10 | 10/10 | 10/10 | 10/10 | 10/10 | 10/10 | 0/60 |
| 24 000 | 23 960 | 10/10 (100,0 %) [72,2 % ; 100,0 %] | 10/10 | 10/10 | 10/10 | 10/10 | 10/10 | 10/10 | 0/60 |
| 32 000 | 31 898 | 10/10 (100,0 %) [72,2 % ; 100,0 %] | 10/10 | 10/10 | 10/10 | 10/10 | 10/10 | 10/10 | 0/60 |
| 48 000 | 47 734 | 5/10 (50,0 %) [23,7 % ; 76,3 %] | 10/10 | 10/10 | 10/10 | 10/10 | 6/10 | 7/10 | 7/60 |

Lecture selon la règle préenregistrée : budget de contexte de 32 000 tokens visés. Budget retenu dans l'ADR-001 : 24 000 tokens.

### Cas 4 — Stabilité

<!-- largeurs: 16,30,34,20 -->
| Requête | Réglage | Identiques à la réponse la plus fréquente | Réponses distinctes |
| --- | --- | --- | --- |
| definition | température 0 | 10/10 (100,0 %) [72,2 % ; 100,0 %] | 1 |
| resume | température 0 | 10/10 (100,0 %) [72,2 % ; 100,0 %] | 1 |
| fiche | température 0 | 10/10 (100,0 %) [72,2 % ; 100,0 %] | 1 |
| ville | graine 42, température 1 | 10/10 (100,0 %) [72,2 % ; 100,0 %] | 1 |
| ville | graines 1 à 10, température 1 | 2/10 (20,0 %) [5,7 % ; 51,0 %] | 9 |

Température 0, trois requêtes réunies : 30/30 (100,0 %) [88,6 % ; 100,0 %].

### Cas 5 — L'outil (20 questions)

<!-- largeurs: 18,30,14,14,12,12 -->
| Condition | Appel correct | Appel mal formé | Chiffre de mémoire | Sans chiffre | Refusés |
| --- | --- | --- | --- | --- | --- |
| sans consigne | 20/20 (100,0 %) [83,9 % ; 100,0 %] | 0 | 0 | 0 | 0 |
| avec consigne | 20/20 (100,0 %) [83,9 % ; 100,0 %] | 0 | 0 | 0 | 0 |

Comparaison appariée : 0 appels obtenus seulement avec la consigne, 0 seulement sans ; p = 1,000.

### Cas 6 — Embeddings et montants (20 triplets)

Cosinus médians avec la phrase de départ : paraphrase 0,942 ; même phrase avec un autre montant 0,990 ; hors sujet 0,144. Triplets où changer le montant déplace moins le vecteur que reformuler la phrase : 20/20 (100,0 %) [83,9 % ; 100,0 %].

### Débit et modèle de coût

Appels de chat analysés : 680. Vitesse d'écriture des appels courts : médiane 130 tokens par seconde (quartiles 123 et 169). Modèle de coût : durée ≈ 0,25 s + tokens lus / 16 238 + tokens écrits / 196.

### Répétition générale sur le faux serveur (hors du dépôt)

Cas 1 : impose 50/50, objet 46/50, consigne 32/50 en lecture stricte et 45/50 en lecture tolérante (13 réponses enveloppées dans une clôture), impose_contre 50/50. Ces chiffres sont fabriqués par le faux serveur : ils valident l'instrument, pas le modèle.

## Annexe B — Incidents et corrections

<!-- largeurs: 28,24,36,12 -->
| Incident | Cause | Correction | Chapitre |
| --- | --- | --- | --- |
| Variables d'environnement absentes | Service fermé ; variables saisies à la main au jour 1 | Bloc de rechargement : adresse relue dans `mesures/capacites.json`, clé saisie par `read -rsp` ; à terme, un secret Onyxia | 3 |
| `LLM_CLE: parameter null or not set` au contrôle de la clé | Commande lancée dans un autre terminal | Recharger la clé seule sur sa ligne, puis contrôler | 3 |
| Confusion sur les paris | Paris demandés avant la présentation des cas | Présenter chaque cas, puis faire parier ; exemple du taux de réponse d'une enquête | 4 |
| Toutes les réponses `termine_par` en échec | Plafond de 300 tokens : réponses coupées | Écart au plan déclaré, seconde lecture, plafond réglable à venir | 6 |
| Bloc de l'écart exécuté deux fois | Double collage dans le terminal | L'`assert` du script a empêché le doublon | 6 |
| Mesures commitées sous un message inexact (`2e91e81`) | Fichiers déjà préparés quand le bloc de commit a été relancé | Signalé dans le journal ; historique non réécrit | 6 |
| Contrôle de la clé sans valeur probante | Différence préparée vide, tout étant déjà commité | Contrôle refait sur tout l'historique : 0 occurrence | 6 |
| Confusion sur l'emplacement des résultats | Programme qui séparait « comprendre » et « lire » | Un cas à la fois : lire sa section du rapport, interpréter, confronter aux paris | 6 |
| Cas 2 peu valide pour l'agent | Consignes génériques, rien de spécifique à un EcoDef | Cas « consignes EcoDef » au début du jour 3 | 9 |
| Modèle d'embeddings du jour 1 mal noté dans le journal | `gemma4-26b-moe` écrit au lieu de `qwen3-embedding-8b` | Corrigé d'après `mesures/limites.json` | 13 |
| Conséquence de l'ADR contredisant la décision 2 | Brouillon rédigé pour 32 000 tokens | Phrase mise en cohérence avant la fusion | 14 |

## Annexe C — Clôture et points en attente

### Les commits du jour 2

<!-- largeurs: 14,86 -->
| Commit | Message |
| --- | --- |
| `73eba0c` | feat: enveloppe v2 (reprise, index du journal, requêtes longues résumées) |
| `028d924` | docs: plan préenregistré du banc et prédictions |
| `c08fb6d` | docs: écart au plan, réponses coupées dans le cas 2 |
| `2e91e81` | docs: écart au plan, réponses coupées dans le cas 2 (contient en fait les mesures, le journal et `banc.log`) |
| `3cda063` | docs: lecture des six cas du banc et seconde lecture du cas 2 |
| `a59fed0` | docs: ADR-001, quatre décisions tirées du banc |
| `7735ad0` | docs: clôture du jour 2 (journal, README) |
| `d371a59` | docs: ADR-001, décision 2 cohérente avec le budget de 24 000 tokens |
| `490d457` | Merge pull request #2 from MaryleneH/jour-2 (le commit de fusion, sur `main`) |

La branche est fusionnée dans `main` par la pull request n° 2, avec le commit de fusion `490d457` : ses deux parents sont le dernier commit de `main` (`f3f1559`) et le dernier commit de la branche (`d371a59`). L'étiquette `jour-2` se pose sur ce commit de fusion.

### Ce qui est fait

- [x] Les sept tests de l'enveloppe passent sur le vrai serveur
- [x] Le jour 1 se rejoue à l'identique avec l'enveloppe v2
- [x] Plan et paris commités avant le premier appel
- [x] Campagne rejouée sans réseau ni clé : rapport identique
- [x] Contrôle de la clé sur tout l'historique : aucune occurrence
- [x] `ADR-001` écrit et commité
- [x] Journal du jour 2 et README à jour
- [x] Branche fusionnée dans `main` par un commit de fusion (`490d457`)

### Points en attente

- **Cas « consignes EcoDef »** : au début du jour 3, dans une campagne complémentaire déclarée.
- **Plafond de tokens réglable** dans le banc, 300 par défaut pour que la campagne du 22 novembre se rejoue.
- **Usage du résultat d'un outil** : à mesurer, avec le cas EcoDef puis dans l'agent.
- **Schéma imposé sur 300 appels** avant toute production.
- **Campagne plus longue à 32 000 tokens**, pour pouvoir relever le budget.
- **Scripts du jour 1 rangés dans `sondes/`**, déplacement validé par rejeu.
- **Accès à Albert**, toujours en attente depuis le jour 1.
- **Données de l'EcoDef n° 273** : un fichier plus précis que les chiffres arrondis de la publication, toujours à chercher depuis le jour 1.

## Annexe D — Glossaire

<!-- largeurs: 24,62,14 -->
| Terme | Définition | Chapitre |
| --- | --- | --- |
| ADR | Enregistrement d'une décision d'architecture : contexte, options, décision, preuves, conséquences, limites, date de révision. | 14 |
| Aiguille | Information exacte cachée dans un long texte, que le modèle doit retrouver. | 10 |
| Banc de fiabilité | Programme qui mesure, sur des essais toujours identiques, ce qu'un modèle réussit et à quel taux ; il se relance et se rejoue. | 1 |
| Borne sans échec | Borne supérieure du taux d'échec quand aucun échec n'est observé sur n essais : 1 − 0,05^(1/n), soit environ 3/n. | 7 |
| Budget de contexte | Quantité de texte confiée au modèle en un appel, fixée d'après les mesures. | 10 |
| Clôture Markdown | Bloc de code entouré de trois accents graves, souvent ajouté par le modèle autour d'un JSON. | 8 |
| Décodage contraint | Restriction, à chaque étape de la génération, des tokens permis, pour respecter un schéma ou une grammaire. | 8 |
| Demande d'appel | Réponse du modèle qui demande l'exécution d'un outil, avec son nom et ses arguments (`tool_calls`). | 12 |
| Écart au plan | Changement ou défaut découvert par rapport au plan préenregistré, déclaré avec sa cause et sa preuve. | 6 |
| Embedding | Représentation d'un texte par un vecteur de nombres, proches pour des textes de sens proche. | 13 |
| Étiquette git | Nom fixe posé sur un commit, comme `jour-1`, qui marque un état du dépôt. | 2 |
| Faux serveur | Doublure de test qui imite le vrai serveur avec des réponses connues, dont certaines fautives exprès. | 5 |
| `finish_reason` | Raison de fin d'une réponse : `stop`, fin naturelle ; `length`, plafond atteint ; `tool_calls`, demande d'outil. | 6 |
| Idempotence | Propriété d'une opération qu'on peut refaire sans effet supplémentaire. | 3 |
| Intervalle de Wilson | Intervalle de confiance d'une proportion, fiable pour les petits échantillons et les taux proches de 0 ou de 100 %. | 7 |
| Lecture stricte, tolérante | Stricte : le texte entier doit être du JSON. Tolérante : on retire d'abord la clôture et le texte autour. | 8 |
| McNemar exact (test de) | Test de comparaison de deux conditions sur les mêmes items, fondé sur les seules paires discordantes. | 7 |
| Non-régression | Vérification qu'un changement de code ne modifie pas les résultats déjà obtenus. | 3 |
| Pari | Valeur attendue d'une mesure, écrite avec sa raison avant la collecte. | 4 |
| Piège | Valeur voisine d'une aiguille, présentée comme ancienne, qui teste la lecture du contexte. | 10 |
| Plan apparié | Plan où chaque item passe dans toutes les conditions, et sert ainsi de témoin à lui-même. | 7 |
| Préenregistrement | Plan de mesure écrit et daté avant la collecte : questions, conditions, mesures, règles de décision. | 4 |
| Pseudo-réplication | Erreur qui consiste à compter comme indépendantes des observations qui ne le sont pas. | 7 |
| Reprise | Mode de l'enveloppe qui relit le journal et ne renvoie que les appels absents ou en échec passager. | 3 |
| Répétition générale | Passage complet du banc contre le faux serveur, avant la vraie campagne. | 5 |
| Témoin | Série de contrôle qui permet d'interpréter une autre série, comme les graines 1 à 10 du cas 4. | 11 |
| Validité d'un test | Mesure dans laquelle un test mesure bien ce qu'on veut savoir pour l'usage visé. | 9 |

## Annexe E — Corrigé des questions

**Chapitre 1.** 1. Un essai ne dit pas à quel taux le modèle réussit : 1 sur 1 est compatible avec 99 % comme avec 60 %, et l'architecture dépend justement de ce taux. 2. Il mesure nos tâches, sur notre serveur, avec nos requêtes, et il se relance à chaque changement de modèle ; un classement public mesure des tâches générales, dans des conditions qui ne sont pas les nôtres.

**Chapitre 2.** 1. `llm.py` serait copié dans chaque dossier et divergerait, et le journal des appels se couperait en plusieurs fichiers ; or le rejeu repose sur une enveloppe et un journal uniques. 2. Le « Squash » écrase les commits du jour en un seul : on perdrait la preuve que le plan a été commité avant les mesures.

**Chapitre 3.** 1. L'empreinte est la clé qui retrouve chaque appel dans le journal : si sa formule change, aucun appel passé n'est retrouvé, et le jour 1 ne se rejoue plus. 2. Pour prouver que le rejeu fonctionne sans clé : si la clé était présente, un rejeu qui l'utiliserait par erreur passerait inaperçu.

**Chapitre 4.** 1. Un pari précis peut être démenti, et l'écart avec le résultat instruit ; un pari vague s'accommode de tout résultat et n'apprend rien. 2. Le commit `028d924`, qui contient le plan et les paris, précède dans l'historique le commit des mesures, et sa date précède le premier appel du journal.

**Chapitre 5.** 1. Pour vérifier que les vérificateurs détectent les fautes : si le rapport de répétition montre les fautes fabriquées, l'instrument sait les compter. 2. Ses réponses sont courtes : aucune n'atteignait le plafond de 300 tokens. La répétition teste la plomberie, pas la façon dont un vrai modèle s'étend.

**Chapitre 6.** 1. `stop` : le modèle a fini de lui-même ; `length` : le plafond de tokens l'a coupé ; `tool_calls` : il demande l'exécution d'un outil. 2. Changer le plafond change la requête, donc son empreinte : les appels de la campagne du 22 novembre ne seraient plus retrouvés, et la campagne ne se rejouerait plus. On ajoute un paramètre, avec 300 par défaut.

**Chapitre 7.** 1. Wald calcule l'écart-type avec le taux observé, nul à 100 % ; l'intervalle s'écrase. Wilson le calcule avec le vrai taux testé et donne [92,9 % ; 100 %]. 2. Les six aiguilles d'un essai partagent le même texte ; elles ne sont pas indépendantes, et les compter séparément donnerait des intervalles faussement étroits.

**Chapitre 8.** 1. Qu'une consigne contraire ne fait pas sortir le modèle du schéma : la conformité vient de la contrainte du serveur, pas de l'obéissance du modèle. 2. Le modèle a enveloppé chaque JSON dans une clôture Markdown, que la lecture stricte refuse et que la lecture tolérante retire ; le JSON à l'intérieur était juste.

**Chapitre 9.** 1. Une réponse rédigée en anglais pourrait réussir une consigne de forme par accident, alors que la réponse devait être en français. 2. Ses consignes sont génériques, sans rapport avec la rédaction d'une publication ; le jour 3 mesurera des consignes de rédaction d'EcoDef, vérifiables par code, sur une fiche de faits publics.

**Chapitre 10.** 1. Deux chiffres inversés font un nombre plausible, que seule une lecture attentive distingue ; le mot « ancien » rend la bonne réponse sans ambiguïté pour qui lit le contexte. 2. Un « je ne sais pas » se voit ; un nombre plausible et faux passe inaperçu, sauf si le code le contrôle contre la source.

**Chapitre 11.** 1. C'est le témoin : il prouve que des graines différentes donnent des réponses différentes, donc que la stabilité observée avec la graine 42 vient bien de la graine. 2. Le serveur regroupe les requêtes par lots ; l'ordre des calculs en virgule flottante dépend du lot, les arrondis changent, et un mot peut basculer.

**Chapitre 12.** 1. Le nom de la fonction et ses arguments en JSON ; c'est le programme qui exécute la fonction et renvoie le résultat au modèle. 2. Il n'y a pas de vrai registre derrière l'outil : le banc n'exécute jamais l'appel et ne renvoie aucun résultat, il s'arrête à la demande.

**Chapitre 13.** 1. Changer un nombre modifie deux ou trois tokens, alors qu'une paraphrase réécrit la phrase ; le vecteur retient surtout les mots et la structure. 2. Retrouver, avec un excellent score, un passage au bon sujet mais aux mauvais chiffres, comme une valeur provisoire au lieu de la valeur révisée.

**Chapitre 14.** 1. Une décision bien écrite tient en une phrase à l'indicatif, vérifiable dans le code, avec des preuves copiées du rapport ; une décision mal écrite ne se vérifie ni dans le code ni par les mesures. 2. La règle du plan a été appliquée et publiée telle quelle, 32 000 tokens ; le budget retenu est un choix de conception plus prudent, écrit comme tel avec sa raison.

## Annexe F — Bibliographie

- Biderman, S., Schoelkopf, H., Sutawika, L., et al. (2024). *Lessons from the Trenches on Reproducible Evaluation of Language Models*. Prépublication arXiv:2405.14782.
- Brown, L. D., Cai, T. T., & DasGupta, A. (2001). Interval Estimation for a Binomial Proportion. *Statistical Science*, 16(2), 101–133.
- Feathers, M. (2004). *Working Effectively with Legacy Code*. Prentice Hall.
- Fischhoff, B. (1975). Hindsight ≠ Foresight: The Effect of Outcome Knowledge on Judgment under Uncertainty. *Journal of Experimental Psychology: Human Perception and Performance*, 1(3), 288–299.
- Gelman, A., & Loken, E. (2014). The Statistical Crisis in Science. *American Scientist*, 102(6), 460–465.
- Geng, S., Cooper, H., Moskal, M., Jenkins, S., Berman, J., Ranchin, N., West, R., Horvitz, E., & Nori, H. (2025). *JSONSchemaBench: A Rigorous Benchmark of Structured Outputs for Language Models*. Prépublication arXiv:2501.10868.
- Georges, A., Buytaert, D., & Eeckhout, L. (2007). Statistically Rigorous Java Performance Evaluation. *Proceedings of OOPSLA '07*, 57–76.
- Hanley, J. A., & Lippman-Hand, A. (1983). If Nothing Goes Wrong, Is Everything All Right? Interpreting Zero Numerators. *JAMA*, 249(13), 1743–1745.
- He, H., & Thinking Machines Lab (2025). *Defeating Nondeterminism in LLM Inference*. Thinking Machines Lab : Connectionism, billet technique, septembre 2025.
- Helland, P. (2012). Idempotence Is Not a Medical Condition. *Communications of the ACM*, 55(5) ; d'abord paru dans *ACM Queue*, 10(4).
- Hsieh, C.-P., Sun, S., Kriman, S., et al. (2024). RULER: What's the Real Context Size of Your Long-Context Language Models? *Conference on Language Modeling (COLM)*.
- Huang, Y., Shi, J., Li, Y., et al. (2024). MetaTool Benchmark for Large Language Models: Deciding Whether to Use Tools and Which to Use. *International Conference on Learning Representations (ICLR)*.
- Hurlbert, S. H. (1984). Pseudoreplication and the Design of Ecological Field Experiments. *Ecological Monographs*, 54(2), 187–211.
- Liu, N. F., Lin, K., Hewitt, J., Paranjape, A., Bevilacqua, M., Petroni, F., & Liang, P. (2024). Lost in the Middle: How Language Models Use Long Contexts. *Transactions of the Association for Computational Linguistics*, 12, 157–173.
- McNemar, Q. (1947). Note on the Sampling Error of the Difference Between Correlated Proportions or Percentages. *Psychometrika*, 12(2), 153–157.
- Meszaros, G. (2007). *xUnit Test Patterns: Refactoring Test Code*. Addison-Wesley.
- Nosek, B. A., Ebersole, C. R., DeHaven, A. C., & Mellor, D. T. (2018). The Preregistration Revolution. *Proceedings of the National Academy of Sciences*, 115(11), 2600–2606.
- Nygard, M. (2011). *Documenting Architecture Decisions*. Cognitect, billet technique, 15 novembre 2011.
- Ouyang, S., Zhang, J. M., Harman, M., & Wang, M. (2023). *LLM is Like a Box of Chocolates: the Non-determinism of ChatGPT in Code Generation*. Prépublication arXiv:2308.02828 ; publié sous le titre *An Empirical Study of the Non-determinism of ChatGPT in Code Generation*, ACM Transactions on Software Engineering and Methodology, doi:10.1145/3697010.
- Peng, R. D. (2011). Reproducible Research in Computational Science. *Science*, 334(6060), 1226–1227.
- Raji, I. D., Bender, E. M., Paullada, A., Denton, E., & Hanna, A. (2021). AI and the Everything in the Whole Wide World Benchmark. *NeurIPS, Datasets and Benchmarks Track*.
- Ram, K. (2013). Git Can Facilitate Greater Reproducibility and Increased Transparency in Science. *Source Code for Biology and Medicine*, 8, 7.
- Reimers, N., & Gurevych, I. (2019). Sentence-BERT: Sentence Embeddings using Siamese BERT-Networks. *Proceedings of EMNLP-IJCNLP 2019*, 3982–3992.
- Schick, T., Dwivedi-Yu, J., Dessì, R., et al. (2023). Toolformer: Language Models Can Teach Themselves to Use Tools. *Advances in Neural Information Processing Systems (NeurIPS)*, 36.
- Schluntz, E., & Zhang, B. (2024). *Building Effective Agents*. Anthropic, billet technique, 19 décembre 2024.
- Sclar, M., Choi, Y., Tsvetkov, Y., & Suhr, A. (2024). Quantifying Language Models' Sensitivity to Spurious Features in Prompt Design. *International Conference on Learning Representations (ICLR)*.
- Sculley, D., Holt, G., Golovin, D., et al. (2015). Hidden Technical Debt in Machine Learning Systems. *Advances in Neural Information Processing Systems (NeurIPS)*, 28.
- Tam, Z. R., Wu, C.-K., Tsai, Y.-L., et al. (2024). Let Me Speak Freely? A Study on the Impact of Format Restrictions on Performance of Large Language Models. *Proceedings of EMNLP 2024, Industry Track*, 1218–1236.
- Thawani, A., Pujara, J., Ilievski, F., & Szekely, P. (2021). Representing Numbers in NLP: a Survey and a Vision. *Proceedings of NAACL 2021*, 644–656.
- Tyree, J., & Akerman, A. (2005). Architecture Decisions: Demystifying Architecture. *IEEE Software*, 22(2), 19–27.
- Wallace, E., Wang, Y., Li, S., Singh, S., & Gardner, M. (2019). Do NLP Models Know Numbers? Probing Numeracy in Embeddings. *Proceedings of EMNLP-IJCNLP 2019*, 5307–5315.
- Willard, B. T., & Louf, R. (2023). *Efficient Guided Generation for Large Language Models*. Prépublication arXiv:2307.09702.
- Wilson, E. B. (1927). Probable Inference, the Law of Succession, and Statistical Inference. *Journal of the American Statistical Association*, 22(158), 209–212.
- Wilson, G., Bryan, J., Cranston, K., Kitzes, J., Nederbragt, L., & Teal, T. K. (2017). Good Enough Practices in Scientific Computing. *PLOS Computational Biology*, 13(6), e1005510.
- Zhou, J., Lu, T., Mishra, S., Brahma, S., Basu, S., Luan, Y., Zhou, D., & Hou, L. (2023). *Instruction-Following Evaluation for Large Language Models*. Prépublication arXiv:2311.07911.
