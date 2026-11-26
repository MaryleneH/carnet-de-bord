---
title: "LangGraph"
subtitle: "Un graphe d'états pas à pas, sur un exemple jouet : nœuds, réducteurs, sauvegardes, pause humaine et reprise"
date: 2026-11-26
toc: true
toc-depth: 3
---

*Ce cours présente LangGraph pas à pas. Son exemple jouet tourne en une seconde, sans modèle de langue, sans clé ni réseau. Il a été exécuté avec les versions épinglées au [chapitre 8 du cours de la séance 3](/cours/seance-03-cours.md#chapitre-8), et les sorties reproduites ici sont les siennes.*

*Il reprend le [chapitre 9](/cours/seance-03-cours.md#chapitre-9) de ce même cours. « Notre graphe » y désigne le graphe du laboratoire, que les [chapitres 10 à 12](/cours/seance-03-cours.md#chapitre-10) lisent, puis exécutent : trois nœuds qui rédigent un texte, font vérifier ses chiffres par le code, puis attendent la décision d'une personne.*

## Ce que nous avons fait

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

## Pourquoi LangGraph

### Le problème que LangGraph résout

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

Ajouter ces capacités à la main, c'est écrire un petit moteur : sauvegarder l'état après chaque étape, savoir où reprendre, gérer l'attente, puis éprouver le tout. C'est l'option que l'`ADR-003`, la décision d'architecture du laboratoire sur ce point, a écartée.

### Ce qu'est LangGraph

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

### D'où vient l'idée

Deux traditions de l'informatique se rejoignent dans LangGraph.

- **Les machines à états.** Harel (1987) a proposé les *statecharts* pour décrire un système qui réagit à des événements. Le système y est représenté par des états, des transitions et des conditions, dessinés plutôt qu'enfouis dans des boucles et des drapeaux. Un graphe LangGraph se lit de la même façon, et se dessine ([chapitre 10 du cours de la séance 3](/cours/seance-03-cours.md#chapitre-10)).
- **Le calcul par super-étapes.** Valiant (1990) a proposé le modèle BSP, pour *bulk synchronous parallel*. Un calcul parallèle y avance par super-étapes : des calculs locaux, des échanges de messages, puis une barrière de synchronisation. Malewicz et ses coauteurs (2010) en ont tiré Pregel, le système de Google pour les très grands graphes. Dans le code de LangGraph, le moteur s'appelle justement `Pregel`. Il exécute les nœuds par super-étapes, et c'est entre deux super-étapes, quand l'état est complet et cohérent, qu'il le sauvegarde.

## Comment ça marche

> **Exemple.** Imaginez un dossier qui circule de bureau en bureau. Le dossier, c'est l'état. Chaque bureau est un nœud : il lit le dossier, puis rend une note qui dit seulement ce qui change. Le circuit de visa, ce sont les arêtes. À chaque passage de relève, on photocopie le dossier et on range la copie dans une armoire, sous le numéro du dossier : ce sont la sauvegarde et le fil. Quand il faut la signature du chef, le dossier attend dans la corbeille « à signer » : c'est l'interruption.

### 1. L'état : le dossier qui circule

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

### 2. Les nœuds : des fonctions qui rendent ce qu'elles changent

```python
def verifier(etat):
    anomalies = [] if "25,1 Md€" in etat["brouillon"] else ["montant absent de la fiche"]
    return {"anomalies": anomalies, "journal": [f"verifier : {len(anomalies)} anomalie(s)"]}
```

Un nœud reçoit l'état et rend un dictionnaire qui ne contient que les champs qu'il change : une **mise à jour partielle**. Il ne modifie jamais l'état reçu. C'est LangGraph qui applique la mise à jour, et c'est ce qui lui permet de la sauvegarder.

> **Définition.** Une *mise à jour partielle* est le dictionnaire rendu par un nœud : seulement les champs qu'il change, avec leur nouvelle valeur. LangGraph la fusionne dans l'état, champ par champ, selon le réducteur de chaque champ.

### 3. Les réducteurs : la règle d'écriture

> **Formule.** Pour chaque champ, nouvelle valeur = réducteur(ancienne valeur, mise à jour). Le réducteur par défaut rend la mise à jour : la nouvelle valeur remplace l'ancienne. Avec `Annotated[list, operator.add]`, le réducteur est l'addition des listes, c'est-à-dire leur concaténation : `["a"] + ["b"]` donne `["a", "b"]`.

Les réducteurs ont deux usages. Le premier est de tenir un journal : notre graphe garde ainsi la liste de ses appels au modèle (`appels`) et celle des décisions humaines (`decisions`). Le second concerne les nœuds qui s'exécutent en parallèle dans la même super-étape. Si deux nœuds écrivent le même champ sans réducteur, LangGraph refuse : `InvalidUpdateError: At key 'x': Can receive only one value per step. Use an Annotated key to handle multiple values.` Avec `operator.add`, les deux valeurs sont réunies.

### 4. Les arêtes : le circuit

```python
constructeur.add_edge(START, "rediger")
constructeur.add_edge("rediger", "verifier")
constructeur.add_conditional_edges("verifier", apres_verifier, ["rediger", "valider"])
constructeur.add_conditional_edges("valider", apres_valider, ["rediger", END])


def apres_verifier(etat):
    return "rediger" if etat["anomalies"] and etat["tours"] < 3 else "valider"
```

Une arête fixe dit « toujours ensuite ». Une arête conditionnelle appelle une fonction, l'**aiguillage**, qui lit l'état et rend le nom du nœud suivant. La liste en troisième argument déclare les destinations possibles : LangGraph s'en sert pour dessiner le graphe. `START` et `END` sont deux nœuds spéciaux, l'entrée et la sortie.

### 5. La compilation, puis l'exécution par super-étapes

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

### 6. La sauvegarde et les fils

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

Quand l'instantané est-il écrit sur le disque ? Le paramètre `durability` le règle. Avec `"exit"`, à la fin de l'exécution seulement. Avec `"async"`, la valeur par défaut, pendant que l'étape suivante s'exécute. Avec `"sync"`, avant qu'elle ne commence. Le [chapitre 12 du cours de la séance 3](/cours/seance-03-cours.md#chapitre-12) y revient, avec la panne.

### 7. L'interruption, puis la reprise

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

### 8. Le jouet, en entier

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

## Ce que nous avons observé

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

## Du jouet à notre graphe

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

## Pièges et bonnes pratiques

- **Modifier l'état en place** au lieu de rendre une mise à jour : le tableau ci-dessus montre que le résultat devient incohérent.
- **Oublier le réducteur** d'un champ qui doit s'allonger : il ne garde que la dernière valeur.
- **Rendre l'état entier** au lieu des seuls champs modifiés : avec un réducteur `operator.add`, la liste rendue, qui contient déjà les anciennes lignes, s'ajouterait à l'ancienne. Essayé sur le jouet, un journal `["a"]` devient `["a", "a", "b"]`.
- **Relancer un fil existant avec une nouvelle entrée** : les réducteurs mélangent deux rédactions.
- **Placer une action avant `interrupt()`** : elle serait refaite à chaque reprise.
- **Entourer `interrupt()` d'un `try … except Exception`** : la pause disparaît.
- **Compter sur la limite par défaut pour arrêter une boucle** : à 10 007 super-étapes, elle laisserait le modèle tourner longtemps. C'est au graphe de borner ses tours.
- **Utiliser `InMemorySaver` en comptant reprendre après un arrêt** : la mémoire meurt avec le processus.

> **À retenir.** Un graphe LangGraph, c'est un état, des nœuds et des arêtes. Un nœud rend ce qu'il change ; un réducteur dit comment fusionner. Le moteur avance par super-étapes et sauvegarde l'état à chaque frontière, sous le nom d'un fil. `interrupt()` met le graphe en pause dans sa sauvegarde ; `Command(resume=…)` le reprend, en relançant le nœud depuis son début. LangGraph garantit l'ordre des étapes et la reprise, pas le contenu des textes.

## Pour vérifier que vous avez compris

1. On ajoute `print("appel coûteux")` juste avant `interrupt()`, dans `valider`. Combien de fois s'affiche-t-il pour un fil validé du premier coup ? Et pour un fil où l'humain demande une correction, puis valide ?
2. Dans le jouet, `valider` s'est exécuté deux fois. Pourquoi l'historique ne compte-t-il qu'un seul instantané après `valider`, l'étape 5 ?

Les réponses sont [à la fin de ce cours](#corrige).

## Références

- Harel, D. (1987). *Statecharts: A visual formalism for complex systems*. Science of Computer Programming, 8(3), p. 231–274. https://doi.org/10.1016/0167-6423(87)90035-9 — **Ce qu'on y apprend :** décrire un système par ses états, ses transitions et leurs conditions, et le dessiner.
- Valiant, L. G. (1990). *A bridging model for parallel computation*. Communications of the ACM, 33(8), p. 103–111. https://doi.org/10.1145/79173.79181 — **Ce qu'on y apprend :** le modèle BSP, où un calcul avance par super-étapes séparées par des barrières de synchronisation.
- Malewicz, G., Austern, M. H., Bik, A. J. C., Dehnert, J. C., Horn, I., Leiser, N., Czajkowski, G. (2010). *Pregel: A System for Large-Scale Graph Processing*. Proceedings of SIGMOD 2010, p. 135–146. https://doi.org/10.1145/1807167.1807184 — **Ce qu'on y apprend :** le calcul sur graphe par super-étapes, dont le moteur de LangGraph reprend le nom et le principe.
- LangChain. *Graph API overview*, *Persistence* et *Interrupts*. Documentation de LangGraph. https://docs.langchain.com/oss/python/langgraph/graph-api — **Ce qu'on y apprend :** l'état, les réducteurs, les arêtes, les sauvegardes, les fils et les interruptions, dans la version actuelle.

## Corrigé des questions {#corrige}

1. Validé du premier coup : deux fois, avant la pause puis à la reprise. Correction puis validation : quatre fois. Une au lancement ; une à la reprise « corriger », qui relance le nœud ; une au retour dans `valider` après le nouveau tour, avant la seconde pause ; une à la reprise « valider ».
2. La première exécution a été interrompue : le nœud n'a pas fini, sa super-étape non plus, et aucun instantané n'a été écrit. L'instantané 4 est resté le dernier, avec la tâche en attente. Seule la seconde exécution, complète, a conclu la super-étape et produit l'instantané 5.
