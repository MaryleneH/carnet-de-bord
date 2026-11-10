---
title: "Séance 1 — Ce que le serveur accepte réellement"
subtitle: "Cours détaillé · laboratoire externe · assistant d'étude statistique sourcée"
date: 2026-11-10
toc: true
toc-depth: 2
---

10 novembre 2026 · trois heures de travail · serveur de modèles du SSP Cloud

> **En bref.** Ce document reprend la séance 1 étape par étape, comme un cours. Chaque chapitre dit ce que nous avons fait, puis pourquoi, comment cela fonctionne, ce que nous avons observé, et quels pièges éviter. Il se termine par des questions de contrôle et par deux ou trois références sérieuses. Les chiffres viennent de nos relevés et ont été recalculés pour ce document. Ceux tirés d'articles sont attribués à leurs auteurs.

## Comment lire ce cours

### Organisation d'un chapitre

Chaque chapitre correspond à une étape de la séance et suit le même plan :

- **Ce que nous avons fait** : l'étape, concrètement, avec le script concerné.
- **Pourquoi cette étape** : le problème qu'elle résout et ce qui se passerait sans elle.
- **Comment ça marche** : le mécanisme, avec le niveau technique nécessaire pour le comprendre vraiment.
- **Ce que nous avons observé** : nos résultats, et ce qu'ils permettent ou non de conclure.
- **Pièges et bonnes pratiques** : les erreurs classiques, dont celles que nous avons commises.
- **À retenir** : trois à cinq idées à garder en tête.
- **Pour vérifier que vous avez compris** : deux ou trois questions. Le corrigé est à l'annexe E.
- **Références** : deux ou trois lectures, avec ce que chacune apporte. L'annexe F les rassemble.

### Les encadrés

> **À retenir.** Les idées essentielles du chapitre.

> **Attention.** Un piège qui coûte cher s'il n'est pas vu à temps.

> **Définition.** Un terme employé pour la première fois. Le glossaire de l'annexe D les reprend tous.

### Les références

Elles sont de trois sortes : des articles évalués par les pairs (conférences et revues), des normes et des livres de référence. Quelques prépublications arXiv et deux billets techniques complètent l'ensemble ; ils sont signalés comme tels. Aucune référence n'a été citée de mémoire : chacune a été vérifiée auprès de l'éditeur, de l'archive ou du dépôt de code des auteurs.

### Le niveau attendu

Le cours suppose connues les bases de Python et de la statistique. Tout le vocabulaire des grands modèles de langage est défini au premier emploi.

## Le fil rouge

Le projet vise un assistant qui conduit une question jusqu'à une étude statistique publiable et sourcée. Une règle commande toute l'architecture : **le modèle ne calcule aucun chiffre et n'en cite aucun de mémoire**. Les chiffres viennent d'un registre de faits et sont vérifiés par un programme.

Avant de construire quoi que ce soit, la séance 1 avait un objectif modeste et indispensable : **savoir ce que le serveur de modèles accepte réellement**. Son critère de fin : chaque inconnue a une réponse, prouvée par une requête que l'on peut rejouer. Ce critère est atteint pour le serveur du SSP Cloud.

## Plan du cours

| N° | Chapitre | La question à laquelle il répond |
| --- | --- | --- |
| 1 | Pourquoi commencer par mesurer | Pourquoi ne pas construire l'agent tout de suite ? |
| 2 | Parler à un modèle par une API | Que se passe-t-il quand on envoie une requête ? |
| 3 | Le token, unité de compte | Avec quelle unité compte-t-on le texte, le temps et les limites ? |
| 4 | L'enveloppe d'appel | Comment rendre rejouable un appel qui ne l'est pas ? |
| 5 | Non-régression et refactorisation | Comment modifier le code sans changer les résultats ? |
| 6 | Sorties structurées | Peut-on obliger le modèle à répondre en JSON ? |
| 7 | Appels d'outils | Comment le modèle demande-t-il une donnée qu'il n'a pas ? |
| 8 | Température, graine et consignes de forme | D'où vient l'aléa, et peut-on le maîtriser ? |
| 9 | La fenêtre de contexte | Combien de texte le modèle lit-il, et l'utilise-t-il vraiment ? |
| 10 | Embeddings et similarité cosinus | Comment mesurer la proximité de sens entre deux textes ? |
| 11 | Débit et modèle de coût | Combien de temps coûte un appel ? |
| 12 | Questions de référence et chiffres arrondis | Avec quoi jugera-t-on l'assistant ? |
| 13 | Un essai ne prouve rien | Que vaut un taux mesuré sur peu d'essais ? |
| 14 | Git, commits et secrets | Comment tout tracer sans rien divulguer ? |
| 15 | Synthèse | Qu'est-ce que la séance change pour l'architecture ? |
| A à F | Annexes | Résultats bruts, incidents, clôture, glossaire, corrigé, bibliographie |

## Chapitre 1 — Pourquoi commencer par mesurer le serveur

### Ce que nous avons fait

Avant d'écrire une seule ligne de l'agent, nous avons passé la séance à interroger le serveur. Nous voulions savoir quelles options il accepte, jusqu'où il va et à quelle vitesse il répond. Trois scripts en sont sortis (`sonde.py`, `capacites.py`, `limites.py`). Ils s'appuient sur une enveloppe d'appel (`llm.py`) et produisent des relevés rejouables.

### Pourquoi cette étape

**L'architecture dépend de faits que nous ignorions.** Plusieurs choix de conception reposent directement sur une propriété du serveur :

- La taille de la fenêtre de contexte décide si l'on donne au modèle des documents entiers ou des extraits.
- Le support des sorties structurées décide si l'on analyse du texte libre ou si l'on reçoit du JSON garanti.
- Le support des appels d'outils décide si le modèle peut interroger lui-même le registre de faits.
- La vitesse décide combien d'appels successifs un agent peut se permettre.

Concevoir avant de savoir, c'est bâtir sur des hypothèses qui céderont au premier essai réel.

**Un modèle servi par un tiers est une dépendance qui change sans prévenir.** Sculley et ses coauteurs (2015) ont montré que le code d'apprentissage n'est qu'une petite partie d'un système d'apprentissage automatique. La dette technique s'accumule ailleurs : frontières qui s'érodent, dépendances aux données, configuration, changements du monde extérieur. Un modèle hébergé par d'autres en est le cas extrême : sa version, sa configuration ou sa charge peuvent changer sans que notre code bouge. La seule défense est un instrument de mesure que l'on peut relancer à tout moment, ce que sont nos scripts.

**Commencer simple, et ne compliquer que si la mesure le justifie.** Anthropic (2024) rapporte une observation tirée de nombreux projets : les réalisations qui réussissent le mieux n'utilisent pas de cadres complexes, mais des briques simples que l'on assemble. Souvent, bien optimiser un appel unique, avec de la recherche documentaire et quelques exemples, suffit. On n'ajoute de la complexité que lorsqu'elle améliore les résultats de façon démontrée. Ce « de façon démontrée » suppose de savoir mesurer.

### Comment ça marche : workflow, agent et modèle augmenté

> **Définition.** Un *workflow* est un système où le modèle et les outils sont orchestrés par des chemins de code fixés à l'avance. Un *agent* est un système où le modèle dirige lui-même son processus et l'usage des outils (Anthropic, 2024).

La brique de base des deux est ce qu'Anthropic appelle le **modèle augmenté** : un modèle de langage complété par de la recherche documentaire, des outils et une mémoire. La séance a mesuré exactement ces briques :

| Brique | Ce que nous avons mesuré | Chapitre |
| --- | --- | --- |
| Le modèle lui-même | Un appel de chat, son coût et sa vitesse | 2, 3, 11 |
| Le contrat avec le code | JSON simple et JSON contraint par un schéma | 6 |
| Les outils | La demande d'appel d'une fonction | 7 |
| La recherche documentaire | Les embeddings et la similarité cosinus | 10 |
| La mémoire de travail | La fenêtre de contexte | 9 |

Évaluer un modèle sur une seule dimension trompe. Le projet HELM (Liang et al., 2023) a posé un principe utile : évaluer selon plusieurs critères à la fois (exactitude, robustesse, efficacité, etc.) et dire explicitement ce que l'évaluation ne couvre pas. Nos mesures suivent ce principe à petite échelle : des **capacités** (le serveur fait-il X ?), des **limites** (jusqu'où ?) et une **efficacité** (à quelle vitesse ?).

### La règle qui commande tout : aucun chiffre ne vient du modèle

Un modèle de langage produit le texte le plus plausible compte tenu de ce qu'il a lu. Plausible ne veut pas dire vérifié. Un service statistique ne peut pas publier un chiffre faux. D'où la règle :

1. Le modèle ne calcule aucun chiffre et n'en cite aucun de mémoire.
2. Chaque chiffre publiable vient d'un **registre de faits** : un identifiant, une valeur, une source, une définition, une date.
3. Le modèle cite des identifiants ; un programme déterministe remplace les identifiants par les valeurs et vérifie que chaque chiffre du texte a une source.

La séance a fourni une illustration directe de cette règle, détaillée au chapitre 6.

### Ce que nous avons observé

Le critère de fin est atteint : chaque inconnue du serveur du SSP Cloud a une réponse appuyée sur une requête rejouable. Les chapitres 6 à 11 détaillent ces réponses ; l'annexe A les rassemble.

### Pièges et bonnes pratiques

- **Mesurer une fois et croire pour toujours.** Un serveur change. Les sondes doivent pouvoir être relancées, et elles le seront à chaque changement de modèle ou de serveur.
- **Transposer un résultat d'un serveur à l'autre.** Ce qui vaut pour le SSP Cloud ne vaut pas forcément pour Albert ou pour un autre serveur. Ce sont les scripts qui se transposent, pas les résultats.
- **Confondre le modèle et le serveur.** Beaucoup de refus viennent de la couche de service (options non prises en charge, limites de taille), pas du modèle lui-même.

> **À retenir.** On ne conçoit pas sur des hypothèses : on mesure d'abord. Un modèle hébergé par un tiers peut changer sans prévenir ; seule une mesure rejouable le détecte. On commence simple et on ne complique que sur preuve. Enfin, aucun chiffre publiable ne vient du modèle.

### Pour vérifier que vous avez compris

1. Citez deux décisions d'architecture qui dépendaient d'une mesure faite pendant la séance.
2. Quelle différence Anthropic fait-il entre un workflow et un agent ?
3. Pourquoi la dette technique « cachée » est-elle particulièrement forte quand le modèle est servi par un tiers ?

### Références

- Anthropic (2024). *Building effective agents*. Billet technique, 19 décembre 2024. https://www.anthropic.com/engineering/building-effective-agents — **Ce qu'on y apprend :** la distinction entre workflow et agent, la brique du modèle augmenté, les motifs simples (enchaînement, routage, parallélisation, orchestrateur, évaluateur) et le conseil de ne compliquer que sur preuve.
- Sculley, D., Holt, G., Golovin, D., Davydov, E., Phillips, T., Ebner, D., Chaudhary, V., Young, M., Crespo, J.-F., Dennison, D. (2015). *Hidden Technical Debt in Machine Learning Systems*. Advances in Neural Information Processing Systems 28 (NIPS 2015), p. 2503–2511. https://papers.nips.cc/paper/5656-hidden-technical-debt-in-machine-learning-systems — **Ce qu'on y apprend :** pourquoi un système d'apprentissage accumule une dette que le code ne montre pas, et quels facteurs de risque surveiller dès la conception.
- Liang, P., Bommasani, R., Lee, T., et al. (2023). *Holistic Evaluation of Language Models*. Transactions on Machine Learning Research. https://arxiv.org/abs/2211.09110 — **Ce qu'on y apprend :** une méthode d'évaluation par scénarios et par critères multiples, et l'exigence de dire ce que l'évaluation ne couvre pas.

## Chapitre 2 — Parler à un modèle par une API

### Ce que nous avons fait

Le script `sonde.py` a établi le premier contact avec le serveur du SSP Cloud. Il demande la liste des modèles disponibles, envoie un message et mesure le temps de réponse. L'adresse du serveur, la clé et le nom du modèle sont lus dans trois variables d'environnement (`LLM_URL`, `LLM_CLE`, `LLM_MODELE`), alimentées par un secret Onyxia. Aucune n'est écrite dans le code.

### Pourquoi cette étape

- **Vérifier la chaîne de bout en bout** avant de construire quoi que ce soit : réseau, authentification, nom du modèle. Une panne à ce niveau rend tout le reste incompréhensible.
- **Apprendre le contrat** : ce que l'on envoie, ce que l'on reçoit, et sous quelle forme.
- **Gagner la portabilité.** L'API dite « compatible OpenAI » est devenue un standard de fait : le SSP Cloud, Albert et la plupart des serveurs auto-hébergés la parlent. Le même code fonctionne partout ; seuls l'adresse, la clé et le nom du modèle changent.

### Comment ça marche

#### Une requête HTTP

Une requête comporte une **méthode** (`GET` pour lire, `POST` pour envoyer), une **adresse** formée de l'adresse de base et d'un chemin, des **en-têtes** et un **corps**. L'en-tête `Authorization: Bearer <clé>` porte la clé ; le corps est un document JSON. Pour le chat, le corps ressemble à ceci :

```json
{
  "model": "<nom du modèle>",
  "messages": [
    {"role": "system", "content": "Tu réponds en français, brièvement."},
    {"role": "user", "content": "Qu'est-ce qu'un indice de prix ?"}
  ],
  "temperature": 0,
  "max_tokens": 200
}
```

La réponse, en JSON elle aussi, contient le texte produit et la comptabilité des tokens :

```json
{
  "choices": [{"message": {"role": "assistant", "content": "<texte>"},
               "finish_reason": "stop"}],
  "usage": {"prompt_tokens": "<n lus>", "completion_tokens": "<n écrits>"}
}
```

Trois chemins nous servent : `GET /models` (liste des modèles), `POST /chat/completions` (génération) et `POST /embeddings` (vecteurs, chapitre 10). Le code de statut HTTP dit ce qui s'est passé avant même de lire le message : 200 pour un succès, 401 ou 403 pour une clé refusée, 404 pour une adresse qui n'existe pas, 400 ou 422 pour une requête refusée (souvent une option non prise en charge), 429 pour un quota dépassé, 5xx pour une erreur du serveur.

> **Définition.** Les *rôles* des messages : `system` fixe le cadre (consignes générales), `user` porte la demande, `assistant` porte les réponses précédentes du modèle, `tool` porte le résultat d'un outil (chapitre 7).

#### Ce que fait le serveur

1. **Mise en forme.** Le serveur assemble les messages en un seul texte, avec des marqueurs spéciaux propres au modèle : c'est le *gabarit de conversation* (chat template). Ce texte est découpé en tokens (chapitre 3).
2. **Calcul.** Le modèle, un Transformer (Vaswani et al., 2017), lit toute la séquence et calcule une distribution de probabilité sur le vocabulaire pour le token suivant.
3. **Choix.** Un token est choisi dans cette distribution (chapitre 8), ajouté à la séquence, et l'on recommence. C'est la génération **autorégressive** : chaque token dépend de tous ceux qui le précèdent.
4. **Arrêt.** La génération s'arrête sur un token de fin (`finish_reason: "stop"`) ou quand `max_tokens` est atteint (`finish_reason: "length"`, la réponse est alors tronquée).
5. **Retour.** Les tokens sont reconvertis en texte ; la réponse JSON est renvoyée avec la comptabilité `usage`.

Le moteur de service, par exemple vLLM (Kwon et al., 2023), traite en même temps les requêtes de nombreux utilisateurs sur le même processeur graphique. Il gère la mémoire dont le calcul a besoin. Nous y reviendrons au chapitre 11, car c'est ce qui explique la vitesse mesurée.

#### L'API n'a pas de mémoire

C'est le point le plus important du chapitre. **Le serveur ne garde rien d'un appel à l'autre.** Chaque requête doit contenir toute la conversation. Trois conséquences :

- La mémoire d'un agent est de la responsabilité du code client. Plus tard, le point de sauvegarde (checkpointer) de LangGraph jouera ce rôle.
- Le coût d'une conversation croît avec son historique : à chaque tour, le modèle relit tout depuis le début (chapitre 11).
- Ce qui est envoyé est exactement ce que l'on peut journaliser, ce qui rend le rejeu possible (chapitre 4).

#### La clé est un secret

La clé est un **jeton porteur** : quiconque la détient consomme le quota à votre nom. Elle vit dans un secret Onyxia, arrive au programme par une variable d'environnement et n'apparaît ni dans le code, ni dans le journal, ni dans un affichage. Notre enveloppe journalise le corps des requêtes, jamais leurs en-têtes. Meli, McNiece et Reaves (2019) ont mesuré l'ampleur du risque inverse. Sur GitHub, la fuite de secrets touche plus de cent mille dépôts, et des milliers de nouveaux secrets y fuient chaque jour. La cause principale : des clés écrites directement dans le code. Supprimer une clé après coup ne l'efface pas de l'historique.

### Ce que nous avons observé

- La liste des modèles et un appel de chat ont fonctionné sur le serveur du SSP Cloud. Le relevé est dans `mesures/2026-11-10_sspcloud.txt`.
- **Incident :** l'adresse de base seule renvoyait une erreur 404. Ce n'était pas une panne : une adresse de base n'est pas un point d'arrivée. Avec `/api/models` et `/api/chat/completions`, tout fonctionne. Leçon : lire le code de statut avant le message.
- L'accès à Albert a été demandé par son Playground, avec une connexion ProConnect ; il n'est pas encore confirmé.

### Pièges et bonnes pratiques

- **« Compatible » ne veut pas dire « identique ».** Un serveur peut ignorer une option sans prévenir, ou la refuser. On teste, on ne suppose pas (chapitres 6 à 8).
- **Le nom du modèle change d'un serveur à l'autre.** Il se lit dans une variable d'environnement, jamais en dur.
- **Une réponse peut avoir une forme inattendue** : `usage` absent, `content` vide quand le modèle appelle un outil. Le code lit avec prudence (`.get()`) et classe ces cas comme « erreur » au lieu de planter.
- **Un délai d'attente adapté.** Une requête longue peut prendre du temps ; l'enveloppe accepte jusqu'à 300 secondes.
- **Ne jamais afficher la clé**, même pour vérifier qu'elle est définie : on teste sa présence, pas sa valeur.

