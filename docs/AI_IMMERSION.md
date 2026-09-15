# IA et immersion

## Principe

L'IA générative ne doit jamais être la source de vérité de la simulation. Le moteur Godot calcule les finances, marchés, décisions stratégiques, production, ventes, événements et règles du jeu. L'IA transforme ensuite ces données en interactions naturelles et crédibles.

## Architecture cible

### Couche 1 — Simulation déterministe

Responsable de :

- économie ;
- demande ;
- parts de marché ;
- production ;
- R&D ;
- décisions concurrentes ;
- acquisitions ;
- contrats ;
- événements ;
- conséquences des décisions.

Cette couche doit fonctionner même sans accès à une IA externe.

### Couche 2 — Agents stratégiques simulés

Chaque concurrent possède un profil durable :

- priorités ;
- tolérance au risque ;
- budget ;
- technologies ;
- marchés préférés ;
- historique ;
- relations ;
- objectifs à court et long terme.

Les décisions sont calculées par le jeu. L'IA générative ne fait qu'enrichir leur présentation.

### Couche 3 — IA générative d'immersion

Utilisations possibles :

- assistant du joueur ;
- conseil financier / technique ;
- rapports ;
- réunions ;
- communication de concurrents ;
- négociations ;
- presse ;
- analystes ;
- réactions clients ;
- événements narratifs contextualisés.

## Assistant du joueur

L'assistant reçoit uniquement les informations autorisées de la partie et peut répondre à des questions comme :

- Pourquoi nos ventes baissent-elles ?
- Peut-on financer une nouvelle usine ?
- Quel segment est le plus rentable ?
- Quel concurrent nous menace le plus ?
- Que risque-t-on si nous baissons les prix de 15 % ?
- Est-il préférable d'acheter ce fournisseur ou de signer un contrat ?

L'assistant doit citer ou résumer les données de simulation qui motivent sa réponse.

## Concurrents

Une entreprise adverse peut disposer d'une personnalité visible, mais sa stratégie reste ancrée dans ses données.

Exemple :

La simulation décide qu'une société abandonne l'entrée de gamme, investit dans l'IA et rachète un fabricant de puces. L'IA générative peut alors produire une annonce, des réactions de presse et une déclaration de son dirigeant cohérentes avec cette décision.

## Fonctionnement hors ligne / coût

Le jeu doit rester jouable sans LLM.

Stratégie envisagée :

- règles et modèles locaux pour la simulation ;
- texte pré-écrit / templates quand l'IA n'est pas disponible ;
- IA générative optionnelle pour enrichir l'expérience ;
- cache des réponses et résumés lorsque pertinent ;
- quotas et fréquence limitée sur mobile ;
- possibilité future d'utiliser un modèle local sur PC.

## Garde-fous de design

- une réponse IA ne modifie jamais directement l'état économique ;
- toute action importante repasse par une commande validée par le moteur ;
- les concurrents ne reçoivent pas d'informations auxquelles ils ne devraient pas avoir accès ;
- l'IA ne doit pas pouvoir créer gratuitement de ressources ou contourner les règles ;
- le jeu doit pouvoir expliquer les décisions importantes via des données structurées, même sans IA.

## Première version

La V0.1 ne nécessite pas encore de LLM.

Ordre recommandé :

1. simulation économique fonctionnelle ;
2. concurrents avec profils et décisions simples ;
3. journal d'événements structuré ;
4. assistant textuel à partir des données ;
5. connexion éventuelle à un LLM ;
6. enrichissement des concurrents et négociations.
