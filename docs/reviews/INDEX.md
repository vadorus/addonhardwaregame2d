# Tech Empire — index des preuves, audits et validations

**Index révisé le 10/10/2026** sur la base `v013/demo-octobre` @ `c1d4f6e`. Le terme « vérifié » est toujours limité à la révision et au protocole cités par chaque rapport.

| Document | Date | Statut d'usage en octobre | Limites |
| --- | --- | --- | --- |
| [NAR-01 — résultats dans PR #88](https://github.com/vadorus/addonhardwaregame2d/blob/feat/press-narration-vary-20261010/docs/reviews/RETOUR_2026-10-10_NAR01.md) | 10/10 | **Testé PC sur branche expérimentale** | 100/100 corps distincts, pas de relecture humaine Pixel |
| [CAREER-02 — résultats dans PR #89](https://github.com/vadorus/addonhardwaregame2d/blob/audit/career-prudent-20261010/docs/reviews/RETOUR_2026-10-10_CAREER02_PRUDENT.md) | 10/10 | **Sonde dérivée testée PC** | Six faillites précoces évitées, 12/12 carrières Standard toujours en faillite, aucune économie modifiée |
| [CAREER-01 — 24 carrières](RETOUR_2026-10-10_CAREER01_4SEEDS.md) | 10/10 | **Mesure au commit c1d4f6e** | 12/12 faillites Standard et richesse élevée Accessible ; rang Empire, pas CPU sectoriel |
| [QA-00 : PC, économie et narration](RETOUR_2026-10-10_QA00.md) | 10/10 | **Preuve actuelle au SHA c1d4f6e** | 12 commandes code 0 ; avertissement UID initial, fuites au test T2 ; 1 graine pour carrière, pas de Pixel |
| [P0 Pixel référence 12 mois](P0_PIXEL_REFERENCE12_COMPLET_2026-10-08.md) | 08/10 | **Historique / baseline** | APK antérieur aux optimisations, pas mesure de la démo HEAD |
| [Validation T2 / C2 / R1 / A1](T2_PIXEL_C2_R1_A1_2026-10-09.md) | 09/10 | **Preuve datée** | Certains écrans et le ressenti audio / animations restent à vérifier |
| [T3 actions Pixel](T3_PIXEL_ACTIONS_2026-10-09.md) | 09/10 | **Preuve datée**, T3 fusionné ensuite | Complément focus testé sur PC, pas retesté sur Pixel |
| [T3 démarrage](T3_DEMARRAGE_2026-10-09.md) | 09/10 | **Historique** | Fait état d'une branche non fusionnée au moment de sa rédaction |
| [C4 branche / ventes Pixel](C4_BRANCHMAP_SALES_AB_PIXEL_2026-10-08.md) | 08/10 | **Preuve datée** | Comparaison attachée aux commits du rapport |
| [C4 réutilisation de lignes](C4_SALES_ROW_REUSE_AB_PIXEL_2026-10-08.md) | 08/10 | **Preuve datée** | Pas garantie sur toute la carrière ou tous les écrans |
| [C3 ancienne mesure](V010_C3_MESURE.md) | antérieur | **Historique** | Baseline d'objectifs antérieurs, ne remplace pas un test actuel |

Audits transversaux historiquement dans `docs/` : [architecture](../AUDIT_ARCHITECTURE_2026-10-08.md), [rendu](../AUDIT_RENDU_2026-10-08.md), [game design](../AUDIT_GAME_DESIGN_2026-10-08.md), [audio](../AUDIT_AUDIO_2026-10-08.md). **Ne pas lire leur rubrique « état actuel » sans vérifier les modifications intervenues depuis.**

## Règle pour un nouveau rapport

Nommer `RETOUR_AAAA-MM-JJ_LOT.md`, utiliser [le modèle](../MODELE_RAPPORT_LOT.md), indiquer commit et conditions. Ajouter une ligne ici et au [journal](../JOURNAL_DEVELOPPEMENT.md). Pas de faux « PASS » : différencier assertion de test, message d'erreur à la sortie, validation matérielle et ressenti humain.