> **À retenir.** Une requête, c'est une méthode, une adresse, des en-têtes et un corps JSON. Le code de statut se lit en premier. Le serveur ne garde aucune mémoire : chaque appel renvoie toute la conversation, ce qui fait croître le coût avec l'historique. La clé ne doit apparaître nulle part, ni dans le code, ni dans le journal, ni à l'écran.

### Pour vérifier que vous avez compris

1. Pourquoi l'appel à l'adresse de base renvoyait-il une erreur 404, et que signifie ce code ?
2. Une conversation compte dix échanges. Combien de fois le premier message a-t-il été lu par le modèle ? Pourquoi ?
3. Que contient le journal de l'enveloppe, et que ne doit-il jamais contenir ?

### Références

- Vaswani, A., Shazeer, N., Parmar, N., Uszkoreit, J., Jones, L., Gomez, A. N., Kaiser, Ł., Polosukhin, I. (2017). *Attention Is All You Need*. Advances in Neural Information Processing Systems 30 (NIPS 2017), p. 5998–6008. https://papers.nips.cc/paper/7181-attention-is-all-you-need — **Ce qu'on y apprend :** l'architecture Transformer et le mécanisme d'attention, dont descendent les modèles de langage actuels.
- Kwon, W., Li, Z., Zhuang, S., Sheng, Y., Zheng, L., Yu, C. H., Gonzalez, J. E., Zhang, H., Stoica, I. (2023). *Efficient Memory Management for Large Language Model Serving with PagedAttention*. Proceedings of the 29th ACM Symposium on Operating Systems Principles (SOSP 2023). Code : https://github.com/vllm-project/vllm — **Ce qu'on y apprend :** comment un moteur de service fait tenir de nombreuses requêtes simultanées en mémoire, et pourquoi c'est la mémoire, plus que le calcul, qui limite le service.
- Meli, M., McNiece, M. R., Reaves, B. (2019). *How Bad Can It Git? Characterizing Secret Leakage in Public GitHub Repositories*. NDSS Symposium 2019. https://doi.org/10.14722/ndss.2019.23418 — **Ce qu'on y apprend :** l'ampleur des fuites de clés sur GitHub, leurs causes, et pourquoi la suppression après coup ne protège pas.

## Chapitre 3 — Le token, unité de compte

### Ce que nous avons fait

Aucun script n'était consacré aux tokens, mais ils étaient partout. Le serveur les compte dans le champ `usage` de chaque réponse, nous avons plafonné les sorties avec `max_tokens` et exprimé le débit en tokens par seconde. Surtout, le test de la fenêtre de contexte (chapitre 9) a relevé le nombre de tokens lus pour cinq tailles de texte, ce qui donne le rapport entre caractères et tokens pour du français.

### Pourquoi cette étape

Tout se compte en tokens : la taille maximale du contexte, la longueur des réponses, la vitesse, les quotas et le coût. Ni les caractères ni les mots ne sont la bonne unité. Pour prévoir un budget (combien de pages de publication peut-on donner au modèle ?), il faut savoir convertir.

### Comment ça marche

> **Définition.** Un *token* est un morceau de texte pris dans un vocabulaire fixe, de quelques dizaines de milliers à quelques centaines de milliers d'entrées. Un mot fréquent forme souvent un seul token ; un mot rare, un nom propre ou un nombre en forme plusieurs.

**Pourquoi pas des mots ?** Un vocabulaire de mots ne peut pas tout couvrir : noms propres, mots composés, fautes de frappe, néologismes. Sennrich, Haddow et Birch (2016) ont résolu ce problème en découpant les mots rares en sous-unités. Leur méthode, l'encodage par paires d'octets (BPE), part des caractères et fusionne de façon répétée la paire voisine la plus fréquente du corpus d'entraînement, jusqu'à atteindre la taille de vocabulaire voulue. Les mots fréquents finissent en un seul token ; les mots rares se décomposent en morceaux connus. Il n'existe plus de mot inconnu.

**Une autre famille de méthodes.** Kudo (2018) a proposé une segmentation fondée sur un modèle de langue « unigramme ». Elle part d'un grand vocabulaire et l'élague, en gardant les sous-unités qui expliquent le mieux le corpus. Elle admet plusieurs découpages possibles d'un même mot, chacun avec sa probabilité. Ces deux méthodes sont implémentées dans la bibliothèque SentencePiece, du même auteur, utilisée par de nombreux modèles.

**Toutes les langues ne coûtent pas pareil.** Un tokenizer est appris surtout sur le texte le plus abondant de son corpus, souvent l'anglais. Petrov et ses coauteurs (2023) ont montré que la même phrase, traduite, peut demander des nombres de tokens très différents selon la langue. Une langue moins bien servie paie davantage, en coût, en temps et en contexte disponible. Le français est plutôt bien servi, mais il coûte un peu plus que l'anglais.

**Les nombres sont découpés en morceaux de chiffres**, selon des règles propres à chaque tokenizer. Le modèle ne manipule donc pas « 522 250 » comme une quantité, mais comme une suite de symboles. C'est une raison de plus de ne jamais lui confier un calcul.

**Qui compte ?** Le serveur, avec le tokenizer exact du modèle. Le champ `usage` fait foi. Une estimation par les caractères sert seulement à prévoir.

### Ce que nous avons observé

| Taille du texte (caractères) | Tokens lus | Caractères par token |
| --- | --- | --- |
| 8 000 | 1 723 | 4,64 |
| 32 000 | 6 654 | 4,81 |
| 64 000 | 13 182 | 4,86 |
| 128 000 | 26 488 | 4,83 |
| 256 000 | 52 697 | 4,86 |

Trois lectures :

- Le nombre de tokens est **proportionnel** au nombre de caractères : doubler le texte double à peu près les tokens.
- Pour les grands textes, le rapport se stabilise vers **4,8 à 4,9 caractères par token**. L'approximation de 4 caractères par token, utilisée au départ pour dimensionner le test, était trop basse pour ce texte : c'est une règle empirique répandue pour l'anglais.
- Le rapport est plus faible pour le petit texte, car le compte inclut une partie fixe : le gabarit de conversation, la question et l'aiguille. Cette partie pèse davantage quand le texte est court.

> **Attention.** Notre texte de remplissage est artificiel : des mots courants, en minuscules, sans chiffres ni noms propres. Une vraie publication statistique, avec ses montants, ses sigles et ses tableaux, comptera probablement plus de tokens pour le même nombre de caractères. La mesure sera refaite sur le texte de l'EcoDef n° 273.

### Pièges et bonnes pratiques

- **Prévoir un budget en caractères** et le dépasser sans le savoir. On convertit avec un rapport mesuré sur son propre corpus, puis on vérifie avec le compte du serveur.
- **Un `max_tokens` trop bas** tronque la sortie. `finish_reason` vaut alors `"length"` ; un JSON tronqué devient invalide.
- **Comparer des nombres de tokens entre deux modèles** qui n'ont pas le même tokenizer n'a pas de sens : ce n'est pas la même unité.
- **Comparer des nombres sous forme de texte.** « 25 100 », « 25100 » et « 25,1 milliers » ne se découpent pas de la même façon. Le registre de faits comparera des valeurs numériques après lecture, jamais des chaînes de caractères.

> **À retenir.** Le token est l'unité de tout : contexte, sortie, débit, quota. Il vient d'un découpage en sous-unités appris sur un corpus, d'où des coûts différents selon les langues. Pour notre texte français, comptez environ 4,8 caractères par token, mais mesurez sur vos vrais documents. Le compte du serveur fait foi. Enfin, les nombres sont découpés en morceaux, ce qui rend les calculs du modèle peu fiables.

### Pour vérifier que vous avez compris

1. Un texte français de 120 000 caractères tient-il dans un budget de 24 000 tokens ? Faites le calcul avec nos mesures, puis dites pourquoi il faut quand même vérifier.
2. Pourquoi le rapport caractères par token est-il plus faible pour le texte de 8 000 caractères ?
3. Donnez une raison, liée à la tokenisation, de ne pas demander de calcul au modèle.

### Références

- Sennrich, R., Haddow, B., Birch, A. (2016). *Neural Machine Translation of Rare Words with Subword Units*. Proceedings of the 54th Annual Meeting of the ACL (vol. 1), p. 1715–1725. https://doi.org/10.18653/v1/P16-1162 — **Ce qu'on y apprend :** pourquoi découper en sous-unités, et l'algorithme BPE pas à pas.
- Kudo, T. (2018). *Subword Regularization: Improving Neural Network Translation Models with Multiple Subword Candidates*. Proceedings of the 56th Annual Meeting of the ACL (vol. 1), p. 66–75. https://doi.org/10.18653/v1/P18-1007 — **Ce qu'on y apprend :** la segmentation par modèle unigramme, et l'idée qu'un même texte admet plusieurs découpages.
- Petrov, A., La Malfa, E., Torr, P. H. S., Bibi, A. (2023). *Language Model Tokenizers Introduce Unfairness Between Languages*. Advances in Neural Information Processing Systems 36 (NeurIPS 2023). https://arxiv.org/abs/2305.15425 — **Ce qu'on y apprend :** la mesure des écarts de longueur de tokenisation entre langues, et leurs effets sur le coût et le contexte disponible.

## Chapitre 4 — L'enveloppe d'appel : empreinte, journal, rejeu

### Ce que nous avons fait

Tous les appels au modèle passent par un seul fichier, `llm.py`, que nous appelons l'**enveloppe**. Pour chaque appel, elle calcule une clé, l'**empreinte**. En mode normal, elle envoie la requête puis ajoute une ligne au journal `journal/appels.jsonl` : horodatage, clé, étiquette, adresse, chemin, statut, durée, requête et réponse. En mode **rejeu** (`LLM_MODE=rejeu`), elle relit la réponse dans le journal, sans réseau ni clé. Les refus du serveur sont journalisés eux aussi, puis signalés par une exception `AppelRefuse` qui porte la clé. Enfin, chaque résultat écrit dans `mesures/` garde sa clé dans un champ `preuve`.

```python
def _empreinte(url, etiquette, corps):
    texte = json.dumps({"url": url, "etiquette": etiquette, "corps": corps},
                       sort_keys=True, ensure_ascii=False)
    return hashlib.sha256(texte.encode()).hexdigest()[:16]
```

### Pourquoi cette étape

**Relancer un appel ne le reproduit pas.** Le hasard de l'échantillonnage en est une cause (chapitre 8), mais pas la seule. Atil et ses coauteurs ont soumis cinq modèles à huit tâches, dix fois chacune, avec des réglages censés être déterministes. Ils observent des écarts d'exactitude allant jusqu'à 15 % d'une exécution à l'autre. Aucun modèle ne donne une exactitude stable sur toutes les tâches, encore moins un texte identique. Une partie de l'explication tient au serveur : le résultat numérique d'une requête peut dépendre des autres requêtes traitées au même moment (Thinking Machines Lab, 2025). Conséquence : **pour reproduire une analyse, il faut enregistrer ce que le modèle a réellement répondu.**

**Chaque résultat doit garder la trace de sa production.** Sandve et ses coauteurs (2013) ont résumé la recherche reproductible en dix règles. Quatre s'appliquent directement ici :

- règle 1 : pour chaque résultat, garder la trace de la façon dont il a été produit ;
- règle 5 : enregistrer tous les résultats intermédiaires ;
- règle 6 : noter les graines des analyses qui comportent du hasard ;
- règle 9 : relier chaque affirmation du texte au résultat qui la fonde.

Le champ `preuve` applique la règle 9 : chaque ligne de mesure pointe vers l'appel exact qui l'a produite.

**Tester sans réseau, sans clé et sans coût.** Le rejeu permet de relancer tous les scripts en quelques secondes. Il permet aussi de les faire tourner dans l'intégration continue de GitHub, qui n'a pas, et ne doit pas avoir, accès à la clé.

**Pouvoir rendre des comptes.** Pour une publication, on doit pouvoir montrer exactement ce que le modèle a reçu et ce qu'il a répondu.

### Comment ça marche

#### Une empreinte comme clé

Une **fonction de hachage** transforme n'importe quel texte en une empreinte de taille fixe. Elle est déterministe : le même texte donne toujours la même empreinte. Le moindre changement du texte change toute l'empreinte. Et deux textes différents ne donnent, en pratique, jamais la même. SHA-256, normalisé par le NIST (FIPS 180-4), produit 256 bits.

Nous gardons les 16 premiers caractères hexadécimaux, soit 64 bits. Le risque de collision se calcule avec le « paradoxe des anniversaires » : parmi *n* clés, la probabilité qu'au moins deux coïncident vaut environ *n*² / 2⁶⁵. Pour un million d'appels, cela fait 2,7 × 10⁻⁸ : négligeable.

> **Définition.** Un JSON *canonique* est une écriture unique d'un même contenu. Avec `sort_keys=True`, deux dictionnaires égaux donnent le même texte, quel que soit l'ordre dans lequel leurs clés ont été créées, donc la même empreinte.

La clé dépend de trois éléments : l'adresse du serveur, l'étiquette de l'appel et le corps de la requête (modèle, messages, paramètres). La clé d'API n'y entre pas, heureusement. Le chemin non plus : c'est sans risque, car un corps de chat et un corps d'embeddings ne se ressemblent pas. L'**étiquette** sert à distinguer deux requêtes identiques que l'on veut garder toutes les deux. C'est le cas de `graine-1` et `graine-2`, qui envoient exactement le même corps.

#### Un journal en ajout seul

Le journal est au format JSONL : un objet JSON par ligne, et l'on ne fait qu'ajouter des lignes, jamais en réécrire. Ce choix a quatre avantages. Une interruption ne peut abîmer que la dernière ligne. Le fichier se lit avec les outils les plus simples (`grep`, `jq`). Git en montre les ajouts ligne à ligne. Enfin, l'historique ne se réécrit pas.

#### Le rejeu

En mode rejeu, la fonction `_entree(cle)` parcourt le journal depuis la fin et rend la dernière entrée portant cette clé. Si la clé est absente, le programme s'arrête avec une erreur explicite (`LookupError`), au lieu d'appeler le réseau en silence. Les scripts reçoivent exactement la réponse d'origine, donc écrivent exactement les mêmes relevés.

#### Du chiffre à sa preuve

Un résultat de `mesures/capacites.json` ressemble à ceci :

```json
{"capacite": "json_schema", "statut": "respecté",
 "detail": "objet : {'ville': 'Lyon', 'habitants': 522250}", "preuve": "<clé>"}
```

La commande `grep <clé> journal/appels.jsonl` retrouve la requête et la réponse complètes.

### Ce que nous avons observé

- L'enveloppe a été commitée (`a124409`), puis le test des capacités et son relevé (`179d17d`).
- Après correction d'une erreur de méthode (chapitre 5), le rejeu de `capacites.py` redonne exactement le même relevé.
- Le journal contient tous les appels de la séance, refus compris.

### Pièges et bonnes pratiques

- **Le journal est public**, puisque le dépôt l'est. Il ne doit contenir que des données publiques, jamais un secret.
- **Changer la formule de l'empreinte** rend tous les journaux passés impossibles à rejouer (chapitre 5).
- **Le rejeu prouve que le code est déterministe** à réponses données. Il ne prouve rien sur la stabilité du modèle : c'est le banc de la séance 2 qui la mesurera.
- **Horodater en temps universel** (`timezone.utc`) pour éviter toute ambiguïté.

> **À retenir.** Relancer un appel ne le reproduit pas : on enregistre donc ce que le modèle a répondu. L'empreinte (SHA-256 d'un JSON canonique) donne à chaque appel une clé stable. Le journal en ajout seul garde tout, refus compris. Le rejeu rend les scripts testables sans réseau ni clé. Le champ `preuve` relie chaque résultat à son appel.

### Pour vérifier que vous avez compris

1. Pourquoi l'étiquette fait-elle partie de la clé ? Que se passerait-il au rejeu, sans elle, pour `graine-1` et `graine-2` ?
2. Pourquoi trier les clés du JSON avant de calculer l'empreinte ?
3. Le rejeu prouve-t-il que le modèle est stable ? Que prouve-t-il exactement ?

### Références

- Sandve, G. K., Nekrutenko, A., Taylor, J., Hovig, E. (2013). *Ten Simple Rules for Reproducible Computational Research*. PLoS Computational Biology, 9(10), e1003285. https://doi.org/10.1371/journal.pcbi.1003285 — **Ce qu'on y apprend :** dix règles concrètes de reproductibilité, dont la traçabilité de chaque résultat et l'archivage des résultats intermédiaires.
- Atil, B., Aykent, S., Chittams, A., Fu, L., Passonneau, R. J., Radcliffe, E., Rajagopal, G. R., Sloan, A., Tudrej, T., Ture, F., Wu, Z., Xu, L., Baldwin, B. (2025). *Non-Determinism of "Deterministic" LLM Settings*. Prépublication arXiv:2408.04667, version 5. https://arxiv.org/abs/2408.04667 — **Ce qu'on y apprend :** une mesure systématique de l'instabilité des modèles à réglages censés être déterministes, et des indicateurs pour la quantifier.
- National Institute of Standards and Technology (2015). *FIPS PUB 180-4: Secure Hash Standard (SHS)*. https://doi.org/10.6028/NIST.FIPS.180-4 — **Ce qu'on y apprend :** la définition normative de SHA-256 et des autres fonctions de hachage de la famille SHA-2.
- Pour aller plus loin : Thinking Machines Lab (2025). *Defeating Nondeterminism in LLM Inference*. Billet technique. https://thinkingmachines.ai/blog/defeating-nondeterminism-in-llm-inference/ — **Ce qu'on y apprend :** pourquoi le résultat d'une requête dépend des autres requêtes du lot, et comment des noyaux de calcul invariants par lot rendent l'inférence déterministe.

## Chapitre 5 — Changer le code sans changer les résultats

### Ce que nous avons fait

La première version de `llm.py`, commitée dans `a124409`, ne savait faire que du chat. Pour `limites.py`, il fallait aussi des embeddings et la durée de chaque appel. Dans la nouvelle version, l'envoi et la journalisation sont regroupés dans une seule fonction, `_appeler(chemin, corps, etiquette)`. Les fonctions `appeler_llm` et `appeler_embeddings` ne font plus que préparer le corps de la requête, et `duree(cle)` relit la durée dans le journal. Une contrainte a guidé ce travail : **la formule de l'empreinte ne devait pas changer**, pour que les anciens appels gardent leur clé et restent rejouables. Le rejeu l'a vérifié :

