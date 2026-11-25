---
title: "Séance 3 — Les consignes d'EcoDef, puis le graphe d'états"
subtitle: "Cours détaillé du laboratoire · assistant d'étude statistique sourcée"
date: 2026-11-25
toc: true
toc-depth: 2
---

24 et 25 novembre 2026 · deux demi-journées, trois heures de travail · serveur de modèles du SSP Cloud

> **En bref.** Ce document reprend la séance 3 du laboratoire étape par étape, comme un cours. La séance a deux parties. La première mesure si le modèle respecte, toutes à la fois, six consignes de rédaction tirées d'une publication EcoDef : 60 essais, préenregistrés, et un résultat parfait qu'il a fallu lire avec méfiance. La seconde construit la première pièce de l'agent : un graphe d'états à trois nœuds qui rédige, fait vérifier les chiffres par le code, s'arrête pour une décision humaine, et survit à l'arrêt brutal de son processus. Un chapitre ajouté après la séance présente LangGraph pas à pas, sur un exemple jouet à lancer soi-même. Chaque chapitre dit ce que nous avons fait, puis pourquoi, comment cela fonctionne, ce que nous avons observé et quels pièges éviter. Les questions posées pendant la séance sont reformulées, avec leur réponse. Les chiffres viennent du rapport du banc, du journal des appels et des sorties du graphe ; ceux tirés d'articles sont attribués à leurs auteurs.

## Comment lire ce cours

### Organisation d'un chapitre

Chaque chapitre correspond à une étape de la séance, sauf le chapitre 9, ajouté après coup pour présenter LangGraph. Tous suivent le même plan :

- **Ce que nous avons fait** : l'étape, concrètement, avec la commande ou le fichier concerné.
- **Pourquoi cette étape** : le problème qu'elle résout et ce qui se passerait sans elle.
- **Comment ça marche** : le mécanisme, avec le niveau technique nécessaire pour le comprendre vraiment.
- **Ce que nous avons observé** : nos résultats, et ce qu'ils permettent ou non de conclure.
- **La question posée pendant la séance** : quand une question a été posée, elle est reformulée, puis sa réponse est développée.
- **Ce qui m'a posé problème, et ce que j'ai compris** : quand une réponse de ma part était fausse ou incomplète, elle est citée, puis corrigée. Ces sections sont souvent les plus instructives.
- **Pièges et bonnes pratiques** : les erreurs classiques, dont celles que nous avons commises.
- **Pour vérifier que vous avez compris** : deux questions. Le corrigé est à l'annexe E.
- **Références** : deux ou trois lectures, avec ce que chacune apporte. L'annexe F les rassemble.

### Les encadrés

> **À retenir.** Les idées essentielles du chapitre.

> **Attention.** Un piège qui coûte cher s'il n'est pas vu à temps.

> **Définition.** Un terme employé pour la première fois. Le glossaire de l'annexe D les reprend tous.

> **Formule.** Un calcul, avec ses notations.

> **Exemple.** Une image tirée de la vie courante, pour se représenter un mécanisme.

### Les références

Elles sont de trois sortes : des articles évalués par les pairs (conférences et revues), des livres de référence, et quelques documentations ou billets techniques, signalés comme tels. Chacune est citée pour ce qu'elle apporte au chapitre.

### Le niveau attendu

Le cours suppose lus ceux des séances 1 et 2 : l'enveloppe d'appel, le journal, le rejeu, le préenregistrement, l'intervalle de Wilson et le test exact de McNemar y sont introduits. Le vocabulaire nouveau est défini au premier emploi.

## Le fil rouge

Le projet vise un assistant qui conduit une question jusqu'à une étude statistique publiable et sourcée. Une règle commande toute l'architecture : **le modèle ne calcule aucun chiffre et n'en cite aucun de mémoire**. Les chiffres viennent d'un registre de faits et sont vérifiés par un programme.

La séance 1 a établi ce que le serveur accepte. La séance 2 a transformé ces impressions en mesures, puis en quatre décisions d'architecture, consignées dans l'`ADR-001`. Elle avait laissé une question ouverte : ses consignes de forme étaient génériques, et ne disaient rien de celles que l'agent recevra vraiment.

La séance 3 y répond, puis passe de la mesure à la construction. La partie A mesure six consignes de rédaction d'EcoDef sur vingt sujets (cas 7 du banc) et en tire l'`ADR-002`. La partie B présente d'abord LangGraph, la bibliothèque choisie, sur un exemple jouet. Puis elle construit un graphe d'états à trois nœuds, `rediger`, `verifier` et `valider`, avec une sauvegarde à chaque étape, et en tire l'`ADR-003`. Son critère de fin : le processus est tué en pleine rédaction, puis repris sans perte ni appel en double. Il l'a été, et la phrase « Les cinq comportements du graphe sont vérifiés » s'est affichée.

La leçon qui traverse toute la séance tient en une phrase : **le code garantit les chiffres, l'humain garantit le sens**. Elle a été démontrée deux fois, par un résultat de 60 sur 60 qui cachait autre chose qu'une réussite, et par un paragraphe sans aucune anomalie pour le code, mais faux.

## Plan du cours

<!-- largeurs: 8,30,62 -->
| N° | Chapitre | La question à laquelle il répond |
| --- | --- | --- |
| 1 | Ouvrir la journée | Comment repartir d'un état propre, et ne rien perdre si le service disparaît ? |
| 2 | Comprendre le cas avant de parier | Comment le code vérifie-t-il une consigne, et que faire quand le modèle la rate ? |
| 3 | Vérifier l'étalon | La fiche de faits dit-elle exactement ce que dit la publication ? |
| 4 | Préenregistrer et parier | Pourquoi écrire ses prédictions, même quand on n'a qu'une intuition ? |
| 5 | Répéter, puis lancer | Comment savoir que l'instrument trouve les fautes, avant de mesurer ? |
| 6 | Lire un résultat trop beau | Que vaut un 60 sur 60, et que cache-t-il ? |
| 7 | L'ADR-002 | Qui, du modèle ou du code, se charge de chaque consigne ? |
| 8 | Une dépendance, épinglée et figée | Comment ajouter une bibliothèque sans perdre la reproductibilité ? |
| 9 | Découvrir LangGraph | Qu'est-ce qu'un état, un nœud, une arête, un réducteur, une sauvegarde, une interruption ? |
| 10 | Lire notre graphe | Que lit, qu'écrit chaque nœud, et peut-on le relancer sans dommage ? |
| 11 | Jusqu'à la décision humaine | Comment un programme attend-il une décision pendant des heures ? |
| 12 | Tuer le processus, puis reprendre | Comment survivre à une panne sans payer deux fois un appel ? |
| 13 | Clore | Comment prouver, consigner et étiqueter une journée de travail ? |
| 14 | Fiche bilan | Que retenir pour tous les travaux agentiques à venir ? |
| A à F | Annexes | Chiffres, fiche et paris ; incidents ; commits et points en attente ; glossaire ; corrigé ; bibliographie |

## Chapitre 1 — Ouvrir la journée

### Ce que nous avons fait

Le matin du 24 novembre, avant même d'ouvrir le programme, j'ai voulu relancer mon service VS Code du SSP Cloud. Nous avons d'abord vérifié ce que GitHub contenait : `main` portait la fusion de la pull request n° 2 (23 novembre, 13 h 55), donc tout le jour 2 ; la branche `jour-2` et l'étiquette `jour-1` étaient là. L'étiquette `jour-2` manquait, mais le commit qu'elle devait marquer était déjà sur GitHub : rien n'était perdu.

Le bloc 0 a ensuite remis le dépôt en ordre, en quatre gestes :

1. **Étiqueter le jour 2** (`git tag -a jour-2`), puis pousser l'étiquette sur GitHub.
2. **Recharger les variables** d'environnement : l'adresse du serveur, les noms des modèles, la clé.
3. **Déposer le paquet** `jour3.zip`, qui apportait le cas 7, le graphe et leurs tests.
4. **Ranger les sondes du jour 1** dans un dossier `sondes/`, retirer les anciens fichiers, puis rejouer les jours 1 et 2 depuis le journal et vérifier que rien n'avait bougé : `git diff --exit-code mesures/`. Le commit `de67afe` s'intitule « refactor: sondes du jour 1 rangées dans sondes/, rejouées à l'identique ».

### Pourquoi cette étape

**Une étiquette rend une journée comparable.** Sans l'étiquette `jour-2`, la question « qu'a changé le jour 3 ? » n'a pas de réponse simple. Avec elle, `git diff jour-2 jour-3` y répond en une commande. Une étiquette annotée est un objet de git, avec un auteur, une date et un message : c'est un jalon, pas un simple nom.

**Ranger sans changer le comportement.** Déplacer trois fichiers paraît anodin, mais leurs chemins d'écriture et leurs imports changent. Fowler (2018) définit le *refactoring* comme une modification de l'organisation d'un programme qui ne change pas son comportement observable. Encore faut-il le prouver.

**Le rejeu est la preuve.** Feathers (2004) appelle « test de caractérisation » un test qui fige le comportement actuel d'un programme, quel qu'il soit, pour détecter tout changement. Notre journal joue exactement ce rôle : les mesures commitées sont le comportement attendu. Si, après le déplacement, le rejeu produit les mêmes fichiers octet pour octet, le comportement n'a pas changé.

### Comment ça marche

**Pourquoi le rejeu est une preuve forte.** Chaque appel du journal est retrouvé par une clé, l'empreinte de l'adresse du serveur, de l'étiquette de l'appel et du corps de la requête. Si une sonde déplacée construisait sa requête autrement, la clé changerait, le journal ne trouverait pas l'appel, et le rejeu échouerait bruyamment. S'il passe, et si `git diff --exit-code` ne trouve aucune différence, les sondes posent les mêmes questions et écrivent les mêmes résultats.

**Ce que GitHub ne voit pas.** Le dépôt de GitHub ne connaît que ce qui a été poussé. Le service VS Code, lui, peut contenir trois sortes de travail invisible : des modifications non commitées, des remises de côté (`stash`) oubliées, et des commits jamais poussés, sur n'importe quelle branche locale. Trois commandes les révèlent.

```bash
git status --short                             # modifications non commitées
git stash list                                 # remises de côté oubliées
git log --branches --not --remotes --oneline   # commits jamais poussés, toutes branches
```

La troisième se lit ainsi : « les commits accessibles depuis mes branches locales, mais depuis aucune branche distante ». Si les trois ne renvoient rien, tout le travail versionné est sur GitHub.

**Ce qui ne doit pas y être.** La clé et les variables d'environnement ne sont jamais versionnées : elles disparaissent avec le service et se rechargent à chaque reprise. L'environnement virtuel se recrée à partir de la liste des paquets. Les fichiers hors du dépôt, comme un PDF téléchargé, sont à mettre de côté.

> **Définition.** Un *service* (ou *pod*) du SSP Cloud est un conteneur qui exécute un environnement de travail, ici VS Code. Son disque peut ne pas survivre à sa suppression : tout ce qui compte doit être poussé ailleurs.

### Ce que nous avons observé

Le rejeu des jours 1 et 2, après le déplacement des sondes, a produit des mesures identiques à celles du dépôt : le rangement est prouvé, pas seulement supposé. L'étiquette `jour-2` est arrivée sur GitHub dans la journée. Le dépôt est reparti d'un état propre, daté, et comparable.

### Pièges et bonnes pratiques

- **Croire que `git push` envoie les étiquettes.** Il ne les envoie pas : une étiquette se pousse explicitement. Le jour 2 l'avait oublié, et le jour 3 a rencontré un autre piège, au chapitre 13.
- **Supprimer les anciens fichiers avant d'avoir prouvé le rejeu.** L'ordre compte : déplacer, rejouer, comparer, puis seulement commiter.
- **Garder la clé dans un fichier du dépôt**, même ignoré par git : elle finit toujours par sortir. Elle vit dans une variable d'environnement, ou mieux, dans le coffre de secrets du service.
- **Relancer un service avec des commits non poussés.** Les trois commandes coûtent dix secondes.

> **À retenir.** Une étiquette rend une journée comparable. Un rangement se prouve par un rejeu identique. Avant de relancer un service : `git status`, `git stash list`, `git log --branches --not --remotes`. Et pousser après chaque commit.

### Pour vérifier que vous avez compris

1. Pourquoi un rejeu identique prouve-t-il que les sondes déplacées se comportent comme avant ? Que faudrait-il faire si le journal n'existait pas ?
2. Vous avez trois commits sur une branche locale `essai`, jamais poussée, et `git status` ne montre rien. Quelle commande vous alerte, et pourquoi `git status` ne suffit-il pas ?

### Références

- Feathers, M. (2004). *Working Effectively with Legacy Code*. Prentice Hall. — **Ce qu'on y apprend :** les tests de caractérisation, qui figent le comportement actuel d'un programme pour pouvoir le modifier sans crainte.
- Fowler, M. (2018). *Refactoring: Improving the Design of Existing Code*, 2ᵉ édition. Addison-Wesley. — **Ce qu'on y apprend :** la définition du *refactoring*, et pourquoi il ne se fait qu'avec des tests qui protègent le comportement.
- OWASP. *Secrets Management Cheat Sheet*. Documentation de l'OWASP Foundation. https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html — **Ce qu'on y apprend :** où ranger une clé d'API, et pourquoi jamais dans un fichier versionné.

## Chapitre 2 — Comprendre le cas avant de parier

### Ce que nous avons fait

Le cas 7 demande au modèle d'écrire un paragraphe de publication à partir d'une fiche de faits, en respectant six consignes tirées des publications EcoDef. Avant de parier sur les résultats, il fallait comprendre comment le code juge chaque consigne. J'ai lu la fonction `verifier()` de `redaction/ecodef.py`, testé quelques cas limites avec un court script, puis, pour chaque consigne, répondu dans mon journal à deux questions : comment le code la vérifie-t-il ? Que devra faire l'agent si le modèle la rate ?

<!-- largeurs: 22,78 -->
| Consigne | Ce que vérifie le code |
| --- | --- |
| `fidelite` | Chaque nombre écrit en chiffres vaut un fait de la fiche du sujet, signe compris s'il est écrit. Les années, les numéros de programme et « n° 273 » sont exclus. |
| `identifiants` | Juste après chaque nombre et son unité vient `[Fnn]`, un fait de la fiche qui porte ce nombre. |
| `format_md` | Ni « milliard », ni « Mds », ni « € » seul ; chaque « Md€ » suit un nombre à une décimale, avec une virgule. |
| `signes` | Un nombre qui correspond à une évolution de la fiche porte « + » ou « − ». |
| `sans_markdown` | Aucun gras, accent grave, titre, puce ou liste numérotée. |
| `source` | La dernière ligne non vide vaut exactement « Source : EcoDef Statistiques n° 273. » |

### Pourquoi cette étape

**On ne parie bien que sur ce qu'on comprend.** Une consigne vérifiée très strictement échouera plus souvent qu'une consigne lâche. La ligne de source, par exemple, doit être exacte au caractère près : des guillemets autour suffisent à la faire échouer. Le savoir change le pari.

**Décider qui répare quoi avant de voir les chiffres.** La seconde question prépare l'`ADR-002`. Y répondre avant la mesure évite de choisir selon les résultats : c'est la même logique que le préenregistrement du chapitre 4.

**Le problème est connu de la recherche.** Écrire un texte à partir de données, c'est le *data-to-text*. Thomson et Reiter (2020) ont montré que les erreurs de ces systèmes ne se réduisent pas aux nombres faux : beaucoup sont des erreurs de contexte, un nombre juste attaché à la mauvaise grandeur. Gao et ses coauteurs (2023) ont mesuré combien il est difficile, pour un modèle, de citer correctement la source de chaque affirmation. Nos identifiants `[Fnn]` sont une forme simple de citation, que le code peut contrôler.

### Comment ça marche

**Trois façons de traiter une consigne ratée.** Pour chacune, l'agent peut :

1. **faire corriger le modèle** (une *reprise*) : le code nomme l'écart, et le modèle réécrit ;
2. **corriger lui-même** (un *rendu*) : le code transforme le texte, sans modèle ;
3. **laisser trancher l'humain**.

**Le critère qui départage.** Réparer l'écart exige-t-il de comprendre le texte ? Si non, le code peut le faire seul. Si oui, le modèle réécrit, guidé par l'écart que le code a nommé. Et si personne ne peut savoir quelle était la bonne valeur, la décision revient à l'humain.

**Le partage qui en résulte.** Le format, l'absence de Markdown et la ligne de source se réparent sans jugement : le code peut s'en charger. Une liste à puces fait exception, car la transformer en paragraphe demande de réécrire. La fidélité, les identifiants et les signes demandent de savoir ce que le modèle voulait dire. Les signes en donnent un bon exemple : ajouter mécaniquement « − » à « en baisse de 18,2 % » donnerait « en baisse de −18,2 % », une double négation.

> **Définition.** Une *reprise* est un nouvel appel au modèle, auquel le code transmet les écarts trouvés dans son texte précédent. Un *rendu* est une transformation faite par le code seul, sans appel au modèle.

### Ce que nous avons observé

Les exemples suivants sont passés par le vrai vérificateur, avec une fiche contenant F01 (30,3 Md€), F02 (+6,1 %), F03 (25,1 Md€) et F05 (+9,4 %).

<!-- largeurs: 46,18,36 -->
| Phrase | Fidélité | Pourquoi |
| --- | --- | --- |
| « … 25,1 Md€ [F03] … soit +9,4 % [F05] par rapport à 2023. » | Passe | Les années ne comptent pas |
| « Les non-résidents ont reçu 5,2 Md€. » | Échoue | Un calcul juste reste hors fiche |
| « Près de 25 Md€ » | Échoue | Un arrondi est un autre nombre |
| « 23 451 entreprises » | Échoue | Vrai, mais absent de la fiche de ce sujet |
| « −9,4 % » | Échoue | Le signe écrit est comparé |
| « 4 programmes » | Échoue | Un comptage est un nombre |
| « 25,1 Md€ [F03] versés à l'ensemble des fournisseurs » | Passe | Faux pourtant : l'ensemble, c'est 30,3 Md€ |
| « quatre programmes », « les quatre cinquièmes » | Passe | Les nombres en lettres sont invisibles |
| « 25,1 % [F03] » | Passe | Le code compare la valeur, pas l'unité |

Les trois dernières lignes sont les angles morts du vérificateur : la grandeur à laquelle un nombre est attaché, l'unité, et les nombres écrits en lettres. Elles disent pourquoi la relecture humaine reste nécessaire.

### La question posée pendant la séance

*Que faut-il écrire dans le journal, pour chaque consigne ?*

Il s'agissait d'un exercice de lecture de code, à rendre sous une forme fixe : une ligne par consigne, avec ce que vérifie le code et ce que doit faire l'agent. L'exemple de la consigne la plus simple a servi de modèle : « `source` : la dernière ligne non vide doit valoir exactement la phrase de source, et des guillemets suffisent à échouer. Si le modèle la rate, le code l'écrit lui-même : la ligne est connue d'avance. »

*Quels exemples permettent de comprendre la consigne de fidélité ?*

Le tableau ci-dessus en est la réponse. Il a été obtenu en faisant passer chaque phrase par le vrai vérificateur, et non en raisonnant sur le code : c'est la seule façon d'être sûr de ce qu'il fait.

### Ce qui m'a posé problème, et ce que j'ai compris

Mes deux premières lignes disaient : « `fidelite` : par exemple, un arrondi "près de 25 milliards" doit passer ; l'agent l'accepte » et « `format_md` : euros ou €, l'agent accepte ».

