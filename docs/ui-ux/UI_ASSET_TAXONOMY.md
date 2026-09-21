# Taxonomie UI/UX — V0.3.1

Chaque concept, asset ou mockup doit être classé par fonction.

## Arborescence officielle

```text
assets/ui/concepts/v0_3_1/
├── 01_qg/
├── 02_laboratoire_cpu/
├── 03_hardware_roadmap/
├── 04_equipe/
├── 05_evolution_entreprise/
├── 06_branding_icone_jeu/
├── 07_mobile/
└── 08_windows/
```

## Convention de nommage

`<element>_<usage>_v<numero>.<ext>`

Exemples :
- `qg_onboarding_chaleureux_v1.png`
- `laboratoire_cpu_guide_v2.png`
- `equipe_cartes_employes_v1.png`
- `garage_depart_soir_v1.png`
- `icone_jeu_1024_v1.png`

## Règles

- un fichier = une fonction principale ;
- ne jamais utiliser des noms comme `image1.png` ou `final2.png` ;
- conserver les anciennes versions importantes ;
- documenter ce qui est validé, rejeté ou à retravailler ;
- tout visuel utilisé par Godot doit ensuite être déplacé vers un dossier d'assets de production distinct des concepts.
