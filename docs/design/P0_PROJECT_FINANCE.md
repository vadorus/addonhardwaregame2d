# P0 — budgets et support logiciel

Le démarrage CPU vérifie un mois de développement plus les frais initiaux. Un
produit ou une mise à jour Software vérifie deux mensualités ; un contrat ou un
correctif vérifie une mensualité. Ce sont des minimums de financement : ils ne
constituent pas une réserve débitée au clic. Les mensualités sont payées lorsque
le travail est effectué. Les salaires et locaux restent dans la prévision globale.

Le devis utilise les mêmes mensualités arrondies et les mêmes multiplicateurs de
difficulté que les paiements. La trésorerie affichée tient déjà compte des dépenses
payées ; ces dépenses sont indiquées séparément et ne sont pas déduites une seconde
fois. Les refus indiquent le disponible, le requis et le manque. L'absence d'équipe,
le marché fermé, le procédé inaccessible et le refus du partenaire gardent leurs
propres messages. `ResearchManager.last_start_quote` conserve le devis du dernier
essai pour le diagnostic ; les paiements émettent déjà `transaction_recorded`.

Une licence Software ouvre douze mois de support, mois de vente inclus. Douze
cohortes de ventes sont sauvegardées par produit. Le coût porte sur leur somme,
pas sur `licenses_total` ou `installed_users`, qui restent des compteurs historiques.
Les cohortes expirent aussi quand un catalogue est suspendu ; un catalogue suspendu
ne vend ni ne paie de support, conformément à la règle préexistante. Une reprise ne
réactive pas les licences expirées. La fiche commerciale indique la règle et la base.

Le schéma de sauvegarde passe de 33 à 34. Une ancienne partie n'a pas les cohortes :
leur reconstruction est une estimation bornée par le cumul vendu, basée sur l'âge
du produit, la moyenne historique et les dernières ventes. Elle ne permet pas de
retrouver une activité utilisateur réelle absente de la sauvegarde. L'argent,
les recettes historiques, les identifiants et les projets ne sont pas modifiés.
Après douze mois de simulation, seuls les nouveaux mois réellement observés restent.

Tests : le défaut historique est reproduit avant correction ; 36 mois de ventes,
expiration après suspension/reprise, montant effectivement payé, seuil exact et
seuil moins un euro dans les trois difficultés, contrat, absence de développeurs,
migration idempotente et sauvegarde/rechargement CPU + Software avec travail
fractionnaire, décisions et cohortes sont couverts par `project_finance_test`.