```bash
git add mesures/capacites.json journal/appels.jsonl
git commit -m "feat: test des capacités du serveur, relevé rejouable"
LLM_MODE=rejeu python capacites.py
git diff --exit-code mesures/ && echo "rejeu identique"
```

### Pourquoi cette étape

**Toute modification risque de casser ce qui marchait.** C'est ce qu'on appelle une **régression**. Dans notre cas, la pire régression serait silencieuse : une formule d'empreinte modifiée rendrait toutes les preuves passées invérifiables, sans qu'aucun message d'erreur ne l'annonce au moment du changement.

**Il fallait pourtant restructurer.** Ajouter les embeddings par copier-coller aurait dupliqué la logique de journalisation, et deux copies finissent toujours par diverger. Fowler (2018) définit la **refactorisation** comme une transformation de la structure interne du code qui ne change pas son comportement observable. Elle se fait par petites étapes, chacune protégée par des tests.

**Nous n'avions pas de tests unitaires, mais nous avions mieux.** Feathers (2004) appelle « code hérité » tout code sans tests. Il recommande, avant de le modifier, d'écrire des **tests de caractérisation**, qui figent le comportement actuel, juste ou non, pour détecter tout changement involontaire. Nos relevés commités et le journal jouent exactement ce rôle : ils caractérisent le comportement du programme. Le rejeu le refait tourner, et la moindre différence se voit.

**Une discipline étudiée.** Yoo et Harman (2012) présentent les tests de non-régression comme l'activité qui donne confiance qu'un changement n'abîme pas le comportement existant. Leur synthèse traite aussi de la question suivante : quand la batterie de tests grossit, quels tests relancer, et dans quel ordre ?

### Comment ça marche

#### L'oracle est le fichier commité

Le test compare le relevé régénéré au relevé commité. `git diff --exit-code` renvoie le code de sortie 0 si rien n'a changé et 1 sinon. Un script ou une intégration continue peut donc s'en servir pour décider seul du succès ou de l'échec.

#### Pourquoi ce test est fort

Le rejeu traverse tout le programme, sauf le réseau : construction du corps, calcul de l'empreinte, lecture du journal, analyse de la réponse, classement en « respecté » ou « non respecté », écriture du JSON. Deux types d'erreur sont ainsi détectés :

- un changement de la clé, qui provoque un `LookupError` ;
- un changement de l'analyse ou du classement, qui produit une différence dans le relevé.

#### Le journal est un contrat avec le passé

Le format du journal et la formule de la clé forment un contrat : tout ce qui a été journalisé doit rester rejouable. S'il faut un jour changer la formule, on la versionne (par exemple un champ `version_cle` dans chaque ligne), ou l'on écrit une migration qui recalcule les clés. Dans les deux cas, on vérifie par un rejeu complet.

#### Bientôt dans l'intégration continue

Une tâche GitHub Actions pourra rejouer tous les scripts en mode `rejeu` puis lancer `git diff --exit-code`. Le test passe au rouge dès qu'un comportement change, sans aucune clé d'API dans la CI.

### Ce que nous avons observé

- **Une première vérification qui ne prouvait rien.** Le relevé n'était pas encore commité, et `git diff` ne compare que les fichiers suivis par Git. L'absence de différence était donc trompeuse. Correction : commiter d'abord, rejouer ensuite, comparer enfin.
- **Une version en avance sur le dépôt.** La version commitée de `llm.py` était la première (68 lignes), pas celle avec les embeddings et les durées. Elle figure dans la liste de clôture (annexe C).
- **Après correction**, le rejeu de `capacites.py` donne un relevé identique : la restructuration n'a rien changé au comportement existant.

### Pièges et bonnes pratiques

