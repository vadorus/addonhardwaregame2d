# Comparer les projets logiciel avant lancement

Première application concrète de la référence Devices Tycoon Simulator : rendre
le compromis produit lisible avant de lancer le développement, au sein du
périmètre Software existant. Le CPU possède déjà ses aperçus d'impact de réglages.

Le formulaire logiciel compare le projet courant à sa version de départ. Le
joueur peut garder une version comme nouvelle référence et continuer à modifier
les fonctionnalités, le public, les niveaux ou le prix. Les écarts montrent les
critères du produit, la qualité, les bugs lorsqu'ils sont estimés par le moteur,
le coût mensuel réellement débité, la durée avec l'équipe disponible et le coût
total prévu. Les économies et améliorations sont vertes, les dépenses, délais
et risques supplémentaires rouges. Le changement du prix de licence est neutre :
il ne garantit ni ventes ni marge.

Les calculs réutilisent les prévisions réelles du SoftwareManager. La référence
conserve les choix et recalcule leur estimation dans le même contexte que le
projet courant, ce qui évite de comparer une ancienne équipe ou une autre date.
Une famille différente crée sa propre référence. La référence est locale au
formulaire ; elle n'ajoute aucun champ aux sauvegardes et n'exige aucune migration.

Garder une version ne lance pas le projet, ne dépense pas d'argent et n'avance
pas le temps. Un financement insuffisant bloque le lancement mais permet encore
de comparer une conception valide. Sans équipe disponible, l'interface indique
que durée et coût total ne sont pas estimables, au lieu d'afficher un coût nul
ou une durée négative. Les coûts restent hors salaires et dépenses ultérieures
indiquées dans le devis.

Le panneau remplit la largeur disponible au lieu d'imposer 820 pixels. Les actions
de comparaison et de lancement restent accessibles en défilant sur les petits
formats. Les fonctions de simulation, prix, progression et règles de ventes sont
conservées.

Validation : `software_choice_preview_test` compare l'interface aux prévisions du
manager dans les trois difficultés, vérifie l'absence d'effets de bord, les choix
gardés, changements de famille, manque d'argent et d'équipe. Il contrôle largeur,
cibles tactiles et défilement à 1616×720, 1280×720, 1067×600, 800×480 et 700×720.
Les captures PC fraîches complètent ces contrôles. Cela ne constitue pas un
playtest novice ni une validation tactile Android.
