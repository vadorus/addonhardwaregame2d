# Lot F3 — marchés stratégiques et diversification

Réalisé le 30/09/2026 sur la base du lot F2.

## Ce qui est ajouté

- Défense accessible à partir de 1980 via une accréditation de 12 mois.
- Aérospatial accessible à partir de 1990, avec proposition de Nora et possibilité de repousser la décision de 3 ans.
- Les accréditations ont un coût initial puis un coût mensuel de conformité.
- Une entreprise accréditée reçoit des appels d'offres plus longs, mieux payés et exigeants en fiabilité.
- L'état des marchés stratégiques est sauvegardé et les anciennes sauvegardes sans données F3 restent compatibles.
- Diversification par filiales vers RAM (1971), PC (1977) et GPU (1995).
- Les marchés de diversification grandissent puis atteignent un plateau.
- Une filiale PC crée une demande captive pour les CPU PC du groupe, plafonnée à +30 %.
- Les filiales diversifiées ont leur propre plafond de marché et ne peuvent pas utiliser le mandat d'intégration CPU.
- Les nouveaux secteurs sont visibles dans Marché, Entreprise et les fiches de filiales.

## Validation

- `StrategicMarketsScenario.gd` ajouté au smoke test.
- Smoke test complet Godot 4.7.2 : vert.
- Export Android F3 : réussi et APK signé.
- Installation `adb install -r` refusée car l'APK actuellement installé sur le Pixel 10 utilise une ancienne signature différente.
- Aucune désinstallation effectuée : la version installée et sa sauvegarde sont intactes.
- Migration de signature Android à traiter séparément avant remplacement de l'application sur le Pixel.