- **Comparer à un fichier non suivi par Git** : c'est notre incident.
- **Le rejeu ne couvre que les chemins déjà enregistrés.** Les embeddings, nouveaux, ont demandé un premier passage réel. Leur relevé devient ensuite la nouvelle référence.
- **Les champs instables font échouer le test sans raison.** Un horodatage dans un relevé changerait à chaque exécution. Nos relevés n'en contiennent pas, et les durées y sont relues dans le journal : le résultat est stable en rejeu. Le principe : séparer les métadonnées variables (le journal) des résultats déterministes (les relevés).
- **Une intention par commit.** Notre nouvelle version mêlait une refactorisation (regrouper l'envoi) et une fonctionnalité (les embeddings). Mieux vaut deux commits : `refactor: …`, dont le rejeu doit être identique, puis `feat: …`. En cas de différence, on sait immédiatement laquelle des deux en est la cause.

> **À retenir.** Une refactorisation change la structure sans changer le comportement, et c'est un test qui le prouve. Faute de tests unitaires, les relevés commités servent de tests de caractérisation, et le rejeu les vérifie. Il faut commiter avant de comparer. Le format du journal et la formule de la clé sont un contrat avec le passé.

### Pour vérifier que vous avez compris

1. Pourquoi `git diff` ne montrait-il rien lors de la première vérification ?
2. Que se passerait-il au rejeu si l'on ajoutait le chemin à la formule de l'empreinte ?
3. Pourquoi vaut-il mieux séparer en deux commits la refactorisation et l'ajout des embeddings ?

### Références

- Yoo, S., Harman, M. (2012). *Regression testing minimization, selection and prioritization: a survey*. Software Testing, Verification and Reliability, 22(2), p. 67–120. https://doi.org/10.1002/stvr.430 — **Ce qu'on y apprend :** les définitions des tests de non-régression, et comment réduire, sélectionner et ordonner une batterie de tests qui grossit.
- Feathers, M. C. (2004). *Working Effectively with Legacy Code*. Prentice Hall. ISBN 978-0-13-117705-5 — **Ce qu'on y apprend :** comment modifier sans risque un code sans tests, en commençant par figer son comportement.
- Fowler, M., avec Beck, K. (2018). *Refactoring: Improving the Design of Existing Code*, 2e édition. Addison-Wesley. ISBN 978-0-13-475759-9 — **Ce qu'on y apprend :** la définition de la refactorisation, ses principes et un catalogue de transformations sûres, chacune avec sa motivation et sa mécanique.

## Chapitre 6 — Sorties structurées : JSON et schéma

### Ce que nous avons fait

`capacites.py` contient deux sondes sur les sorties structurées.

- **JSON simple.** La requête porte `response_format={"type": "json_object"}` et demande un objet `{"ville": ..., "pays": ...}` pour Lyon. Le test réussit si la réponse se lit avec `json.loads`.
- **JSON avec schéma.** La requête porte un schéma JSON strict : `ville` est une chaîne, `habitants` un entier, les deux sont obligatoires et aucun autre champ n'est admis (`additionalProperties: false`). Le test réussit si la réponse se lit, a exactement ces deux clés, et si `habitants` est un entier.

Chaque sonde classe le résultat en quatre statuts : **refusé** (le serveur renvoie une erreur HTTP), **non respecté**, **respecté**, **erreur** (réponse de forme inattendue).

### Pourquoi cette étape

Les étapes d'un agent échangent des données avec le code : un plan, une liste d'identifiants de faits, une classification. Du texte libre oblige à des analyses fragiles (expressions régulières) et laisse passer des erreurs silencieuses. Une **sortie structurée** est un contrat que le code peut valider. Si le serveur sait **imposer** ce contrat, toute une classe de pannes disparaît.

### Comment ça marche

#### Demander ou imposer

Il y a deux façons d'obtenir du JSON :

1. **Le demander** dans la consigne. Le modèle obéit souvent, pas toujours.
2. **L'imposer** par le *décodage contraint*. À chaque pas de génération, le serveur met à zéro la probabilité de tout token qui rendrait la sortie non conforme à la grammaire (JSON, ou le schéma). Il renormalise les probabilités restantes, puis choisit parmi les tokens autorisés. La sortie est alors valide par construction, sauf si elle est tronquée par `max_tokens`.

> **Formule.** Si *p(t)* est la probabilité du token *t* et *A* l'ensemble des tokens autorisés à ce pas, le décodage contraint tire selon *p'(t) = p(t) / Σ p(u)* pour *t* dans *A*, la somme portant sur les *u* de *A*, et *p'(t) = 0* hors de *A*.

Le défi est de calculer *A* vite, à chaque token, sur un vocabulaire de plus de cent mille entrées. Willard et Louf (2023) ramènent le problème à un **automate fini** : une expression régulière ou une grammaire devient un automate, et l'on précalcule, pour chaque état de l'automate, la liste des tokens qui peuvent le faire avancer. Pendant la génération, trouver les tokens autorisés devient une simple lecture dans un index. Geng et ses coauteurs (2023) montrent qu'une grammaire formelle peut décrire les sorties de nombreuses tâches structurées : extraction d'information, désambiguïsation, analyse syntaxique. Avec le décodage contraint, un modèle non réentraîné s'y améliore nettement.

#### « Respecté » n'est pas « imposé »

Notre test ne permet pas de savoir si le serveur a imposé le format. La consigne demandait déjà du JSON, et un bon modèle s'y conforme de lui-même. Pour prouver que la contrainte est imposée, il faut une expérience où **la consigne contredit le format** : demander une réponse en prose tout en exigeant le schéma. Si la sortie reste conforme, c'est le serveur qui l'impose. Ce test est au programme de la séance 2.

#### Le schéma garantit la forme, pas le fond

Notre sortie était `{"ville": "Lyon", "habitants": 522250}` : parfaitement valide. Mais d'où vient 522 250 ? De la mémoire du modèle, c'est-à-dire de ses paramètres. Que ce nombre soit juste ou faux, **il est inutilisable** dans une publication. Il n'a pas de source. Il n'a pas de millésime. Il n'a pas de définition : population municipale ou totale ? Commune ou métropole ? Le type `integer` a garanti le type, pas la vérité.

C'est exactement la raison d'être de la règle des chiffres. Dans l'architecture, une sortie structurée du modèle contiendra des **identifiants de faits** (par exemple `F-0012`), jamais de valeurs. Les valeurs viendront du registre.

#### Le format peut avoir un coût

Tam et ses coauteurs (2024) ont comparé des tâches résolues avec ou sans contrainte de format. Sur les tâches de raisonnement, imposer un format fait baisser les performances, et une contrainte plus stricte les fait en général baisser davantage. Les tâches de classification en souffrent moins. Deux parades sont à tester au banc :

- laisser le modèle raisonner librement, puis structurer dans un second appel ;
- placer un champ de justification libre **avant** le champ de décision dans le schéma. La génération se fait de gauche à droite, donc l'ordre des champs compte.

### Ce que nous avons observé

| Sonde | Statut | Détail |
| --- | --- | --- |
| JSON simple | respecté | JSON valide |
| JSON avec schéma | respecté | `{"ville": "Lyon", "habitants": 522250}` |

Un seul essai par sonde : c'est un indice, pas une preuve. Le chapitre 13 montre ce qu'un essai unique permet de conclure, c'est-à-dire très peu.

### Pièges et bonnes pratiques

- **La troncature.** Une sortie coupée par `max_tokens` est invalide, même sous contrainte. On vérifie `finish_reason` avant de lire le JSON.
- **Les mots-clés de schéma non pris en charge** peuvent être ignorés sans avertissement, selon le moteur. On garde des schémas simples (`type`, `required`, `enum`, `additionalProperties`) et l'on teste chaque mot-clé utilisé.
- **Valider quand même à la réception**, par exemple avec la bibliothèque `jsonschema`. C'est une défense en profondeur.
- **Ne jamais obtenir un nombre ou un fait par un schéma.** On demande des identifiants ou des valeurs prises dans une liste fermée (`enum`).
- **Nommer les champs clairement** (`identifiant_fait` plutôt que `x`) : le modèle lit aussi le schéma.

> **À retenir.** Le décodage contraint garantit la forme en interdisant, token par token, ce qui violerait la grammaire. Une sortie conforme ne prouve pas que la contrainte est imposée ; seule une expérience où la consigne contredit le format le prouve. Le schéma garantit la forme, jamais la vérité : un nombre produit par le modèle reste sans source. Enfin, un format strict peut coûter en qualité de raisonnement.

### Pour vérifier que vous avez compris

1. Expliquez avec vos mots comment le décodage contraint garantit un JSON valide.
2. Proposez une expérience qui distingue « respecté » de « imposé ».
3. Le nombre 522 250 est peut-être exact. Pourquoi reste-t-il inutilisable dans une publication ?

### Références

- Willard, B. T., Louf, R. (2023). *Efficient Guided Generation for Large Language Models*. Prépublication arXiv:2307.09702. https://arxiv.org/abs/2307.09702 — **Ce qu'on y apprend :** comment transformer une expression régulière ou une grammaire en automate, et indexer le vocabulaire pour contraindre la génération à faible coût.
- Geng, S., Josifoski, M., Peyrard, M., West, R. (2023). *Grammar-Constrained Decoding for Structured NLP Tasks without Finetuning*. Proceedings of EMNLP 2023. https://aclanthology.org/2023.emnlp-main.674 — **Ce qu'on y apprend :** que le décodage contraint par grammaire peut servir de cadre commun à de nombreuses tâches structurées, sans réentraîner le modèle.
- Tam, Z. R., et al. (2024). *Let Me Speak Freely? A Study on the Impact of Format Restrictions on Performance of Large Language Models*. EMNLP 2024 (Industry Track). https://arxiv.org/abs/2408.02442 — **Ce qu'on y apprend :** l'effet mesuré des contraintes de format sur la qualité des réponses, et les situations où il est le plus fort.

## Chapitre 7 — Appels d'outils

### Ce que nous avons fait

Nous avons déclaré un outil fictif, `population`, avec une description (« Renvoie la population d'une ville ») et un paramètre obligatoire, `ville`. Puis nous avons demandé : « Quelle est la population de Lyon ? Utilise l'outil. », avec `tool_choice="auto"`. Le test réussit si la réponse contient une demande d'appel (`tool_calls`) dont les arguments se lisent en JSON.

### Pourquoi cette étape

Un modèle n'a ni données récentes, ni nos données, ni calcul exact. Les outils lui donnent accès à tout cela. Pour notre projet, l'outil est le moyen par lequel le modèle **demande** un fait au registre, ou un calcul à un programme déterministe, au lieu de l'inventer. C'est ce mécanisme qui rend la règle des chiffres applicable.

### Comment ça marche

#### Le cycle d'un appel d'outil

1. Le client **déclare** les outils : un nom, une description, et un schéma JSON des paramètres.
2. Le serveur insère ces déclarations dans le gabarit de conversation. Le modèle a été entraîné à produire, quand c'est utile, un message structuré qui demande un appel.
3. Le serveur reconnaît ce message et le renvoie dans `tool_calls` : le nom de la fonction et ses arguments, sous forme de texte JSON.
4. **Le code client exécute la fonction.** Le modèle n'exécute rien ; il demande.
5. Le client renvoie le résultat dans un message de rôle `tool`, et le modèle rédige sa réponse.

```json
{"role": "assistant", "content": null,
 "tool_calls": [{"id": "<id>", "type": "function",
                 "function": {"name": "population",
                              "arguments": "{\"ville\": \"Lyon\"}"}}]}
```

Les arguments arrivent sous forme de **texte**, qu'il faut lire avec `json.loads`. C'est là que se logent les erreurs de format.

#### D'où vient cette capacité

Schick et ses coauteurs (2023) partent d'un paradoxe : les modèles de langage résolvent des tâches difficiles mais échouent sur des fonctions élémentaires, comme l'arithmétique ou la recherche d'un fait. Avec Toolformer, ils montrent qu'un modèle peut apprendre, presque sans annotation humaine, quelles interfaces appeler, quand, avec quels arguments, et comment intégrer le résultat. Leurs outils : une calculatrice, un système de questions-réponses, un moteur de recherche, un traducteur et un calendrier.

Yao et ses coauteurs (2023), avec ReAct, font alterner un raisonnement écrit et des actions. Chaque observation renvoyée par l'environnement nourrit le raisonnement suivant. Ce va-et-vient limite les inventions et la propagation des erreurs. C'est le cœur d'un agent : penser, agir, observer, recommencer. Anthropic (2024) le dit simplement : un agent est, la plupart du temps, un modèle qui utilise des outils en boucle à partir de ce que l'environnement lui renvoie. D'où son conseil d'investir dans la définition des outils autant que dans la consigne : se mettre à la place du modèle et se demander si l'usage de l'outil est évident à la lecture de sa description.

#### Contraint ou libre ?

Avec `tool_choice="auto"`, le modèle décide s'il appelle un outil, et il rédige les arguments librement. La documentation de vLLM indique que ce mode n'est pas guidé par le décodage contraint : les arguments peuvent donc être mal formés. Notre code les lit et classe le résultat au lieu de supposer qu'ils sont valides. Forcer un outil précis peut, selon le serveur, activer le décodage contraint ; ce sera à tester en séance 2.

### Ce que nous avons observé

Résultat : **respecté**, `population({'ville': 'Lyon'})`. Le modèle a choisi l'outil et produit des arguments valides.

> **Attention.** La consigne disait « Utilise l'outil ». Nous avons donc mesuré l'**obéissance** à une instruction explicite, pas le **jugement** du modèle sur le moment où un outil est nécessaire. Or c'est le jugement qui compte pour le projet. Au chapitre 6, sans outil, le même modèle a répondu de mémoire. La vraie question est : sans instruction explicite, le modèle interroge-t-il le registre plutôt que sa mémoire ? Le banc mesurera ce taux.

### Pièges et bonnes pratiques

- **Le modèle répond de mémoire au lieu d'appeler l'outil.** On mesure le taux d'appel. On rédige descriptions et consignes pour que l'outil soit la voie évidente. Au besoin, on force l'appel.
- **Les arguments sont des entrées non fiables.** On les valide avec le schéma et avec une liste blanche (la ville existe-t-elle dans le registre ?). On ne les transmet jamais tels quels à un terminal ou à une requête SQL.
- **Le résultat d'un outil est du texte non fiable**, surtout s'il vient du web. Il peut contenir des instructions déguisées : c'est l'*injection de consigne*. Il se traite comme une donnée, jamais comme un ordre.
- **Plusieurs appels dans une même réponse, ou des boucles sans fin.** On prévoit une condition d'arrêt, par exemple un nombre maximal d'itérations, comme le recommande Anthropic.
- **Une mauvaise description donne un mauvais usage.** La documentation d'un outil fait partie de la consigne.

> **À retenir.** Le modèle ne fait que **demander** un appel ; c'est notre code qui exécute. Les outils sont le moyen d'obtenir des faits et des calculs sans les inventer : c'est la clé de la règle des chiffres. Un agent est un modèle qui utilise des outils en boucle. En mode `auto`, les arguments ne sont pas garantis : on les valide. Notre test a mesuré l'obéissance, pas le jugement.

### Pour vérifier que vous avez compris

1. Qui exécute la fonction `population` : le modèle, le serveur ou notre code ? Que renvoie le modèle, exactement ?
2. Pourquoi notre test mesure-t-il l'obéissance plutôt que le jugement ? Comment le modifier ?
3. Pourquoi faut-il valider les arguments d'un appel d'outil avant de l'exécuter ?

### Références

- Schick, T., Dwivedi-Yu, J., Dessì, R., Raileanu, R., Lomeli, M., Hambro, E., Zettlemoyer, L., Cancedda, N., Scialom, T. (2023). *Toolformer: Language Models Can Teach Themselves to Use Tools*. Advances in Neural Information Processing Systems 36 (NeurIPS 2023). https://arxiv.org/abs/2302.04761 — **Ce qu'on y apprend :** pourquoi un modèle a besoin d'outils pour l'arithmétique et les faits, et comment il peut apprendre à les appeler.
- Yao, S., Zhao, J., Yu, D., Du, N., Shafran, I., Narasimhan, K., Cao, Y. (2023). *ReAct: Synergizing Reasoning and Acting in Language Models*. International Conference on Learning Representations (ICLR 2023). https://arxiv.org/abs/2210.03629 — **Ce qu'on y apprend :** la boucle raisonnement, action, observation, qui fonde les agents actuels.
- Anthropic (2024). *Building effective agents*, en particulier l'annexe 2 sur la conception des outils. https://www.anthropic.com/engineering/building-effective-agents — **Ce qu'on y apprend :** comment rédiger des définitions d'outils que le modèle utilise correctement.

## Chapitre 8 — Température, graine et consignes de forme

### Ce que nous avons fait

La sonde `graine` envoie deux fois la même question, « Invente un prénom original. Un seul mot. ». Les deux appels portent les étiquettes `graine-1` et `graine-2`, avec une graine fixée (`seed=42`), une température de 1 et au plus 10 tokens. Si les deux réponses sont identiques, la sonde conclut « respecté », avec la mention « indice, à confirmer au banc ». Les deux réponses ont été `**Luvian**`.

### Pourquoi cette étape

Pour un assistant qui prépare des publications, trois questions se posent :

- Peut-on rendre le comportement **déterministe** pour les tâches d'extraction et de structuration ?
- Que reste-t-il d'aléa même dans ce cas (chapitre 4) ?
- Le serveur respecte-t-il la **graine** ? Ce serait utile pour un tirage reproductible, par exemple pour produire plusieurs plans d'étude et les comparer.

### Comment ça marche

#### De la distribution au token

À chaque pas, le modèle produit un score *zᵢ* (un *logit*) pour chaque token *i* du vocabulaire. Ces scores deviennent des probabilités par la fonction softmax, réglée par la **température** *T* :

> **Formule.** *pᵢ = exp(zᵢ / T) / Σⱼ exp(zⱼ / T)*

- Quand *T* tend vers 0, toute la probabilité se concentre sur le token le plus probable : c'est le **décodage glouton**.
- À *T* = 1, on tire selon la distribution du modèle lui-même.
- Au-delà de 1, la distribution s'aplatit et les choix deviennent plus surprenants.

Un générateur pseudo-aléatoire tire ensuite un token selon ces probabilités. On peut d'abord tronquer la distribution : garder les *k* tokens les plus probables (*top-k*), ou le plus petit ensemble dont la probabilité cumulée atteint *p* (*top-p*, ou échantillonnage par noyau). Holtzman et ses coauteurs (2020) ont montré que maximiser la probabilité, comme le fait le décodage glouton, produit en génération ouverte des textes ternes et répétitifs. À l'inverse, tirer dans toute la distribution produit de l'incohérence, à cause de la longue « queue » de tokens improbables et peu fiables. L'échantillonnage par noyau coupe cette queue.

Pour notre usage, la règle est simple. **Température 0** pour extraire, classer et structurer. Température positive seulement quand on veut de la diversité, par exemple plusieurs ébauches de plan à comparer.

#### La graine

Un générateur pseudo-aléatoire produit une suite entièrement déterminée par sa **graine**. Même graine et même distribution donnent donc les mêmes tirages, et le même texte. Mais la condition « même distribution » peut ne pas tenir sur un serveur partagé : les calculs numériques peuvent varier d'un appel à l'autre (chapitre 4). Une graine ne garantit donc pas, à elle seule, des sorties identiques.

#### Une expérience sans témoin ne prouve rien

Nos deux réponses identiques prouvent-elles que le serveur respecte la graine ? Non. Si, pour cette question, le modèle préfère très nettement un prénom, deux tirages sans graine pourraient aussi coïncider. Une expérience concluante a besoin d'une **condition témoin** :

- même consigne et même graine, répétées : les sorties doivent être toujours identiques ;
- même consigne et graines différentes (ou pas de graine), répétées : les sorties doivent souvent différer.

La graine n'est respectée que si les deux conditions sont réunies. C'est le plan de la séance 2.

#### La forme parasite

Nous avions demandé « un seul mot » ; nous avons reçu le mot entouré des marques de gras du Markdown. L'habitude du modèle, entraîné pour des interfaces de discussion qui affichent le Markdown, l'a emporté sur la consigne. Zhou et ses coauteurs (2023) ont fait de ce type d'écart un objet de mesure, avec IFEval. Ils construisent des **consignes vérifiables** : des consignes dont le respect se contrôle par un programme (longueur, mots imposés, format, etc.). On obtient ainsi un taux de respect objectif, sans juge humain ni modèle juge.

Pour nous, deux conséquences :

- La séance 2 construira des consignes vérifiables en français : « un seul mot », « sans mise en forme Markdown », « nombre écrit en chiffres », « pas de phrase d'introduction ».
- Dans l'architecture, aucune forme ne sera garantie par la seule consigne. Chaque sortie sera nettoyée (retrait du Markdown) ou refusée, puis redemandée. Quand la forme compte vraiment, on utilise le décodage contraint (chapitre 6).

### Ce que nous avons observé

- Deux fois `**Luvian**` avec la même graine : un indice, pas une preuve, faute de témoin.
- Une mise en forme non demandée, d'où une règle d'architecture : nettoyer ou refuser.

### Pièges et bonnes pratiques

- **Croire que la température 0 garantit le déterminisme.** Elle supprime l'aléa du tirage, pas celui du calcul.
- **Croire qu'une graine garantit la reproductibilité.** Un serveur peut l'ignorer sans le dire, et les calculs peuvent varier.
- **Tester sans condition témoin**, comme nous l'avons fait ici.
- **Comparer des textes bruts** quand la forme varie. Atil et ses coauteurs distinguent l'accord sur le texte brut et l'accord sur la réponse extraite. Le second est beaucoup plus élevé que le premier, et c'est souvent lui qui compte.

> **À retenir.** La température règle l'aplatissement de la distribution ; à 0, on choisit toujours le token le plus probable. La graine fixe le tirage, pas le calcul, et ne garantit rien sur un serveur partagé. Une expérience sans condition témoin ne prouve rien. Une consigne de forme n'est pas une garantie : on vérifie par programme, puis on nettoie ou on refuse.

### Pour vérifier que vous avez compris

1. Que devient la distribution des tokens quand la température tend vers 0 ? Et quand elle augmente ?
2. Concevez l'expérience qui prouverait que le serveur respecte la graine. Quelle est la condition témoin ?
3. Pourquoi `**Luvian**` pose-t-il problème à un programme qui attend un prénom ? Proposez deux parades.

### Références

- Holtzman, A., Buys, J., Du, L., Forbes, M., Choi, Y. (2020). *The Curious Case of Neural Text Degeneration*. International Conference on Learning Representations (ICLR 2020). https://arxiv.org/abs/1904.09751 — **Ce qu'on y apprend :** pourquoi maximiser la probabilité dégrade le texte, pourquoi la queue de la distribution est peu fiable, et ce qu'apporte l'échantillonnage par noyau.
- Atil, B., et al. (2025). *Non-Determinism of "Deterministic" LLM Settings*. Prépublication arXiv:2408.04667. https://arxiv.org/abs/2408.04667 — **Ce qu'on y apprend :** la variabilité mesurée à température nulle, et la distinction entre accord sur le texte brut et accord sur la réponse extraite.
- Zhou, J., Lu, T., Mishra, S., Brahma, S., Basu, S., Luan, Y., Zhou, D., Hou, L. (2023). *Instruction-Following Evaluation for Large Language Models*. Prépublication arXiv:2311.07911. https://arxiv.org/abs/2311.07911 — **Ce qu'on y apprend :** comment évaluer le respect des consignes avec des instructions vérifiables par programme.

## Chapitre 9 — La fenêtre de contexte : une aiguille dans une botte de foin

### Ce que nous avons fait

La première partie de `limites.py` cache une phrase, l'**aiguille** (« Le code de la séance est 4721. »), dans un texte de remplissage. Elle demande ensuite : « Quel est le code de la séance ? Réponds par le nombre seul. » Le test croise deux facteurs, la taille du texte et la position de l'aiguille :

| Facteur | Niveaux |
| --- | --- |
| Taille du texte | 8 000, 32 000, 64 000, 128 000 et 256 000 caractères |
| Position de l'aiguille | 10 %, 50 % et 90 % de la longueur |

Tout le reste est fixé : même aiguille, même question, température 0, au plus 10 tokens en sortie. Le remplissage est tiré au hasard avec une graine égale à la taille, donc identique d'une exécution à l'autre. Son vocabulaire ne contient **aucun chiffre** : « 4721 » ne peut venir que de l'aiguille, et la simple présence de cette chaîne dans la réponse suffit à conclure. Chaque réponse est classée « retrouvée », « manquée » ou « refusée ». Cela fait quinze appels.

### Pourquoi cette étape

La fenêtre de contexte est la mémoire de travail du modèle : tout ce qu'il doit lire pour répondre doit y tenir. Sa taille décide de l'architecture. Si le modèle lit une publication entière, on peut la lui donner telle quelle. Sinon, il faut découper les documents et ne transmettre que les passages utiles, retrouvés par recherche (chapitre 10). Il faut aussi savoir où le serveur refuse : au-delà, l'appel échoue.

### Comment ça marche

#### Un plan d'expérience à deux facteurs

Box, Hunter et Hunter (2005) enseignent quatre principes que ce petit test applique en partie :

- **Croiser les facteurs** plutôt que les faire varier un par un. Le plan factoriel complet (5 × 3 = 15 cellules) permet de voir un effet de la taille, un effet de la position, et une éventuelle interaction : la position ne compterait que pour les grands textes.
- **Fixer tout le reste**, pour attribuer les différences aux seuls facteurs étudiés.
- **Répéter** chaque cellule, pour estimer la variabilité. Nous ne l'avons pas fait : un essai par cellule.
- **Randomiser l'ordre** des essais, pour qu'une dérive dans le temps ne se confonde pas avec un facteur. Nous avons procédé par tailles croissantes : pour les durées (chapitre 11), la taille se confond donc avec l'heure de l'appel.

#### Ce qu'un « oui » ne dit pas

Le test de l'aiguille a été popularisé fin 2023 par Kamradt, sur les grands modèles commerciaux de l'époque. Il a deux limites connues.

**Retrouver une aiguille est la tâche la plus facile.** Hsieh et ses coauteurs (2024) ont construit RULER. On y trouve des aiguilles multiples, des clés et des valeurs à associer, le suivi de variables d'un passage à l'autre, des agrégations et des questions avec distracteurs. Des modèles presque parfaits au test simple voient leurs performances chuter nettement quand la longueur augmente sur ces tâches plus exigeantes. Seule une partie d'entre eux reste satisfaisante à la longueur de contexte qu'ils annoncent. La **taille effective** d'un contexte est souvent plus petite que sa taille nominale.

**La position compte.** Liu et ses coauteurs (2024) ont fait varier la place de l'information utile dans des tâches de questions-réponses sur plusieurs documents. Les performances sont souvent meilleures quand l'information est au début ou à la fin du contexte, et se dégradent nettement quand elle est au milieu. On l'observe même sur des modèles conçus pour les contextes longs. C'est la courbe en U de *Lost in the Middle*.

### Ce que nous avons observé

| Taille (caractères) | Tokens lus | Aiguille retrouvée |
| --- | --- | --- |
| 8 000 | 1 723 | 3 positions sur 3 |
| 32 000 | 6 654 | 3 positions sur 3 |
| 64 000 | 13 182 | 3 positions sur 3 |
| 128 000 | 26 488 | 3 positions sur 3 |
| 256 000 | 52 697 | 3 positions sur 3 |

**Quinze succès sur quinze, et aucun refus.** La limite du serveur se situe donc au-delà de 52 697 tokens. Nous ne savons pas où exactement.

Ces quinze succès ne contredisent pas *Lost in the Middle*. Notre tâche était trop facile pour faire apparaître un effet de position : une seule phrase contenait des chiffres, et elle tranchait sur un remplissage répétitif. Un test trop facile ne mesure rien d'utile. Il a seulement montré que le serveur accepte de grands contextes et que le modèle y repère un élément très saillant.

#### La décision d'architecture

Le budget de contexte est volontairement prudent, et non calé sur ce serveur : **environ 24 000 tokens d'entrée par appel**. On garde ainsi de la place pour la consigne, la sortie et une marge. Ce budget sera confirmé par la mesure sur chaque serveur. Au-delà, on découpe les documents et l'on cherche les passages utiles.

### Pièges et bonnes pratiques

- **Confondre accepter et utiliser.** Un serveur qui accepte 50 000 tokens ne garantit pas que le modèle s'en sert bien.
- **Un remplissage artificiel.** Une suite de mots courants n'a rien d'une publication statistique, pleine de nombres qui se ressemblent.
- **L'absence de nombres pièges.** Une aiguille unique et saillante ne teste pas la confusion entre « 4721 » et « 4712 ».
- **Pas de répétition.** Un essai par cellule ne donne aucune mesure de variabilité (chapitre 13).

Pour la séance 2 : plusieurs aiguilles, des nombres pièges (« Le code de la salle est 4712. »), un remplissage réaliste tiré de publications publiques, des positions plus fines, des répétitions et un ordre aléatoire.

> **À retenir.** La fenêtre de contexte est la mémoire de travail du modèle. Un plan factoriel isole l'effet de la taille et de la position, à condition de répéter et de randomiser. Retrouver une aiguille unique est la tâche la plus facile : la taille effective d'un contexte est souvent plus petite que sa taille nominale, et l'information placée au milieu est moins bien utilisée. Le budget de l'architecture est volontairement prudent.

### Pour vérifier que vous avez compris

1. Pourquoi le vocabulaire de remplissage ne contient-il aucun chiffre ?
2. Nos quinze succès contredisent-ils *Lost in the Middle* ? Expliquez.
3. Quels facteurs ajouter, et quelles règles de plan d'expérience appliquer, pour que ce test dise quelque chose d'utile au projet ?

### Références

- Liu, N. F., Lin, K., Hewitt, J., Paranjape, A., Bevilacqua, M., Petroni, F., Liang, P. (2024). *Lost in the Middle: How Language Models Use Long Contexts*. Transactions of the Association for Computational Linguistics, 12. https://arxiv.org/abs/2307.03172 — **Ce qu'on y apprend :** l'effet de la position de l'information dans un long contexte, et la courbe en U.
- Hsieh, C.-P., Sun, S., Kriman, S., Acharya, S., Rekesh, D., Jia, F., Zhang, Y., Ginsburg, B. (2024). *RULER: What's the Real Context Size of Your Long-Context Language Models?* Prépublication arXiv:2404.06654. https://arxiv.org/abs/2404.06654 — **Ce qu'on y apprend :** pourquoi le test de l'aiguille ne suffit pas, et comment mesurer la taille effective d'un contexte.
- Box, G. E. P., Hunter, J. S., Hunter, W. G. (2005). *Statistics for Experimenters: Design, Innovation, and Discovery*, 2e édition. Wiley. ISBN 978-0-471-71813-0 — **Ce qu'on y apprend :** les plans factoriels, la répétition, la randomisation et le découpage en blocs, avec des exemples tirés de nombreux domaines.
- Pour l'origine du test : Kamradt, G. (2023). *Needle In A Haystack — Pressure Testing LLMs*. Dépôt de code. https://github.com/gkamradt/LLMTest_NeedleInAHaystack

## Chapitre 10 — Embeddings et similarité cosinus

### Ce que nous avons fait

La deuxième partie de `limites.py` envoie trois phrases au point d'arrivée `/embeddings` et compare les vecteurs obtenus par similarité cosinus :

| Phrase | Rôle | Similarité avec la phrase 1 |
| --- | --- | --- |
| « Le ministère a payé ses fournisseurs en 2024. » | Référence | — |
| « En 2024, les fournisseurs ont été réglés par le ministère. » | Paraphrase | 0,838 |
| « Il pleut souvent à Brest en hiver. » | Hors sujet | 0,235 |

Le test est déclaré « cohérent » si la paraphrase est plus proche que la phrase hors sujet. Les vecteurs ont 4 096 dimensions.

### Pourquoi cette étape

L'assistant devra retrouver, dans un corpus de publications et de notes méthodologiques, les passages utiles à une question : c'est la **recherche documentaire** de la génération augmentée (RAG). La fenêtre de contexte ne permet pas de tout lire (chapitre 9). Il faut donc une mesure de proximité de sens, rapide à calculer sur des milliers de passages. Les embeddings la fournissent.

### Comment ça marche

> **Définition.** Un *embedding* est un vecteur de nombres réels, de dimension fixe, associé à un texte par un modèle entraîné pour que des textes de sens proche reçoivent des vecteurs proches.

#### La similarité cosinus

> **Formule.** *cos(u, v) = (u · v) / (‖u‖ × ‖v‖)*, compris entre −1 et 1.

Le cosinus mesure l'angle entre deux vecteurs, indépendamment de leur longueur. Le code de `limites.py` le calcule directement :

```python
def cosinus(u, v):
    produit = sum(a * b for a, b in zip(u, v))
    return produit / (math.sqrt(sum(a * a for a in u)) * math.sqrt(sum(b * b for b in v)))
```

#### Pourquoi des vecteurs de phrases

On pourrait juger la proximité de deux phrases en les donnant **ensemble** à un modèle (un *cross-encodeur*). C'est précis, mais il faut un calcul par paire : impossible sur des milliers de passages. Reimers et Gurevych (2019), avec Sentence-BERT, entraînent un réseau « siamois » qui encode **chaque phrase séparément** en un vecteur comparable par cosinus. On encode le corpus une fois pour toutes ; une recherche ne coûte plus qu'un encodage de la question et des produits scalaires. C'est le principe de tous les index de recherche par le sens. En pratique, on combine souvent les deux : les vecteurs pour présélectionner quelques dizaines de passages, un cross-encodeur pour les reclasser.

#### Pourquoi la phrase hors sujet ne donne pas zéro

Ethayarajh (2019) a étudié la géométrie des représentations produites par BERT, ELMo et GPT-2. Elles ne se répartissent pas uniformément dans l'espace : elles occupent un **cône étroit** (on parle d'*anisotropie*). Deux mots sans rapport y ont donc une similarité cosinus nettement positive. Ce constat porte sur des représentations de mots, mais il éclaire notre 0,235 : un cosinus ne se lit **jamais dans l'absolu**. Seules comptent les comparaisons entre textes, avec le même modèle. Un seuil fixé pour un modèle (« au-dessus de 0,7, c'est pertinent ») ne vaut pas pour un autre.

