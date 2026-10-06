# P0/P1 — validation du 6 octobre 2026

## Résultat

Le parcours CPU + Software et les corrections financières sont implémentés sur
`codex/p0-p1-project-reliability`, basé sur `v010/gameplay-r2` et sa correction
R2.1 `cca2caa`. Aucun nouveau marché n'est ajouté. La copie de travail RC2
préexistante a été conservée, isolée et testée ; voir `P0_P1_RC2_BASELINE.md`.

- CPU : normalisation des anciens départements, refus distincts et chiffrés,
  premier mois et frais initiaux calculés comme les paiements réels, affichage
  du coût mensuel réel plutôt que de l'intensité de recherche.
- Software : support de douze mois par licence, ventes historiques conservées,
  dépenses du dernier mois distinguées du barème actuel, seuils cohérents.
- Sauvegarde 34 : migration idempotente, cohortes et projets CPU/Software
  persistants. La protection contre un second paiement du mois au rechargement
  fait partie de la base RC2 conservée.
- Nouveau projet CPU/Software accessible pendant un projet actif, suivi compact
  dans le garage, décisions de phase et partage de l'équipe R1/R2 conservés.

## Preuves PC

Quinze suites ont passé aux étapes concernées : `project_finance_test`,
`second_cpu_budget_test`, `save_clock_lifecycle_test`, `complete_experience_test`,
`software_manager_test`, `software_gameplay_test`, `software_integration_test`,
`complete_layout_test`, `garage_layout_test`, `workshop_layout_test`,
`project_cockpit_test`, `gameplay_r2_test`, `smoke_test`, `branding_config_test`
et `balance_ceiling_test`.

Les derniers changements d'interface ont été contrôlés par les suites de mise
en page et le contrôle général. Le dernier message de refus fournisseur a été
contrôlé par import, démarrage, test financier et contrôle général. Ces contrôles
vérifient aussi l'absence d'erreurs de script, au-delà du code de sortie.

Les exports GitHub ont réussi lors du premier passage. Le contrôle Godot a
détecté une attente de version 0.10.0 restée dans le test de configuration ;
elle est mise à jour pour la RC1. Les tests de configuration et de plafonds
économiques ont ensuite passé localement, avec import, démarrage et contrôle
général relancés. Le résultat de la nouvelle exécution GitHub doit être vérifié
sur la demande de fusion ; la réussite locale ne le remplace pas.

Le test financier couvre 36 mois de ventes/support, suspension et reprise,
expiration, seuil exact et seuil moins un euro dans les trois difficultés,
paiements réels et sauvegarde/rechargement des deux projets simultanés.
Le défaut de support a été reproduit avant correction. Une copie de la
sauvegarde Pixel à 995 307 € permet de lancer un CPU sans toucher au fichier
original. Les contrôles d'interface couvrent six dimensions de 800×480 à
1616×720, ainsi que le portrait 700×720. Des captures PC fraîches ont été
inspectées. Deux avertissements d'ancrage préexistants subsistent.

Les exports Windows et Android sont réalisés avec Godot 4.7.2. Les tests sont
lancés séparément ; le paramètre `-SkipTests` de l'export n'exécute pas ces suites.

## Preuves Pixel et limite tactile

La RC1 code 17 a été installée avec la clé de test commune et sans désinstallation.
L'APK installé et essayé possède le SHA-256
`d708283f1acbd3db76c8119a01d1fc570e08fb8f1e9b7e0097b77c90a9e0dc05`.

La partie a été chargée en pause, 20 septembre 1980, 995 307 €. Nouveau projet
→ Processeur a affiché 1 869 €/mois et 1 869 € minimum, puis créé Nova science 3.
La décision Architecture éprouvée a été appliquée et affichée dans le garage.
Nouveau projet → Logiciel a ouvert le choix contrat/produit.

Les interactions ont été suspendues lorsque le téléphone a été utilisé dans
une autre application. Le lancement tactile d'un logiciel et le rechargement
des deux projets sur Android restent à faire. Le principal et son secours ont
été restaurés puis vérifiés identiques à l'avant-test, SHA-256 commun
`ec418e24b8cceab3b805180d498665601f376e01639cd95d59775454c402454c`.

Les livrables finaux comprennent les dernières précisions de libellés et de
refus fournisseur, ajoutées après ce test tactile. Ils ont été reconstruits et
contrôlés sur PC, mais pas installés ni essayés à nouveau sur le Pixel occupé.

## Limites et suite

Les ventes mensuelles des anciennes sauvegardes n'étaient pas conservées : leurs
cohortes de support sont estimées. La migration ne change ni l'argent ni les
coûts déjà payés ; après douze mois, seules les nouvelles cohortes restent.

Priorités : terminer le test tactile CPU + Software et rechargement sur Pixel,
observer les quinze premières minutes d'un novice, puis mesurer une carrière
CPU + Software et ses marges avec le support limité à douze mois. Les tests
déterministes ne prouvent pas l'équilibrage d'une carrière entière ni la
compréhension par de vrais joueurs. Aucune fusion ou publication commerciale
n'est effectuée dans ce chantier.
