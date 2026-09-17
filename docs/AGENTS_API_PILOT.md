# Pilote Agents API — maintenance assistée de Tech Empire

## Objectif

Ce pilote permet de demander à un agent de préparer une petite évolution du jeu depuis GitHub, même sans avoir le projet Godot sur le PC utilisé. Il ne fait pas partie du jeu distribué aux joueurs et ne rend pas Tech Empire dépendant d'un LLM.

Le pilote est volontairement limité à la vertical slice CPU et à des tâches courtes et vérifiables.

## Flux sécurisé en deux validations

### 1. Produire une proposition sans accès GitHub en écriture

Le workflow **Agent API - Préparer une proposition** :

1. récupère le commit courant sans conserver les identifiants GitHub ;
2. vérifie que la base Godot et le smoke test sont sains ;
3. crée une session Agents API ;
4. connecte un exécuteur Codex dans un conteneur Docker temporaire ;
5. autorise l'agent à modifier uniquement la copie de travail ;
6. collecte un patch, le rapport, les événements et la liste des fichiers ;
7. publie le tout comme artefact GitHub pendant 14 jours.

À cette étape, l'agent ne possède pas le `GITHUB_TOKEN`, ne peut ni committer, ni pousser, ni créer de PR.

### 2. Créer une PR uniquement après revue humaine

Après lecture de l'artefact, le workflow **Agent API - Créer la PR validée** demande :

- le Run ID de la proposition ;
- le titre souhaité ;
- la confirmation explicite `CREER LA PR`.

Le workflow revalide le patch, refuse les fichiers d'infrastructure, crée une branche `agent/proposal-<run-id>` puis ouvre une Pull Request **brouillon**. Il ne lance aucun code provenant du patch avec un jeton en écriture. La CI Godot standard s'exécute ensuite avec des droits en lecture seule.

La fusion reste toujours manuelle.

## Configuration initiale

Deux clés distinctes sont nécessaires. Ne jamais les enregistrer dans le dépôt.

### Clé d'application

Dans le projet OpenAI Platform utilisé pour le pilote, créer une clé d'application avec uniquement :

- `api.agents.read` ;
- `api.agents.write` ;
- `api.responses.write`.

L'ajouter dans **GitHub → Settings → Secrets and variables → Actions → New repository secret** sous le nom :

```text
OPENAI_API_KEY
```

### Clé d'environnement

Dans l'onglet Agents du même projet OpenAI, créer une clé d'environnement restreinte. Toutes les autres permissions doivent rester à `None`.

L'ajouter aux secrets GitHub sous le nom :

```text
OPENAI_EXECUTOR_API_KEY
```

Cette clé est la seule transmise au conteneur de travail. Elle permet de connecter l'exécuteur à l'environnement, mais pas d'appeler les autres API.

### Modèle optionnel

Le modèle par défaut du pilote est `gpt-6-astra`, conformément à l'exemple actuel de l'Agents API. Pour en utiliser un autre qui est autorisé dans le projet OpenAI, créer une **variable GitHub Actions** :

```text
OPENAI_AGENT_MODEL
```

Le coût dépend du modèle et de la durée du travail. Le workflow impose une durée maximale et ne se lance jamais automatiquement.

## Utilisation

1. Ouvrir l'onglet **Actions** du dépôt.
2. Choisir **Agent API - Préparer une proposition**.
3. Cliquer sur **Run workflow** et saisir une tâche petite, précise et testable.
4. Attendre la fin du workflow et noter son Run ID.
5. Télécharger `agent-proposal-<run-id>`.
6. Lire au minimum `report.md`, `validation.txt`, `changed-files.txt` et `changes.patch`.
7. Si la proposition convient, lancer **Agent API - Créer la PR validée**.
8. Fournir le Run ID, le titre et sélectionner `CREER LA PR`.
9. Relire la PR brouillon et attendre la CI Godot avant toute fusion.

Exemple de tâche adaptée :

> Ajouter au système de fabrication CPU un contrat de fonderie simplifié avec trois niveaux de capacité, préserver les sauvegardes V6 et étendre le smoke test.

Éviter les demandes vagues comme « améliore tout le jeu ».

## Protections appliquées

- déclenchement manuel uniquement ;
- checkout sans identifiants persistants pendant le travail de l'agent ;
- conteneur Docker éphémère, capacités Linux supprimées et système interne en lecture seule ;
- clé OpenAI d'application conservée hors du conteneur ;
- aucune clé GitHub disponible dans le conteneur ;
- durée, mémoire, processeurs et nombre de processus limités ;
- refus des modifications de `.github/`, `tools/agents/`, `AGENTS.md` et des fichiers de configuration Git ;
- types et taille des fichiers contrôlés deux fois ;
- aucun commit automatique lors de la phase de proposition ;
- PR toujours créée en brouillon ;
- aucune fusion automatique.

Ces protections réduisent le risque mais ne remplacent jamais la lecture humaine du patch.

## Limites actuelles

- Le pilote utilise une API en bêta susceptible d'évoluer.
- La première exécution peut être lente car l'image Docker doit être construite.
- Les tests headless ne remplacent pas une vérification visuelle sous Windows et Android.
- Le réseau nécessaire à la connexion de l'exécuteur existe ; aucun secret du dépôt ne doit donc être placé dans la copie de travail.
- Les images, sons et gros fichiers binaires sont volontairement refusés.
- Une proposition expirée après 14 jours doit être régénérée.

## Documentation officielle

- [Agents API — démarrage](https://developers.openai.com/api/docs/guides/agents-api/quickstart)
- [Environnements auto-hébergés](https://developers.openai.com/api/docs/guides/agents-api/environments/self-hosted)
- [Sécurité des environnements](https://developers.openai.com/api/docs/guides/agents-api/environments/security)