#### Choisir un modèle

Muennighoff et ses coauteurs (2022) ont réuni MTEB, un banc d'essai qui couvre de nombreuses tâches (recherche, classification, regroupement, similarité de phrases, etc.) et de nombreuses langues. Leur constat principal : **aucune méthode ne domine sur toutes les tâches**. On choisit donc un modèle sur les tâches qui ressemblent à la sienne, ici la recherche de passages en français, et non sur sa moyenne générale. Pour Albert, le modèle prévu est BGE-M3 (Chen et al., 2024) ; il a été conçu pour être multilingue et pour traiter des textes de longueurs très variées.

### Ce que nous avons observé

- **Cohérent** : 0,838 pour la paraphrase, 0,235 pour la phrase hors sujet. L'écart est large ; le serveur fournit des embeddings utilisables.
- **4 096 dimensions.** En nombres flottants de 4 octets, un vecteur occupe 16 Kio ; 100 000 passages occupent environ 1,6 Go. La dimension pèse sur le stockage et sur le temps de recherche.

### Les décisions qui en découlent

- **Un seul modèle d'embeddings par index.** Deux modèles produisent des espaces différents, dont les vecteurs ne se comparent pas. Changer de modèle impose de tout réindexer.
- **Les embeddings ne servent pas à rapprocher des chiffres.** Deux phrases qui ne diffèrent que par un montant (« 25,1 Md€ » et « 21,5 Md€ ») auront très probablement des vecteurs presque identiques. C'est une hypothèse à vérifier au banc. Le rapprochement des chiffres reste l'affaire du registre de faits.

### Pièges et bonnes pratiques

- **Lire un cosinus dans l'absolu** ou transposer un seuil d'un modèle à l'autre.
- **Mélanger les modèles** dans un même index.
- **Préparer différemment** les documents indexés et les questions. Certains modèles demandent justement un traitement différent des questions et des passages : il faut lire la fiche du modèle.
- **Confondre similarité et pertinence.** Une phrase très proche peut ne pas répondre à la question ; la recherche par le sens se complète par la recherche par mots-clés et par un reclassement.

> **À retenir.** Un embedding est un vecteur qui situe un texte dans un espace de sens. Le cosinus compare des angles et ne se lit que par comparaison, avec un même modèle. Encoder chaque texte séparément rend la recherche possible à grande échelle. On choisit un modèle sur des tâches proches des siennes. Un index n'admet qu'un seul modèle, et les embeddings ne servent pas à comparer des chiffres.

### Pour vérifier que vous avez compris

1. Pourquoi la phrase hors sujet n'a-t-elle pas une similarité nulle avec la phrase de départ ?
2. Que se passe-t-il si l'on indexe des documents avec un modèle d'embeddings et qu'on les interroge avec un autre ?
3. Proposez une expérience pour tester si les embeddings distinguent deux phrases qui ne diffèrent que par un montant.

### Références

- Reimers, N., Gurevych, I. (2019). *Sentence-BERT: Sentence Embeddings using Siamese BERT-Networks*. Proceedings of EMNLP-IJCNLP 2019. https://arxiv.org/abs/1908.10084 — **Ce qu'on y apprend :** pourquoi encoder chaque phrase séparément, et comment entraîner un modèle à produire des vecteurs comparables par cosinus.
- Ethayarajh, K. (2019). *How Contextual are Contextualized Word Representations? Comparing the Geometry of BERT, ELMo, and GPT-2 Embeddings*. Proceedings of EMNLP-IJCNLP 2019, p. 55–65. https://doi.org/10.18653/v1/D19-1006 — **Ce qu'on y apprend :** la géométrie des représentations, l'anisotropie, et ses conséquences pour l'interprétation du cosinus.
- Muennighoff, N., Tazi, N., Magne, L., Reimers, N. (2022). *MTEB: Massive Text Embedding Benchmark*. Prépublication arXiv:2210.07316. https://arxiv.org/abs/2210.07316 — **Ce qu'on y apprend :** comment comparer des modèles d'embeddings sur des tâches et des langues variées, et pourquoi aucun ne domine partout.
- Pour Albert : Chen, J., Xiao, S., Zhang, P., Luo, K., Lian, D., Liu, Z. (2024). *BGE M3-Embedding: Multi-Lingual, Multi-Functionality, Multi-Granularity Text Embeddings Through Self-Knowledge Distillation*. Prépublication arXiv:2402.03216. https://arxiv.org/abs/2402.03216

## Chapitre 11 — Débit et modèle de coût : lire est bon marché, écrire est cher

### Ce que nous avons fait

La troisième partie de `limites.py` envoie trois fois la même demande, « Décris en 150 mots le rôle d'un service statistique. », à température 0 et avec au plus 300 tokens. Le débit perçu est le nombre de tokens écrits divisé par la durée totale de l'appel, relue dans le journal. Nous avons aussi exploité les durées du test de contexte. Ces appels lisent beaucoup et n'écrivent presque rien (10 tokens au plus) : ils mesurent donc la vitesse de **lecture**.

### Pourquoi cette étape

Le coût d'un agent est la somme de ses appels. Pour concevoir un agent qui répond en un temps raisonnable et tient dans ses quotas, il faut un **modèle de coût** : comment la durée d'un appel dépend des tokens lus et des tokens écrits.

### Comment ça marche

#### Deux phases très différentes

Pope et ses coauteurs (2023) décrivent l'inférence d'un Transformer en deux phases :

- **Le préremplissage (prefill)** traite d'un coup tous les tokens de la requête. Les calculs portent sur des matrices entières, et le processeur graphique est pleinement employé.
- **Le décodage (decode)** produit les tokens un par un. À chaque pas, il faut relire en mémoire tous les paramètres du modèle et le *cache d'attention* (KV cache), pour un seul token produit par requête.

> **Définition.** Le *cache d'attention* (KV cache) garde, pour chaque token déjà traité, les « clés » et les « valeurs » dont le mécanisme d'attention a besoin. Il évite de tout recalculer à chaque pas, mais occupe une mémoire qui croît avec la longueur du contexte et avec le nombre de requêtes servies en même temps.

#### Le modèle roofline

Williams, Waterman et Patterson (2009) expliquent pourquoi ces deux phases vont à des vitesses si différentes. Les performances atteignables sont plafonnées par deux limites, la puissance de calcul et la bande passante mémoire. L'**intensité opérationnelle**, c'est-à-dire le nombre d'opérations par octet lu en mémoire, dit laquelle s'applique :

> **Formule.** *performance atteignable = min(puissance de calcul maximale, bande passante × intensité opérationnelle)*

- Le préremplissage réutilise chaque paramètre lu pour des milliers de tokens : intensité élevée, le calcul est la limite.
- Le décodage relit tous les paramètres pour produire un seul token : intensité faible, la bande passante mémoire est la limite.

D'où un token écrit beaucoup plus coûteux qu'un token lu.

#### Servir plusieurs utilisateurs à la fois

Un serveur regroupe les requêtes en **lots** : pendant le décodage, chaque lecture des paramètres sert à toutes les requêtes du lot. Plus le lot est grand, plus le débit total du serveur augmente, à condition d'avoir la mémoire pour les caches d'attention de toutes ces requêtes. C'est le problème que résout PagedAttention (Kwon et al., 2023). La mémoire du cache y est gérée par pages, comme celle d'un système d'exploitation. On évite ainsi le gaspillage, et l'on peut servir davantage de requêtes en même temps. Mais la vitesse perçue par **une** requête dépend de la charge. Agrawal et ses coauteurs (2024) montrent aussi que le préremplissage des nouvelles requêtes peut interrompre le décodage des requêtes en cours. Sur un serveur partagé, les longues requêtes des autres peuvent donc nous ralentir.

### Ce que nous avons observé

**L'écriture.** Trois appels d'environ 216 tokens écrits :

| Appel | Durée | Tokens écrits | Tokens par seconde |
| --- | --- | --- | --- |
| `debit-1` | 1,37 s | 216 | 157,7 |
| `debit-2` | 1,41 s | 216 | 153,2 |
| `debit-3` | 1,39 s | 220 | 158,3 |

Soit environ **156 tokens écrits par seconde**. La durée inclut le réseau et la lecture d'une courte requête : c'est donc une borne basse de la vitesse de décodage pure.

**La lecture.** Les appels du test de contexte donnent la durée en fonction du nombre de tokens lus :

| Tokens lus | Durée moyenne d'un appel |
| --- | --- |
| 13 182 | 0,72 s (2 appels relevés) |
| 26 488 | 1,37 s |
| 52 697 | 2,76 s |

La droite des moindres carrés a une pente de 5,18 × 10⁻⁵ s par token, soit environ 19 300 tokens par seconde, arrondis à **19 000 tokens lus par seconde** dans le modèle de coût. Son ordonnée à l'origine vaut 0,02 s : c'est la part fixe de l'appel, comprenant l'écriture de la courte réponse. Utiliser la **pente** plutôt que le rapport brut sépare le coût marginal du coût fixe.

**Le modèle de coût.** Écrire un token prend environ 120 fois plus de temps qu'en lire un sur ce serveur.

> **Formule.** *durée (s) ≈ tokens lus / 19 000 + tokens écrits / 156*

> **Exemple.** Un appel qui lit 20 000 tokens et en écrit 800 demande environ 1,05 s de lecture et 5,13 s d'écriture, soit 6,2 s. S'il n'écrit que 200 tokens, il ne demande plus que 2,3 s. Pour un agent de six appels, cela fait 37 s dans un cas, 14 s dans l'autre.

D'où la règle de conception : **un contexte généreux, des sorties courtes et structurées.**

#### Un biais possible : le cache des préfixes

Pour une taille donnée, les trois positions de l'aiguille utilisent le même remplissage. L'appel à 90 % partage donc la moitié de son début avec l'appel à 50 %. Or certains moteurs gardent en mémoire le calcul des débuts de requêtes déjà vus, ce que PagedAttention permet de partager entre requêtes. Les derniers appels pourraient ainsi être artificiellement accélérés. Nos données ne montrent pas d'effet net : l'appel `256k-90` a duré 2,66 s, pour une moyenne de 2,76 s à cette taille. Réutiliser la moitié de 52 697 tokens aurait fait gagner plus d'une seconde. Mais un bon plan doit écarter ce biais : un remplissage distinct pour chaque appel, et un ordre aléatoire.

### Pièges et bonnes pratiques

- **Le chronomètre est côté client.** Il inclut le réseau et l'attente dans la file du serveur.
- **Trois appels, à une seule heure de la journée.** La charge du serveur varie ; la mesure se répète à plusieurs moments.
- **Un autre serveur, un autre modèle de coût.** Albert sera mesuré avec le même script.
- **L'affichage progressif (streaming)** améliore la latence perçue, pas la durée totale.
- **L'historique d'un agent grossit.** Si chaque tour ajoute *m* tokens, une conversation de *n* tours fait lire au total *m × n(n + 1)/2* tokens : une croissance quadratique. Lire est bon marché, mais pas gratuit, et les quotas se comptent souvent en tokens.

> **À retenir.** Le préremplissage lit toute la requête en parallèle ; le décodage écrit token par token et bute sur la bande passante mémoire. Sur ce serveur, écrire un token coûte environ 120 fois plus de temps qu'en lire un. Le modèle de coût s'estime par une pente, pas par un rapport brut. D'où la règle : contexte généreux, sorties courtes et structurées. Un serveur partagé ralentit avec la charge.

### Pour vérifier que vous avez compris

1. Pourquoi écrire un token coûte-t-il beaucoup plus de temps qu'en lire un ? Répondez avec le modèle roofline.
2. Avec notre modèle de coût, combien de temps prend un appel qui lit 10 000 tokens et en écrit 400 ?
3. Pourquoi les appels du test de contexte auraient-ils pu être artificiellement accélérés, et comment l'éviter ?

### Références

- Pope, R., Douglas, S., Chowdhery, A., Devlin, J., Bradbury, J., Heek, J., Xiao, K., Agrawal, S., Dean, J. (2023). *Efficiently Scaling Transformer Inference*. Proceedings of Machine Learning and Systems 5 (MLSys 2023), p. 606–624. https://proceedings.mlsys.org/paper_files/paper/2023/hash/c4be71ab8d24cdfb45e3d06dbfca2780-Abstract-mlsys2023.html — **Ce qu'on y apprend :** les deux phases de l'inférence, et les compromis entre latence et débit selon la taille des lots et du contexte.
- Williams, S., Waterman, A., Patterson, D. (2009). *Roofline: An Insightful Visual Performance Model for Multicore Architectures*. Communications of the ACM, 52(4), p. 65–76. https://cacm.acm.org/research/roofline-an-insightful-visual-performance-model-for-multicore-architectures/ — **Ce qu'on y apprend :** comment savoir si un calcul est limité par la puissance ou par la mémoire, à partir de son intensité opérationnelle.
- Kwon, W., et al. (2023). *Efficient Memory Management for Large Language Model Serving with PagedAttention*. SOSP 2023. Code : https://github.com/vllm-project/vllm — **Ce qu'on y apprend :** pourquoi la mémoire du cache d'attention limite le nombre de requêtes servies, et comment la gérer par pages.
- Pour aller plus loin : Agrawal, A., Kedia, N., Panwar, A., Mohan, J., Kwatra, N., Gulavani, B. S., Tumanov, A., Ramjee, R. (2024). *Taming Throughput-Latency Tradeoff in LLM Inference with Sarathi-Serve*. 18th USENIX Symposium on Operating Systems Design and Implementation (OSDI 2024).

## Chapitre 12 — Questions de référence et chiffres publiés arrondis

### Ce que nous avons fait

Nous avons choisi la publication publique qui servira de référence au laboratoire : l'**EcoDef Statistiques n° 273** (S2E, janvier 2026), « En 2024, le ministère des Armées a versé 25,1 milliards d'euros à ses fournisseurs résidents ». À partir d'elle, nous avons écrit trois questions, chacune avec ses valeurs de référence tirées de la publication et ce qu'elle teste :

| Question | Valeurs de référence | Ce qu'elle teste |
| --- | --- | --- |
| 1. Combien le ministère des Armées a-t-il versé à ses fournisseurs résidents en 2024, et comment ce montant a-t-il évolué depuis 2023 ? | 25,1 Md€ ; 82,9 % des 30,3 Md€ versés ; +9,4 % ; 23 451 entreprises résidentes | Montants, part et évolution |
| 2. Quels secteurs d'activité et quelles catégories d'entreprises reçoivent ces paiements en 2024 ? | Industrie 17,7 Md€ (70,7 %) ; grandes entreprises 15,8 Md€ (+24,0 %) ; ETI 3,3 Md€ (−18,2 %) | Répartitions ; la baisse des ETI est en partie un effet de structure |
| 3. Quels programmes de la mission « Défense » financent ces paiements en 2024 ? | P146 11,7 Md€ ; P178 9,8 Md€ ; P144 1,5 Md€ ; P212 0,9 Md€ | Un champ partiel : 23,9 Md€, et non 25,1 |

### Pourquoi cette étape

**La référence se fixe avant de construire.** Si on la choisit après avoir vu les réponses du système, on ajuste la cible au résultat, souvent sans s'en rendre compte. C'est la même discipline que celle qui consiste à écrire un test avant le code.

**Chaque question vise un mode d'échec différent.** La première demande des montants, une part et une évolution. La deuxième demande des répartitions et une interprétation prudente : la baisse des ETI tient en partie au changement de catégorie de certaines entreprises. La troisième tend un piège de champ.

**Mesurer des comportements, pas seulement une exactitude moyenne.** Ribeiro et ses coauteurs (2020) montrent, avec CheckList, que l'exactitude mesurée sur un jeu de test surestime souvent les performances réelles. Ils proposent de tester des **capacités** avec trois types de tests :

- **fonctionnalité minimale** : des cas simples qui doivent passer ;
- **invariance** : des modifications qui ne doivent pas changer la sortie ;
- **attente directionnelle** : des modifications qui doivent la changer dans un sens connu.

Transposés à notre question 1, cela donne :

- fonctionnalité minimale : « quel est le montant total ? » doit citer le bon fait du registre ;
- invariance : reformuler la question ne doit pas changer les faits cités ;
- attente directionnelle : remplacer 2024 par 2023 doit changer les faits cités.

