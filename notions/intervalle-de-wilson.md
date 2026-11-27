---
title: "Intervalle de Wilson"
subtitle: "Lire un taux mesuré sur peu d'essais, sans lui faire dire plus qu'il ne sait"
date: 2026-11-27
toc: true
toc-depth: 3
---

*Ce cours explique pourquoi un taux observé ne se lit jamais seul, et comment calculer l'intervalle qui l'accompagne. Il reprend le [chapitre 13 du cours de la séance 1](/cours/seance-01-cours.md#chapitre-13), « Un essai ne prouve rien ».*

*« Le serveur » y désigne le serveur de modèles du laboratoire, dont chaque capacité venait d'être testée une seule fois, et « le banc » le banc de fiabilité, qui a répété ces tests à la séance 2. Deux chapitres prolongent ce cours : le [chapitre 7 du cours de la séance 2](/cours/seance-02-cours.md#chapitre-7) compare Wald et Wilson sur les taux du banc et ajoute le test de McNemar, et le [chapitre 6 du cours de la séance 3](/cours/seance-03-cours.md#chapitre-6) donne la borne basse quand tous les essais réussissent.*

## Ce que nous avons fait

Chaque capacité du serveur a été testée **une fois**, et chaque test a réussi. Le bilan de séance le signalait : un essai par capacité donne un indice, pas un taux. Ce cours explique pourquoi, chiffres à l'appui.

## Pourquoi un intervalle

Nous allons prendre des décisions d'architecture à partir de taux observés. Par exemple : « le serveur impose le schéma », ou « le modèle appelle le registre quand il le faut dans au moins 95 % des cas ». Un taux sans incertitude est un piège, et les évaluations de modèles de langage portent souvent sur de petits effectifs.

## Comment ça marche

### Le modèle statistique

Chaque essai est une épreuve de Bernoulli de probabilité de succès *p*, inconnue. On observe *k* succès en *n* essais ; l'estimateur naturel est *p̂ = k/n*. Toute la question est l'incertitude autour de *p̂*.

### L'intervalle de Wald, et pourquoi l'éviter

L'intervalle enseigné en premier, *p̂ ± z √(p̂(1 − p̂)/n)*, s'effondre aux bords. Avec 1 succès en 1 essai, *p̂ = 1* et la largeur est nulle : l'intervalle [100 % ; 100 %] prétendrait à la certitude. Brown, Cai et DasGupta (2001) ont montré que sa probabilité de couverture est erratique et souvent bien inférieure à son niveau annoncé, y compris pour de grands échantillons. Ils recommandent l'intervalle de Wilson, ou celui de Jeffreys, pour les petits *n*, et celui d'Agresti et Coull pour les plus grands.

### L'intervalle de Wilson

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

### La règle de trois

Quand aucun échec n'est observé en *n* essais, la borne supérieure à 95 % du taux d'échec vaut environ **3/n**. Hanley et Lippman-Hand (1983) l'ont popularisée dans un article au titre parlant : « Si rien ne va mal, tout va-t-il bien ? ». Pour 50 essais sans échec, le taux d'échec est inférieur à environ 6 % (5,8 % par le calcul exact). Wilson donne 7,1 % : la méthode est différente et un peu plus prudente. L'essentiel est ailleurs : **zéro échec observé ne veut pas dire zéro échec.**

### Combien d'essais ?

Pour estimer un taux voisin de 90 % à ±10 points près, il faut environ 35 essais ; à ±5 points près, environ 139 (par l'approximation normale, *n = z² p(1 − p) / E²*). Avec une cinquantaine d'essais par test, la précision est d'environ ±8 points autour de 90 %. C'est le compromis retenu pour le banc.

### Deux sources de variabilité

Miller (2024) rappelle qu'évaluer un modèle, c'est tirer des questions dans une population de questions possibles. À cela s'ajoute le hasard propre au modèle sur chaque question. D'où deux protocoles qui ne mesurent pas la même chose :

- **répéter cinquante fois la même requête** mesure la **stabilité** du serveur et du modèle sur cette requête ;
- **poser cinquante requêtes différentes** mesure la **capacité** du modèle sur une population de cas.

Miller recommande de publier une erreur type avec chaque score. Il recommande aussi des erreurs types groupées quand les questions forment des familles liées, et des comparaisons appariées quand deux modèles passent les mêmes questions.

## Ce que nous avons observé

- Quatre capacités, un essai chacune, quatre succès. Chacune a pour intervalle de Wilson [20,7 % ; 100 %].
- Les valeurs de contrôle prévues pour la fonction de Wilson du carnet de bord sont correctes : 2 sur 60 donne [0,9 % ; 11,4 %], 0 sur 100 donne [0,0 % ; 3,7 %] et 5 sur 100 donne [2,2 % ; 11,2 %].

## Pièges et bonnes pratiques

- **Annoncer 100 %** après une poignée d'essais.
- **Utiliser l'intervalle de Wald** près de 0 ou de 1.
- **Appeler « capacité » ce qui n'est qu'une répétition** de la même requête.
- **Multiplier les tests** sans s'attendre à ce que certains échouent par hasard.
- **Supposer les essais indépendants** alors qu'ils sont lancés au même moment sur un serveur partagé. On répartit les essais dans le temps et l'on mélange leur ordre.

> **À retenir.** Un taux sans intervalle ne vaut rien. L'intervalle de Wilson reste correct près de 0 et de 1, contrairement à celui de Wald. Après un seul succès, le vrai taux peut descendre à 21 %. Zéro échec en *n* essais borne le taux d'échec à environ 3/*n*, pas à zéro. Répéter une requête mesure la stabilité ; varier les requêtes mesure la capacité.

## Pour vérifier que vous avez compris

1. Calculez l'intervalle de Wilson pour 1 succès en 1 essai. Que peut-on conclure ?
2. Aucun échec en 50 essais : que dit la règle de trois ? Pourquoi n'est-ce pas « 0 % d'échec » ?
3. Quelle différence entre répéter cinquante fois la même question et poser cinquante questions différentes ?

Les réponses sont [à la fin de ce cours](#corrige).

## Références

- Wilson, E. B. (1927). *Probable Inference, the Law of Succession, and Statistical Inference*. Journal of the American Statistical Association, 22, p. 209–212. — **Ce qu'on y apprend :** l'intervalle obtenu en retournant le test du score, qui reste valable près de 0 et de 1.
- Brown, L. D., Cai, T. T., DasGupta, A. (2001). *Interval Estimation for a Binomial Proportion*. Statistical Science, 16(2), p. 101–133. https://doi.org/10.1214/ss/1009213286 — **Ce qu'on y apprend :** pourquoi l'intervalle de Wald couvre mal, et quels intervalles choisir selon la taille de l'échantillon.
- Hanley, J. A., Lippman-Hand, A. (1983). *If Nothing Goes Wrong, Is Everything All Right? Interpreting Zero Numerators*. JAMA, 249(13), p. 1743–1745. https://doi.org/10.1001/jama.1983.03330370053031 — **Ce qu'on y apprend :** comment interpréter l'absence d'événement, et la règle de trois.
- Pour aller plus loin : Miller, E. (2024). *Adding Error Bars to Evals: A Statistical Approach to Language Model Evaluations*. Prépublication arXiv:2411.00640. https://arxiv.org/abs/2411.00640 — **Ce qu'on y apprend :** comment appliquer ces outils à l'évaluation des modèles de langage.

## Corrigé des questions {#corrige}

1. Avec *n* = 1 et *p̂* = 1 : centre = (1 + 1,92) / (1 + 3,84) ≈ 0,603 ; demi-largeur ≈ 0,405 × 0,98 ≈ 0,397. L'intervalle est [20,7 % ; 100 %] : on ne peut presque rien conclure.
2. Le taux d'échec est probablement inférieur à 3/50, soit 6 % (borne supérieure à 95 %). Ne rien observer en 50 essais reste compatible avec un taux d'échec de quelques pour cent.
3. Répéter la même question mesure la stabilité sur cette question ; varier les questions mesure la capacité sur une population de cas. Ce sont deux sources de variabilité différentes.