Elles décrivaient ce que je souhaitais, pas ce que fait le code : « près de 25 milliards » échoue (25 n'est pas 25,1), et « 25,1 milliards d'euros » aussi. J'ai compris la différence entre les deux questions. La première est factuelle : elle décrit le code tel qu'il est. La seconde est une décision : mon avis sur la règle y a sa place.

Sur le fond, tolérer un arrondi obligerait à fixer un seuil. 25 pour 25,1, d'accord ; mais 24 ? 20 ? Ma garantie deviendrait « chaque chiffre est proche de la fiche », et non plus « chaque chiffre est dans la fiche ». Or j'avais écrit au jour 2 : « Ma règle étant non négociable, le code contrôle quand même chaque nombre du texte contre le registre. » Si l'on veut des arrondis, c'est le code qui doit les écrire à partir du fait, selon une règle déclarée.

Pour le format, accepter « milliards d'euros » est un choix de style défendable. Mais il se prend avant de préenregistrer, en changeant la consigne et sa vérification, sinon le banc mesure une règle qu'on ne veut pas. Nous avons gardé « Md€ », en laissant au code la conversion.

### Pièges et bonnes pratiques

- **Décrire le code qu'on aimerait**, au lieu de celui qui existe. On le lit, puis on le teste sur des phrases choisies.
- **Confondre tolérance et vérification.** Une règle tolérante sans seuil écrit n'est plus vérifiable.
- **Croire qu'un paragraphe qui passe les six vérifications est juste.** Il est seulement traçable et bien formé.

> **À retenir.** Pour chaque consigne : ce que vérifie le code, puis qui répare. Ce qui se répare sans jugement va au code ; ce qui demande de réécrire va au modèle, sous contrôle du code ; ce que personne ne peut savoir va à l'humain. Le vérificateur a des angles morts : la grandeur, l'unité, les nombres en lettres.

### Pour vérifier que vous avez compris

1. Pourquoi « 25,1 % [F03] » passe-t-il les six vérifications, et qu'est-ce qui fermera ce trou au jour 4 ?
2. Pourquoi le code peut-il écrire seul la ligne de source, mais pas réparer « près de 25 Md€ » ?

### Références

- Thomson, C., Reiter, E. (2020). *A Gold Standard Methodology for Evaluating Accuracy in Data-To-Text Systems*. Proceedings of INLG 2020, p. 158–168. https://doi.org/10.18653/v1/2020.inlg-1.22 — **Ce qu'on y apprend :** une typologie des erreurs des textes générés à partir de données, dont les erreurs de contexte, et une méthode d'annotation humaine.
- Gao, T., Yen, H., Yu, J., Chen, D. (2023). *Enabling Large Language Models to Generate Text with Citations*. Proceedings of EMNLP 2023, p. 6465–6488. https://doi.org/10.18653/v1/2023.emnlp-main.398 — **Ce qu'on y apprend :** comment mesurer si chaque affirmation d'un texte généré est soutenue par la source qu'il cite.
- Jiang, Y., Wang, Y., Zeng, X., Zhong, W., Li, L., Mi, F., Shang, L., Jiang, X., Liu, Q., Wang, W. (2024). *FollowBench: A Multi-level Fine-grained Constraints Following Benchmark for Large Language Models*. Proceedings of ACL 2024, p. 4667–4688. https://doi.org/10.18653/v1/2024.acl-long.257 — **Ce qu'on y apprend :** le respect des consignes baisse quand elles s'accumulent, ce qui justifie de mesurer les six à la fois.

## Chapitre 3 — Vérifier l'étalon

### Ce que nous avons fait

La fiche de faits du cas 7 compte dix-neuf faits, chacun avec un libellé, une valeur, une unité et une référence. Elle avait été établie à partir de notes et d'extraits, pas de la publication elle-même. Avant de préenregistrer, nous l'avons confrontée au PDF de l'EcoDef Statistiques n° 273, fait par fait, sur trois points : la valeur, l'unité, et ce que mesure exactement le libellé.

Le PDF ne contenait pas de texte exploitable par la machine : ses six pages ont été lues comme des images. Les corrections ont été appliquées par un script qui conserve la mise en forme du fichier, pour que `git diff` ne montre que les onze lignes modifiées. Le plan préenregistré mentionne cette vérification et ses corrections.

### Pourquoi cette étape

**La fiche est l'étalon de la mesure.** La consigne de fidélité compare chaque nombre du texte à la fiche. Si un libellé est faux, un modèle qui le recopie fidèlement écrit une phrase fausse, et le code la certifie. Vérifier l'instrument avant de mesurer est aussi élémentaire que d'étalonner une balance.

**L'exactitude ne se réduit pas aux valeurs.** Wang et Strong (1996) ont montré, en interrogeant des utilisateurs de données, que la qualité perçue tient à plusieurs dimensions : l'exactitude, mais aussi l'interprétabilité et la pertinence du contexte. Une valeur juste, avec un libellé qui omet son champ, est une donnée de mauvaise qualité.

### Comment ça marche

**Trois vérifications par fait.** La valeur, à la décimale près. L'unité. Et le champ : résidents ou non, entreprises privées ou toutes, quelle année, et pour une part, sur quel total.

**L'arithmétique des nombres arrondis.** Les publications arrondissent au dixième. Un rapport calculé sur des valeurs arrondies n'est donc connu qu'à un intervalle près.

> **Formule.** Si a et b sont arrondis au dixième, leurs vraies valeurs sont dans [a − 0,05 ; a + 0,05] et [b − 0,05 ; b + 0,05]. Le rapport a/b est alors compris entre (a − 0,05)/(b + 0,05) et (a + 0,05)/(b − 0,05). C'est le principe de l'arithmétique d'intervalles (Moore et coll., 2009).

Elle a servi deux fois, dans deux sens opposés.

- **F10 : un écart qui ne prouve rien.** 17,7 Md€ sur 25,1 Md€ donnent 70,5 %, et la publication écrit 70,7 %. Mais le vrai rapport est compris entre 17,65/25,15 = 70,2 % et 17,75/25,05 = 70,9 % : 70,7 % y est. L'écart s'explique par les arrondis.
- **F15 et F11 : une contradiction réelle.** Tel qu'il était écrit, F15 disait que 90,6 % des paiements à l'industrie vont aux grandes entreprises, soit 0,906 × 17,7 = 16,0 Md€. Or F11 donnait 15,8 Md€ pour les grandes entreprises de tous les secteurs. Une partie ne peut pas dépasser le tout : même en poussant les arrondis à l'extrême, on obtient au moins 15,98 Md€ contre au plus 15,85. Un des libellés était faux.

**La réconciliation par les figures.** La figure 1 de la publication répartit par taille les seules entreprises *privées* (grandes entreprises : 15,8 Md€ ; ETI : 3,3 Md€) et donne aux entreprises publiques une ligne à part (3,6 Md€). La figure 3, elle, classe par taille toutes les entreprises résidentes, publiques comprises. En reconstituant ses montants secteur par secteur, ses grandes entreprises reçoivent environ 19,0 Md€ et ses ETI environ 3,8 Md€ : 3,7 Md€ de plus que dans la figure 1, à peu près le montant des entreprises publiques. F15 était juste ; c'était F11 qui omettait le mot « privées ».

### Ce que nous avons observé

<!-- largeurs: 14,86 -->
| Fait | Correction |
| --- | --- |
| Les 19 | Toutes les valeurs sont justes |
| F11 à F14 | « privées » ajouté, comme dans la figure 1 |
| F07 | 25 486 fournisseurs, valeur exacte de la figure 1, au lieu de l'arrondi du texte, « près de 25 500 » |
| F10 | Champ confirmé, les paiements aux fournisseurs résidents ; libellé aligné sur la publication |
| F19 | Le programme 212 s'appelle « Soutien de la politique de défense » |
| F04 | « Part des paiements versés aux fournisseurs résidents », pour ne plus le confondre avec F08, qui compte des fournisseurs |
| Références | Page et figure précisées pour chaque fait |

La correction de F11 a eu un effet visible plus tard : dans les paragraphes rédigés par le modèle, les 15,8 Md€ sont devenus ceux des « grandes entreprises privées ». Un modèle qui recopie les libellés hérite de leur précision, ou de leur imprécision.

> **Attention.** Le programme de la séance contenait deux erreurs sur ce point. Il concluait que l'écart de F10 prouvait un autre champ : c'était un effet d'arrondi. Puis il soupçonnait F15 : c'était F11. La première se corrige par l'arithmétique d'intervalles, la seconde par la lecture des figures. Dans les deux cas, la vérification contre la source a eu le dernier mot.

### Pièges et bonnes pratiques

- **Traiter un rapport de nombres arrondis comme exact.** Un écart d'un ou deux dixièmes ne prouve rien tant qu'on n'a pas calculé l'intervalle.
- **Un libellé qui omet son champ.** C'est l'erreur la plus dangereuse : la valeur est juste, le code la valide, et la phrase qui la reprend est fausse.
- **Prendre l'arrondi du texte quand le tableau donne la valeur exacte.** Un registre garde la valeur publiée la plus précise ; arrondir est un choix d'écriture.
- **Corriger à la main un fichier de données.** Un script qui conserve la mise en forme rend la correction relisible.

> **À retenir.** La fiche est l'étalon : elle se vérifie contre la source avant toute mesure. Sur des nombres arrondis, on raisonne par intervalles. Deux figures d'une même publication peuvent couvrir deux champs différents : le libellé doit le dire.

### Pour vérifier que vous avez compris

1. 25,1 Md€ sur 30,3 Md€ donnent 82,8 %, et la publication écrit 82,9 % (F04). Y a-t-il contradiction ? Faites le calcul d'intervalle.
2. Pourquoi l'ajout du seul mot « privées » change-t-il la justesse des textes produits par un modèle qui recopie les libellés ?

### Références

- Moore, R. E., Kearfott, R. B., Cloud, M. J. (2009). *Introduction to Interval Analysis*. SIAM. https://doi.org/10.1137/1.9780898717716 — **Ce qu'on y apprend :** calculer avec des intervalles plutôt qu'avec des valeurs ponctuelles, pour savoir ce qu'un calcul sur des données imprécises permet de conclure.
- Wang, R. Y., Strong, D. M. (1996). *Beyond Accuracy: What Data Quality Means to Data Consumers*. Journal of Management Information Systems, 12(4), p. 5–33. https://doi.org/10.1080/07421222.1996.11518099 — **Ce qu'on y apprend :** les dimensions de la qualité des données telles que les utilisateurs les perçoivent, au-delà de l'exactitude des valeurs.

## Chapitre 4 — Préenregistrer et parier

### Ce que nous avons fait

Trois gestes, dans cet ordre, avant le premier appel au modèle :

1. **Compléter la section du cas 7** dans `banc/PLAN.md` : le nom de la campagne, `2026-11-24-gemma4-26b-moe-ecodef`, le serveur, le modèle, et la mention de la fiche vérifiée.
2. **Écrire mes paris**, puis lire ceux de Claude, écrits la veille.
3. **Commiter le tout**, après avoir vérifié que la clé n'y figurait pas : commit `24a9ba2`, « docs: plan du cas 7 (consignes EcoDef) et prédictions ».

Les règles de décision étaient déjà écrites : une consigne respectée moins de 19 fois sur 20 est confiée au code ; la décision sur la langue des consignes est confirmée si le français ne fait pas nettement moins bien que l'anglais ; les faits peuvent arriver par un outil si la fidélité y reste à 19 sur 20 au moins ; plus d'une réponse coupée par condition impose un écart déclaré.

### Pourquoi cette étape

**Séparer la prédiction de la lecture.** Nosek et ses coauteurs (2018) distinguent la prédiction, faite avant de voir les données, de la « postdiction », qui explique après coup ce qu'on a vu. Les deux sont utiles, mais seule la première met une hypothèse à l'épreuve. Le préenregistrement les sépare par une date : celle du commit.

**Limiter ses propres degrés de liberté.** Simmons, Nelson et Simonsohn (2011) ont montré qu'en choisissant après coup ses règles d'analyse, on peut rendre « significatif » presque n'importe quoi. Écrire les règles avant la mesure retire cette liberté, et rend le résultat crédible, y compris pour soi-même.

**Un pari rend l'apprentissage mesurable.** Une prédiction sans nombre ne peut pas être fausse, donc n'apprend rien. Brier (1950) a proposé, pour les prévisions météorologiques, un score qui compare la probabilité annoncée à ce qui s'est produit : c'est l'ancêtre des scores qui mesurent aujourd'hui la calibration d'un prévisionniste.

### Comment ça marche

**Le taux des six à la fois.** Il ne peut pas dépasser le taux de la consigne la moins respectée. Si les échecs étaient indépendants, il vaudrait le produit des six taux.

> **Formule.** Avec des taux p₁ à p₆ indépendants, le taux de réussite simultanée vaut p₁ × p₂ × … × p₆. Six consignes à 18/20 donnent 0,9⁶ ≈ 0,53, soit environ 11 sur 20.

Avec mes taux (18, 20, 20, 20, 17 et 19 sur 20), le produit donnait environ 14,5 sur 20 ; j'avais parié 16. Parier au-dessus du produit, c'est parier que les échecs se concentrent sur les mêmes réponses. Claude, avec des taux plus bas, obtenait un produit d'environ 25 %, soit 5 sur 20, et pariait 6, pour la même raison : les échecs se concentreraient sur les sujets à quatre chiffres.

**Ce qu'est un écart « net ».** Le test exact de McNemar compare deux conditions sur les mêmes sujets en ne regardant que les paires discordantes.

> **Formule.** Avec b sujets qui réussissent seulement dans la première condition et c seulement dans la seconde, la valeur p bilatérale vaut 2 × P(X ≤ min(b, c)), où X suit une loi binomiale de paramètres b + c et 1/2. Six paires discordantes, toutes dans le même sens, donnent p = 2 × 0,5⁶ ≈ 0,031 : c'est le minimum pour un écart net au seuil de 5 %.

### Ce que nous avons observé

<!-- largeurs: 28,24,24,24 -->
| Mesure (condition `fiche`) | Mon pari | Pari de Claude | Résultat (chapitre 6) |
| --- | --- | --- | --- |
| Aucun chiffre hors de la fiche | 18/20 | 17/20 | 20/20 |
| Un identifiant après chaque chiffre | 20/20 | 13/20 | 20/20 |
| Montants en Md€ | 20/20 | 16/20 | 20/20 |
| Évolutions signées | 20/20 | 14/20 | 20/20 |
| Texte brut | 17/20 | 19/20 | 20/20 |
| Ligne de source | 19/20 | 17/20 | 20/20 |
| Les six à la fois | 16/20 | 6/20 | 20/20 |

Pour les comparaisons, nous pariions tous deux qu'il n'y aurait pas d'écart net, ni avec l'outil, ni avec l'anglais, et aucune réponse coupée. Mes paris étaient bien plus proches du résultat que ceux de Claude, sans raison écrite pour la plupart : « par intuition ».

### La question posée pendant la séance

*Comment parier avec une simple intuition, et peut-on s'aider des paris d'un autre ?*

Trois réponses. D'abord, « par intuition » est une raison honnête, bien meilleure qu'une raison inventée après coup : elle sera confrontée au résultat comme les autres. Ensuite, on ne retouche pas ses chiffres après avoir lu ceux d'un autre : c'est l'écart entre son intuition et le résultat qui apprend quelque chose. Enfin, un pari préenregistré ne doit permettre qu'une lecture. Mes trois derniers paris étaient écrits « 4 », « 0 » et « 20 » : quatre réponses avec un chiffre inventé en `outil`, aucun écart avec l'anglais, vingt réponses sur vingt menées au bout. Nous les avons réécrits avec leur unité.

### Pièges et bonnes pratiques

- **Un pari sans nombre ni unité.** « 4 » peut se lire de plusieurs façons ; « fidélité 16/20 en `outil` » d'une seule.
- **Parier « 90 % partout ».** C'est refuser de se demander quelle consigne le modèle ratera le plus.
- **Modifier ses paris après avoir lu ceux des autres**, ou après le premier appel.
- **Commiter le plan après le premier appel.** La date du commit est la seule preuve que les règles précèdent la mesure.

> **À retenir.** Le plan et les paris se commitent avant le premier appel. Un pari, c'est un nombre, une unité et une raison, même si la raison est « intuition ». Le taux des six à la fois ne dépasse jamais le plus faible des six, et sous indépendance, il vaut leur produit.

### Pour vérifier que vous avez compris

1. Six consignes à 18/20, indépendantes : quel taux attendre pour les six à la fois ? Et si les échecs tombent tous sur les deux mêmes essais ?
2. Pourquoi le commit du plan doit-il précéder le premier appel, et que prouve-t-il exactement ?

### Références

- Nosek, B. A., Ebersole, C. R., DeHaven, A. C., Mellor, D. T. (2018). *The preregistration revolution*. Proceedings of the National Academy of Sciences, 115(11), p. 2600–2606. https://doi.org/10.1073/pnas.1708274114 — **Ce qu'on y apprend :** la différence entre prédiction et postdiction, et comment le préenregistrement les sépare.
- Simmons, J. P., Nelson, L. D., Simonsohn, U. (2011). *False-Positive Psychology: Undisclosed Flexibility in Data Collection and Analysis Allows Presenting Anything as Significant*. Psychological Science, 22(11), p. 1359–1366. https://doi.org/10.1177/0956797611417632 — **Ce qu'on y apprend :** comment des choix faits après coup produisent de faux résultats, et les règles qui l'empêchent.
- Brier, G. W. (1950). *Verification of forecasts expressed in terms of probability*. Monthly Weather Review, 78(1), p. 1–3. https://doi.org/10.1175/1520-0493(1950)078<0001:VOFEIT>2.0.CO;2 — **Ce qu'on y apprend :** un score simple pour juger des prévisions chiffrées, première pierre de la mesure de la calibration.

## Chapitre 5 — Répéter, puis lancer

### Ce que nous avons fait

**La répétition générale.** Dans un second terminal, j'ai lancé le faux serveur (`python3 outils/faux_serveur.py 8765`). Dans le premier, le banc a joué tout le cas 7 contre lui, avec des variables placées devant la commande :

```bash
NO_PROXY=127.0.0.1 LLM_URL=http://127.0.0.1:8765/v1 LLM_CLE=essai LLM_MODELE=modele-test \
LLM_JOURNAL=/tmp/repetition7/appels.jsonl \
python3 -m banc --campagne repetition --cas ecodef --sortie /tmp/repetition7
```

Soixante essais, soixante appels, en une seconde. Le tableau obtenu était identique, au chiffre près, à celui que Claude avait obtenu de son côté avec la même fiche corrigée.

**La campagne.** Après trois vérifications (la cible, la présence de la clé, le commit du plan en dernier), le banc a lancé les 60 appels réels :

```bash
python3 -m banc --campagne 2026-11-24-gemma4-26b-moe-ecodef --cas ecodef 2>&1 | tee banc-ecodef.log
```

Résultat : « 60 essais ; 60 appels envoyés en 58 s », et soixante lignes « réussi (envoyé) ». Aucune ligne « coupé par le plafond ».

**Le commit avant la lecture.** Les mesures, le journal et le fichier `banc-ecodef.log` ont été commités avant toute lecture du rapport : commit `0fd6657`. `git log` montrait l'ordre attendu : les sondes, puis le plan, puis les mesures.

### Pourquoi cette étape

**Vérifier que l'instrument trouve les fautes.** Le faux serveur glisse une faute connue dans quatre réponses sur dix : un identifiant oublié, un signe manquant, un montant en milliards, une ligne de source absente, un chiffre faux, du Markdown. Si chaque ligne du tableau montre au moins un échec, chaque vérificateur trouve ce qu'il cherche. Meszaros (2007) range ce genre d'objet parmi les doublures de test : un faux composant, contrôlable, qui remplace le vrai pendant l'essai. Ribeiro et ses coauteurs (2020) défendent la même idée pour les modèles de langue : tester des comportements dont on connaît la réponse attendue.

**Vérifier avant de croire.** Kohavi, Tang et Xu (2020) recommandent, avant toute expérience, des contrôles de cohérence : l'expérience doit retrouver ce qu'on sait déjà. La répétition en est un. Un banc qui ne trouverait aucune des fautes plantées mesurerait mal, quel que soit le modèle.

**Figer les mesures avant de les lire.** Une fois commités, les résultats ne peuvent plus être modifiés, même inconsciemment, par ce qu'on y lira. Le programme plaçait ce commit plus tard ; le faire tout de suite est plus sûr.

### Comment ça marche

**Des variables qui ne valent que pour une commande.** Placées devant la commande, les variables ne s'appliquent qu'à elle : la vraie clé ne part pas vers le faux serveur, et les faux appels ne touchent pas le journal du dépôt.

**Une doublure reproductible.** Le faux serveur ne tire pas ses fautes au hasard : il calcule l'empreinte SHA-256 du message reçu, et en déduit la faute éventuelle. Le même message produit donc toujours la même réponse. C'est ce qui a permis de comparer deux environnements : si le tableau de ma répétition différait de celui de Claude, ma fiche différait de la sienne.

**Ce que veut dire « réussi ».** Dans le journal du banc, « réussi » signifie : les six consignes respectées, et une réponse rédigée en français. « Envoyé » signifie que l'appel est parti au serveur ; « relu », qu'il a été lu dans le journal.

### Ce que nous avons observé

La répétition, sur 20 essais par condition :

```
                 fiche  outil  anglais
fidélité           18     18     19
identifiants       15     17     18
Md€                15     17     18
signes             19     18     19
sans Markdown      20     17     18
source             19     19     17
les six            10     13     11
```

Chaque ligne a au moins une case sous 20 : l'instrument trouve les fautes. Puis la campagne réelle : 60 réussites sur 60, sans réponse coupée.

### Pièges et bonnes pratiques

- **Oublier `LLM_JOURNAL` pendant la répétition :** les faux appels se mêleraient au journal du dépôt.
- **Envoyer la vraie clé au faux serveur**, en exportant les variables au lieu de les placer devant la commande.
- **Lire le rapport avant de commiter les mesures.**
- **Relancer un bloc de commit déjà exécuté.** Git répond « no changes added to commit » : rien n'est perdu, les fichiers avaient été commités au premier passage. `git log --oneline -3` le confirme.

> **À retenir.** Une répétition contre une doublure qui plante des fautes connues prouve que l'instrument les trouve. Une doublure déterministe permet de comparer deux environnements. Les mesures se commitent avant d'être lues.

### Pour vérifier que vous avez compris

1. Pourquoi la répétition doit-elle montrer au moins un échec dans chaque ligne du tableau ? Que conclure d'une ligne à 20/20 dans les trois colonnes ?
2. Pourquoi un faux serveur déterministe permet-il de vérifier que deux personnes ont la même fiche ?

### Références

- Meszaros, G. (2007). *xUnit Test Patterns: Refactoring Test Code*. Addison-Wesley. — **Ce qu'on y apprend :** la famille des doublures de test (bouchons, simulacres, faux), et quand utiliser chacune.
- Ribeiro, M. T., Wu, T., Guestrin, C., Singh, S. (2020). *Beyond Accuracy: Behavioral Testing of NLP Models with CheckList*. Proceedings of ACL 2020, p. 4902–4912. https://doi.org/10.18653/v1/2020.acl-main.442 — **Ce qu'on y apprend :** tester un modèle de langue comme un logiciel, sur des comportements dont on connaît la réponse attendue.
- Kohavi, R., Tang, D., Xu, Y. (2020). *Trustworthy Online Controlled Experiments: A Practical Guide to A/B Testing*. Cambridge University Press. https://doi.org/10.1017/9781108653985 — **Ce qu'on y apprend :** les contrôles qui rendent une expérience digne de confiance, et la « loi de Twyman », qu'on retrouve au chapitre 6.

## Chapitre 6 — Lire un résultat trop beau

### Ce que nous avons fait

Le rapport ne contenait que des 20 sur 20 : chaque consigne, dans chaque condition, et les six à la fois. Aucune paire discordante entre les conditions, aucune réponse coupée, rédigée en anglais ou refusée.

Il n'y avait donc aucun échec à suivre jusqu'au journal. Nous avons fait l'inverse : lire des réussites. Un court script a extrait du journal trois paragraphes de la condition `fiche`, choisis parce qu'ils réunissent des faits voisins, donc piégeux : s04, s17 et s18. Je les ai lus en cherchant ce que le code ne voit pas. La fiche de lecture et ses « surprises » sont dans mon journal.

### Pourquoi cette étape

**Un résultat parfait se vérifie avant d'être cru.** Kohavi et ses coauteurs (2020) rapportent la « loi de Twyman » : tout chiffre qui paraît intéressant ou très différent de l'attendu est le plus souvent faux. Un 60 sur 60, meilleur que les deux paris, en est un candidat.

**Le code ne voit que ce qu'il vérifie.** Le chapitre 2 a établi ses angles morts. La relecture humaine est la méthode de référence de Thomson et Reiter (2020) pour évaluer l'exactitude d'un texte généré : des annotateurs lisent chaque phrase contre les données.

### Comment ça marche

**Ce que vaut un 20 sur 20.** L'intervalle de Wilson à 95 % est [83,9 % ; 100 %].

> **Formule.** Quand tous les essais réussissent (x = n), la borne basse de l'intervalle de Wilson vaut n/(n + z²), avec z = 1,96 au niveau de 95 %. Pour n = 20 : 20/(20 + 3,84) ≈ 0,839 (Wilson, 1927).

**Une borne pour le taux d'échec.** Avec zéro échec sur n essais, on cherche le plus grand taux d'échec p encore compatible avec ce résultat.

> **Formule.** La probabilité de n réussites quand le taux d'échec vaut p est (1 − p)ⁿ. On la fixe à 5 % : p = 1 − 0,05^(1/n). Pour n = 20, p ≈ 13,9 % ; pour n = 60, p ≈ 4,9 %. C'est la borne exacte de Clopper et Pearson (1934). La « règle de trois », p ≈ 3/n, en donne une bonne approximation (Hanley et Lippman-Hand, 1983).

Vingt réussites sur vingt disent donc seulement que le taux d'échec est probablement inférieur à 14 % dans chaque condition. C'est beaucoup, et ce n'est pas zéro.

**Trois paragraphes lus à l'œil.** Sur les chiffres, la lecture confirme le résultat : chaque nombre est juste et attaché à la bonne grandeur. Mais elle montre trois choses que le banc ne mesure pas.

- **s17 ne répond pas à la question.** La question demandait si les paiements aux fournisseurs résidents avaient progressé plus vite que l'ensemble. Le paragraphe pose les deux évolutions côte à côte, sans jamais conclure : « …avec une évolution de +6,1 % [F02] entre 2023 et 2024. Les paiements directs aux fournisseurs résidents atteignent 25,1 Md€ [F03] et affichent une progression de +9,4 % [F05] sur la même période. »
- **s18 oppose ce qui ne s'oppose pas.** « …la part versée aux grandes entreprises atteint 90,6 % [F15], alors que les paiements aux grandes entreprises privées résidentes s'établissent à 15,8 Md€ [F11]. » « Alors que » met face à face deux grandeurs aux champs différents : c'est le piège du chapitre 3, déplacé dans la phrase.
- **s04 recopie les libellés.** « …une part de 82,9 % [F04] des paiements versés aux fournisseurs résidents dans l'ensemble des paiements en 2024. » C'est juste, mais ce n'est pas encore une phrase de publication.

**Pourquoi 60 sur 60.** La fiche donne chaque valeur au format demandé : « +9,4 % », « 25,1 Md€ ». La consigne montre, par un exemple, où placer l'identifiant. En recopiant, le modèle respecte d'office les signes et le format. Min et ses coauteurs (2022) ont montré un phénomène voisin : dans les exemples donnés au modèle, c'est la forme, plus que l'exactitude du contenu, qui guide sa réponse. Le cas 7 a donc surtout mesuré la tendance du modèle à recopier une fiche bien formatée.

### Ce que nous avons observé

L'explication est une hypothèse, et elle se teste : refaire le cas avec une fiche aux valeurs non formatées, sans signe et en millions d'euros, et voir si les taux chutent. Elle explique aussi pourquoi mes paris étaient plus justes que ceux de Claude : Claude imaginait un modèle qui rédige en prose française naturelle (« en hausse de 9,4 % », « 25,1 milliards d'euros ») ; le modèle a recopié.

C'est de nouveau une question de validité, celle que j'avais soulevée au jour 2 à propos du cas des consignes : le test mesure-t-il ce que l'on croit mesurer ? Ici, il mesure le respect de consignes de forme quand l'entrée montre déjà la forme attendue. C'est utile, et c'est un argument pour la suite : si la forme vient de la fiche, autant que ce soit le code qui l'écrive.

### Pièges et bonnes pratiques

- **Prendre 20 sur 20 pour une perfection.** Avec vingt essais, le taux d'échec peut encore approcher 14 %.
- **Conclure que le modèle obéit, alors qu'il recopie.** Le même résultat a deux explications ; seule une nouvelle mesure les départage.
- **Ne lire aucune sortie quand tout réussit.** Quand il n'y a pas d'échec à suivre, on lit des réussites, en choisissant les cas les plus piégeux.

> **À retenir.** Un résultat trop beau se vérifie : on calcule ce qu'il borne, puis on lit des sorties. 20 sur 20 borne le taux d'échec à 13,9 %, pas à zéro. Un modèle qui respecte un format peut simplement recopier celui qu'on lui montre. Le code vérifie la forme et la traçabilité ; la réponse à la question et la logique des phrases restent à l'humain.

### Pour vérifier que vous avez compris

1. Zéro échec sur 20 essais : quelle borne à 95 % pour le taux d'échec ? Et sur 60 essais identiques ? Que donne la règle de trois dans les deux cas ?
2. Proposez une mesure qui départage « le modèle obéit aux consignes » et « le modèle recopie la fiche ».

### Références

- Wilson, E. B. (1927). *Probable Inference, the Law of Succession, and Statistical Inference*. Journal of the American Statistical Association, 22(158), p. 209–212. https://doi.org/10.1080/01621459.1927.10502953 — **Ce qu'on y apprend :** l'intervalle qui reste juste aux bords, quand tous les essais réussissent ou échouent.
- Clopper, C. J., Pearson, E. S. (1934). *The use of confidence or fiducial limits illustrated in the case of the binomial*. Biometrika, 26(4), p. 404–413. https://doi.org/10.1093/biomet/26.4.404 — **Ce qu'on y apprend :** les bornes exactes d'une proportion binomiale, dont celle du cas « zéro échec ».
- Min, S., Lyu, X., Holtzman, A., Artetxe, M., Lewis, M., Hajishirzi, H., Zettlemoyer, L. (2022). *Rethinking the Role of Demonstrations: What Makes In-Context Learning Work?* Proceedings of EMNLP 2022, p. 11048–11064. https://doi.org/10.18653/v1/2022.emnlp-main.759 — **Ce qu'on y apprend :** la forme des exemples donnés au modèle compte souvent plus que l'exactitude de leur contenu.

## Chapitre 7 — L'ADR-002

### Ce que nous avons fait

L'`ADR-002` a été rempli à partir de la fiche de lecture, puis commité avec mon journal (commit `059a1a6`). Dans le même temps, la branche `jour-3` a été poussée pour la première fois sur GitHub, avec `git push -u origin jour-3`, et ensuite après chaque commit.

<!-- largeurs: 30,12,28,30 -->
| Consigne | Taux en `fiche` | Qui s'en charge | Pourquoi |
| --- | --- | --- | --- |
| Aucun chiffre hors de la fiche | 20/20 | Le code, toujours | Règle du projet : un taux, même de 20 sur 20, laisse un risque |
| Un identifiant après chaque chiffre | 20/20 | Le modèle, vérifié par le code | Au-dessus de la règle de 19 sur 20 |
| Montants en Md€ | 20/20 | Le modèle, vérifié par le code | Au-dessus de la règle |
| Évolutions signées | 20/20 | Le modèle, vérifié par le code | Au-dessus de la règle |
| Texte brut | 20/20 | Le modèle, vérifié par le code | Au-dessus de la règle |
| Ligne de source | 20/20 | Le modèle, vérifié par le code | Au-dessus de la règle |

S'y ajoutent deux décisions. La langue des consignes, provisoire dans l'`ADR-001`, est confirmée : le français. Et les faits peuvent arriver au modèle par le résultat d'un outil, puisque la fidélité y est restée à 20 sur 20.

### Pourquoi cette étape

**Une décision s'écrit le jour où on la prend.** Nygard (2011) a proposé une forme légère pour consigner les décisions d'architecture : le contexte, la décision, ses conséquences. Dans trois mois, quand quelqu'un demandera pourquoi la ligne de source est vérifiée par le code, la réponse sera dans le dépôt, avec ses preuves.

**Les décisions suivent la règle écrite avant.** Toutes les consignes sont à 20 sur 20, donc toutes restent au modèle, et le code les vérifie quand même. La tentation serait d'ajuster la règle au résultat ; le préenregistrement l'interdit.

**Distinguer une règle d'une leçon.** L'`ADR-002` annonce pourtant qu'au jour 4, le code rendra lui-même les chiffres, leur format et la ligne de source. Ce n'est pas une entorse à la règle : cette décision ne vient pas des taux, mais de ce que la lecture a montré, la recopie. L'ADR le dit explicitement.

### Comment ça marche

**Ce que dit un test de McNemar sans paire discordante.** Entre `fiche` et `anglais`, les vingt sujets réussissent des deux côtés : zéro paire discordante, donc p = 1. Cela ne prouve pas que les deux conditions se valent ; cela dit qu'aucune donnée ne montre de différence. La règle préenregistrée était formulée pour ce cas : la décision est confirmée si le français ne fait pas nettement moins bien.

**Ce que l'ADR ne garantit pas.** Un modèle, un serveur, une date ; vingt sujets tirés d'une seule publication ; un taux d'échec seulement borné à 13,9 % par condition ; des consignes de forme et de traçabilité, qui ne disent rien de la justesse des phrases. Cette section est aussi importante que les décisions : elle dit quand les revoir.

### Ce que nous avons observé

Les décisions n'ont demandé aucune délibération : la règle les donnait. Le travail a porté sur ce que les mesures ne couvrent pas, et sur les conséquences pour le graphe : le nœud `verifier` contrôle les six consignes sur chaque texte, quels que soient les taux ; le nœud `valider` reste seul juge du sens.

### La question posée pendant la séance

*À quel moment pousser le travail sur GitHub, quand le service peut disparaître ?*

La réponse : maintenant, puis après chaque commit. La première fois, `git push -u origin jour-3` crée la branche sur GitHub et la relie à la branche locale (`-u` pour *upstream*) ; ensuite, `git push` suffit. Pousser une branche ne fusionne rien : la pull request viendrait à la clôture. Les fichiers de la partie B, pas encore commités, restaient dans le paquet `jour3.zip`, à récupérer sans écraser les commits si le service disparaissait.

### Pièges et bonnes pratiques

- **Décider au sentiment, après avoir vu les résultats**, au lieu d'appliquer la règle écrite.
- **Écrire des preuves de mémoire.** Chaque taux de l'ADR se recopie du rapport.
- **Lire p = 1 comme une preuve d'équivalence.** Sans paire discordante, le test ne dit rien sur la taille d'un éventuel écart.
- **Laisser des commits dans un service fragile.** Une branche poussée ne craint plus sa disparition.

> **À retenir.** Un ADR consigne la décision, ses preuves, ses conséquences et ses limites. Les décisions suivent la règle préenregistrée ; une leçon tirée de la lecture peut orienter la suite, à condition d'être présentée comme telle. On pousse après chaque commit.

### Pour vérifier que vous avez compris

1. Pourquoi l'annonce du rendu par le code, au jour 4, n'est-elle pas une entorse à la règle préenregistrée ?
2. Entre `fiche` et `anglais`, le test de McNemar donne p = 1 avec zéro paire discordante. Que permet-il de conclure, et que ne permet-il pas ?

### Références

- Nygard, M. (2011). *Documenting Architecture Decisions*. Billet technique, Cognitect, 15 novembre 2011. https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions — **Ce qu'on y apprend :** la forme légère du relevé de décision d'architecture, et pourquoi l'écrire au moment de la décision.
- McNemar, Q. (1947). *Note on the sampling error of the difference between correlated proportions or percentages*. Psychometrika, 12(2), p. 153–157. https://doi.org/10.1007/BF02295996 — **Ce qu'on y apprend :** comparer deux proportions mesurées sur les mêmes sujets, en ne regardant que les paires discordantes.

## Chapitre 8 — Une dépendance, épinglée et figée

### Ce que nous avons fait

Le 25 novembre, la partie B a commencé par deux vérifications : les fichiers du graphe, livrés la veille, étaient toujours là (`git status --short`), et Python était en version 3.13, au-dessus du minimum de 3.10. Puis, dans le dossier du dépôt :

```bash
python3 -m venv .venv
. .venv/bin/activate                  # à refaire dans chaque nouveau terminal
pip install -r requirements.txt
python3 -c "import importlib.metadata as m; print(m.version('langgraph'))"   # 1.2.24
pip freeze > requirements-fige.txt
git status --short                    # .venv/ ne doit pas apparaître
```

Le commit `bb02d66`, « build: LangGraph 1.2.24 et sauvegarde SQLite 3.1.3, versions épinglées », contient `requirements.txt`, `requirements-fige.txt` et `.gitignore`. Il a été poussé aussitôt. Ce bloc n'a connu aucun incident.

### Pourquoi cette étape

**Une dépendance peut changer votre code sans que vous y touchiez.** Jusqu'ici, l'enveloppe et le banc n'utilisaient que la bibliothèque standard de Python. Le graphe a besoin de LangGraph, qui a ses propres dépendances. Si l'une d'elles change de version, le comportement du programme peut changer, sans qu'une seule ligne du dépôt ait bougé. Sandve et ses coauteurs (2013) en font l'une de leurs dix règles de la recherche reproductible : archiver la version exacte de chaque programme dont on dépend.

**Deux fichiers, deux rôles.** `requirements.txt` dit ce que nous avons choisi : deux bibliothèques, épinglées avec `==`. `requirements-fige.txt` dit ce qui a réellement été installé ce jour-là, dépendances des dépendances comprises. La documentation de pip décrit cette gradation.

**Un environnement par projet.** L'environnement virtuel isole les paquets du dépôt de ceux du système et des autres projets. On versionne la liste des paquets, jamais les paquets eux-mêmes : `.venv/` est ignoré par git.

### Comment ça marche

**Ce qu'est un environnement virtuel.** `python3 -m venv .venv` crée un dossier qui contient un lanceur `python3` et son propre répertoire de paquets, `site-packages`. Le mécanisme est décrit par la PEP 405 (Meyer, 2011). Le script `activate` place `.venv/bin` en tête du `PATH` : dans ce terminal, `python3` et `pip` désignent désormais ceux de l'environnement. `which python3` le confirme, et `deactivate` revient en arrière. Un nouveau terminal ne connaît pas cette activation : il faut la refaire.

**Comment pip choisit les versions.** Chaque paquet déclare ses dépendances avec des intervalles. LangGraph 1.2.24, par exemple, demande `langchain-core` en version 1.4.7 au moins et inférieure à 2. Pip résout cet arbre en prenant, pour chaque paquet, la version la plus récente qui satisfait toutes les contraintes, **au moment de l'installation**. Le même `requirements.txt`, installé dans six mois, peut donc produire un autre arbre, même si nos deux versions directes sont épinglées.

<!-- largeurs: 22,78 -->
| Écriture | Ce qu'elle accepte |
| --- | --- |
| `langgraph==1.2.24` | Exactement cette version |
| `langgraph~=1.2.24` | 1.2.24 ou une version corrective ultérieure de la série 1.2 (1.2.25…), pas la 1.3 |
| `langgraph>=1.2` | Toute version à partir de 1.2, y compris une future 2.0 |

**Trois degrés de reproductibilité.** Le premier épingle les dépendances directes. Le deuxième fige tout l'arbre installé (`pip freeze`) : `pip install -r requirements-fige.txt` réinstalle exactement les mêmes versions. Le troisième vérifie en plus l'empreinte de chaque fichier téléchargé (`--require-hashes`), pour être sûr que la version 1.2.24 d'aujourd'hui est bien le même fichier que celle de demain. C'est le rôle des fichiers de verrouillage, au programme du jour 12.

### Ce que nous avons observé

Deux dépendances choisies ont produit 41 paquets installés. Parmi les 39 autres, aucun n'a été choisi par nous : `langgraph-checkpoint` 4.3.2, `langchain-core` 1.8.4, `langsmith` 0.16.2, `pydantic` 2.14.4, `httpx` 0.28.1, etc. Chacun peut changer de comportement d'une version à l'autre ; `requirements-fige.txt` les fige tous.

La présence de `langchain-core` et de `langsmith` mérite une explication. LangGraph s'appuie sur les interfaces de `langchain-core`, qui dépend à son tour de `langsmith`. Nous n'appelons pourtant aucun modèle par LangChain : notre graphe passe par `llm.py` (chapitre 9). Et `langsmith` n'envoie rien : le traçage vers sa plateforme ne s'active que si une variable d'environnement le demande, comme `LANGSMITH_TRACING=true`, et nous n'en définissons aucune.

### Pièges et bonnes pratiques

- **Ouvrir un nouveau terminal sans réactiver l'environnement.** Le symptôme : `ModuleNotFoundError: No module named 'langgraph'`. Le remède : `. .venv/bin/activate`.
- **Lancer `pip freeze` hors de l'environnement.** Le fichier figerait les paquets du système, sans rapport avec le projet.
- **Commiter `.venv/`** : des milliers de fichiers, propres à une machine. `git status` le vérifie.
- **Copier un exemple trouvé en ligne sans regarder sa version.** Les noms et les signatures de LangGraph ont changé plusieurs fois avant la version 1.0 ; un exemple ancien peut ne plus fonctionner.

> **À retenir.** Une dépendance se choisit, s'épingle et se fige. `requirements.txt` dit ce qu'on a voulu, `requirements-fige.txt` ce qu'on a obtenu. Un environnement virtuel par projet, réactivé dans chaque terminal, et jamais versionné.

### Pour vérifier que vous avez compris

1. Pourquoi `pip install -r requirements.txt`, lancé dans six mois, pourrait-il installer d'autres paquets qu'aujourd'hui, alors que nos deux versions sont épinglées avec `==` ?
2. Que signifie `~=1.2.24`, et pourquoi avons-nous préféré `==` ?

### Références

- Sandve, G. K., Nekrutenko, A., Taylor, J., Hovig, E. (2013). *Ten Simple Rules for Reproducible Computational Research*. PLoS Computational Biology, 9(10), e1003285. https://doi.org/10.1371/journal.pcbi.1003285 — **Ce qu'on y apprend :** dix règles pour que chaque résultat garde la trace de sa production, versions des programmes comprises.
- Meyer, C. (2011). *PEP 405 – Python Virtual Environments*. Python Enhancement Proposals. https://peps.python.org/pep-0405/ — **Ce qu'on y apprend :** le mécanisme des environnements virtuels de Python, et pourquoi il est intégré au langage depuis la version 3.3.
- pip developers. *Repeatable Installs*. Documentation de pip. https://pip.pypa.io/en/stable/topics/repeatable-installs/ — **Ce qu'on y apprend :** les degrés de reproductibilité d'une installation, de l'épinglage au gel complet et aux empreintes.

## Chapitre 9 — Découvrir LangGraph

*Ce chapitre ne correspond à aucun bloc de la séance. Il a été ajouté au cours pour présenter LangGraph pas à pas, avant de lire notre graphe au chapitre 10. Son exemple jouet tourne en une seconde, sans modèle de langue, sans clé ni réseau. Il a été exécuté avec les versions épinglées au chapitre 8, et les sorties reproduites ici sont les siennes.*

### Ce que nous avons fait

Nous avons construit un graphe jouet sur le modèle du nôtre. Il a trois nœuds, `rediger`, `verifier` et `valider`, une boucle de correction et une pause pour la décision humaine. Une seule différence : le « rédacteur » n'est pas un modèle de langue, mais une fonction qui oublie la décimale au premier tour, exprès, puis se corrige.

Le jouet s'exécute en quatre temps :

1. un premier lancement, qui s'arrête devant l'humain ;
2. un coup d'œil à l'état du fil ;
3. la reprise, avec la décision ;
4. la liste des sauvegardes.

Une variante, `jouet_deux_temps.py`, refait la même chose en trois processus séparés, avec une sauvegarde SQLite, comme les commandes `lancer` et `decider` de notre graphe. Pour lancer le jouet soi-même, dans un dossier hors du dépôt mais visible dans l'explorateur de VS Code :

```bash
mkdir -p ~/work/jouet && cd ~/work/jouet
# y déposer jouet_graphe.py et jouet_deux_temps.py, puis :
. ~/work/assistant-etude-sourcee/.venv/bin/activate
python3 jouet_graphe.py
```

### Pourquoi cette étape

#### Le problème que LangGraph résout

Écrite en Python ordinaire, notre rédaction tiendrait en quelques lignes :

```python
brouillon = rediger(question)
for _ in range(2):         # deux reprises automatiques au plus
    anomalies = verifier(brouillon)
    if not anomalies:
        break
    brouillon = rediger(question, anomalies)
decision = input("valider, corriger ou abandonner ? ")
```

Ce script fonctionne tant que rien ne se passe mal. Il lui manque quatre capacités :

1. **Attendre longtemps.** `input()` bloque le processus. Si la relectrice décide le lendemain, le processus doit vivre jusque-là, et le service du SSP Cloud peut disparaître entre-temps.
2. **Survivre à une panne.** Si le processus meurt juste après l'appel au modèle, tout est perdu : il faut tout relancer, et payer l'appel une seconde fois.
3. **Garder l'histoire.** À quoi ressemblait le texte du tour 1 ? Qui a décidé quoi, et à quel tour ? Le script ne le sait plus.
4. **Reprendre ailleurs.** Décider depuis un autre terminal, ou un autre jour, suppose que l'état de la rédaction soit rangé quelque part, hors du processus.

Ajouter ces capacités à la main, c'est écrire un petit moteur : sauvegarder l'état après chaque étape, savoir où reprendre, gérer l'attente, puis éprouver le tout. C'est l'option 1 que l'`ADR-003` a écartée.

#### Ce qu'est LangGraph

LangGraph est une bibliothèque Python libre, publiée par la société LangChain. Sa documentation la présente comme un cadre d'orchestration « de bas niveau » pour des agents qui durent et qui gardent un état. On y décrit le travail comme un graphe : un état partagé, des nœuds, des arêtes. On peut y mêler des étapes écrites dans le code et des étapes confiées à un modèle. Le moteur fournit les quatre capacités qui manquaient au script : l'exécution durable, la reprise après panne, la pause pour un humain et l'historique des états. La version 1.0 date d'octobre 2025 ; elle a stabilisé l'interface des graphes sans la changer.

Trois noms circulent ensemble, qu'il faut savoir distinguer :

<!-- largeurs: 16,54,30 -->
| Nom | Ce que c'est | Dans notre projet |
| --- | --- | --- |
| LangChain | Des composants de haut niveau : connexions aux modèles, outils, et un agent tout prêt (`create_agent`), lui-même construit sur LangGraph | Non utilisé : l'`ADR-003` fait passer les appels par `llm.py` |
| LangGraph | Le moteur de bas niveau : graphe, état, sauvegardes, interruptions | Utilisé, en version 1.2.24 |
| LangSmith | La plateforme commerciale de LangChain, pour observer et déployer des agents | Non utilisé |

LangGraph n'oblige pas à passer par LangChain pour appeler un modèle : un nœud est une fonction Python ordinaire, qui appelle ce qu'elle veut. C'est ce qui nous permet de garder notre enveloppe, son journal et son rejeu.

LangGraph propose aussi une seconde façon d'écrire un flux de travail, l'API fonctionnelle, avec deux décorateurs, `@entrypoint` et `@task`, et des boucles Python ordinaires. Les deux API partagent le même moteur. Nous utilisons la première, l'API des graphes, que la documentation recommande pour les nouveaux agents, et qui se dessine.

#### D'où vient l'idée

Deux traditions de l'informatique se rejoignent dans LangGraph.

- **Les machines à états.** Harel (1987) a proposé les *statecharts* pour décrire un système qui réagit à des événements. Le système y est représenté par des états, des transitions et des conditions, dessinés plutôt qu'enfouis dans des boucles et des drapeaux. Un graphe LangGraph se lit de la même façon, et se dessine (chapitre 10).
- **Le calcul par super-étapes.** Valiant (1990) a proposé le modèle BSP, pour *bulk synchronous parallel*. Un calcul parallèle y avance par super-étapes : des calculs locaux, des échanges de messages, puis une barrière de synchronisation. Malewicz et ses coauteurs (2010) en ont tiré Pregel, le système de Google pour les très grands graphes. Dans le code de LangGraph, le moteur s'appelle justement `Pregel`. Il exécute les nœuds par super-étapes, et c'est entre deux super-étapes, quand l'état est complet et cohérent, qu'il le sauvegarde.

### Comment ça marche

> **Exemple.** Imaginez un dossier qui circule de bureau en bureau. Le dossier, c'est l'état. Chaque bureau est un nœud : il lit le dossier, puis rend une note qui dit seulement ce qui change. Le circuit de visa, ce sont les arêtes. À chaque passage de relève, on photocopie le dossier et on range la copie dans une armoire, sous le numéro du dossier : ce sont la sauvegarde et le fil. Quand il faut la signature du chef, le dossier attend dans la corbeille « à signer » : c'est l'interruption.

#### 1. L'état : le dossier qui circule

L'état est un dictionnaire, dont on déclare les champs une fois pour toutes avec un `TypedDict` :

```python
class Etat(TypedDict, total=False):
    brouillon: str                            # remplacé à chaque mise à jour
    tours: int                                # remplacé à chaque mise à jour
    anomalies: list                           # remplacé à chaque mise à jour
    decision: str                             # remplacé à chaque mise à jour
    journal: Annotated[list, operator.add]    # chaque mise à jour s'ajoute à la liste
```

`total=False` autorise un état incomplet : au départ, ni `brouillon` ni `decision` n'existent encore. Avec un `TypedDict`, les types documentent l'état, mais LangGraph ne les vérifie pas pendant l'exécution. Un nœud qui rendrait `{"tours": "pas un entier"}` passerait sans erreur ; un modèle Pydantic, lui, ferait cette vérification.

#### 2. Les nœuds : des fonctions qui rendent ce qu'elles changent

```python
def verifier(etat):
    anomalies = [] if "25,1 Md€" in etat["brouillon"] else ["montant absent de la fiche"]
    return {"anomalies": anomalies, "journal": [f"verifier : {len(anomalies)} anomalie(s)"]}
```

Un nœud reçoit l'état et rend un dictionnaire qui ne contient que les champs qu'il change : une **mise à jour partielle**. Il ne modifie jamais l'état reçu. C'est LangGraph qui applique la mise à jour, et c'est ce qui lui permet de la sauvegarder.

> **Définition.** Une *mise à jour partielle* est le dictionnaire rendu par un nœud : seulement les champs qu'il change, avec leur nouvelle valeur. LangGraph la fusionne dans l'état, champ par champ, selon le réducteur de chaque champ.

#### 3. Les réducteurs : la règle d'écriture

> **Formule.** Pour chaque champ, nouvelle valeur = réducteur(ancienne valeur, mise à jour). Le réducteur par défaut rend la mise à jour : la nouvelle valeur remplace l'ancienne. Avec `Annotated[list, operator.add]`, le réducteur est l'addition des listes, c'est-à-dire leur concaténation : `["a"] + ["b"]` donne `["a", "b"]`.

Les réducteurs ont deux usages. Le premier est de tenir un journal : notre graphe garde ainsi la liste de ses appels au modèle (`appels`) et celle des décisions humaines (`decisions`). Le second concerne les nœuds qui s'exécutent en parallèle dans la même super-étape. Si deux nœuds écrivent le même champ sans réducteur, LangGraph refuse : `InvalidUpdateError: At key 'x': Can receive only one value per step. Use an Annotated key to handle multiple values.` Avec `operator.add`, les deux valeurs sont réunies.

#### 4. Les arêtes : le circuit

```python
constructeur.add_edge(START, "rediger")
constructeur.add_edge("rediger", "verifier")
constructeur.add_conditional_edges("verifier", apres_verifier, ["rediger", "valider"])
constructeur.add_conditional_edges("valider", apres_valider, ["rediger", END])


def apres_verifier(etat):
    return "rediger" if etat["anomalies"] and etat["tours"] < 3 else "valider"
```

Une arête fixe dit « toujours ensuite ». Une arête conditionnelle appelle une fonction, l'**aiguillage**, qui lit l'état et rend le nom du nœud suivant. La liste en troisième argument déclare les destinations possibles : LangGraph s'en sert pour dessiner le graphe. `START` et `END` sont deux nœuds spéciaux, l'entrée et la sortie.

#### 5. La compilation, puis l'exécution par super-étapes

`construire().compile(checkpointer=InMemorySaver())` transforme le plan en programme exécutable. La compilation vérifie la structure, mais pas tout : une arête vers un nœud inconnu est refusée (`ValueError: Found edge ending at unknown node`), alors qu'un nœud que rien n'atteint est accepté sans un mot.

`graphe.invoke(entree, config)` lance l'exécution. Le moteur avance par super-étapes, chacune en trois temps, comme dans le modèle de Valiant :

1. **Planifier :** choisir les nœuds à exécuter, ceux que les arêtes de l'étape précédente ont déclenchés.
2. **Exécuter :** lancer ces nœuds, en parallèle s'il y en a plusieurs. Chacun voit l'état tel qu'il était au début de l'étape.
3. **Mettre à jour :** appliquer toutes les mises à jour, par les réducteurs, puis sauvegarder.

L'exécution s'arrête quand aucun nœud n'est plus planifié (`END` est atteint), quand un nœud s'interrompt, ou quand le nombre de super-étapes dépasse une limite, la `recursion_limit`. LangGraph lève alors une `GraphRecursionError`. Dans la version 1.2.24, cette limite vaut 10 007 par défaut : c'est un garde-fou de dernier recours. Contre une boucle sans fin, notre vrai garde-fou est `MAX_TOURS`.

Dans le jouet, chaque super-étape exécute un seul nœud :

<!-- largeurs: 9,49,24,18 -->
| Étape | Ce qui vient de se passer | État après l'étape | Prochain nœud |
| --- | --- | --- | --- |
| −1 | L'entrée `{"tours": 0}` est reçue | (vide) | `__start__` |
| 0 | L'entrée est écrite dans l'état | `tours` 0 | `rediger` |
| 1 | `rediger`, tour 1 : « 25 Md€ » | `tours` 1 | `verifier` |
| 2 | `verifier` : une anomalie | `anomalies` 1 | `rediger` |
| 3 | `rediger`, tour 2 : « 25,1 Md€ » | `tours` 2 | `verifier` |
| 4 | `verifier` : aucune anomalie | `anomalies` 0 | `valider` |
| — | `valider` s'interrompt : aucune sauvegarde, l'exécution s'arrête | inchangé | `valider`, en attente |
| 5 | `valider`, à la reprise : décision « valider » | `decision` | aucun : fin |

#### 6. La sauvegarde et les fils

À chaque frontière de super-étape, le *checkpointer* enregistre un instantané, qui comprend :

- les valeurs de l'état (`values`) ;
- les nœuds à exécuter ensuite (`next`) ;
- des métadonnées, dont le numéro d'étape (`step`) ;
- la date (`created_at`) ;
- les tâches en attente, avec leurs interruptions (`tasks`).

Trois sauvegardes sont courantes :

<!-- largeurs: 24,40,36 -->
| Sauvegarde | Où vont les instantanés | Usage |
| --- | --- | --- |
| `InMemorySaver` | Dans la mémoire du processus : ils meurent avec lui | Les essais et les tests, comme le jouet |
| `SqliteSaver` | Dans un fichier SQLite | Le développement, comme notre graphe (`etat/graphe.sqlite`) |
| `PostgresSaver` | Dans une base PostgreSQL | La production, selon la documentation |

Chaque exécution appartient à un **fil** (*thread*), désigné par son nom dans la configuration : `{"configurable": {"thread_id": "essai-1"}}`. Chaque fil a sa propre suite d'instantanés, et deux fils ne partagent rien. On lit le dernier instantané avec `get_state(config)`, et toute la suite avec `get_state_history(config)`.

Une nouvelle entrée sur un fil existant ne le remet pas à zéro : elle est appliquée par les réducteurs, et le graphe repart de `START`. C'est pourquoi notre commande `lancer` refuse un fil qui existe déjà.

Quand l'instantané est-il écrit sur le disque ? Le paramètre `durability` le règle. Avec `"exit"`, à la fin de l'exécution seulement. Avec `"async"`, la valeur par défaut, pendant que l'étape suivante s'exécute. Avec `"sync"`, avant qu'elle ne commence. Le chapitre 12 y revient, avec la panne.

#### 7. L'interruption, puis la reprise

```python
def valider(etat):
    print("   [valider]  début du nœud")
    decision = interrupt({"brouillon": etat["brouillon"]})
    print(f"   [valider]  décision reçue : {decision}")
    return {"decision": decision, "journal": [f"valider : {decision}"]}
```

Au premier appel, `interrupt(valeur)` lève une exception d'un type particulier, `GraphInterrupt`, qui arrête l'exécution. LangGraph rend alors la valeur à l'appelant, sous la clé `__interrupt__`. Le dernier instantané reste en place, avec `next = ('valider',)`, et le processus peut se terminer. Le graphe n'attend pas dans un processus : il attend dans sa sauvegarde.

Pour reprendre, n'importe quel processus qui ouvre la même sauvegarde appelle `graphe.invoke(Command(resume=reponse), config)`. LangGraph recharge l'instantané, puis relance `valider` **depuis sa première ligne**. Cette fois, `interrupt` ne s'arrête pas : il rend la réponse. D'où cinq règles :

1. **Rien avant `interrupt()`** qu'on ne puisse refaire sans dommage : ni appel au modèle, ni écriture de fichier, ni envoi de courriel. Tout cela serait refait à chaque reprise.
2. **Plusieurs interruptions dans un même nœud** sont appariées aux réponses dans leur ordre d'apparition.
3. **Jamais de `try … except Exception` autour d'`interrupt()`.** `GraphInterrupt` hérite d'`Exception` : le bloc l'avalerait, et la pause n'aurait pas lieu.
4. **Une sauvegarde est indispensable**, puisque la pause vit dans l'instantané.
5. **La valeur passée à `interrupt()`** est sauvegardée avec l'instantané : elle doit être sérialisable, par exemple un dictionnaire de textes et de nombres.

#### 8. Le jouet, en entier

```python
"""Un graphe jouet pour découvrir LangGraph : trois nœuds, une boucle, une pause humaine.

Aucun modèle de langue : le « rédacteur » est une fonction qui se trompe une fois, exprès.
Lancement : python3 jouet_graphe.py (avec l'environnement où LangGraph est installé).
"""
import operator
from typing import Annotated, TypedDict

from langgraph.checkpoint.memory import InMemorySaver
from langgraph.graph import END, START, StateGraph
from langgraph.types import Command, interrupt


class Etat(TypedDict, total=False):
    brouillon: str                            # remplacé à chaque mise à jour
    tours: int                                # remplacé à chaque mise à jour
    anomalies: list                           # remplacé à chaque mise à jour
    decision: str                             # remplacé à chaque mise à jour
    journal: Annotated[list, operator.add]    # chaque mise à jour s'ajoute à la liste


def rediger(etat):
    tour = etat.get("tours", 0) + 1
    montant = "25 Md€" if tour == 1 else "25,1 Md€"   # oublie la décimale au premier tour
    print(f"   [rediger]  tour {tour}")
    return {"brouillon": f"Les paiements atteignent {montant}.", "tours": tour,
            "journal": [f"rediger : tour {tour}"]}


def verifier(etat):
    anomalies = [] if "25,1 Md€" in etat["brouillon"] else ["montant absent de la fiche"]
    print(f"   [verifier] {len(anomalies)} anomalie(s)")
    return {"anomalies": anomalies, "journal": [f"verifier : {len(anomalies)} anomalie(s)"]}


def valider(etat):
    print("   [valider]  début du nœud")      # s'affiche deux fois : avant la pause, et à la reprise
    decision = interrupt({"brouillon": etat["brouillon"]})
    print(f"   [valider]  décision reçue : {decision}")
    return {"decision": decision, "journal": [f"valider : {decision}"]}


def apres_verifier(etat):
    return "rediger" if etat["anomalies"] and etat["tours"] < 3 else "valider"


def apres_valider(etat):
    return "rediger" if etat["decision"] == "corriger" else END


def construire():
    """Le plan du graphe : les nœuds et les arêtes. Il reste à le compiler."""
    constructeur = StateGraph(Etat)
    constructeur.add_node("rediger", rediger)
    constructeur.add_node("verifier", verifier)
    constructeur.add_node("valider", valider)
    constructeur.add_edge(START, "rediger")
    constructeur.add_edge("rediger", "verifier")
    constructeur.add_conditional_edges("verifier", apres_verifier, ["rediger", "valider"])
    constructeur.add_conditional_edges("valider", apres_valider, ["rediger", END])
    return constructeur


def demonstration():
    graphe = construire().compile(checkpointer=InMemorySaver())   # sauvegarde en mémoire
    config = {"configurable": {"thread_id": "essai-1"}}            # le nom du fil

    print("1. Premier lancement")
    resultat = graphe.invoke({"tours": 0}, config)
    print("   Pause :", resultat["__interrupt__"][0].value)

    print("2. Où en est le fil ?")
    instantane = graphe.get_state(config)
    print("   Prochain nœud :", instantane.next, "; tours :", instantane.values["tours"])

    print("3. Reprise, avec la décision humaine")
    resultat = graphe.invoke(Command(resume="valider"), config)
    print("   Décision :", resultat["decision"])
    print("   Journal :", resultat["journal"])

    print("4. Les sauvegardes du fil, de la plus récente à la plus ancienne")
    for s in graphe.get_state_history(config):
        print(f"   étape {s.metadata['step']:>2} | prochain {s.next} | tours {s.values.get('tours')}")


if __name__ == "__main__":
    demonstration()
```

La dernière ligne compte : grâce au test `if __name__ == "__main__"`, la démonstration ne s'exécute que si l'on lance le fichier. La variante en deux temps peut ainsi importer `construire()` sans tout rejouer.

### Ce que nous avons observé

```
1. Premier lancement
   [rediger]  tour 1
   [verifier] 1 anomalie(s)
   [rediger]  tour 2
   [verifier] 0 anomalie(s)
   [valider]  début du nœud
   Pause : {'brouillon': 'Les paiements atteignent 25,1 Md€.'}
2. Où en est le fil ?
   Prochain nœud : ('valider',) ; tours : 2
3. Reprise, avec la décision humaine
   [valider]  début du nœud
   [valider]  décision reçue : valider
   Décision : valider
   Journal : ['rediger : tour 1', 'verifier : 1 anomalie(s)', 'rediger : tour 2', 'verifier : 0 anomalie(s)', 'valider : valider']
4. Les sauvegardes du fil, de la plus récente à la plus ancienne
   étape  5 | prochain () | tours 2
   étape  4 | prochain ('valider',) | tours 2
   étape  3 | prochain ('verifier',) | tours 2
   étape  2 | prochain ('rediger',) | tours 1
   étape  1 | prochain ('verifier',) | tours 1
   étape  0 | prochain ('rediger',) | tours 0
   étape -1 | prochain ('__start__',) | tours None
```

Quatre choses se lisent dans cette sortie.

- **La boucle.** Le code a trouvé l'anomalie du tour 1 et a renvoyé le texte au rédacteur, sans déranger l'humain.
- **La pause.** `invoke` est revenu avec la valeur de l'interruption, et le fil attend `valider`.
- **La reprise relance le nœud depuis son début.** « début du nœud » s'affiche deux fois : une fois avant la pause, une fois à la reprise. C'est la preuve de la règle 1.
- **Le réducteur et l'historique.** Le journal garde les cinq lignes, une par nœud exécuté jusqu'au bout. L'historique compte sept instantanés, un par super-étape, exactement la structure que la commande `historique` affichera pour notre graphe.

Nous avons ensuite fait varier le jouet, pour voir ce qui casse :

<!-- largeurs: 30,38,32 -->
| Expérience | Résultat | Leçon |
| --- | --- | --- |
| `journal` sans réducteur | `['valider : valider']` | Chaque mise à jour remplace la précédente |
| Un nœud qui modifie l'état en place et rend `{}` | `tours` inchangé. L'ajout à `journal` apparaît dans le résultat d'`invoke`, mais pas dans la sauvegarde | Une modification en place n'est pas une mise à jour : au mieux elle se perd, au pire elle rend l'état incohérent |
| Une nouvelle entrée sur le fil terminé | Le journal garde les 5 anciennes lignes et en ajoute 4 | Un fil ne se relance pas ; on en ouvre un autre |
| `recursion_limit` fixée à 3 | `GraphRecursionError` | Le garde-fou de dernier recours |
| Une arête vers un nœud inconnu | `ValueError` à la compilation | La compilation vérifie la structure… |
| Un nœud que rien n'atteint | Accepté sans un mot | … mais pas tout |

Enfin, la variante en deux temps, en trois processus successifs :

```
$ python3 jouet_deux_temps.py lancer
   [rediger]  tour 1
   [verifier] 1 anomalie(s)
   [rediger]  tour 2
   [verifier] 0 anomalie(s)
   [valider]  début du nœud
En pause, prochain nœud : ('valider',)
$ python3 jouet_deux_temps.py decider corriger
   [valider]  début du nœud
   [valider]  décision reçue : corriger
   [rediger]  tour 3
   [verifier] 0 anomalie(s)
   [valider]  début du nœud
En pause, prochain nœud : ('valider',)
$ python3 jouet_deux_temps.py decider valider
   [valider]  début du nœud
   [valider]  décision reçue : valider
Terminé. Journal : ['rediger : tour 1', 'verifier : 1 anomalie(s)', 'rediger : tour 2', 'verifier : 0 anomalie(s)', 'valider : corriger', 'rediger : tour 3', 'verifier : 0 anomalie(s)', 'valider : valider']
```

Chaque processus est mort à la fin de sa commande ; le fil, lui, a survécu dans `jouet.sqlite`. La décision « corriger » a renvoyé le texte au rédacteur, pour un tour 3, avant une nouvelle pause.

### Du jouet à notre graphe

<!-- largeurs: 32,40,28 -->
| Dans le jouet | Dans notre graphe | Ce que cela change |
| --- | --- | --- |
| `rediger` se trompe exprès | `rediger` appelle le modèle par `llm.py`, avec l'étiquette `graphe/<fil>/rediger/<tour>` | Journal, rejeu, et reprise sans second appel |
| `verifier` cherche « 25,1 Md€ » | `verifier` lance les six contrôles du cas 7 | Les vraies consignes |
| `valider` et `interrupt` | Les mêmes, et le code refuse « valider » s'il reste des anomalies | Le code garde le dernier mot sur les chiffres |
| `journal`, avec réducteur | `appels` et `decisions`, avec réducteur | Les preuves de chaque texte validé |
| `InMemorySaver` | `SqliteSaver`, sur `etat/graphe.sqlite` | Le fil survit au processus |
| `durability` par défaut (`"async"`) | `durability="sync"` | Aucune étape finie n'est perdue |
| `Command(resume="valider")` | `python3 -m graphe decider --fil … --decision valider` | Une décision par commande |
| `thread_id = "essai-1"` | `--fil q1-premier` | Un fil par rédaction |

### Pièges et bonnes pratiques

- **Modifier l'état en place** au lieu de rendre une mise à jour : le tableau ci-dessus montre que le résultat devient incohérent.
- **Oublier le réducteur** d'un champ qui doit s'allonger : il ne garde que la dernière valeur.
- **Rendre l'état entier** au lieu des seuls champs modifiés : avec un réducteur `operator.add`, la liste rendue, qui contient déjà les anciennes lignes, s'ajouterait à l'ancienne. Essayé sur le jouet, un journal `["a"]` devient `["a", "a", "b"]`.
- **Relancer un fil existant avec une nouvelle entrée** : les réducteurs mélangent deux rédactions.
- **Placer une action avant `interrupt()`** : elle serait refaite à chaque reprise.
- **Entourer `interrupt()` d'un `try … except Exception`** : la pause disparaît.
- **Compter sur la limite par défaut pour arrêter une boucle** : à 10 007 super-étapes, elle laisserait le modèle tourner longtemps. C'est au graphe de borner ses tours.
- **Utiliser `InMemorySaver` en comptant reprendre après un arrêt** : la mémoire meurt avec le processus.

> **À retenir.** Un graphe LangGraph, c'est un état, des nœuds et des arêtes. Un nœud rend ce qu'il change ; un réducteur dit comment fusionner. Le moteur avance par super-étapes et sauvegarde l'état à chaque frontière, sous le nom d'un fil. `interrupt()` met le graphe en pause dans sa sauvegarde ; `Command(resume=…)` le reprend, en relançant le nœud depuis son début. LangGraph garantit l'ordre des étapes et la reprise, pas le contenu des textes.

### Pour vérifier que vous avez compris

1. On ajoute `print("appel coûteux")` juste avant `interrupt()`, dans `valider`. Combien de fois s'affiche-t-il pour un fil validé du premier coup ? Et pour un fil où l'humain demande une correction, puis valide ?
2. Dans le jouet, `valider` s'est exécuté deux fois. Pourquoi l'historique ne compte-t-il qu'un seul instantané après `valider`, l'étape 5 ?

### Références

- Harel, D. (1987). *Statecharts: A visual formalism for complex systems*. Science of Computer Programming, 8(3), p. 231–274. https://doi.org/10.1016/0167-6423(87)90035-9 — **Ce qu'on y apprend :** décrire un système par ses états, ses transitions et leurs conditions, et le dessiner.
- Valiant, L. G. (1990). *A bridging model for parallel computation*. Communications of the ACM, 33(8), p. 103–111. https://doi.org/10.1145/79173.79181 — **Ce qu'on y apprend :** le modèle BSP, où un calcul avance par super-étapes séparées par des barrières de synchronisation.
- Malewicz, G., Austern, M. H., Bik, A. J. C., Dehnert, J. C., Horn, I., Leiser, N., Czajkowski, G. (2010). *Pregel: A System for Large-Scale Graph Processing*. Proceedings of SIGMOD 2010, p. 135–146. https://doi.org/10.1145/1807167.1807184 — **Ce qu'on y apprend :** le calcul sur graphe par super-étapes, dont le moteur de LangGraph reprend le nom et le principe.
- LangChain. *Graph API overview*, *Persistence* et *Interrupts*. Documentation de LangGraph. https://docs.langchain.com/oss/python/langgraph/graph-api — **Ce qu'on y apprend :** l'état, les réducteurs, les arêtes, les sauvegardes, les fils et les interruptions, dans la version actuelle.

## Chapitre 10 — Lire notre graphe

### Ce que nous avons fait

Le bloc 6 a commencé par une lecture, dans cet ordre : `graphe/etat.py` (ce qui circule), `graphe/noeuds.py` (ce que fait chaque étape), puis `graphe/construire.py` (comment les étapes s'enchaînent). Puis trois gestes :

1. **Dessiner le graphe** dans `docs/graphe.md`, au format Mermaid, que GitHub sait afficher : `{ echo '```mermaid'; python3 -m graphe dessiner; echo '```'; } > docs/graphe.md`, puis `cat docs/graphe.md` pour vérifier.
2. **Répondre à trois questions pour chaque nœud**, dans le journal : que lit-il dans l'état ? Qu'y écrit-il ? Pourrait-on le relancer sans dommage ?
3. **Commiter et pousser** le code du graphe, son dessin et le journal : commit `1bb1d07`, « feat: graphe d'états rediger, verifier, valider, et son dessin ». Le programme gardait ce commit pour la clôture ; avec un service fragile, nous l'avons avancé.

### Pourquoi cette étape

**Lire un programme avant de le lancer.** Celui qui sait ce que lit et écrit chaque nœud peut prévoir ce que fera le graphe, et reconnaître l'anomalie quand elle arrive. Les trois questions transforment une lecture vague en exercice précis.

**Un flux de travail, pas un agent libre.** Schluntz et Zhang (2024) distinguent deux familles de systèmes. Dans un flux de travail, le code écrit les chemins. Dans un agent, le modèle choisit lui-même ses étapes et ses outils, comme dans la boucle « raisonner, puis agir » de ReAct (Yao et coll., 2023). Ils recommandent de commencer par le système le plus simple qui suffit. Notre graphe est un flux de travail : le modèle n'intervient que dans `rediger`, et le code décide de tout le reste. C'est la conséquence directe de l'`ADR-001`.

**Une décision par module.** Parnas (1972) conseille de découper un système de façon que chaque module cache une décision susceptible de changer. Nos trois nœuds suivent cette règle. `rediger` cache le modèle et ses consignes, `verifier` les règles de contrôle, `valider` la décision humaine. Changer de modèle ne touche qu'un nœud ; durcir un contrôle, un autre.

**La troisième question prépare la panne.** « Relancer sans dommage » est la question de l'idempotence, au cœur du chapitre 12.

### Comment ça marche

#### L'état de notre graphe

<!-- largeurs: 26,44,30 -->
| Champ | Rôle | Écrit par |
| --- | --- | --- |
| `fil`, `question_id`, `question`, `faits` | L'entrée de la rédaction | `lancer`, une seule fois |
| `tours` | Nombre de textes rédigés, reprises comprises | `lancer` (0), puis `rediger` |
| `brouillon`, `coupee` | Le dernier texte, et s'il a été coupé par le plafond | `rediger` |
| `anomalies` | Les écarts trouvés par le code dans le dernier texte | `verifier` |
| `remarques` | Ce que le prochain tour doit corriger | `verifier`, `valider` ; vidées par `rediger` |
| `decision`, `texte_valide` | La décision humaine, et le texte s'il est validé | `valider` |
| `appels` (réducteur) | Les clés des appels au modèle, dans l'ordre | `rediger` |
| `decisions` (réducteur) | Les décisions humaines, tour par tour | `valider` |

#### La méthode de lecture

1. **Ce que lit le nœud :** chaque `etat["…"]` ou `etat.get("…")` dans le corps de la fonction.
2. **Ce qu'il écrit :** les clés du dictionnaire rendu par `return`. S'il y a plusieurs `return`, chacun peut écrire des champs différents.
3. **S'il est relançable sans dommage :** LangGraph sauvegarde entre deux nœuds, jamais pendant. Si le processus meurt au milieu d'un nœud, la reprise le relance depuis sa première ligne. La question devient : l'exécuter deux fois revient-il au même que l'exécuter une fois ?

> **Exemple.** Appuyer deux fois sur le bouton d'un ascenseur ne change rien : l'opération est idempotente. Payer deux fois la même facture, si.

#### Les trois nœuds

<!-- largeurs: 12,24,30,34 -->
| Nœud | Lit | Écrit | Relançable sans dommage ? |
| --- | --- | --- | --- |
| `rediger` | `tours`, `question`, `faits`, `remarques`, `brouillon`, `fil` | `brouillon`, `coupee`, `tours`, `remarques` (vidées), `appels` | Oui, grâce au journal : s'il meurt après l'appel, `tours` n'a pas changé, donc l'appel relancé porte la même étiquette, et le journal rend la réponse déjà reçue |
| `verifier` | `brouillon`, `faits`, `coupee` | `anomalies`, et les mêmes en `remarques` | Oui : c'est un calcul pur, sans appel extérieur ; les mêmes entrées donnent les mêmes anomalies |
| `valider` | `question`, `brouillon`, `anomalies`, `tours` | `decision` et `decisions` ; plus `texte_valide` si l'on valide, ou `remarques` si l'on corrige | Oui : rien n'est fait avant `interrupt()`, qui rend directement la réponse à la reprise |

#### Les aiguillages, et la borne des tours

```python
def apres_verification(etat):
    if etat["anomalies"] and etat["tours"] < MAX_TOURS:
        return "rediger"  # le code a trouvé des écarts : le modèle corrige, sans déranger l'humain
    return "valider"


def apres_validation(etat):
    return "rediger" if etat["decision"] == "corriger" else END
```

`MAX_TOURS` vaut 3 : un premier jet et deux reprises automatiques au plus. Au-delà, le graphe s'arrête devant l'humain, anomalies affichées, au lieu de boucler. Un détail se lit dans le code : `tours` compte tous les textes, y compris ceux qu'a demandés l'humain. Après une correction humaine au tour 3 ou plus, la moindre anomalie conduit donc tout droit à `valider`. La borne limite les corrections automatiques, pas les corrections humaines.

**Deux gardes sur la validation.** La commande `decider` refuse `valider` tant que le code voit une anomalie. Le nœud `valider` refuse aussi, et transforme la décision en correction, au cas où une autre interface l'appellerait un jour : le code garde le dernier mot sur les chiffres.

**Le point de panne.** `panne("rediger")`, placé juste après l'appel au modèle, ne fait rien en temps normal. Si la variable `GRAPHE_PANNE` vaut `rediger`, il tue le processus à cet endroit précis : le chapitre 12 s'en sert.

#### Le dessin

`python3 -m graphe dessiner` produit le graphe en Mermaid, un langage de description de diagrammes. Les flèches pleines sont les arêtes fixes, les flèches en pointillé les arêtes conditionnelles. On y voit trois nœuds et deux boucles qui reviennent vers `rediger` : la première part de `verifier`, quand le code trouve des écarts ; la seconde de `valider`, quand l'humain demande une correction.

```
graph TD;
	__start__([<p>__start__</p>]):::first
	rediger(rediger)
	verifier(verifier)
	valider(valider)
	__end__([<p>__end__</p>]):::last
	__start__ --> rediger;
	rediger --> verifier;
	valider -.-> __end__;
	valider -.-> rediger;
	verifier -.-> rediger;
	verifier -.-> valider;
```

### La question posée pendant la séance

*Comment remplir, pour chaque nœud, le modèle proposé dans le journal ?*

Le modèle à remplir prenait `verifier` comme exemple. La réponse a d'abord donné la méthode : les `etat["…"]` pour ce qu'il lit, les clés du `return` pour ce qu'il écrit, et l'ascenseur contre la facture pour l'idempotence. Puis nous avons fait `rediger` ensemble, en annotant chaque ligne :

```python
def rediger(etat):
    tour = etat.get("tours", 0) + 1                              # lit : tours
    messages = messages_fiche(etat["question"], etat["faits"],   # lit : question, faits
                              remarques=etat.get("remarques"),   # lit : remarques
                              brouillon=etat.get("brouillon"))   # lit : brouillon
    reponse, cle = appeler_llm(messages, f"graphe/{etat['fil']}/rediger/{tour}", …)  # lit : fil
    …
    return {"brouillon": …, "coupee": …, "tours": tour,          # écrit : brouillon, coupee, tours,
            "remarques": [], "appels": [cle]}                    #         remarques, appels
```

Il me restait `valider`, avec la même méthode.

### Ce qui m'a posé problème, et ce que j'ai compris

Ma ligne disait : « lit question, brouillon, anomalies, tours, retourne decision – interrupt : on récupère decision et remarque et on refait la decision ».

La lecture était juste : les quatre champs. Deux choses manquaient.

- **Ce qu'il écrit.** `decision`, oui, mais aussi `decisions`, à chaque fois : la trace de ma décision, ajoutée à la liste par le réducteur. Et, selon le cas, `texte_valide` si je valide, ou `remarques` si je demande une correction. Un nœud à plusieurs `return` n'écrit pas toujours les mêmes champs.
- **Pourquoi la relance est sans dommage.** J'avais l'idée que le nœud recommence. Mais « on refait la décision » laisse croire qu'on me la redemande. Ce n'est pas le cas : à la reprise, `interrupt()` ne s'arrête pas une seconde fois, il rend directement ma réponse. Et la relance est sûre parce qu'aucune action n'est faite avant `interrupt()`. S'il y avait, avant cette ligne, un appel au modèle ou l'envoi d'un courriel, il serait refait à chaque reprise.

Le jouet du chapitre 9 rend ce mécanisme visible : « début du nœud » s'y affiche deux fois.

### Ce que nous avons observé

Les trois lignes du journal sont celles du tableau des trois nœuds, ci-dessus. Le dessin semblait parfait dans le terminal.

> **Attention.** En préparant ce cours, nous avons découvert que `docs/graphe.md` ne s'affiche pas correctement sur GitHub. La page montre deux titres illisibles et le code du diagramme en texte brut, sans le dessin. La première ligne du fichier commence par des caractères invisibles, que `cat -A docs/graphe.md | head -1` révèle (`^[]633;E;echo '```mermaid'…`). Ce sont des codes que l'intégration du terminal de VS Code envoie juste avant chaque commande. Dans un groupe `{ … } > fichier`, la sortie est déjà redirigée vers le fichier quand ces codes partent, et ils atterrissent dedans. Une commande simple avec redirection ne pose pas ce problème. Le terminal, lui, interprète ces codes sans les afficher : `cat` ne pouvait rien montrer. Le correctif tient en une ligne ; il est donné à l'annexe B, pour le début du jour 4.

### Pièges et bonnes pratiques

- **Lire un nœud sans lire ses aiguillages** : c'est l'aiguillage qui dit où va le graphe après lui.
- **Croire que `MAX_TOURS` borne aussi les corrections humaines** : il ne borne que les reprises automatiques.
- **Juger un fichier à son apparence dans le terminal.** Des caractères invisibles peuvent s'y cacher ; `cat -A` les montre. Un fichier destiné à GitHub se vérifie sur GitHub.
- **Rediriger un groupe de commandes vers un fichier** dans le terminal de VS Code. Mieux vaut faire écrire le fichier par Python.

> **À retenir.** Pour lire un nœud : ce qu'il lit (`etat[…]`), ce qu'il écrit (les clés du `return`), et s'il supporte d'être relancé. `rediger` le supporte grâce au journal, `verifier` parce qu'il calcule sans rien appeler, `valider` parce que rien ne précède `interrupt()`. Notre graphe est un flux de travail : le modèle rédige, le code décide du chemin.

### Pour vérifier que vous avez compris

1. Après une correction humaine au tour 3, le code trouve une anomalie dans le texte du tour 4. Où va le graphe, et que peut faire l'humain ?
2. Pourquoi `verifier` est-il relançable sans dommage par nature, alors que `rediger` ne l'est que grâce au journal ?

### Références

- Schluntz, E., Zhang, B. (2024). *Building effective agents*. Billet technique, Anthropic, décembre 2024. https://www.anthropic.com/engineering/building-effective-agents — **Ce qu'on y apprend :** la différence entre un flux de travail, dont le code écrit les chemins, et un agent, qui choisit ses étapes ; et pourquoi commencer par le système le plus simple qui suffit.
- Yao, S., Zhao, J., Yu, D., Du, N., Shafran, I., Narasimhan, K., Cao, Y. (2023). *ReAct: Synergizing Reasoning and Acting in Language Models*. ICLR 2023. https://arxiv.org/abs/2210.03629 — **Ce qu'on y apprend :** la boucle d'un agent qui alterne raisonnement et actions, l'autre famille de systèmes, que nous n'avons pas choisie.
- Parnas, D. L. (1972). *On the criteria to be used in decomposing systems into modules*. Communications of the ACM, 15(12), p. 1053–1058. https://doi.org/10.1145/361598.361623 — **Ce qu'on y apprend :** découper un système pour que chaque module cache une décision susceptible de changer.

## Chapitre 11 — Jusqu'à la décision humaine

### Ce que nous avons fait

Le bloc 7 a fait tourner le graphe jusqu'à une décision, d'abord sur le faux serveur, puis sur le vrai.

**Sur le faux serveur.** Réglé pour glisser une faute dans chaque premier jet (`FAUX_ECODEF_FAUTE=1`), il a démarré dans un second terminal, après deux incidents (annexe B). Dans le premier terminal, une variable `ESSAI` a envoyé tout l'essai dans `/tmp` :

```bash
ESSAI="NO_PROXY=127.0.0.1 LLM_URL=http://127.0.0.1:8765/v1 LLM_CLE=essai LLM_MODELE=modele-test \
LLM_JOURNAL=/tmp/graphe/appels.jsonl GRAPHE_ETAT=/tmp/graphe/etat.sqlite GRAPHE_SORTIES=/tmp/graphe/sorties"
env $ESSAI python3 -m graphe lancer --fil essai --question Q1
env $ESSAI python3 -m graphe historique --fil essai
```

Le graphe s'est arrêté au tour 2, sans anomalie. Deux décisions ont suivi : `corriger`, avec la remarque « Commence par le montant versé aux fournisseurs résidents. », puis `valider`. La sortie a été écrite dans `/tmp/graphe/sorties/essai.md`.

**Sur le vrai serveur.** `python3 -m graphe lancer --fil q1-premier --question Q1` a répondu : « Le fil q1-premier existe déjà : reprendre, decider, ou un autre nom. » Le fil avait été lancé plus tôt. `etat` et `historique` l'ont montré en attente de décision au tour 1, sans anomalie, avec un appel. Après lecture, une remarque, un tour 2 et la validation, la sortie `sorties/q1-premier.md` a été commitée : commit `d08e830`, « docs: première rédaction par le graphe (Q1), corrigée puis validée ».

### Pourquoi cette étape

**Automatiser la rédaction, pas la décision de publier.** Parasuraman, Sheridan et Wickens (2000) décomposent l'automatisation en quatre fonctions : recueillir l'information, l'analyser, choisir une décision, l'exécuter. Chacune peut être plus ou moins automatisée, et le bon niveau dépend du coût d'une erreur. Ici, la rédaction et le contrôle des chiffres sont automatisés. La décision de publier ne l'est pas, parce qu'un chiffre faux publié par un service statistique coûte cher.

**Montrer à l'humain de quoi décider.** Amershi et ses coauteurs (2019) ont tiré dix-huit lignes directrices pour l'interaction entre humains et systèmes d'IA. Deux s'appliquent ici : faire comprendre pourquoi le système a fait ce qu'il a fait, et rendre la correction facile. Le graphe affiche le texte et les anomalies trouvées par le code ; la remarque part telle quelle au tour suivant.

**Se méfier de sa propre confiance.** Parasuraman et Manzey (2010) ont fait la synthèse des travaux sur la complaisance envers l'automatisation : plus un système paraît fiable, moins on vérifie ce qu'il produit. Après 60 sur 60 et des textes sans anomalie, c'est exactement le risque : valider parce que le code n'a rien trouvé.

**Tester la tuyauterie avant de payer.** Le faux serveur montre toute la mécanique, faute, correction automatique, pause et décisions, sans dépenser un seul appel.

### Comment ça marche

**Une variable qui isole tout l'essai.** `env $ESSAI commande` découpe la variable en affectations et les applique à la seule commande : le faux serveur, une fausse clé, puis un journal, une sauvegarde et des sorties dans `/tmp`. `NO_PROXY=127.0.0.1` évite qu'un éventuel mandataire réseau (*proxy*) intercepte un appel local. Rien ne touche le dépôt.

**Lire l'historique,** de bas en haut ; chaque ligne est une sauvegarde :

```
étape  4 | prochain ('valider',) | tours 2 | 2026-11-25T17:46:01.481794+00:00
étape  3 | prochain ('verifier',) | tours 2 | 2026-11-25T17:46:01.478376+00:00
étape  2 | prochain ('rediger',) | tours 1 | 2026-11-25T17:46:01.466890+00:00
étape  1 | prochain ('verifier',) | tours 1 | 2026-11-25T17:46:01.460592+00:00
étape  0 | prochain ('rediger',) | tours 0 | 2026-11-25T17:46:01.422457+00:00
étape -1 | prochain ('__start__',) | tours None | 2026-11-25T17:46:01.420583+00:00
```

Aux étapes −1 et 0, la question arrive et le graphe part vers `rediger`. À l'étape 1, le premier jet est écrit. À l'étape 2, le code a trouvé la faute glissée par le faux serveur ; comme `tours` vaut 1, l'aiguillage renvoie vers `rediger`. À l'étape 3, le second jet est écrit. À l'étape 4, plus d'anomalie : direction `valider`, où `interrupt()` a suspendu le graphe. C'est la structure exacte du jouet du chapitre 9.

**Réafficher un texte en attente, sans rien changer :**

```bash
python3 -c "from graphe.__main__ import afficher; from graphe.construire import ouvrir; afficher(ouvrir(), 'q1-premier')"
```

La fonction `afficher` ne fait que lire la sauvegarde (`get_state`) : aucune étape n'est exécutée.

**La sortie d'un fil validé** répond aux questions d'un relecteur, section par section :

- **Texte validé :** ce qui serait publié.
- **Faits de la fiche :** tout ce que le modèle avait sous les yeux, avec la page de la publication.
- **Contrôles :** ce que le code a vérifié.
- **Décisions :** qui a décidé quoi, à quel tour, avec la remarque mot pour mot.
- **Appels au modèle :** la clé de chaque appel, pour retrouver la requête et la réponse exactes dans le journal.

D'un chiffre publié, on remonte ainsi à la page de l'EcoDef ; d'un texte, à l'appel exact qui l'a produit.

### Ce que nous avons observé

**L'essai.** Le texte du faux serveur recolle les libellés de la fiche (« Paiements directs aux fournisseurs résidents en 2024 : 25,1 Md€ [F03]. … ») : il teste la tuyauterie, pas la rédaction. Le faux serveur ne lit pas les remarques ; le tour 3 était donc identique au tour 2. La sortie contenait aussi une imperfection de notre code : elle annonçait « Clés dans `journal/appels.jsonl` », alors que les clés de l'essai étaient dans `/tmp/graphe/appels.jsonl`. Le correctif est venu à la clôture (chapitre 13).

**Le vrai fil, `q1-premier`.** Le tour 1 était juste, mais la réponse arrivait tard :

> « En 2024, les paiements du ministère des Armées à l'ensemble de ses fournisseurs s'élèvent à 30,3 Md€ [F01]. Les paiements directs aux fournisseurs résidents atteignent 25,1 Md€ [F03], ce qui représente une part de 82,9 % [F04] de l'ensemble des paiements. Ces paiements aux fournisseurs résidents affichent une évolution de +9,4 % [F05] entre 2023 et 2024. […] »

La remarque : « Réponds à la question dès la première phrase : le montant versé aux fournisseurs résidents et son évolution depuis 2023. Les autres chiffres viennent ensuite, en contexte. » Le tour 2 l'a suivie à la lettre :

> « Les paiements directs aux fournisseurs résidents en 2024 s'élèvent à 25,1 Md€ [F03], soit une évolution de +9,4 % [F05] par rapport à 2023. En 2024, les paiements du ministère des Armées à l'ensemble de ses fournisseurs atteignent 30,3 Md€ [F01]. […] »

Les chiffres n'ont pas bougé, et le code n'a toujours rien trouvé à redire. Il reste un peu de recopie (« la part des paiements versés aux fournisseurs résidents dans l'ensemble des paiements »), mais rien de faux. Une remarque précise a suffi, en un tour.

### Les questions posées pendant la séance

*Où trouver la sortie de l'essai, invisible dans l'explorateur de VS Code ?*

L'explorateur de VS Code ne montre que l'espace de travail, `~/work`. `/tmp` est un dossier du système, en dehors. Deux façons de le voir quand même : dans le terminal, `ls -l /tmp/graphe/sorties/` et `cat /tmp/graphe/sorties/essai.md` ; dans VS Code, la palette de commandes (Ctrl+Maj+P), « File: Open File… », puis le chemin. Le contenu était d'ailleurs déjà affiché dans le terminal, sous « Texte validé écrit dans… ». Pour le vrai serveur, la sortie va dans `sorties/`, visible dans l'explorateur.

*Peut-on valider dès que le code ne signale aucune anomalie ?*

La question accompagnait la sortie d'`etat` et d'`historique` : `tours 1 ; anomalies 0`. La réponse : pas encore, on ne valide jamais sans lire. `etat` ne montre qu'un résumé, et le code ne vérifie ni le sens des phrases, ni la réponse à la question. Il fallait d'abord afficher le texte, puis le relire avec trois questions :

1. Répond-il à la question, combien et avec quelle évolution, dès la première phrase ?
2. Chaque chiffre est-il attaché à la bonne grandeur ?
3. Est-ce une phrase de publication, ou des libellés recopiés ?

### Ce qui m'a posé problème, et ce que j'ai compris

Après avoir affiché le texte du tour 1, j'ai répondu : « ça me va ». Le texte était juste, et le valider se défendait. Mais il ne passait pas la première des trois questions : la réponse n'arrivait qu'à la deuxième phrase, après un total que la question ne demandait pas.

J'ai compris que valider n'est pas un sentiment, c'est une lecture contre des critères. Le code m'avait dit « aucune anomalie » ; cela voulait dire « aucun chiffre hors fiche, aucun format faux », pas « texte publiable ». Et une remarque précise coûte un tour, quelques secondes.

### Pièges et bonnes pratiques

- **Valider sans lire,** parce que le code n'a rien trouvé.
- **Une remarque vague,** comme « améliore le texte » : le modèle ne peut corriger que ce qu'on lui nomme.
- **Relancer `lancer` sur un fil existant** : la commande refuse, et c'est voulu. Un fil se poursuit par `decider` ou `reprendre`, ou bien on en ouvre un autre.
- **Exporter les variables d'essai** au lieu de les placer devant la commande : le vrai journal recevrait de faux appels.
- **Oublier un faux serveur allumé** : il occupe le port, et sans `FAUX_ECODEF_FAUTE=1` il ne glisse aucune faute.

> **À retenir.** La rédaction et le contrôle sont automatisés ; la décision de publier ne l'est pas. Le graphe attend dans sa sauvegarde, pas dans un processus. « Aucune anomalie » veut dire « chiffres conformes », pas « texte publiable » : on lit chaque texte contre trois questions, et une remarque précise suffit à le corriger.

### Pour vérifier que vous avez compris

1. Que teste exactement l'essai sur le faux serveur, et pourquoi ne dit-il rien de la qualité de la rédaction ?
2. Le code ne trouvait aucune anomalie dans le tour 1 de `q1-premier`. Pourquoi l'avons-nous quand même corrigé, et qu'est-ce qui a changé ?

### Références

- Parasuraman, R., Sheridan, T. B., Wickens, C. D. (2000). *A model for types and levels of human interaction with automation*. IEEE Transactions on Systems, Man, and Cybernetics — Part A, 30(3), p. 286–297. https://doi.org/10.1109/3468.844354 — **Ce qu'on y apprend :** comment choisir, fonction par fonction, ce qu'on automatise et ce qu'on laisse à l'humain.
- Amershi, S., Weld, D., Vorvoreanu, M., Fourney, A., Nushi, B., Collisson, P., Suh, J., Iqbal, S., Bennett, P. N., Inkpen, K., Teevan, J., Kikin-Gil, R., Horvitz, E. (2019). *Guidelines for Human-AI Interaction*. Proceedings of CHI 2019, article 3. https://doi.org/10.1145/3290605.3300233 — **Ce qu'on y apprend :** dix-huit règles pour qu'un humain comprenne, corrige et garde la main sur un système d'IA.
- Parasuraman, R., Manzey, D. H. (2010). *Complacency and Bias in Human Use of Automation: An Attentional Integration*. Human Factors, 52(3), p. 381–410. https://doi.org/10.1177/0018720810376055 — **Ce qu'on y apprend :** pourquoi l'on vérifie de moins en moins un système qui paraît fiable, et comment s'en prémunir.

## Chapitre 12 — Tuer le processus, puis reprendre

### Ce que nous avons fait

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

### Pourquoi cette étape

**Une panne n'est pas une exception, c'est une certitude.** Elnozahy et ses coauteurs (2002) ont fait la synthèse des protocoles de reprise après panne. Ils reposent sur deux outils : le point de reprise (*checkpoint*), une sauvegarde de l'état à un instant donné, et la journalisation des messages reçus. Après une panne, le système recharge le dernier point de reprise, puis rejoue le journal. Notre graphe utilise exactement ces deux outils : la sauvegarde SQLite de LangGraph, et le journal des appels de l'enveloppe.

**Refaire une étape ne doit rien coûter.** Helland (2012) rappelle qu'une opération répétée doit avoir le même effet qu'une seule : c'est l'idempotence, déjà rencontrée au jour 2. Appliquée à l'agent, elle veut dire qu'un appel au modèle relancé n'est ni payé deux fois, ni remplacé par une autre réponse.

**Provoquer la panne exprès.** Basiri et ses coauteurs (2016) décrivent l'ingénierie du chaos pratiquée chez Netflix : on provoque des pannes volontairement, en conditions contrôlées, pour vérifier que le système s'en remet. Une reprise qui n'a jamais été éprouvée n'est qu'une promesse.

### Comment ça marche

#### Quand la sauvegarde est écrite

<!-- largeurs: 14,44,42 -->
| `durability` | Quand LangGraph écrit l'instantané | Ce qu'une panne fait perdre |
| --- | --- | --- |
| `"exit"` | Seulement quand l'exécution s'arrête : fin, erreur ou interruption | Tout ce qui s'est passé depuis le début de l'exécution |
| `"async"` | Pendant que l'étape suivante s'exécute (valeur par défaut) | Peut-être la dernière étape |
| `"sync"` | Avant que l'étape suivante ne commence | Rien de ce qui est fini |

Notre commande choisit `"sync"` à chaque appel. Le coût, une écriture SQLite par étape, est négligeable devant un appel au modèle. Avec `"sync"`, l'entrée et l'étape 0 sont écrites avant le premier nœud : après une panne dans `rediger`, le fil existe, et il attend `rediger`.

#### La panne, puis la reprise, pas à pas

1. **`lancer`** écrit les instantanés −1 et 0, puis exécute `rediger`. L'appel au modèle part, et l'enveloppe ajoute une ligne au journal, avec la clé de l'appel.
2. **`panne("rediger")`** appelle `os._exit(3)`. Le processus meurt sur-le-champ, avant que le nœud ne rende son résultat : aucun bloc `finally`, aucun rangement, comme une coupure de courant. Pour LangGraph, le tour 1 n'a jamais eu lieu : `tours 0`, `appels 0`.
3. **`reprendre`** appelle `graphe.invoke(None, config)` : sans entrée, sur un fil existant, LangGraph recharge le dernier instantané et relance le travail inachevé, c'est-à-dire `rediger`, depuis sa première ligne.
4. **Le nœud reconstruit le même appel.** `tours` vaut toujours 0, donc `tour` vaut 1 : même étiquette, `graphe/panne-q2/rediger/1`. La question, les faits, les remarques et le brouillon viennent du même instantané : même corps de requête.
5. **Même étiquette et même corps, donc même clé.** Rappel du chapitre 1 : la clé est l'empreinte SHA-256 de l'adresse du serveur, de l'étiquette et du corps de la requête.
6. **Le journal répond à la place du modèle.** En mode reprise, l'enveloppe trouve la clé dans le journal et rend la réponse enregistrée, sans rien envoyer. Le nœud finit, l'instantané 1 est écrit, et le graphe continue jusqu'à `valider`.

La sauvegarde garde les étapes finies ; le journal garde les appels faits. Chacun couvre ce que l'autre ne voit pas.

#### Les cinq tests

<!-- largeurs: 28,72 -->
| Test | Ce qu'il prouve |
| --- | --- |
| 1. Arrêt humain | Le graphe corrige seul la faute du premier jet, puis s'arrête avant `valider` |
| 2. Décisions | « corriger » puis « valider », chacune dans un nouveau processus, mènent au texte validé |
| 3. Panne dans `rediger` | Après la reprise, l'appel du tour 1 figure une seule fois dans le journal |
| 4. Panne dans `verifier` | La reprise ne relance pas la rédaction, déjà sauvegardée |
| 5. Rejeu | Serveur arrêté, sans clé, avec une sauvegarde neuve : le fil se rejoue et produit un texte validé identique, octet pour octet |

### Ce que nous avons observé

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

La phrase sur les grandes entreprises est fausse deux fois. Les 15,8 Md€ vont aux grandes entreprises privées de tous les secteurs, pas seulement de l'industrie. Et 15,8 sur 17,7 font 89,3 %, pas 90,6 %. Même avec l'arithmétique d'intervalles du chapitre 3, le rapport reste entre 88,7 % et 89,8 % : la contradiction est réelle. Le modèle a fusionné F11 et F15, exactement le piège découvert la veille dans la fiche. Comme chaque chiffre figure dans la fiche avec le bon identifiant, les six contrôles passent. C'est l'erreur de contexte décrite par Thomson et Reiter (2020), en vrai.

Le texte contenait un second défaut : « une baisse de −18,2 % », une double négation. Notre propre consigne des signes la provoque, puisqu'elle exige un signe devant chaque évolution.

La remarque nommait les deux défauts : les 15,8 Md€ ne sont pas une partie de l'industrie, et il fallait écrire « une évolution de −18,2 % ». Le tour 2 les a corrigés :

> « […] La part des paiements à l'industrie versée aux grandes entreprises est de 90,6 % [F15]. Par ailleurs, les paiements aux grandes entreprises privées résidentes atteignent 15,8 Md€ [F11], soit une évolution de +24,0 % [F12], tandis que les paiements aux entreprises de taille intermédiaire (ETI) privées résidentes s'établissent à 3,3 Md€ [F13], avec une évolution de −18,2 % [F14]. »

Une maladresse demeure : « 15,8 Md€, soit une évolution de +24,0 % ». « Soit » annonce une équivalence, alors qu'un montant n'est pas une évolution. Ce n'est pas une erreur ; le texte a été validé.

### Ce qui m'a posé problème, et ce que j'ai compris

À la question « pourquoi le second `grep` affiche-t-il 1, et pas 2 ? », j'ai répondu : « 1 car si meurt après l'appel ne relance pas le tour ».

C'était presque juste, mais pas tout à fait : le nœud `rediger` est bien relancé, depuis sa première ligne. Ce qui n'est pas refait, c'est l'appel au modèle. Le mécanisme tient en trois temps :

1. **Le tour 1 n'existe pas encore pour le graphe :** le processus est mort avant que `rediger` ne rende son résultat, donc l'état ne l'a jamais enregistré.
2. **La reprise reconstruit le même appel :** même tour, donc même étiquette ; même état, donc même requête ; donc même clé.
3. **Le journal répond à la place du modèle :** l'enveloppe, en mode reprise, trouve la clé et rend la réponse enregistrée.

J'ai compris la différence entre « relancer l'étape » et « refaire ses effets ». LangGraph relance l'étape ; c'est le journal qui empêche d'en refaire l'effet coûteux.

### Pièges et bonnes pratiques

- **Exporter `GRAPHE_PANNE`** au lieu de la placer devant la seule commande `lancer` : `reprendre` mourrait au même endroit.
- **Choisir `"exit"` pour aller plus vite :** une panne ferait perdre tout le fil depuis son lancement.
- **Écrire un nœud qui agit sur le monde avant `interrupt()`,** par exemple qui envoie un courriel : il le renverrait à chaque reprise.
- **Supprimer `etat/graphe.sqlite`** : les fils en cours sont perdus. Le journal, lui, reste, et chaque fil se rejoue comme au test 5.
- **Croire que le code voit les erreurs de contexte.** Il vérifie que chaque chiffre est dans la fiche, pas qu'il est attaché à la bonne grandeur.

> **À retenir.** Une reprise après panne repose sur deux outils : un point de reprise et un journal. La sauvegarde garde les étapes finies, le journal garde les appels faits : relancer une étape ne refait pas son effet coûteux. Une reprise se prouve en provoquant la panne. Et un texte qui passe tous les contrôles peut encore être faux : seule la relecture humaine l'a vu.

### Pour vérifier que vous avez compris

1. Si la panne avait eu lieu dans `verifier` (`GRAPHE_PANNE=verifier`), quel nœud la reprise aurait-elle relancé, et combien de lignes du tour 1 le journal aurait-il contenues ?
2. Imaginez que `rediger` incrémente un compteur rangé dans un fichier, hors de l'état, juste avant l'appel au modèle, et en tire le numéro de tour. Que se passerait-il à la reprise ?

### Références

- Elnozahy, E. N., Alvisi, L., Wang, Y.-M., Johnson, D. B. (2002). *A survey of rollback-recovery protocols in message-passing systems*. ACM Computing Surveys, 34(3), p. 375–408. https://doi.org/10.1145/568522.568525 — **Ce qu'on y apprend :** les points de reprise et la journalisation, les deux outils de toute reprise après panne.
- Helland, P. (2012). *Idempotence Is Not a Medical Condition*. ACM Queue, 10(4) ; repris dans Communications of the ACM, 55(5). https://queue.acm.org/detail.cfm?id=2187821 — **Ce qu'on y apprend :** pourquoi une opération répétée doit avoir le même effet qu'une seule, dans tout système qui peut tomber en panne.
- Basiri, A., Behnam, N., de Rooij, R., Hochstein, L., Kosewski, L., Reynolds, J., Rosenthal, C. (2016). *Chaos Engineering*. IEEE Software, 33(3), p. 35–41. https://doi.org/10.1109/MS.2016.60 — **Ce qu'on y apprend :** pourquoi provoquer des pannes exprès, et comment le faire sans risque.

## Chapitre 13 — Clore

### Ce que nous avons fait

Le bloc 9 a pris trois temps.

**Corriger, puis consigner.**

- **Le correctif.** La sortie du graphe indique désormais le vrai chemin du journal. Il a été testé sur une copie du dépôt, où les cinq tests passaient toujours, puis commité : `10f7c4c`, « fix: la sortie du graphe indique le vrai chemin du journal ».
- **L'`ADR-003`.** Il a été relu, puis passé au statut « accepté pour le laboratoire » et daté du 25 novembre. Il est commité avec les cinq tests : `4751874`, « docs: ADR-003 accepté, et les cinq tests du graphe ».

**Prouver.** Le cas 7 a été rejoué sans réseau ni clé, et la clé cherchée dans tout l'historique :

```bash
env -u LLM_CLE LLM_MODE=rejeu python3 -m banc --campagne 2026-11-24-gemma4-26b-moe-ecodef --cas ecodef > /dev/null
git diff --exit-code mesures/ && echo "cas 7 rejoué à l'identique"
git log -p --all | grep -cF "${LLM_CLE:?}"     # doit afficher 0
```

Les deux contrôles ont donné le résultat attendu. Le `README.md` a reçu la date du jour 3 et la commande de rejeu du cas 7. Le `JOURNAL.md` a reçu sa clôture : commit `ebb459d`, « docs: clôture du jour 3 (journal, README) ».

**Fusionner, puis étiqueter.** La pull request n° 3, de `jour-3` vers `main`, a été fusionnée par un commit de fusion, `19446e4`. L'étiquette annotée `jour-3` a été posée sur ce commit, puis poussée, au second essai.

### Pourquoi cette étape

**Un résultat qu'on ne peut pas rejouer n'est qu'une affirmation.** Peng (2011) fait de la reproductibilité la norme minimale, quand une réplication complète est hors d'atteinte. Le cas 7 se rejoue depuis le journal, et chaque texte validé garde ses faits, ses décisions et les clés de ses appels.

**Git comme instrument de transparence.** Ram (2013) montre comment un système de gestion de versions rend un travail scientifique traçable. Chaque état y est daté, chaque changement attribué, et l'on peut revenir à n'importe quel point. Le commit de fusion et l'étiquette en tirent parti : la journée entière se retrouve en une commande.

**Une décision d'architecture s'écrit pendant qu'on s'en souvient.** L'`ADR-003` dit pourquoi le graphe appelle le modèle par l'enveloppe, et non par l'intégration de LangChain. Dans trois mois, la question reviendra ; la réponse sera dans le dépôt, avec ses preuves.

### Comment ça marche

**Un rejeu qui ne peut pas tricher.** `env -u LLM_CLE` retire la clé pour cette seule commande. Sans clé, aucun appel ne peut partir. Si une réponse manquait au journal, le banc s'arrêterait sur une erreur au lieu de la redemander au serveur. Le rapport produit doit être identique, au caractère près, à celui qui a été commité : `git diff --exit-code` le vérifie.

**Un contrôle de la clé qui ne peut pas se tromper.** `git log -p --all` affiche toutes les modifications de toutes les branches. `grep -cF` y compte les lignes qui contiennent la clé, prise comme une chaîne fixe (`-F`) et non comme une expression régulière. La forme `${LLM_CLE:?}` arrête le shell, avec un message, si la variable est vide ou absente. Sans elle, `grep` chercherait une chaîne vide, que toutes les lignes contiennent, et le contrôle n'aurait aucun sens.

**Trois façons de fusionner.** GitHub propose un commit de fusion, un écrasement (*squash*) ou un rebasage. Le commit de fusion garde les onze commits de la journée tels quels, et les rattache à `main` par un commit qui a deux parents. `git log --first-parent --oneline main` montre alors une ligne par jour, et `git log jour-2..jour-3` le détail de la journée.

**Une branche et une étiquette de même nom.** Git range les branches sous `refs/heads/` et les étiquettes sous `refs/tags/`. Après la fusion, `jour-3` désignait les deux. `git push origin jour-3` est donc ambigu, et git refuse de deviner : « src refspec jour-3 matches more than one ». Le mot `tag` lève l'ambiguïté : `git push origin tag jour-3`.

**Une étiquette annotée est un objet.** `git ls-remote --tags origin` a affiché deux lignes pour `jour-3` : `97148df…`, l'objet étiquette lui-même, avec son auteur, sa date et son message ; puis `jour-3^{}`, `19446e4…`, le commit qu'il désigne. Le suffixe `^{}` « épluche » l'étiquette jusqu'au commit.

### Ce que nous avons observé

Onze commits sur la branche `jour-3`, puis le commit de fusion `19446e4`, qui a bien deux parents. Leur liste, avec leurs messages, est à l'annexe C.

Le premier `git push origin jour-3` a échoué sur l'ambiguïté ; `git push origin tag jour-3` a réussi : « * [new tag] jour-3 -> jour-3 ». Une commande de vérification de Claude, `git rev-parse --short` avec deux révisions, a aussi échoué (« fatal: Needed a single revision »), sans conséquence : `--short` n'accepte qu'une révision à la fois, et `git ls-remote` faisait la même vérification.

Après la clôture, en préparant ce cours, nous avons trouvé un dernier défaut : le dessin de `docs/graphe.md` ne s'affiche pas sur GitHub (chapitre 10). Son correctif ouvrira le jour 4.

### Pièges et bonnes pratiques

- **Oublier de pousser l'étiquette** : `git push` ne l'envoie pas. `git ls-remote --tags origin` le vérifie.
- **Donner le même nom à une branche et à une étiquette** sans le savoir : la commande `git push origin tag <nom>` lève l'ambiguïté.
- **Fusionner par écrasement** : les onze commits deviendraient un seul, et l'histoire de la journée serait perdue.
- **Supprimer la branche** après la fusion, par réflexe : rien ne s'y oppose techniquement, mais nous gardons les branches des jours.
- **Contrôler la clé avec une variable vide** : `${LLM_CLE:?}` l'empêche.

> **À retenir.** Commiter, rejouer sans réseau ni clé, comparer, chercher la clé dans tout l'historique. Fusionner par un commit de fusion, étiqueter ce commit, pousser l'étiquette explicitement. Une décision d'architecture s'écrit le jour où on la prend.

### Pour vérifier que vous avez compris

1. Pourquoi écrire `${LLM_CLE:?}` plutôt que `$LLM_CLE` dans le contrôle de la clé ?
2. Pourquoi git a-t-il refusé `git push origin jour-3` après la fusion, et que précise le mot `tag` ?

### Références

- Peng, R. D. (2011). *Reproducible Research in Computational Science*. Science, 334(6060), p. 1226–1227. https://doi.org/10.1126/science.1213847 — **Ce qu'on y apprend :** la reproductibilité comme norme minimale, quand la réplication complète est hors d'atteinte.
- Ram, K. (2013). *Git can facilitate greater reproducibility and increased transparency in science*. Source Code for Biology and Medicine, 8, article 7. https://doi.org/10.1186/1751-0473-8-7 — **Ce qu'on y apprend :** comment la gestion de versions rend un travail scientifique traçable et vérifiable.
- Chacon, S., Straub, B. (2014). *Pro Git*, 2ᵉ édition. Apress. https://git-scm.com/book/fr/v2 — **Ce qu'on y apprend :** les références, les étiquettes annotées et les stratégies de fusion, expliquées en détail.

## Chapitre 14 — Fiche bilan

### Ce que la séance a produit

<!-- largeurs: 34,66 -->
| Livrable | Où le trouver |
| --- | --- |
| Fiche de faits vérifiée contre la publication | `redaction/fiche_ecodef273.json` |
| Plan et paris du cas 7, préenregistrés | `banc/PLAN.md`, commit `24a9ba2` |
| Mesures du cas 7 et journal des 60 appels | `mesures/`, `journal/`, `banc-ecodef.log` |
| Qui se charge de chaque consigne | `docs/adr/0002-consignes-de-redaction.md` |
| Versions épinglées et figées | `requirements.txt`, `requirements-fige.txt` |
| Le graphe et son dessin | `graphe/`, `docs/graphe.md` (à corriger) |
| Les cinq tests du graphe | `verifier_graphe.py` |
| Deux textes validés, avec leurs preuves | `sorties/q1-premier.md`, `sorties/panne-q2.md` |
| Le graphe orchestre, l'enveloppe appelle | `docs/adr/0003-graphe-et-enveloppe.md` |
| La journée, fusionnée et étiquetée | commit `19446e4`, étiquette `jour-3` |

### Les dix leçons

1. **Le code garantit les chiffres, l'humain garantit le sens.** Démontré deux fois : un 60 sur 60 qui mesurait surtout une recopie, et un texte de Q2 sans anomalie pour le code, mais faux.
2. **Un étalon se vérifie avant la mesure.** Onze lignes de la fiche ont changé après lecture du PDF, dont un libellé qui omettait son champ.
3. **Sur des nombres arrondis, on raisonne par intervalles.** Un écart d'un dixième ne prouve rien ; une partie plus grande que son tout prouve une erreur.
4. **On préenregistre, même avec une intuition.** Un pari sans raison écrite vaut mieux qu'une raison inventée après coup.
5. **Une doublure qui plante des fautes connues prouve que l'instrument les trouve.** Déterministe, elle compare aussi deux environnements.
6. **Un résultat trop beau se lit.** 20 sur 20 borne le taux d'échec à 13,9 %, pas à zéro, et peut avoir une autre explication que la réussite.
7. **Une dépendance se choisit, s'épingle et se fige.**
8. **LangGraph : un état, des nœuds, des arêtes, des réducteurs.** Le moteur avance par super-étapes, sauvegarde à chaque frontière sous le nom d'un fil, et s'interrompt dans sa sauvegarde, pas dans un processus.
9. **Rien avant `interrupt()` ; une sauvegarde et un journal.** La sauvegarde garde les étapes finies, le journal les appels faits : relancer une étape ne refait pas son effet coûteux. Et une reprise se prouve en provoquant la panne.
10. **Un fichier se vérifie là où il sera lu.** `docs/graphe.md` paraissait parfait dans le terminal, et ne s'affiche pas sur GitHub.

### Ce que je sais faire maintenant

- [x] Prouver un rangement de code par un rejeu identique.
- [x] Lire une fonction de vérification et la tester sur des cas limites.
- [x] Vérifier une fiche de faits contre sa source, avec l'arithmétique d'intervalles.
- [x] Préenregistrer un plan et des paris chiffrés, puis les confronter au résultat.
- [x] Calculer et interpréter une borne de taux d'échec quand tout réussit.
- [x] Épingler et figer les dépendances d'un projet Python.
- [x] Expliquer l'état, les nœuds, les arêtes, les réducteurs, les super-étapes, les sauvegardes, les fils et les interruptions de LangGraph.
- [x] Dire, pour chaque nœud, ce qu'il lit, ce qu'il écrit, et s'il supporte d'être relancé.
- [x] Mener un fil jusqu'à la validation, avec une remarque précise.
- [x] Provoquer une panne, reprendre, et expliquer pourquoi l'appel n'est pas refait.
- [x] Fusionner par un commit de fusion, et pousser une étiquette sans ambiguïté.

### Ce qui reste ouvert

- **Le jour 4 :** transformer la fiche en registre de faits produit par du code, et faire écrire les chiffres par le code (le rendu). Le nœud `verifier` y deviendra le contrôleur.
- **L'hypothèse de la recopie :** refaire le cas 7 avec une fiche aux valeurs non formatées, sans signe et en millions d'euros, et voir si les taux chutent.
- **Le dessin du graphe :** corriger `docs/graphe.md` au début du jour 4 (annexe B).
- **Les points en attente depuis le jour 2 :**
  - l'accès à l'API Albert, pour mesurer le modèle de travail ;
  - la campagne de 300 appels du schéma imposé ;
  - une campagne plus longue à 32 000 tokens ;
  - un fichier plus précis que les chiffres arrondis de l'EcoDef n° 273 ;
  - la clé, à ranger dans les secrets d'Onyxia.

## Annexe A — Les chiffres de la séance

Chaque chiffre vient du rapport du banc, du journal des appels, des sorties du graphe ou d'un calcul refait pour ce cours.

### Le cas 7

<!-- largeurs: 46,54 -->
| Mesure | Valeur |
| --- | --- |
| Campagne | `2026-11-24-gemma4-26b-moe-ecodef` : 3 conditions × 20 sujets |
| Appels | 60, envoyés en 58 s |
| Essais réussis (six consignes et réponse en français) | 60 sur 60 |
| Réponses coupées, refus, réponses en anglais | 0, 0, 0 |
| Chaque consigne, dans chaque condition | 20/20 (100,0 %), intervalle de Wilson à 95 % : [83,9 % ; 100 %] |
| Borne exacte du taux d'échec (0 échec sur 20) | 13,9 % ; sur 60 essais identiques, ce serait 4,9 % |
| `outil` contre `fiche`, `anglais` contre `fiche` | 0 paire discordante, McNemar p = 1,000 |

### La répétition contre le faux serveur

<!-- largeurs: 40,20,20,20 -->
| Consigne | `fiche` | `outil` | `anglais` |
| --- | --- | --- | --- |
| Fidélité | 18 | 18 | 19 |
| Identifiants | 15 | 17 | 18 |
| Md€ | 15 | 17 | 18 |
| Signes | 19 | 18 | 19 |
| Sans Markdown | 20 | 17 | 18 |
| Source | 19 | 19 | 17 |
| Les six à la fois | 10 | 13 | 11 |

### Les calculs d'intervalles

<!-- largeurs: 34,40,26 -->
| Rapport | Intervalle compatible avec les arrondis | Valeur publiée |
| --- | --- | --- |
| F09 / F03 = 17,7 / 25,1 | [70,2 % ; 70,9 %] | F10 = 70,7 % : compatible |
| F03 / F01 = 25,1 / 30,3 | [82,5 % ; 83,1 %] | F04 = 82,9 % : compatible |
| F15 × F09 = 90,6 % × 17,7 | au moins 15,98 Md€ | F11 au plus 15,85 Md€ : contradiction, F11 omettait « privées » |
| F11 / F09 = 15,8 / 17,7 | [88,7 % ; 89,8 %] | 90,6 % dans le texte de Q2 : faux |

### Le graphe

<!-- largeurs: 30,70 -->
| Fil | Ce qui s'est passé |
| --- | --- |
| `essai` (faux serveur) | Faute au tour 1, corrigée seule au tour 2 ; remarque, tour 3, validation ; 3 appels ; 6 instantanés à la pause |
| `q1-premier` | Aucune anomalie au tour 1, réponse en deuxième phrase ; remarque, tour 2, validation ; 2 appels |
| `panne-q2` | Code de sortie 3, `appels 0` ; `grep` à 1 avant et après la reprise ; erreur de contexte au tour 1 ; remarque, tour 2, validation ; 2 appels |
| `verifier_graphe.py` | « Les cinq comportements du graphe sont vérifiés. » |

### Le reste

- La fiche : 19 faits, toutes les valeurs justes ; 11 lignes modifiées, soit sept libellés précisés, F07 à sa valeur exacte, et des références de page et de figure.
- Les dépendances : 2 choisies, 41 installées.
- Le jouet du chapitre 9 : 7 instantanés, de l'étape −1 à l'étape 5.
- Les commits : 11 sur la branche `jour-3`, plus le commit de fusion `19446e4`.

### La fiche de faits vérifiée

Source : EcoDef Statistiques n° 273, janvier 2026. Valeurs recopiées de la publication, puis vérifiées une à une contre le PDF le 24 novembre 2026. Fiche provisoire : le registre de faits la remplacera au jour 4.

<!-- largeurs: 8,56,14,22 -->
| Id | Libellé | Valeur | Référence |
| --- | --- | --- | --- |
| F01 | Paiements du ministère des Armées à l'ensemble de ses fournisseurs en 2024 | 30,3 Md€ | page 1 |
| F02 | Évolution de ces paiements entre 2023 et 2024 | +6,1 % | résumé |
| F03 | Paiements directs aux fournisseurs résidents en 2024 | 25,1 Md€ | page 1, figure 1 |
| F04 | Part des paiements versés aux fournisseurs résidents dans l'ensemble des paiements en 2024 | 82,9 % | page 1 |
| F05 | Évolution des paiements aux fournisseurs résidents entre 2023 et 2024 | +9,4 % | page 1, figure 1 |
| F06 | Nombre d'entreprises résidentes fournisseurs du ministère en 2024 | 23 451 entreprises | page 1, figure 1 |
| F07 | Nombre de fournisseurs du ministère en 2024, résidents ou non | 25 486 fournisseurs | page 1, figure 1 |
| F08 | Part des fournisseurs qui résident en France en 2024 | 92,0 % | résumé |
| F09 | Paiements aux entreprises résidentes de l'industrie en 2024 | 17,7 Md€ | page 2, figure 2 |
| F10 | Part de l'industrie dans les paiements aux fournisseurs résidents en 2024 | 70,7 % | page 2, figure 2 |
| F11 | Paiements aux grandes entreprises privées résidentes en 2024 | 15,8 Md€ | page 1, figure 1 |
| F12 | Évolution des paiements aux grandes entreprises privées entre 2023 et 2024 | +24,0 % | page 1, figure 1 |
| F13 | Paiements aux entreprises de taille intermédiaire (ETI) privées résidentes en 2024 | 3,3 Md€ | page 1, figure 1 |
| F14 | Évolution des paiements aux ETI privées entre 2023 et 2024 | −18,2 % | page 1, figure 1 |
| F15 | Part des paiements à l'industrie versée aux grandes entreprises en 2024 | 90,6 % | page 3, figure 3 |
| F16 | Paiements aux fournisseurs résidents financés par le programme 146 « Équipement des forces » en 2024 | 11,7 Md€ | figure 7 |
| F17 | Paiements aux fournisseurs résidents financés par le programme 178 « Préparation et emploi des forces » en 2024 | 9,8 Md€ | figure 7 |
| F18 | Paiements aux fournisseurs résidents financés par le programme 144 « Environnement et prospective de la politique de défense » en 2024 | 1,5 Md€ | figure 7 |
| F19 | Paiements aux fournisseurs résidents financés par le programme 212 « Soutien de la politique de défense » en 2024 | 0,9 Md€ | figure 7 |

### Les paris et les résultats

<!-- largeurs: 34,22,22,22 -->
| Prédiction | Mon pari | Pari de Claude | Résultat |
| --- | --- | --- | --- |
| Fidélité en `fiche` | 18/20 | 17/20 | 20/20 |
| Identifiants en `fiche` | 20/20 | 13/20 | 20/20 |
| Md€ en `fiche` | 20/20 | 16/20 | 20/20 |
| Signes en `fiche` | 20/20 | 14/20 | 20/20 |
| Texte brut en `fiche` | 17/20 | 19/20 | 20/20 |
| Ligne de source en `fiche` | 19/20 | 17/20 | 20/20 |
| Les six à la fois en `fiche` | 16/20 | 6/20 | 20/20 |
| Fidélité en `outil` | 16/20, sans écart net | pas d'écart net | 20/20, aucune paire discordante |
| `anglais` contre `fiche` | pas d'écart net | pas d'écart net | aucune paire discordante |
| Réponses coupées | aucune | aucune | aucune |

**Ce que les écarts apprennent.** Mes paris étaient plus proches du résultat, sans raison écrite pour la plupart. Ceux de Claude imaginaient un modèle qui rédige en prose française naturelle ; le modèle a recopié une fiche déjà formatée. Le produit des taux, sous indépendance, donnait environ 14,5 sur 20 pour mes paris et 5 sur 20 pour ceux de Claude. Nous avions tous deux parié au-dessus, en supposant des échecs concentrés sur les mêmes réponses. Il n'y a eu aucun échec.

## Annexe B — Incidents, erreurs et correctifs

### Les incidents de la séance

<!-- largeurs: 13,29,29,29 -->
| Quand | Symptôme | Cause | Remède |
| --- | --- | --- | --- |
| 24/11, bloc 0 | L'étiquette `jour-2` manque sur GitHub | Oubliée au jour 2 : `git push` n'envoie pas les étiquettes | Posée, puis poussée |
| 24/11, bloc 3 | « no changes added to commit » | Bloc de commit relancé : les fichiers avaient été commités au premier passage | Rien à faire ; `git log --oneline -3` le confirme |
| 25/11, bloc 7 | « OSError: [Errno 98] Address already in use » | Le faux serveur de la veille occupait encore le port 8765 | `pgrep -af faux_serveur`, puis `pkill -f faux_serveur` |
| 25/11, bloc 7 | « can't open file '…/work/outils/faux_serveur.py' » | Après `cd ..`, un niveau au-dessus du dépôt | `cd ~/work/assistant-etude-sourcee` |
| 25/11, bloc 7 | `essai.md` introuvable dans l'explorateur | `/tmp` est hors de l'espace de travail de VS Code | `ls` et `cat`, ou « File: Open File… » |
| 25/11, bloc 7 | La sortie de l'essai annonce `journal/appels.jsonl` | Chemin écrit en dur dans la fonction `exporter` | Correctif `10f7c4c` |
| 25/11, bloc 7 | « Le fil q1-premier existe déjà » | Fil lancé plus tôt | `etat`, `historique`, puis `decider` |
| 25/11, bloc 8 | La sortie de Q2 introuvable | Elle porte le nom du fil, `panne-q2.md`, et n'existe qu'après validation | `etat`, puis réaffichage du texte |
| 25/11, bloc 9 | « src refspec jour-3 matches more than one » | Une branche et une étiquette de même nom | `git push origin tag jour-3` |
| 25/11, bloc 9 | « fatal: Needed a single revision » | `git rev-parse --short` avec deux révisions, dans une commande de Claude | Sans conséquence |
| Après la séance | Le dessin de `docs/graphe.md` ne s'affiche pas sur GitHub | Codes invisibles du terminal de VS Code, capturés par `{ … } > fichier` | Correctif ci-dessous |

### Les erreurs du programme, corrigées pendant la séance

- **F10.** Le programme concluait que l'écart entre 70,5 % et 70,7 % prouvait un autre champ. C'était un effet d'arrondi (chapitre 3).
- **F15.** Le programme soupçonnait F15. C'était F11, qui omettait le mot « privées » (chapitre 3).
- **L'étiquette.** `git push origin jour-3` devient `git push origin tag jour-3` (chapitre 13).
- **Le dessin.** La commande `{ echo …; python3 -m graphe dessiner; echo …; } > docs/graphe.md` est remplacée par une écriture en Python (ci-dessous).

### Le correctif de `docs/graphe.md`, pour le début du jour 4

À faire sur la branche du jour 4, avant tout autre travail. Le script ne touche que la première ligne, et refuse d'agir si elle n'a pas la forme attendue :

```bash
python3 - <<'EOF'
from pathlib import Path
p = Path("docs/graphe.md")
lignes = p.read_text(encoding="utf-8").split("\n")
assert lignes[0].endswith("```mermaid"), "première ligne inattendue : fichier déjà corrigé ?"
lignes[0] = "```mermaid"
p.write_text("\n".join(lignes), encoding="utf-8")
print("caractères invisibles restants :", p.read_text(encoding="utf-8").count("\x1b"))   # 0
EOF
git diff --stat                      # docs/graphe.md | 2 +-
git add docs/graphe.md
git commit -m "fix: dessin du graphe lisible sur GitHub (codes invisibles du terminal retirés)"
git push
```

Le correctif a été essayé sur une copie du dépôt : une ligne change, et il ne reste aucun caractère invisible. Après le `push`, la page du fichier sur GitHub doit montrer le dessin.

Pour redessiner le graphe à l'avenir, c'est Python qui écrit le fichier, sans redirection du shell :

```bash
python3 - <<'EOF'
import subprocess, sys
from pathlib import Path
dessin = subprocess.run([sys.executable, "-m", "graphe", "dessiner"],
                        capture_output=True, text=True, check=True).stdout
Path("docs/graphe.md").write_text("```mermaid\n" + dessin.rstrip("\n") + "\n```\n", encoding="utf-8")
EOF
```

## Annexe C — Commits, contrôles et points en attente

### Les commits de la journée

<!-- largeurs: 14,86 -->
| Commit | Message |
| --- | --- |
| `de67afe` | refactor: sondes du jour 1 rangées dans sondes/, rejouées à l'identique |
| `24a9ba2` | docs: plan du cas 7 (consignes EcoDef) et prédictions |
| `0fd6657` | chore: mesures du cas 7 (campagne complémentaire, consignes EcoDef) |
| `059a1a6` | docs: ADR-002, consignes de rédaction (cas 7), et lecture du cas |
| `bb02d66` | build: LangGraph 1.2.24 et sauvegarde SQLite 3.1.3, versions épinglées |
| `1bb1d07` | feat: graphe d'états rediger, verifier, valider, et son dessin |
| `d08e830` | docs: première rédaction par le graphe (Q1), corrigée puis validée |
| `d85a22a` | docs: panne et reprise du graphe (Q2), texte corrigé puis validé |
| `10f7c4c` | fix: la sortie du graphe indique le vrai chemin du journal |
| `4751874` | docs: ADR-003 accepté, et les cinq tests du graphe |
| `ebb459d` | docs: clôture du jour 3 (journal, README) |
| `19446e4` | Merge pull request #3 from MaryleneH/jour-3 (commit de fusion) |

### Les contrôles de la journée

- [x] Sondes du jour 1 rangées, rejouées à l'identique
- [x] Fiche de faits vérifiée contre la publication avant le préenregistrement
- [x] Plan et paris commités avant le premier appel
- [x] Répétition contre le faux serveur : chaque consigne trouve des fautes
- [x] Mesures commitées avant d'être lues
- [x] `ADR-002` écrit et commité
- [x] Versions épinglées et figées
- [x] Cinq tests du graphe : « Les cinq comportements du graphe sont vérifiés. »
- [x] Panne provoquée à la main : code de sortie 3, deux `grep` à 1
- [x] Deux fils validés sur le vrai serveur, chacun après une remarque
- [x] `ADR-003` accepté
- [x] Cas 7 rejoué sans réseau ni clé : identique
- [x] Clé absente de tout l'historique
- [x] Journal et README à jour
- [x] Branche `jour-3` fusionnée par un commit de fusion
- [x] Étiquette `jour-3` posée sur le commit de fusion et poussée

### Les points en attente

<!-- largeurs: 30,52,18 -->
| Point | Détail | Statut |
| --- | --- | --- |
| Cas « consignes EcoDef » | Le cas 7, préenregistré, mesuré et lu (chapitres 2 à 7) | fait |
| Sondes du jour 1 | Rangées dans `sondes/`, déplacement validé par rejeu (chapitre 1) | fait |
| Usage du résultat d'un outil | La fidélité reste à 20 sur 20 quand les faits arrivent par un outil (chapitre 7) ; à revoir dans l'agent | fait en partie |
| Dessin du graphe | Corriger `docs/graphe.md` au début du jour 4 (annexe B) | en attente |
| Hypothèse de la recopie | Refaire le cas 7 avec une fiche aux valeurs non formatées | en attente |
| Registre de faits et rendu | Le jour 4 | en attente |
| Plafond de tokens réglable | Un paramètre du banc, pour le cas des consignes génériques du jour 2 | en attente |
| Schéma imposé | Une campagne plus longue avant toute production | en attente |
| Budget de contexte | Une campagne plus longue à 32 000 tokens, avant de relever le budget | en attente |
| Accès à l'API Albert | Pour mesurer le modèle de travail | en attente |
| Données de l'EcoDef n° 273 | Un fichier plus précis que les chiffres arrondis de la publication | en attente |
| Clé | À ranger dans les secrets d'Onyxia | en attente |

## Annexe D — Glossaire

<!-- largeurs: 24,76 -->
| Terme | Définition |
| --- | --- |
| ADR | *Architecture Decision Record* : relevé d'une décision d'architecture, avec son contexte, ses options, ses preuves, ses conséquences et ses limites. |
| Aiguillage | Fonction d'une arête conditionnelle : elle lit l'état et rend le nom du nœud suivant. |
| Arête | Lien entre deux nœuds : fixe (« toujours ensuite ») ou conditionnelle (choisie par un aiguillage). |
| Arithmétique d'intervalles | Calcul sur des intervalles plutôt que sur des valeurs, pour savoir ce qu'un calcul sur des nombres arrondis permet de conclure. |
| BSP | *Bulk synchronous parallel* : modèle de calcul parallèle par super-étapes, séparées par des barrières de synchronisation (Valiant, 1990). |
| Clé d'appel | Empreinte SHA-256 de l'adresse du serveur, de l'étiquette de l'appel et du corps de la requête ; elle identifie un appel dans le journal. |
| Commit de fusion | Commit à deux parents, qui rattache une branche à une autre sans réécrire ses commits. |
| Doublure de test | Faux composant, contrôlable, qui remplace le vrai pendant un essai ; ici, le faux serveur. |
| *Durability* | Réglage de LangGraph qui dit quand l'instantané est écrit : `"exit"`, `"async"` (par défaut) ou `"sync"`. |
| Environnement virtuel | Dossier qui isole les paquets Python d'un projet de ceux du système. |
| Épingler, figer | Épingler : fixer la version d'une dépendance choisie (`==`). Figer : enregistrer la version de tout ce qui est installé (`pip freeze`). |
| Erreur de contexte | Nombre juste attaché à la mauvaise grandeur : le code de vérification ne la voit pas. |
| Étiquette annotée | Objet git qui nomme un commit, avec un auteur, une date et un message. |
| Fil (*thread*) | Une exécution du graphe, désignée par un nom, avec sa propre suite d'instantanés. Chez nous, une rédaction. |
| Flux de travail | Système dont le code écrit les chemins ; le modèle n'y fait que certaines étapes. S'oppose à l'agent qui choisit ses étapes. |
| Idempotence | Propriété d'une opération qu'on peut répéter sans autre effet que de la faire une fois. |
| Instantané (*checkpoint*) | Sauvegarde de l'état du graphe à une frontière de super-étape : valeurs, nœuds suivants, métadonnées, tâches en attente. |
| `interrupt()` | Fonction de LangGraph qui met le graphe en pause dans sa sauvegarde ; à la reprise, elle rend la réponse et le nœud repart de son début. |
| Journal des appels | Fichier où l'enveloppe ajoute une ligne par appel au modèle, avec sa clé, sa requête et sa réponse. |
| LangGraph | Bibliothèque Python d'orchestration : graphe d'états, sauvegardes, reprise, interruptions. |
| Mise à jour partielle | Dictionnaire rendu par un nœud : seulement les champs qu'il change. |
| Nœud | Étape du graphe : une fonction qui reçoit l'état et rend une mise à jour partielle. |
| Point de reprise | Sauvegarde de l'état d'un système, à partir de laquelle il peut repartir après une panne. |
| Préenregistrement | Écriture du plan, des règles et des prédictions avant de voir les données, datée par un commit. |
| Pregel | Système de calcul sur graphe de Google, par super-étapes ; nom du moteur de LangGraph. |
| `recursion_limit` | Nombre maximal de super-étapes d'une exécution ; au-delà, `GraphRecursionError`. |
| Réducteur | Fonction qui fusionne une mise à jour avec l'ancienne valeur d'un champ ; par défaut, la remplace. |
| Rejeu, reprise | Modes de l'enveloppe. Rejeu : tout relire dans le journal, sans réseau. Reprise : relire les appels déjà faits, envoyer les autres. |
| Rendu | Transformation faite par le code seul, sans modèle : au jour 4, le code écrira les chiffres. |
| Reprise (d'un texte) | Nouvel appel au modèle, auquel le code transmet les écarts trouvés dans son texte précédent. |
| Super-étape | Un « tic » du moteur : planifier les nœuds, les exécuter, appliquer leurs mises à jour, sauvegarder. |
| `TypedDict` | Type Python qui déclare les champs d'un dictionnaire ; il documente l'état sans le vérifier à l'exécution. |

## Annexe E — Corrigé des questions

### Chapitre 1

1. Chaque appel du journal est retrouvé par sa clé, qui dépend de la requête. Une sonde déplacée qui poserait sa question autrement produirait une autre clé, et le rejeu échouerait. S'il passe, et si les mesures produites sont identiques à celles du dépôt, les sondes posent les mêmes questions et écrivent les mêmes résultats. Sans journal, il faudrait des tests de caractérisation contre une doublure déterministe, puisque le vrai modèle ne répond pas toujours la même chose.
2. `git log --branches --not --remotes --oneline` liste les commits de toutes les branches locales qui ne sont sur aucune branche distante. `git status` ne parle que de la branche courante et des fichiers non commités : une autre branche jamais poussée lui échappe.

### Chapitre 2

1. La fidélité compare la valeur, 25,1, à celle de F03, pas l'unité. Les identifiants passent aussi, puisque F03 porte bien 25,1. Le format ne regarde que les montants en euros, les signes que les évolutions, et ni le texte brut ni la source ne sont concernés. Au jour 4, le modèle écrira l'identifiant et le code écrira la valeur avec son unité, tirée du registre : l'unité ne pourra plus être fausse.
2. La ligne de source est connue d'avance : l'écrire ne demande aucune compréhension. Pour « près de 25 Md€ », le code sait que 25 n'est pas dans la fiche, mais pas quel fait était visé, ni si l'arrondi était voulu : il faut comprendre la phrase, donc la faire réécrire.

### Chapitre 3

1. Le vrai rapport est compris entre 25,05/30,35 = 82,5 % et 25,15/30,25 = 83,1 %. 82,9 % est dans l'intervalle : pas de contradiction, l'écart vient des arrondis.
2. Un modèle qui recopie « grandes entreprises résidentes » attribue 15,8 Md€ à toutes les grandes entreprises, publiques comprises, ce qui est faux, et le code le valide puisque la valeur est dans la fiche. Avec « privées », la phrase recopiée devient vraie. Corriger l'étalon corrige tous les textes qui le recopient.

### Chapitre 4

1. Sous indépendance, 0,9⁶ ≈ 0,53, soit environ 11 sur 20. Si les échecs tombent tous sur les deux mêmes essais, les dix-huit autres réussissent tout : 18 sur 20, le plafond fixé par la consigne la plus faible.
2. Le plan doit dater d'avant les données, pour que ni les règles ni les paris n'aient pu être ajustés aux résultats. Le commit, poussé sur GitHub, prouve l'ordre : le plan existait avant le premier appel du journal.

### Chapitre 5

1. Une case sous 20 prouve que le vérificateur de cette consigne a trouvé au moins une faute plantée. Une ligne à 20 partout voudrait dire que le faux serveur n'a planté aucune faute de ce type, ou que le vérificateur ne la voit pas : on ne pourrait pas se fier à cette consigne sans enquêter.
2. La faute dépend de l'empreinte du message reçu. Deux fiches identiques produisent les mêmes messages, donc les mêmes fautes et le même tableau ; un tableau différent trahit une entrée différente.

### Chapitre 6

1. Sur 20 essais : 1 − 0,05^(1/20) ≈ 13,9 % ; la règle de trois donne 3/20 = 15 %. Sur 60 essais identiques : 1 − 0,05^(1/60) ≈ 4,9 % ; la règle de trois donne 3/60 = 5 %.
2. Refaire le cas avec une fiche aux valeurs non formatées : sans signe, en millions d'euros. Si le modèle obéit aux consignes, il convertit et signe, et les taux restent hauts ; s'il recopie, les taux de format et de signes chutent. La prédiction se préenregistre, comme les autres.

### Chapitre 7

1. Les décisions tirées des taux restent celles que donnait la règle : tout reste au modèle, vérifié par le code. L'annonce du jour 4 repose sur une autre preuve, la recopie observée à la lecture, et l'ADR la présente comme une leçon, pas comme une conséquence des taux.
2. Le test dit qu'aucune donnée ne montre de différence sur ces vingt sujets, et la règle préenregistrée s'applique : décision confirmée. Il ne prouve pas que les deux conditions se valent : avec vingt sujets, un écart de quelques points resterait invisible.

### Chapitre 8

1. Les dépendances indirectes sont déclarées par intervalles, et pip prend la version la plus récente de chaque intervalle au moment de l'installation. Dans six mois, de nouvelles versions existeront : l'arbre changera. `requirements-fige.txt` empêche ce glissement.
2. `~=1.2.24` accepte 1.2.24 et les versions correctives suivantes de la série 1.2, pas la 1.3. Nous avons préféré `==` : toute montée de version, même corrective, doit être un choix explicite, éprouvé par `verifier_graphe.py`, comme le prévoit l'`ADR-003`.

### Chapitre 9

1. Validé du premier coup : deux fois, avant la pause puis à la reprise. Correction puis validation : quatre fois. Une au lancement ; une à la reprise « corriger », qui relance le nœud ; une au retour dans `valider` après le nouveau tour, avant la seconde pause ; une à la reprise « valider ».
2. La première exécution a été interrompue : le nœud n'a pas fini, sa super-étape non plus, et aucun instantané n'a été écrit. L'instantané 4 est resté le dernier, avec la tâche en attente. Seule la seconde exécution, complète, a conclu la super-étape et produit l'instantané 5.

### Chapitre 10

1. `tours` vaut 4, donc au moins `MAX_TOURS` : l'aiguillage conduit à `valider`, anomalies affichées. L'humain ne peut pas valider, puisque la commande et le nœud refusent tant qu'une anomalie reste. Il peut corriger, avec une remarque, ou abandonner.
2. `verifier` est un calcul pur : les mêmes entrées donnent les mêmes anomalies, et il n'agit pas sur le monde. `rediger` appelle un serveur : l'appel coûte, et sa réponse peut varier. Le relancer sans journal paierait un second appel et pourrait changer le texte ; avec le journal et une clé stable, la relance relit la réponse déjà reçue.

### Chapitre 11

1. L'enchaînement des nœuds, la correction automatique d'une faute plantée, l'arrêt pour décision, les décisions dans de nouveaux processus et l'écriture de la sortie : la tuyauterie. Le faux serveur ne rédige pas, il recolle les libellés et ne lit pas les remarques : il n'y a rien à juger côté rédaction.
2. Le tour 1 était juste en chiffres, mais ne répondait à la question qu'à la deuxième phrase. La remarque a fait passer le montant et l'évolution en tête. Les chiffres n'ont pas changé, le code n'a rien trouvé avant comme après : ce qui a changé, c'est la réponse à la question, que seul l'humain juge.

### Chapitre 12

1. Avec `"sync"`, l'instantané qui suit `rediger` était écrit avant que `verifier` ne commence. La reprise relance donc `verifier` seul, et le journal contient une seule ligne du tour 1 : c'est ce que prouve le test 4.
2. Le compteur aurait été incrémenté avant la panne. À la reprise, `rediger` lirait 2 au lieu de 1 : autre étiquette, donc autre clé. Le journal ne la trouverait pas, un second appel partirait au serveur, payé et peut-être différent, et la numérotation sauterait un tour. Une action hors de l'état, faite avant la fin du nœud, casse l'idempotence.

### Chapitre 13

1. `${LLM_CLE:?}` arrête le shell, avec un message, si la variable est vide ou absente. Sans cela, `grep` chercherait la chaîne vide, que toutes les lignes contiennent : le compte n'aurait aucun sens, et l'on ne saurait même pas que la clé n'était pas chargée.
2. Après la fusion et l'étiquetage, `jour-3` désignait à la fois une branche (`refs/heads/jour-3`) et une étiquette (`refs/tags/jour-3`), et git refuse de deviner. `tag` précise qu'il faut pousser l'étiquette.

## Annexe F — Bibliographie

### Articles et livres

- Amershi, S., Weld, D., Vorvoreanu, M., Fourney, A., Nushi, B., Collisson, P., Suh, J., Iqbal, S., Bennett, P. N., Inkpen, K., Teevan, J., Kikin-Gil, R., Horvitz, E. (2019). *Guidelines for Human-AI Interaction*. Proceedings of CHI 2019, article 3. https://doi.org/10.1145/3290605.3300233
- Basiri, A., Behnam, N., de Rooij, R., Hochstein, L., Kosewski, L., Reynolds, J., Rosenthal, C. (2016). *Chaos Engineering*. IEEE Software, 33(3), p. 35–41. https://doi.org/10.1109/MS.2016.60
- Brier, G. W. (1950). *Verification of forecasts expressed in terms of probability*. Monthly Weather Review, 78(1), p. 1–3. https://doi.org/10.1175/1520-0493(1950)078<0001:VOFEIT>2.0.CO;2
- Chacon, S., Straub, B. (2014). *Pro Git*, 2ᵉ édition. Apress. https://git-scm.com/book/fr/v2
- Clopper, C. J., Pearson, E. S. (1934). *The use of confidence or fiducial limits illustrated in the case of the binomial*. Biometrika, 26(4), p. 404–413. https://doi.org/10.1093/biomet/26.4.404
- Elnozahy, E. N., Alvisi, L., Wang, Y.-M., Johnson, D. B. (2002). *A survey of rollback-recovery protocols in message-passing systems*. ACM Computing Surveys, 34(3), p. 375–408. https://doi.org/10.1145/568522.568525
- Feathers, M. (2004). *Working Effectively with Legacy Code*. Prentice Hall.
- Fowler, M. (2018). *Refactoring: Improving the Design of Existing Code*, 2ᵉ édition. Addison-Wesley.
- Gao, T., Yen, H., Yu, J., Chen, D. (2023). *Enabling Large Language Models to Generate Text with Citations*. Proceedings of EMNLP 2023, p. 6465–6488. https://doi.org/10.18653/v1/2023.emnlp-main.398
- Harel, D. (1987). *Statecharts: A visual formalism for complex systems*. Science of Computer Programming, 8(3), p. 231–274. https://doi.org/10.1016/0167-6423(87)90035-9
- Helland, P. (2012). *Idempotence Is Not a Medical Condition*. ACM Queue, 10(4) ; repris dans Communications of the ACM, 55(5). https://queue.acm.org/detail.cfm?id=2187821
- Jiang, Y., Wang, Y., Zeng, X., Zhong, W., Li, L., Mi, F., Shang, L., Jiang, X., Liu, Q., Wang, W. (2024). *FollowBench: A Multi-level Fine-grained Constraints Following Benchmark for Large Language Models*. Proceedings of ACL 2024, p. 4667–4688. https://doi.org/10.18653/v1/2024.acl-long.257
- Kohavi, R., Tang, D., Xu, Y. (2020). *Trustworthy Online Controlled Experiments: A Practical Guide to A/B Testing*. Cambridge University Press. https://doi.org/10.1017/9781108653985
- Malewicz, G., Austern, M. H., Bik, A. J. C., Dehnert, J. C., Horn, I., Leiser, N., Czajkowski, G. (2010). *Pregel: A System for Large-Scale Graph Processing*. Proceedings of SIGMOD 2010, p. 135–146. https://doi.org/10.1145/1807167.1807184
- McNemar, Q. (1947). *Note on the sampling error of the difference between correlated proportions or percentages*. Psychometrika, 12(2), p. 153–157. https://doi.org/10.1007/BF02295996
- Meszaros, G. (2007). *xUnit Test Patterns: Refactoring Test Code*. Addison-Wesley.
- Min, S., Lyu, X., Holtzman, A., Artetxe, M., Lewis, M., Hajishirzi, H., Zettlemoyer, L. (2022). *Rethinking the Role of Demonstrations: What Makes In-Context Learning Work?* Proceedings of EMNLP 2022, p. 11048–11064. https://doi.org/10.18653/v1/2022.emnlp-main.759
- Moore, R. E., Kearfott, R. B., Cloud, M. J. (2009). *Introduction to Interval Analysis*. SIAM. https://doi.org/10.1137/1.9780898717716
- Nosek, B. A., Ebersole, C. R., DeHaven, A. C., Mellor, D. T. (2018). *The preregistration revolution*. Proceedings of the National Academy of Sciences, 115(11), p. 2600–2606. https://doi.org/10.1073/pnas.1708274114
- Parasuraman, R., Manzey, D. H. (2010). *Complacency and Bias in Human Use of Automation: An Attentional Integration*. Human Factors, 52(3), p. 381–410. https://doi.org/10.1177/0018720810376055
- Parasuraman, R., Sheridan, T. B., Wickens, C. D. (2000). *A model for types and levels of human interaction with automation*. IEEE Transactions on Systems, Man, and Cybernetics — Part A, 30(3), p. 286–297. https://doi.org/10.1109/3468.844354
- Parnas, D. L. (1972). *On the criteria to be used in decomposing systems into modules*. Communications of the ACM, 15(12), p. 1053–1058. https://doi.org/10.1145/361598.361623
- Peng, R. D. (2011). *Reproducible Research in Computational Science*. Science, 334(6060), p. 1226–1227. https://doi.org/10.1126/science.1213847
- Ram, K. (2013). *Git can facilitate greater reproducibility and increased transparency in science*. Source Code for Biology and Medicine, 8, article 7. https://doi.org/10.1186/1751-0473-8-7
- Ribeiro, M. T., Wu, T., Guestrin, C., Singh, S. (2020). *Beyond Accuracy: Behavioral Testing of NLP Models with CheckList*. Proceedings of ACL 2020, p. 4902–4912. https://doi.org/10.18653/v1/2020.acl-main.442
- Sandve, G. K., Nekrutenko, A., Taylor, J., Hovig, E. (2013). *Ten Simple Rules for Reproducible Computational Research*. PLoS Computational Biology, 9(10), e1003285. https://doi.org/10.1371/journal.pcbi.1003285
- Simmons, J. P., Nelson, L. D., Simonsohn, U. (2011). *False-Positive Psychology: Undisclosed Flexibility in Data Collection and Analysis Allows Presenting Anything as Significant*. Psychological Science, 22(11), p. 1359–1366. https://doi.org/10.1177/0956797611417632
- Thomson, C., Reiter, E. (2020). *A Gold Standard Methodology for Evaluating Accuracy in Data-To-Text Systems*. Proceedings of INLG 2020, p. 158–168. https://doi.org/10.18653/v1/2020.inlg-1.22
- Valiant, L. G. (1990). *A bridging model for parallel computation*. Communications of the ACM, 33(8), p. 103–111. https://doi.org/10.1145/79173.79181
- Wang, R. Y., Strong, D. M. (1996). *Beyond Accuracy: What Data Quality Means to Data Consumers*. Journal of Management Information Systems, 12(4), p. 5–33. https://doi.org/10.1080/07421222.1996.11518099
- Wilson, E. B. (1927). *Probable Inference, the Law of Succession, and Statistical Inference*. Journal of the American Statistical Association, 22(158), p. 209–212. https://doi.org/10.1080/01621459.1927.10502953
- Yao, S., Zhao, J., Yu, D., Du, N., Shafran, I., Narasimhan, K., Cao, Y. (2023). *ReAct: Synergizing Reasoning and Acting in Language Models*. ICLR 2023. https://arxiv.org/abs/2210.03629

### Documentations, propositions et billets techniques

- LangChain. *Graph API overview*, *Persistence* et *Interrupts*. Documentation de LangGraph. https://docs.langchain.com/oss/python/langgraph/graph-api
- Meyer, C. (2011). *PEP 405 – Python Virtual Environments*. Python Enhancement Proposals. https://peps.python.org/pep-0405/
- Nygard, M. (2011). *Documenting Architecture Decisions*. Billet technique, Cognitect, 15 novembre 2011. https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions
- OWASP Foundation. *Secrets Management Cheat Sheet*. OWASP Cheat Sheet Series. https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html
- pip developers. *Repeatable Installs*. Documentation de pip. https://pip.pypa.io/en/stable/topics/repeatable-installs/
- Schluntz, E., Zhang, B. (2024). *Building effective agents*. Billet technique, Anthropic, décembre 2024. https://www.anthropic.com/engineering/building-effective-agents