HELM (Liang et al., 2023) ajoute l'exigence de **plusieurs critères**. Pour chaque question, nous mesurerons :

- l'exactitude des faits cités (aucun chiffre sans source) ;
- la couverture des faits attendus ;
- le refus quand la donnée manque ;
- la durée et le coût.

### Comment ça marche : vérifier un chiffre arrondi

Les montants publiés sont **arrondis** au dixième de milliard, alors que les parts sont calculées par le producteur sur les données **non arrondies**. Recalculer une part à partir des montants arrondis donne donc une valeur un peu différente : 17,7 / 25,1 = 70,5 %, alors que la publication indique 70,7 %.

Un vérificateur naïf signalerait une erreur qui n'existe pas. Un vérificateur laxiste, avec une tolérance d'un demi-point, laisserait passer de vraies erreurs. La bonne réponse est l'**arithmétique d'intervalles**.

> **Formule.** Un montant publié *x̃*, arrondi au dixième, signifie que la vraie valeur *x* est dans [*x̃* − 0,05 ; *x̃* + 0,05]. Pour un rapport *a/b* de deux quantités positives, avec *a* dans [*a*₋ ; *a*₊] et *b* dans [*b*₋ ; *b*₊], le rapport est dans [*a*₋ / *b*₊ ; *a*₊ / *b*₋].

> **Exemple.** L'industrie est dans [17,65 ; 17,75] et le total dans [25,05 ; 25,15]. Sa part est donc dans [70,2 % ; 70,9 %], et la valeur publiée de 70,7 % est **compatible avec les arrondis**. De même, la part de 82,9 % (25,1 sur 30,3) est dans l'intervalle [82,5 % ; 83,1 %].

La règle du vérificateur en découle : un chiffre du texte est accepté s'il est compatible avec les valeurs du registre, compte tenu de leur arrondi. Sinon, il est signalé. Et si un fichier de données plus précis existe, on l'utilise : c'est un point en attente.

**Une somme qui ne boucle pas n'est pas forcément une erreur.** Les quatre programmes de la question 3 totalisent 11,7 + 9,8 + 1,5 + 0,9 = 23,9 Md€, et non 25,1. Ils ne couvrent pas tout le champ. Le registre doit donc enregistrer le **champ** de chaque fait. Un vérificateur ne doit jamais additionner des faits de champs différents.

### Le secret statistique

Pour les statistiques d'entreprises, l'Insee ne publie aucun résultat qui concerne **moins de trois unités**, ni aucun résultat dont une seule unité représente l'essentiel (seuil de **85 %**). Masquer une case ne suffit pas toujours, car sa valeur peut se retrouver par différence avec les totaux de ligne ou de colonne. On masque alors d'autres cases : c'est le **secret secondaire**.

Pour un agent, le danger est concret. En calculant des différences entre agrégats, il pourrait reconstituer une case masquée. Pour le laboratoire, qui ne manipule que des chiffres déjà publiés, le risque est nul. Dès que des données confidentielles sont en jeu, c'est une contrainte dure : aucun chiffre calculé à partir de ces données ne sort sans contrôle du secret. Hundepool et ses coauteurs (2012) ont écrit le manuel de référence du domaine. Il couvre la protection des fichiers individuels et des tableaux, les secrets primaire et secondaire, et l'arbitrage entre risque de divulgation et utilité des données.

### Ce que nous avons observé

- Trois questions de référence couvrent montants, parts, évolutions, répartitions, effet de structure et champ partiel.
- **Point ouvert :** les montants publiés sont arrondis, et les parts recalculées s'en écartent. Il faut soit un fichier de données plus précis, soit un contrôle de compatibilité avec les arrondis, celui de ce chapitre.

### Pièges et bonnes pratiques

- **Écrire les questions après avoir vu les réponses.**
- **Ne prévoir que des questions faciles.** Il faut aussi des pièges de champ, des effets de structure et des données absentes : l'assistant doit savoir répondre « non disponible ».
- **Comparer des nombres sous forme de texte** (chapitre 3).
- **Faire vérifier les chiffres du modèle par un modèle.** La vérification des chiffres est déterministe, ou elle n'est pas.

> **À retenir.** La référence se fixe avant de construire, avec des questions qui visent chacune un mode d'échec. On teste des comportements (fonctionnalité minimale, invariance, attente directionnelle), sur plusieurs critères. Un chiffre arrondi se vérifie par intervalles, pas par égalité ni par tolérance arbitraire. Chaque fait a un champ, et l'on n'additionne pas des champs différents. Le secret statistique s'impose à tout chiffre calculé.

### Pour vérifier que vous avez compris

1. Montrez que 70,7 % est compatible avec les montants arrondis de 17,7 et 25,1 Md€.
2. Pourquoi la somme des programmes (23,9 Md€) ne contredit-elle pas le total de 25,1 Md€ ?
3. Transposez les trois types de tests de CheckList à la question 2.

### Références

- Ribeiro, M. T., Wu, T., Guestrin, C., Singh, S. (2020). *Beyond Accuracy: Behavioral Testing of NLP Models with CheckList*. Proceedings of the 58th Annual Meeting of the ACL (ACL 2020). Code : https://github.com/marcotcr/checklist — **Ce qu'on y apprend :** une méthode pour tester des capacités précises d'un modèle, avec des tests de fonctionnalité minimale, d'invariance et d'attente directionnelle.
- Liang, P., Bommasani, R., Lee, T., et al. (2023). *Holistic Evaluation of Language Models*. Transactions on Machine Learning Research. https://arxiv.org/abs/2211.09110 — **Ce qu'on y apprend :** comment organiser une évaluation par scénarios et par critères multiples, en documentant ce qu'elle ne couvre pas.
- Hundepool, A., Domingo-Ferrer, J., Franconi, L., Giessing, S., Schulte Nordholt, E., Spicer, K., de Wolf, P.-P. (2012). *Statistical Disclosure Control*. Wiley. https://doi.org/10.1002/9781118348239 — **Ce qu'on y apprend :** les méthodes de protection contre la divulgation, pour les fichiers individuels comme pour les tableaux.
- Sources officielles sur les règles françaises : Insee, *Secret statistique*, https://www.insee.fr/fr/information/1300624 ; Insee, *Guide du secret statistique* (mise à jour de septembre 2025), https://www.insee.fr/fr/statistiques/fichier/1300624/GUIDE%20DU%20SECRET%20STATISTIQUE%20MAJ%202509.pdf ; Insee, *Courrier des statistiques* n° 9 (2023), « Confidentialité des données statistiques : un enjeu majeur pour le service statistique public », https://www.insee.fr/fr/information/7635823?sommaire=7635842

## Chapitre 13 — Un essai ne prouve rien : intervalles de confiance pour des taux

### Ce que nous avons fait

Chaque capacité du serveur a été testée **une fois**, et chaque test a réussi. Le bilan de séance le signalait : un essai par capacité donne un indice, pas un taux. Ce chapitre explique pourquoi, chiffres à l'appui, et prépare le banc de la séance 2.

### Pourquoi cette étape

Nous allons prendre des décisions d'architecture à partir de taux observés. Par exemple : « le serveur impose le schéma », ou « le modèle appelle le registre quand il le faut dans au moins 95 % des cas ». Un taux sans incertitude est un piège, et les évaluations de modèles de langage portent souvent sur de petits effectifs.

### Comment ça marche

#### Le modèle statistique

Chaque essai est une épreuve de Bernoulli de probabilité de succès *p*, inconnue. On observe *k* succès en *n* essais ; l'estimateur naturel est *p̂ = k/n*. Toute la question est l'incertitude autour de *p̂*.

#### L'intervalle de Wald, et pourquoi l'éviter

L'intervalle enseigné en premier, *p̂ ± z √(p̂(1 − p̂)/n)*, s'effondre aux bords. Avec 1 succès en 1 essai, *p̂ = 1* et la largeur est nulle : l'intervalle [100 % ; 100 %] prétendrait à la certitude. Brown, Cai et DasGupta (2001) ont montré que sa probabilité de couverture est erratique et souvent bien inférieure à son niveau annoncé, y compris pour de grands échantillons. Ils recommandent l'intervalle de Wilson, ou celui de Jeffreys, pour les petits *n*, et celui d'Agresti et Coull pour les plus grands.

#### L'intervalle de Wilson

