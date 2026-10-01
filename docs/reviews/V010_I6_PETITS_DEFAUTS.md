# V0.10 / I6 — Petits défauts vus au doigt

Liste de la feuille de route, et un défaut trouvé en préparant l'étude I5.

| Défaut | Correction |
|---|---|
| « Conception avancée » promettait tous les réglages, mais ils restaient repliés | Le formulaire expert s'ouvre et la page y défile (`LabScreen.focus_expert_form`). |
| Libellé « Passer à 151/mois » pour une baisse de capacité | Trois cas distincts : « Réduire à X/mois (gratuit, moins de stock) », « Remonter à X/mois (déjà réservé, gratuit) », ou le coût et le délai de remboursement. |
| Menu du mode de jeu petit et difficile à toucher sur téléphone | Trois gros boutons (Accessible / Standard / Simulation), celui choisi en orange. Les menus déroulants restants ont un texte plus grand et plus espacé. |
| Le 2e CPU était identique au 1er | Terminer un CPU apprend quelque chose à l'équipe : architecture des circuits +2,6 au 1er, puis de moins en moins. Une alerte le dit. L'assistant de conception affiche « Progrès par rapport à votre dernier CPU : … » (ou « Même puce que la précédente » en orange). |
| **Nouveau** : la page Vendre disait « Réduire à 141 » alors que l'usine était pleine à 143 ; un prix de 125 € s'affichait 126 € | Les champs numériques avançaient par pas de 10 (ou 5) **en partant de 1** : seules les valeurs 1, 11… 141, 151 existaient. Désormais la valeur reste exacte et seules les flèches gardent le pas (`UiKit.spin`). Ça touchait tous les champs du jeu. Corriger « Appliquer le nouveau prix » aurait sinon changé le prix d'un euro. |

## Tests

- `SmallDefectsScenario` (smoke) : un champ à pas de 10 garde 143 ; le retour d'expérience baisse mais reste positif.
- `workshop_layout_test` : sur le vrai parcours, on lance la gamme, un mois passe, puis pour chaque modèle en vente, le champ capacité et le champ prix montrent les vraies valeurs, sans proposer de « réduire ». Sans la correction, il échoue : « I4 CPU E shows capacity 141 / price 126 instead of 142 / 125 ».
- smoke, garage_layout, workshop_layout, balance_ceiling : OK.
- Capture de l'écran de création avec les trois boutons de mode (1616×720) vérifiée.