Wilson (1927) retourne le problème. Au lieu de centrer l'intervalle sur *p̂* avec une variance estimée en *p̂*, il cherche toutes les valeurs de *p* compatibles avec l'observation : celles pour lesquelles |*p̂* − *p*| ≤ *z* √(*p*(1 − *p*)/*n*). Résoudre cette inégalité du second degré en *p* donne :

> **Formule.** centre = (*p̂* + *z*²/(2*n*)) / (1 + *z*²/*n*) ; demi-largeur = *z* / (1 + *z*²/*n*) × √(*p̂*(1 − *p̂*)/*n* + *z*²/(4*n*²)), avec *z* = 1,96 pour 95 %.

| Observation | Intervalle de Wilson à 95 % |
| --- | --- |
| 1 succès sur 1 | [20,7 % ; 100 %] |
| 45 succès sur 50 | [78,6 % ; 95,7 %] |
| 49 succès sur 50 | [89,5 % ; 99,6 %] |
| 50 succès sur 50 | [92,9 % ; 100 %] |
| 0 succès sur 50 | [0 % ; 7,1 %] |

**Lecture :** après un succès sur un essai, le vrai taux de succès peut être aussi bas que 21 %. Notre test unique ne prouve presque rien. Après cinquante succès sur cinquante, il est d'au moins 92,9 %.

#### La règle de trois

Quand aucun échec n'est observé en *n* essais, la borne supérieure à 95 % du taux d'échec vaut environ **3/n**. Hanley et Lippman-Hand (1983) l'ont popularisée dans un article au titre parlant : « Si rien ne va mal, tout va-t-il bien ? ». Pour 50 essais sans échec, le taux d'échec est inférieur à environ 6 % (5,8 % par le calcul exact). Wilson donne 7,1 % : la méthode est différente et un peu plus prudente. L'essentiel est ailleurs : **zéro échec observé ne veut pas dire zéro échec.**

#### Combien d'essais ?

Pour estimer un taux voisin de 90 % à ±10 points près, il faut environ 35 essais ; à ±5 points près, environ 139 (par l'approximation normale, *n = z² p(1 − p) / E²*). Avec une cinquantaine d'essais par test, la précision est d'environ ±8 points autour de 90 %. C'est le compromis retenu pour le banc.

#### Deux sources de variabilité

Miller (2024) rappelle qu'évaluer un modèle, c'est tirer des questions dans une population de questions possibles. À cela s'ajoute le hasard propre au modèle sur chaque question. D'où deux protocoles qui ne mesurent pas la même chose :

- **répéter cinquante fois la même requête** mesure la **stabilité** du serveur et du modèle sur cette requête ;
- **poser cinquante requêtes différentes** mesure la **capacité** du modèle sur une population de cas.

Miller recommande de publier une erreur type avec chaque score. Il recommande aussi des erreurs types groupées quand les questions forment des familles liées, et des comparaisons appariées quand deux modèles passent les mêmes questions.

### Ce que nous avons observé

- Quatre capacités, un essai chacune, quatre succès. Chacune a pour intervalle de Wilson [20,7 % ; 100 %].
- Les valeurs de contrôle prévues pour la fonction de Wilson du carnet de bord sont correctes : 2 sur 60 donne [0,9 % ; 11,4 %], 0 sur 100 donne [0,0 % ; 3,7 %] et 5 sur 100 donne [2,2 % ; 11,2 %].

### Pièges et bonnes pratiques

- **Annoncer 100 %** après une poignée d'essais.
- **Utiliser l'intervalle de Wald** près de 0 ou de 1.
- **Appeler « capacité » ce qui n'est qu'une répétition** de la même requête.
- **Multiplier les tests** sans s'attendre à ce que certains échouent par hasard.
- **Supposer les essais indépendants** alors qu'ils sont lancés au même moment sur un serveur partagé. On répartit les essais dans le temps et l'on mélange leur ordre.

> **À retenir.** Un taux sans intervalle ne vaut rien. L'intervalle de Wilson reste correct près de 0 et de 1, contrairement à celui de Wald. Après un seul succès, le vrai taux peut descendre à 21 %. Zéro échec en *n* essais borne le taux d'échec à environ 3/*n*, pas à zéro. Répéter une requête mesure la stabilité ; varier les requêtes mesure la capacité.

### Pour vérifier que vous avez compris

1. Calculez l'intervalle de Wilson pour 1 succès en 1 essai. Que peut-on conclure ?
2. Aucun échec en 50 essais : que dit la règle de trois ? Pourquoi n'est-ce pas « 0 % d'échec » ?
3. Quelle différence entre répéter cinquante fois la même question et poser cinquante questions différentes ?

### Références

- Wilson, E. B. (1927). *Probable Inference, the Law of Succession, and Statistical Inference*. Journal of the American Statistical Association, 22, p. 209–212. — **Ce qu'on y apprend :** l'intervalle obtenu en retournant le test du score, qui reste valable près de 0 et de 1.
- Brown, L. D., Cai, T. T., DasGupta, A. (2001). *Interval Estimation for a Binomial Proportion*. Statistical Science, 16(2), p. 101–133. https://doi.org/10.1214/ss/1009213286 — **Ce qu'on y apprend :** pourquoi l'intervalle de Wald couvre mal, et quels intervalles choisir selon la taille de l'échantillon.
- Hanley, J. A., Lippman-Hand, A. (1983). *If Nothing Goes Wrong, Is Everything All Right? Interpreting Zero Numerators*. JAMA, 249(13), p. 1743–1745. https://doi.org/10.1001/jama.1983.03330370053031 — **Ce qu'on y apprend :** comment interpréter l'absence d'événement, et la règle de trois.
- Pour aller plus loin : Miller, E. (2024). *Adding Error Bars to Evals: A Statistical Approach to Language Model Evaluations*. Prépublication arXiv:2411.00640. https://arxiv.org/abs/2411.00640 — **Ce qu'on y apprend :** comment appliquer ces outils à l'évaluation des modèles de langage.

## Chapitre 14 — Git, commits et secrets : tout tracer sans rien divulguer

### Ce que nous avons fait

Le laboratoire vit dans un dépôt **public** sur GitHub, dossier `assistant`. Deux commits sont confirmés :

- `a124409` feat: enveloppe d'appel au modèle avec journal et rejeu
- `179d17d` feat: test des capacités du serveur, relevé rejouable

Avant chaque commit, une commande vérifie que la clé d'API ne figure pas dans ce qui va être enregistré :

```bash
git diff --staged | grep -cF "${LLM_CLE:?}"   # doit afficher 0
```

Deux incidents ont été corrigés en chemin : un module nommé `LLM.py` que Python ne trouvait pas, et des fichiers écrits hors du dépôt.

### Pourquoi cette étape

**Savoir quel code a produit quel résultat.** Chaque commit est un instantané du projet, désigné par un identifiant unique. Avec les relevés et le journal commités au même endroit, on peut dire exactement quelle version du code a produit quelle mesure. C'est la règle 4 de Sandve et ses coauteurs (chapitre 4) : versionner tous ses scripts. Blischak, Davenport et Wilson (2016) présentent les notions de base (dépôt, commit, zone de préparation, dépôt distant). Ils rappellent aussi ce qu'il ne faut pas versionner, à commencer par les informations sensibles comme les mots de passe.

**Des pratiques suffisantes plutôt que parfaites.** Wilson et ses coauteurs (2017) ont rassemblé les pratiques « suffisamment bonnes » pour qui débute en programmation scientifique. On y trouve notamment : faire des changements petits, les partager souvent, utiliser un système de gestion de versions, rendre les dépendances explicites, et enregistrer toutes les étapes du traitement des données.

**Un dépôt public ne pardonne pas.** Meli et ses coauteurs (2019) ont montré que la fuite de clés sur GitHub est massive (chapitre 2). Une clé supprimée dans un commit suivant reste dans l'historique : la seule protection est de ne jamais la commiter.

### Comment ça marche

#### Les quatre étages de Git

| Étage | Commande pour y passer | Ce que l'on y trouve |
| --- | --- | --- |
| Dossier de travail | (modifier les fichiers) | L'état actuel des fichiers |
| Zone de préparation | `git add` | Ce qui partira au prochain commit |
| Dépôt local | `git commit` | L'historique des instantanés |
| Dépôt distant | `git push` | La copie partagée, qui sert aussi de sauvegarde |

`git diff` compare le dossier de travail à la zone de préparation, pour les seuls fichiers suivis. `git diff --staged` compare la zone de préparation au dernier commit : c'est exactement ce qui va être enregistré. Un fichier jamais ajouté est invisible pour `git diff`, ce qui explique l'incident du chapitre 5.

#### Les messages de commit conventionnels

La spécification Conventional Commits 1.0.0 impose la forme `type(portée facultative): description`. Les types de base sont `feat` (nouvelle fonctionnalité) et `fix` (correction). L'usage en ajoute d'autres : `docs`, `refactor`, `test`, `chore`. Un `!` après le type, ou une mention `BREAKING CHANGE` en pied de message, signale un changement incompatible. L'historique devient lisible par un humain et exploitable par un programme : un journal des modifications peut en être tiré automatiquement.

#### Le contrôle anti-fuite, pièce par pièce

- `git diff --staged` affiche ce qui va être commité.
- `grep -c` compte les lignes qui contiennent le motif ; `-F` le traite comme une chaîne fixe, et non comme une expression régulière, car une clé peut contenir des caractères spéciaux.
- `${LLM_CLE:?}` arrête la commande avec une erreur si la variable est vide ou absente. Sans cette précaution, dans un terminal où la variable n'est pas définie, `grep` chercherait une chaîne vide. Le contrôle ne contrôlerait alors plus rien : un contrôle qui ne contrôle rien doit échouer bruyamment.
- Le résultat attendu est `0`.

Une amélioration viendra avec l'intégration continue : un détecteur de secrets lancé automatiquement à chaque envoi.

#### Ce qui se commite, et ce qui ne se commite jamais

| Se commite | Ne se commite jamais |
| --- | --- |
| Le code : `llm.py` et les scripts | La clé d'API, les fichiers `.env` |
| Les relevés : `mesures/` | Toute donnée interne, même anonymisée |
| Le journal des appels, qui ne contient que des données publiques | Tout nom de système ou d'outil interne |
| Le journal de séance et la documentation | Les fichiers générés (`__pycache__/`, etc.) |

#### Deux incidents, deux règles

**La casse compte sous Linux.** `import llm` cherche le fichier `llm.py` ; `LLM.py` est un autre fichier pour Linux, qui distingue majuscules et minuscules. macOS et Windows, souvent configurés pour ne pas les distinguer, cachent le problème. Un code qui marche sur un poste peut donc échouer sur un autre. La convention de Python (PEP 8) veut des noms de modules courts et en minuscules.

**Les chemins relatifs dépendent du dossier de lancement.** Le bouton d'exécution de VS Code lance les scripts depuis `~/work`, et les fichiers partaient hors du dépôt. Correction : ancrer les chemins sur le dossier du script.

```python
RACINE = Path(__file__).resolve().parent
JOURNAL = RACINE / "journal" / "appels.jsonl"
```

### Ce que nous avons observé

- Deux commits confirmés, un historique lisible. Le reste de la clôture est dans l'annexe C.
- Les deux incidents sont corrigés et ont donné deux règles durables.

### Pièges et bonnes pratiques

- **Commiter un secret puis le supprimer.** Il reste dans l'historique : il faut révoquer la clé et en créer une nouvelle.
- **Un commit fourre-tout.** Une intention par commit (chapitre 5).
- **Oublier de pousser.** Le dépôt distant est aussi la sauvegarde.
- **Oublier que le dépôt est public.** Tout ce qui est commité est publié, journal compris.

> **À retenir.** Un commit est un instantané identifié : il relie chaque résultat au code qui l'a produit. `git diff --staged` montre ce qui va partir, et le contrôle anti-fuite s'applique avant chaque commit. Un secret commité est compromis, même supprimé ensuite. Les messages conventionnels rendent l'historique lisible. Enfin, des noms de modules en minuscules et des chemins ancrés sur le dossier du script évitent deux pannes classiques.

### Pour vérifier que vous avez compris

1. Que fait exactement `${LLM_CLE:?}`, et que se passerait-il sans le `:?` dans un terminal où la variable n'est pas définie ?
2. Une clé a été commitée, puis supprimée au commit suivant. Est-elle protégée ? Que faut-il faire ?
3. Rédigez les messages conventionnels des deux commits qui auraient dû séparer la refactorisation de l'enveloppe et l'ajout des embeddings.

### Références

- Blischak, J. D., Davenport, E. R., Wilson, G. (2016). *A Quick Introduction to Version Control with Git and GitHub*. PLoS Computational Biology, 12(1), e1004668. https://doi.org/10.1371/journal.pcbi.1004668 — **Ce qu'on y apprend :** les notions de base de Git et GitHub pour des scientifiques, et ce qu'il ne faut pas versionner.
- Wilson, G., Bryan, J., Cranston, K., Kitzes, J., Nederbragt, L., Teal, T. K. (2017). *Good enough practices in scientific computing*. PLoS Computational Biology, 13(6), e1005510. https://doi.org/10.1371/journal.pcbi.1005510 — **Ce qu'on y apprend :** un ensemble de pratiques réalistes pour les données, le code, l'organisation d'un projet et le suivi des changements.
- Meli, M., McNiece, M. R., Reaves, B. (2019). *How Bad Can It Git? Characterizing Secret Leakage in Public GitHub Repositories*. NDSS Symposium 2019. https://doi.org/10.14722/ndss.2019.23418 — **Ce qu'on y apprend :** pourquoi la prévention est la seule protection contre la fuite de secrets.
- Spécification : *Conventional Commits 1.0.0*. https://www.conventionalcommits.org/en/v1.0.0/

## Chapitre 15 — Synthèse : ce que la séance change pour l'architecture

### Des observations aux décisions

| Observation | Décision d'architecture | À confirmer en séance 2 |
| --- | --- | --- |
| Le serveur accepte plus de 52 697 tokens ; l'aiguille unique est retrouvée partout | Budget prudent d'environ 24 000 tokens d'entrée par appel ; au-delà, découpage et recherche | Taille effective avec plusieurs aiguilles et des nombres pièges |
| JSON et schéma respectés, un essai chacun | Sorties structurées pour tout échange avec le code ; validation à la réception | La contrainte est-elle imposée, ou seulement respectée ? |
| Le modèle remplit un champ numérique de mémoire | Aucun nombre dans les sorties du modèle : des identifiants de faits seulement | Taux de chiffres sans source dans des conditions réalistes |
| L'appel d'outil est produit sur consigne explicite | Le registre de faits est un outil ; ses arguments sont validés | Taux d'appel sans consigne explicite |
| Mise en forme Markdown non demandée | Toute sortie est nettoyée ou refusée ; décodage contraint quand la forme compte | Taux de respect de consignes vérifiables en français |
| Deux sorties identiques avec la même graine | Température 0 par défaut ; on ne compte pas sur la graine | Stabilité, avec une condition témoin |
| Embeddings cohérents, 4 096 dimensions | Un seul modèle d'embeddings par index | Sensibilité des embeddings aux montants |
| Écrire coûte environ 120 fois plus de temps que lire | Contexte généreux, sorties courtes ; budget d'appels par agent | Modèle de coût sur Albert ; variation selon l'heure |
| Les chiffres publiés sont arrondis | Vérification par intervalles ; un champ pour chaque fait | Disponibilité d'un fichier de données précis |
| Ce serveur n'impose pas de contrainte de temps | Les contraintes de temps viennent des quotas et du serveur cible | Quotas d'Albert |

### Ce que nous ne savons pas encore

- **Des taux.** Chaque capacité a été testée une fois ; l'intervalle de Wilson va de 20,7 % à 100 % (chapitre 13).
- **Albert.** Les scripts sont prêts ; il manque l'accès.
- **La taille effective du contexte**, au-delà d'une aiguille unique et saillante.

### Séance 2 : le banc

- **Objectif :** chiffrer les faiblesses du modèle.
- **Contenu :**
  - chaque test répété une cinquantaine de fois, pour obtenir des taux avec leur intervalle de Wilson ;
  - un test du schéma contre la consigne, pour savoir si la contrainte est imposée ;
  - la stabilité de la graine, avec une condition témoin ;
  - des consignes vérifiables en français, dont la mise en forme parasite ;
  - plusieurs aiguilles et des nombres pièges ;
  - l'appel d'outil sans consigne explicite ;
  - la sensibilité des embeddings aux montants.
- **Livrables :** `mesures/rapport_banc.md` et un premier enregistrement de décision d'architecture, l'ADR-001. Un ADR est un court document qui consigne une décision, son contexte et ses conséquences.
- **Critère de fin :** l'ADR-001 est écrit.

### Ce que la séance vous a appris à faire

1. Mesurer un serveur avant de concevoir, avec des scripts rejouables.
2. Rendre reproductible un appel qui ne l'est pas : empreinte, journal, rejeu.
3. Modifier du code sans changer ses résultats, et le prouver.
4. Distinguer forme et vérité, respect et contrainte, obéissance et jugement.
5. Concevoir une expérience avec facteurs, constantes, témoin, répétition et ordre aléatoire.
6. Lire une similarité cosinus et un modèle de coût.
7. Vérifier un chiffre arrondi par intervalles.
8. Mettre un intervalle de confiance sur un taux.
9. Tout tracer dans Git sans rien divulguer.

## Annexe A — Résultats bruts de la séance

Serveur de modèles du SSP Cloud, 10 novembre 2026. Tous les résultats sont rejouables à partir de `journal/appels.jsonl`.

### Capacités (un essai chacune)

| Option | Statut | Observation |
| --- | --- | --- |
| JSON simple | respecté | JSON valide |
| JSON avec schéma | respecté | `{"ville": "Lyon", "habitants": 522250}` |
| Appel d'outil | respecté | `population(ville = "Lyon")` |
| Graine | respecté | Deux fois `**Luvian**` : simple indice |

### Fenêtre de contexte

| Taille (caractères) | Tokens lus | Aiguille retrouvée | Durée moyenne d'un appel |
| --- | --- | --- | --- |
| 8 000 | 1 723 | 3 positions sur 3 | non relevée |
| 32 000 | 6 654 | 3 positions sur 3 | non relevée |
| 64 000 | 13 182 | 3 positions sur 3 | 0,72 s (2 appels relevés) |
| 128 000 | 26 488 | 3 positions sur 3 | 1,37 s |
| 256 000 | 52 697 | 3 positions sur 3 | 2,76 s |

Aucun refus : la limite du serveur se situe au-delà de 52 697 tokens.

### Embeddings

Vecteurs de 4 096 dimensions. Similarité cosinus avec la phrase de départ : 0,838 pour la paraphrase, 0,235 pour la phrase hors sujet. Statut : cohérent.

### Débit

| Appel | Durée | Tokens écrits | Tokens par seconde |
| --- | --- | --- | --- |
| `debit-1` | 1,37 s | 216 | 157,7 |
| `debit-2` | 1,41 s | 216 | 153,2 |
| `debit-3` | 1,39 s | 220 | 158,3 |

### Modèle de coût

> **Formule.** *durée (s) ≈ tokens lus / 19 000 + tokens écrits / 156*

Pente de la durée en fonction des tokens lus : 5,18 × 10⁻⁵ s par token, soit environ 19 300 tokens par seconde ; ordonnée à l'origine : 0,02 s.

## Annexe B — Incidents et corrections

| Incident | Cause | Correction | Chapitre |
| --- | --- | --- | --- |
| Erreur 404 sur l'adresse de base du serveur | Une adresse de base n'est pas un point d'arrivée | Appeler `/api/models` ou `/api/chat/completions` | 2 |
| Formulaire d'accès à Albert introuvable | Remplacé par une connexion ProConnect | Passer par le Playground d'Albert ; formulaire DataPass en cas de refus | 2 |
| Approximation de 4 caractères par token trop basse | Règle empirique valable pour l'anglais | Mesure sur notre texte : 4,6 à 4,9 caractères par token | 3 |
| Vérification du rejeu sans effet | `git diff` ignore un fichier non suivi | Commiter d'abord, rejouer ensuite, comparer enfin | 5 |
| Version de `llm.py` commitée en retard | Le dépôt contient la première version (68 lignes) | Commiter la version avec embeddings et durées | 5 |
| `ModuleNotFoundError: No module named 'llm'` | Fichier nommé `LLM.py` ; la casse compte sous Linux | Noms de modules en minuscules | 14 |
| Fichiers écrits hors du dépôt | Chemins relatifs au dossier de lancement | Chemins ancrés sur le dossier du script | 14 |

## Annexe C — Clôture et points en attente

### Commits confirmés

- `a124409` feat: enveloppe d'appel au modèle avec journal et rejeu
- `179d17d` feat: test des capacités du serveur, relevé rejouable

### À cocher

- [ ] `llm.py`, version avec embeddings et durées, commité
- [ ] `limites.py`, `mesures/limites.json` et le journal des appels commités
- [ ] Rejeu de `limites.json` identique
- [ ] Journal de la séance complété et commité
- [ ] `git push`

### Points en attente

- **Accès à Albert :** relancer `capacites.py` et `limites.py` avec ses variables et `LLM_MODELE_EMB=bge-m3`.
- **Données de l'EcoDef n° 273 :** chercher un fichier plus précis que les chiffres arrondis de la publication.
- **Validation du cadre des deux projets :** en attente.
- **Carnet de bord :** le créer à partir du prompt Copilot préparé.

### Séance 2

Le programme du banc est détaillé à la fin du chapitre 15.

## Annexe D — Glossaire

| Terme | Définition | Chap. |
| --- | --- | --- |
| ADR | Enregistrement de décision d'architecture : court document qui consigne une décision, son contexte et ses conséquences | 15 |
| Agent | Système où le modèle dirige lui-même son processus et l'usage des outils | 1 |
| Aiguille (test de l') | Phrase cachée dans un long texte, que le modèle doit retrouver | 9 |
| Anisotropie | Répartition non uniforme des représentations dans l'espace ; deux textes sans rapport y ont une similarité positive | 10 |
| API compatible OpenAI | Format de requêtes HTTP et de réponses JSON devenu un standard de fait | 2 |
| Arithmétique d'intervalles | Calcul sur des intervalles de valeurs possibles, utilisé ici pour vérifier des chiffres arrondis | 12 |
| BPE | Encodage par paires d'octets : tokenisation par fusions successives des paires les plus fréquentes | 3 |
| Cache d'attention (KV cache) | Mémoire des clés et des valeurs des tokens déjà traités, qui évite de les recalculer | 11 |
| Cache des préfixes | Réutilisation du calcul d'un début de requête déjà vu | 11 |
| Champ (d'un fait) | Population ou périmètre que couvre un chiffre | 12 |
| Condition témoin | Condition de comparaison sans le facteur étudié ; sans elle, une expérience ne prouve rien | 8 |
| Consigne vérifiable | Consigne dont le respect se contrôle par un programme | 8 |
| Décodage (phase de) | Production des tokens un par un, limitée par la bande passante mémoire | 11 |
| Décodage contraint | Génération où seuls les tokens conformes à une grammaire sont autorisés | 6 |
| Embedding | Vecteur qui situe un texte dans un espace de sens | 10 |
| Empreinte | Clé d'un appel, calculée par hachage sur l'adresse, l'étiquette et le corps de la requête | 4 |
| Enveloppe d'appel | Module unique par lequel passent tous les appels au modèle | 4 |
| Fenêtre de contexte | Nombre maximal de tokens que le modèle peut lire en un appel | 9 |
| Gabarit de conversation | Mise en forme des messages en un texte unique, propre à chaque modèle | 2 |
| Graine | Valeur initiale d'un générateur pseudo-aléatoire | 8 |
| Injection de consigne | Instructions cachées dans un contenu lu par le modèle | 7 |
| Intervalle de Wilson | Intervalle de confiance pour une proportion, valable près de 0 et de 1 | 13 |
| JSONL | Fichier qui contient un objet JSON par ligne | 4 |
| Modèle augmenté | Modèle de langage complété par une recherche documentaire, des outils et une mémoire | 1 |
| Plan factoriel | Plan d'expérience qui croise tous les niveaux de plusieurs facteurs | 9 |
| Préremplissage (prefill) | Lecture en parallèle de tous les tokens de la requête | 11 |
| Refactorisation | Changement de la structure du code sans changement de son comportement | 5 |
| Registre de faits | Base de chiffres sourcés, datés et définis, seule source des chiffres publiés | 1 |
| Règle de trois | Zéro événement en *n* essais borne le taux à environ 3/*n*, au niveau de 95 % | 13 |
| Rejeu | Relecture des réponses dans le journal, sans réseau ni clé | 4 |
| Secret secondaire | Masquage de cases supplémentaires pour empêcher de retrouver une case masquée par différence | 12 |
| Similarité cosinus | Cosinus de l'angle entre deux vecteurs | 10 |
| Sortie structurée | Réponse conforme à un format, par exemple un schéma JSON | 6 |
| Température | Paramètre qui concentre ou aplatit la distribution des tokens | 8 |
| Test de caractérisation | Test qui fige le comportement actuel d'un code pour détecter tout changement | 5 |
| Test de non-régression | Test qui vérifie qu'une modification n'abîme pas le comportement existant | 5 |
| Token | Morceau de texte pris dans le vocabulaire du modèle ; unité de compte du contexte, du débit et des quotas | 3 |
| Top-p | Échantillonnage par noyau : tirage limité au plus petit ensemble de tokens dont la probabilité cumulée atteint *p* | 8 |
| Workflow | Système où le modèle et les outils sont orchestrés par des chemins de code fixés à l'avance | 1 |

## Annexe E — Corrigé des questions

### Chapitre 1

1. Par exemple : la taille du contexte, qui fixe le budget d'entrée et décide du découpage des documents ; le support des sorties structurées, qui permet d'échanger des identifiants de faits en JSON ; le support des outils, qui fait du registre un outil ; la vitesse, qui conduit à des sorties courtes et à un nombre limité d'appels par agent.
2. Dans un workflow, le modèle et les outils sont orchestrés par des chemins de code fixés à l'avance. Dans un agent, le modèle dirige lui-même son processus et l'usage des outils.
3. La version, la configuration et la charge du modèle peuvent changer sans que notre code change. Ces changements n'apparaissent dans aucun diff ; seule une mesure rejouable, relancée régulièrement, les révèle.

### Chapitre 2

1. Une adresse de base n'est pas un point d'arrivée : aucune ressource n'y correspond. Le code 404 signifie « ressource introuvable » : la requête est bien arrivée, mais à une adresse qui n'existe pas. Il fallait `/api/models` ou `/api/chat/completions`.
2. Dix fois. Le serveur ne garde rien d'un appel à l'autre : chaque appel renvoie toute la conversation, et le modèle la relit entièrement. Un cache des préfixes peut économiser du calcul, mais les tokens sont quand même envoyés.
3. Il contient l'horodatage, la clé, l'étiquette, l'adresse, le chemin, le statut, la durée, le corps de la requête et la réponse. Il ne doit jamais contenir la clé d'API ni, dans le laboratoire public, la moindre donnée non publique.

### Chapitre 3

1. 120 000 / 4,85 ≈ 24 700 tokens : le texte dépasse le budget, avant même la consigne et le gabarit. Il faut vérifier, car un vrai texte, avec des chiffres et des sigles, compte souvent plus de tokens par caractère que notre remplissage. Le compte du serveur fait foi.
2. Le compte comprend une partie fixe (gabarit de conversation, question, aiguille), qui pèse proportionnellement plus quand le texte est court.
3. Les nombres sont découpés en morceaux de chiffres selon les règles du tokenizer : le modèle manipule des suites de symboles, pas des quantités.

### Chapitre 4

1. L'étiquette distingue deux requêtes au corps identique. Sans elle, `graine-1` et `graine-2` auraient la même clé. Au rejeu, les deux appels liraient la même entrée du journal, et le test conclurait toujours « identique », quoi que le serveur ait répondu.
2. Pour que deux dictionnaires égaux donnent le même texte, donc la même empreinte, quel que soit l'ordre de création de leurs clés.
3. Non. Il prouve que, pour des réponses données, le code produit toujours les mêmes relevés : le code est déterministe. La stabilité du modèle se mesure en relançant de vrais appels, au banc.

### Chapitre 5

1. Le relevé n'était pas encore suivi par Git, et `git diff` ne compare que les fichiers suivis : il n'y avait rien à comparer, donc rien à afficher.
2. Toutes les clés changeraient : les anciens appels ne seraient plus retrouvés dans le journal, et le rejeu s'arrêterait sur une `LookupError`. Il faudrait versionner la formule ou migrer le journal.
3. Le commit de refactorisation doit donner un rejeu identique ; celui des embeddings ajoute un comportement. Séparés, ils indiquent tout de suite lequel est en cause en cas de différence, et chacun se relit facilement.

### Chapitre 6

1. À chaque pas, le serveur calcule l'ensemble des tokens qui laissent la sortie conforme à la grammaire. Il met à zéro la probabilité des autres et tire parmi les tokens autorisés. Une sortie non conforme ne peut donc pas être produite, sauf troncature.
2. Exiger le schéma par `response_format` tout en demandant, dans la consigne, une réponse en prose, et répéter l'essai. Si la sortie reste conforme au schéma, la contrainte est imposée par le serveur ; si elle passe en prose, elle n'était que demandée.
3. Il n'a ni source, ni millésime, ni définition (population municipale ou totale, commune ou métropole). On ne peut ni le vérifier ni le citer.

### Chapitre 7

1. Notre code. Le modèle renvoie seulement une demande d'appel : le nom de la fonction et ses arguments, sous forme de texte JSON, dans `tool_calls`.
2. La consigne disait « Utilise l'outil ». Pour mesurer le jugement, on pose des questions sans cette mention, sur des cas variés, dont certains demandent l'outil et d'autres non, et l'on mesure le taux d'appels pertinents.
3. Les arguments sont produits par le modèle. Ils peuvent être mal formés, hors du domaine attendu, ou dangereux s'ils sont transmis tels quels à un programme. On les valide avec le schéma et une liste blanche.

### Chapitre 8

1. Quand la température tend vers 0, la distribution se concentre sur le token le plus probable : c'est le choix glouton. Quand elle augmente, la distribution s'aplatit et les tokens moins probables gagnent du poids.
2. On répète la même requête avec la même graine : les sorties doivent toujours être identiques. On la répète aussi avec des graines différentes : les sorties doivent souvent différer. Cette seconde condition est le témoin. Sans elle, on ne peut pas exclure qu'un modèle très sûr de lui donne toujours la même réponse, graine ou non.
3. Le programme recevrait `**Luvian**`, astérisques compris, et non le prénom. Parades : nettoyer la sortie (retirer la mise en forme), la refuser et la redemander, ou contraindre la sortie par un schéma.

### Chapitre 9

1. Pour que « 4721 » ne puisse venir que de l'aiguille : la présence de cette chaîne dans la réponse suffit alors à conclure, sans ambiguïté.
2. Non. Notre tâche était trop facile (une seule phrase avec des chiffres, très saillante) pour faire apparaître un effet de position. L'absence d'effet dans un test trop facile ne dit rien des tâches réalistes.
3. Ajouter des aiguilles multiples, des nombres pièges, un remplissage réaliste et des positions plus fines ; répéter chaque cellule ; randomiser l'ordre des essais ; utiliser un remplissage distinct pour chaque appel.

### Chapitre 10

1. Les représentations ne se répartissent pas uniformément dans l'espace (anisotropie) : même deux textes sans rapport ont une similarité positive. Le cosinus se lit par comparaison, jamais dans l'absolu.
2. Les vecteurs des deux modèles vivent dans des espaces différents. Les comparer n'a pas de sens, et la recherche renvoie des passages sans rapport avec la question. Il faut réindexer avec le modèle utilisé pour interroger.
3. Former des paires de phrases identiques à un montant près, et des paires de paraphrases au même montant. Mesurer les similarités, sur de nombreuses phrases. Vérifier si les paires à montants différents se distinguent des paraphrases.

### Chapitre 11

1. Le décodage relit tous les paramètres pour produire un seul token par requête : peu d'opérations par octet lu, c'est la bande passante mémoire qui limite. Le préremplissage réutilise chaque paramètre lu pour des milliers de tokens : c'est le calcul qui limite, et chaque token coûte beaucoup moins.
2. 10 000 / 19 000 ≈ 0,53 s de lecture et 400 / 156 ≈ 2,56 s d'écriture : environ 3,1 s.
3. Pour une taille donnée, les trois appels partagent le même remplissage, donc le même début de requête. Un serveur qui garde en cache les débuts déjà calculés accélérerait les appels suivants. On l'évite avec un remplissage distinct par appel et un ordre aléatoire.

### Chapitre 12

1. L'industrie est dans [17,65 ; 17,75] et le total dans [25,05 ; 25,15]. La part est donc dans [17,65 / 25,15 ; 17,75 / 25,05], soit [70,2 % ; 70,9 %], qui contient 70,7 %.
2. Les quatre programmes cités ne couvrent pas tout le champ des paiements : leur somme porte sur un champ partiel. Additionner des faits de champs différents n'a pas de sens.
3. Fonctionnalité minimale : « quel secteur reçoit le plus ? » doit citer le fait relatif à l'industrie. Invariance : reformuler la question ne change pas les faits cités. Attente directionnelle : demander les catégories d'entreprises au lieu des secteurs doit changer les faits cités (grandes entreprises, ETI).

### Chapitre 13

1. Avec *n* = 1 et *p̂* = 1 : centre = (1 + 1,92) / (1 + 3,84) ≈ 0,603 ; demi-largeur ≈ 0,405 × 0,98 ≈ 0,397. L'intervalle est [20,7 % ; 100 %] : on ne peut presque rien conclure.
2. Le taux d'échec est probablement inférieur à 3/50, soit 6 % (borne supérieure à 95 %). Ne rien observer en 50 essais reste compatible avec un taux d'échec de quelques pour cent.
3. Répéter la même question mesure la stabilité sur cette question ; varier les questions mesure la capacité sur une population de cas. Ce sont deux sources de variabilité différentes.

### Chapitre 14

1. Elle arrête la commande avec une erreur si `LLM_CLE` est vide ou absente. Sans elle, `grep` chercherait une chaîne vide : le contrôle ne vérifierait plus rien, et son résultat n'aurait aucun sens.
2. Non : elle reste dans l'historique et, si le dépôt a été poussé, elle est publique. Il faut la révoquer et en créer une nouvelle. Réécrire l'historique ne suffit pas, car des copies ont pu être faites.
3. `refactor: regrouper l'envoi et la journalisation dans _appeler`, puis `feat: embeddings et durées dans l'enveloppe d'appel`.

## Annexe F — Bibliographie

Toutes les références citées dans le cours, par ordre alphabétique. Les prépublications et les billets techniques sont signalés comme tels.

- Agrawal, A., Kedia, N., Panwar, A., Mohan, J., Kwatra, N., Gulavani, B. S., Tumanov, A., Ramjee, R. (2024). *Taming Throughput-Latency Tradeoff in LLM Inference with Sarathi-Serve*. 18th USENIX Symposium on Operating Systems Design and Implementation (OSDI 2024).
- Anthropic (2024). *Building effective agents*. Billet technique, 19 décembre 2024. https://www.anthropic.com/engineering/building-effective-agents
- Atil, B., Aykent, S., Chittams, A., Fu, L., Passonneau, R. J., Radcliffe, E., Rajagopal, G. R., Sloan, A., Tudrej, T., Ture, F., Wu, Z., Xu, L., Baldwin, B. (2025). *Non-Determinism of "Deterministic" LLM Settings*. Prépublication arXiv:2408.04667, version 5. https://arxiv.org/abs/2408.04667
- Blischak, J. D., Davenport, E. R., Wilson, G. (2016). *A Quick Introduction to Version Control with Git and GitHub*. PLoS Computational Biology, 12(1), e1004668. https://doi.org/10.1371/journal.pcbi.1004668
- Box, G. E. P., Hunter, J. S., Hunter, W. G. (2005). *Statistics for Experimenters: Design, Innovation, and Discovery*, 2e édition. Wiley. ISBN 978-0-471-71813-0
- Brown, L. D., Cai, T. T., DasGupta, A. (2001). *Interval Estimation for a Binomial Proportion*. Statistical Science, 16(2), p. 101–133. https://doi.org/10.1214/ss/1009213286
- Chen, J., Xiao, S., Zhang, P., Luo, K., Lian, D., Liu, Z. (2024). *BGE M3-Embedding: Multi-Lingual, Multi-Functionality, Multi-Granularity Text Embeddings Through Self-Knowledge Distillation*. Prépublication arXiv:2402.03216. https://arxiv.org/abs/2402.03216
- *Conventional Commits 1.0.0*. https://www.conventionalcommits.org/en/v1.0.0/
- Ethayarajh, K. (2019). *How Contextual are Contextualized Word Representations? Comparing the Geometry of BERT, ELMo, and GPT-2 Embeddings*. Proceedings of EMNLP-IJCNLP 2019, p. 55–65. https://doi.org/10.18653/v1/D19-1006
- Feathers, M. C. (2004). *Working Effectively with Legacy Code*. Prentice Hall. ISBN 978-0-13-117705-5
- Fowler, M., avec Beck, K. (2018). *Refactoring: Improving the Design of Existing Code*, 2e édition. Addison-Wesley. ISBN 978-0-13-475759-9
- Geng, S., Josifoski, M., Peyrard, M., West, R. (2023). *Grammar-Constrained Decoding for Structured NLP Tasks without Finetuning*. Proceedings of EMNLP 2023. https://aclanthology.org/2023.emnlp-main.674
- Hanley, J. A., Lippman-Hand, A. (1983). *If Nothing Goes Wrong, Is Everything All Right? Interpreting Zero Numerators*. JAMA, 249(13), p. 1743–1745. https://doi.org/10.1001/jama.1983.03330370053031
- Holtzman, A., Buys, J., Du, L., Forbes, M., Choi, Y. (2020). *The Curious Case of Neural Text Degeneration*. International Conference on Learning Representations (ICLR 2020). https://arxiv.org/abs/1904.09751
- Hsieh, C.-P., Sun, S., Kriman, S., Acharya, S., Rekesh, D., Jia, F., Zhang, Y., Ginsburg, B. (2024). *RULER: What's the Real Context Size of Your Long-Context Language Models?* Prépublication arXiv:2404.06654. https://arxiv.org/abs/2404.06654
- Hundepool, A., Domingo-Ferrer, J., Franconi, L., Giessing, S., Schulte Nordholt, E., Spicer, K., de Wolf, P.-P. (2012). *Statistical Disclosure Control*. Wiley. https://doi.org/10.1002/9781118348239
- Insee, *Courrier des statistiques* n° 9 (2023), « Confidentialité des données statistiques : un enjeu majeur pour le service statistique public », https://www.insee.fr/fr/information/7635823?sommaire=7635842
- Insee, *Guide du secret statistique* (mise à jour de septembre 2025), https://www.insee.fr/fr/statistiques/fichier/1300624/GUIDE%20DU%20SECRET%20STATISTIQUE%20MAJ%202509.pdf
- Insee, *Secret statistique*, https://www.insee.fr/fr/information/1300624
- Kamradt, G. (2023). *Needle In A Haystack — Pressure Testing LLMs*. Dépôt de code. https://github.com/gkamradt/LLMTest_NeedleInAHaystack
- Kudo, T. (2018). *Subword Regularization: Improving Neural Network Translation Models with Multiple Subword Candidates*. Proceedings of the 56th Annual Meeting of the ACL (vol. 1), p. 66–75. https://doi.org/10.18653/v1/P18-1007
- Kwon, W., Li, Z., Zhuang, S., Sheng, Y., Zheng, L., Yu, C. H., Gonzalez, J. E., Zhang, H., Stoica, I. (2023). *Efficient Memory Management for Large Language Model Serving with PagedAttention*. Proceedings of the 29th ACM Symposium on Operating Systems Principles (SOSP 2023). Code : https://github.com/vllm-project/vllm
- Liang, P., Bommasani, R., Lee, T., et al. (2023). *Holistic Evaluation of Language Models*. Transactions on Machine Learning Research. https://arxiv.org/abs/2211.09110
- Liu, N. F., Lin, K., Hewitt, J., Paranjape, A., Bevilacqua, M., Petroni, F., Liang, P. (2024). *Lost in the Middle: How Language Models Use Long Contexts*. Transactions of the Association for Computational Linguistics, 12. https://arxiv.org/abs/2307.03172
- Meli, M., McNiece, M. R., Reaves, B. (2019). *How Bad Can It Git? Characterizing Secret Leakage in Public GitHub Repositories*. NDSS Symposium 2019. https://doi.org/10.14722/ndss.2019.23418
- Miller, E. (2024). *Adding Error Bars to Evals: A Statistical Approach to Language Model Evaluations*. Prépublication arXiv:2411.00640. https://arxiv.org/abs/2411.00640
- Muennighoff, N., Tazi, N., Magne, L., Reimers, N. (2022). *MTEB: Massive Text Embedding Benchmark*. Prépublication arXiv:2210.07316. https://arxiv.org/abs/2210.07316
- National Institute of Standards and Technology (2015). *FIPS PUB 180-4: Secure Hash Standard (SHS)*. https://doi.org/10.6028/NIST.FIPS.180-4
- Petrov, A., La Malfa, E., Torr, P. H. S., Bibi, A. (2023). *Language Model Tokenizers Introduce Unfairness Between Languages*. Advances in Neural Information Processing Systems 36 (NeurIPS 2023). https://arxiv.org/abs/2305.15425
- Pope, R., Douglas, S., Chowdhery, A., Devlin, J., Bradbury, J., Heek, J., Xiao, K., Agrawal, S., Dean, J. (2023). *Efficiently Scaling Transformer Inference*. Proceedings of Machine Learning and Systems 5 (MLSys 2023), p. 606–624. https://proceedings.mlsys.org/paper_files/paper/2023/hash/c4be71ab8d24cdfb45e3d06dbfca2780-Abstract-mlsys2023.html
- Reimers, N., Gurevych, I. (2019). *Sentence-BERT: Sentence Embeddings using Siamese BERT-Networks*. Proceedings of EMNLP-IJCNLP 2019. https://arxiv.org/abs/1908.10084
- Ribeiro, M. T., Wu, T., Guestrin, C., Singh, S. (2020). *Beyond Accuracy: Behavioral Testing of NLP Models with CheckList*. Proceedings of the 58th Annual Meeting of the ACL (ACL 2020). Code : https://github.com/marcotcr/checklist
- Sandve, G. K., Nekrutenko, A., Taylor, J., Hovig, E. (2013). *Ten Simple Rules for Reproducible Computational Research*. PLoS Computational Biology, 9(10), e1003285. https://doi.org/10.1371/journal.pcbi.1003285
- Schick, T., Dwivedi-Yu, J., Dessì, R., Raileanu, R., Lomeli, M., Hambro, E., Zettlemoyer, L., Cancedda, N., Scialom, T. (2023). *Toolformer: Language Models Can Teach Themselves to Use Tools*. Advances in Neural Information Processing Systems 36 (NeurIPS 2023). https://arxiv.org/abs/2302.04761
- Sculley, D., Holt, G., Golovin, D., Davydov, E., Phillips, T., Ebner, D., Chaudhary, V., Young, M., Crespo, J.-F., Dennison, D. (2015). *Hidden Technical Debt in Machine Learning Systems*. Advances in Neural Information Processing Systems 28 (NIPS 2015), p. 2503–2511. https://papers.nips.cc/paper/5656-hidden-technical-debt-in-machine-learning-systems
- Sennrich, R., Haddow, B., Birch, A. (2016). *Neural Machine Translation of Rare Words with Subword Units*. Proceedings of the 54th Annual Meeting of the ACL (vol. 1), p. 1715–1725. https://doi.org/10.18653/v1/P16-1162
- Tam, Z. R., et al. (2024). *Let Me Speak Freely? A Study on the Impact of Format Restrictions on Performance of Large Language Models*. EMNLP 2024 (Industry Track). https://arxiv.org/abs/2408.02442
- Thinking Machines Lab (2025). *Defeating Nondeterminism in LLM Inference*. Billet technique. https://thinkingmachines.ai/blog/defeating-nondeterminism-in-llm-inference/
- Vaswani, A., Shazeer, N., Parmar, N., Uszkoreit, J., Jones, L., Gomez, A. N., Kaiser, Ł., Polosukhin, I. (2017). *Attention Is All You Need*. Advances in Neural Information Processing Systems 30 (NIPS 2017), p. 5998–6008. https://papers.nips.cc/paper/7181-attention-is-all-you-need
- Willard, B. T., Louf, R. (2023). *Efficient Guided Generation for Large Language Models*. Prépublication arXiv:2307.09702. https://arxiv.org/abs/2307.09702
- Williams, S., Waterman, A., Patterson, D. (2009). *Roofline: An Insightful Visual Performance Model for Multicore Architectures*. Communications of the ACM, 52(4), p. 65–76. https://cacm.acm.org/research/roofline-an-insightful-visual-performance-model-for-multicore-architectures/
- Wilson, E. B. (1927). *Probable Inference, the Law of Succession, and Statistical Inference*. Journal of the American Statistical Association, 22, p. 209–212.
- Wilson, G., Bryan, J., Cranston, K., Kitzes, J., Nederbragt, L., Teal, T. K. (2017). *Good enough practices in scientific computing*. PLoS Computational Biology, 13(6), e1005510. https://doi.org/10.1371/journal.pcbi.1005510
- Yao, S., Zhao, J., Yu, D., Du, N., Shafran, I., Narasimhan, K., Cao, Y. (2023). *ReAct: Synergizing Reasoning and Acting in Language Models*. International Conference on Learning Representations (ICLR 2023). https://arxiv.org/abs/2210.03629
- Yoo, S., Harman, M. (2012). *Regression testing minimization, selection and prioritization: a survey*. Software Testing, Verification and Reliability, 22(2), p. 67–120. https://doi.org/10.1002/stvr.430
- Zhou, J., Lu, T., Mishra, S., Brahma, S., Basu, S., Luan, Y., Zhou, D., Hou, L. (2023). *Instruction-Following Evaluation for Large Language Models*. Prépublication arXiv:2311.07911. https://arxiv.org/abs/2311.07911
