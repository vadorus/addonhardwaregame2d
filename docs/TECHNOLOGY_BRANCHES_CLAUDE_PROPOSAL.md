# Tech Empire — Carte des branches technologiques et des marchés

> **Document de travail, non implémenté.** Analyse proposée par Claude à la demande du créateur, d'après la branche `feature/ui-ux-v0.3.1` au commit `b600d20`. Les deux parties ci-dessous conservent sa réponse et son complément. Elles ne remplacent pas la `DESIGN_BIBLE.md` et ne valent pas validation des équilibres ou des dates historiques.

## Relecture avant adoption (Codex)

- **Vision à préserver :** logiciel autonome et rentable sur toute la partie ; CPU, GPU et autres composants facultatifs ; achat, licence, sous-traitance et codéveloppement disponibles selon le cas. Les marchés aval demandent des composants compatibles et une capacité réelle, sans obliger à posséder toutes les technologies.
- **Choix libre des domaines, décision confirmée par le créateur :** après l'investissement nécessaire pour grandir, le joueur décide librement d'ouvrir logiciel, CPU, GPU, mémoire, appareils ou services, dans l'ordre souhaité et en parallèle. Le CPU est approfondi en premier dans la production du jeu, mais ne sert pas de passage obligé dans la partie ; seules les exigences d'un projet concret limitent sa réalisation.
- **Trois niveaux distincts :** recherches et procédés ; conception d'un produit avec ses compromis ; spécialisation d'une équipe et d'une lignée. Les marchés (PC, automobile, naval, aéronautique, spatial, défense) orientent ces choix et leurs qualifications ; ils ne deviennent pas systématiquement des technologies à rechercher.
- **Corrections de lecture :** une nouvelle microarchitecture ou lignée ne casse **pas forcément** l'ISA, le socket ni la compatibilité logicielle ; chaque rupture se décide et se vérifie séparément. Un serveur n'exige pas universellement plusieurs processeurs/cœurs ; la recette du §6.5 est un profil de serveur proposé. Un PC peut être vendu sans OS préinstallé si son marché et son offre le permettent ; une licence tierce doit rester possible.
- **Statut des exemples :** les 100 nœuds, seuils, budgets, prix et chiffres des CPU Brise/Rempart/Comète sont des exemples de conception, non des données équilibrées ni des faits historiques. Les lignes qui marquent un type mixte `TEC/COM` devront être scindées lors de la modélisation. Les liens de sources historiques proposés par Claude n'ont pas été vérifiés dans sa session.
- **Suite de conception :** retenir d'abord les domaines et les routes alternatives ; choisir ensuite les familles et paramètres qui rendent les premières minutes intéressantes sur mobile. Aucun de ces 100 nœuds n'a besoin d'apparaître d'un coup dans le garage.

---

# Tech Empire : carte des technologies, des produits et de la chaîne de valeur

## 0. Portée, source et conventions

**Source lue.** Le chemin Windows `C:\Users\Admin\Documents\TechEmpire-v031-validation` n'est pas accessible depuis mon environnement. J'ai donc cloné en lecture seule le dépôt public `vadorus/addonhardwaregame2d`, branche `feature/ui-ux-v0.3.1`. Le HEAD est bien **`b600d20`** (« Document Claude review of independent software career »).

**Ce que je n'ai pas fait.** Je n'ai modifié aucun fichier, fait aucun commit et lancé aucun test. Le projet `addonhardwaregame` rattaché à la session n'a pas été utilisé.

**Documents lus en entier :**
- `docs/DESIGN_BIBLE.md`
- `docs/ROADMAP.md`
- `docs/SOFTWARE_CAREER_CLAUDE_REVIEW.md`
- `docs/CPU_VERTICAL_SLICE.md`
- `docs/VISION.md`
- `docs/GAME_DESIGN.md`
- `docs/ui-ux/garage-interactions-v031.md`
- `AGENTS.md`

**Code lu en partie :** `GameData.gd`, `ResearchManager.gd`, `CpuDesign.gd`, `MarketManager.gd`, `FoundryManager.gd`, `SoftwareStudioManager.gd`, `StartupManager.gd`, `DivisionManager.gd`, `PatentManager.gd`.

**Balises utilisées dans tout le document :**
- **[Constat]** : lu dans le dépôt, avec sa référence.
- **[Proposition]** : ma recommandation de conception.
- **[À trancher]** : décision qui appartient au créateur.
- **[Hypothèse]** : supposition non vérifiée, notamment sur l'équilibrage ou l'histoire.

Les dates historiques sont des **repères arrondis**. Les sources primaires sont au §8. Je n'ai pas pu ouvrir leurs liens, car le réseau sortant de mon environnement les bloque. Il faut donc les vérifier avant de les inscrire dans la bible.

---

## 1. Ce qui est déjà établi dans le dépôt

| # | Constat | Référence |
|---|---|---|
| C1 | Le moteur doit distinguer technologie, composant, produit, service, plateforme, infrastructure, division, marque et filiale. | `DESIGN_BIBLE.md` §4, l. 36-48 |
| C2 | Un produit assemblé n'est accessible que si **toutes** ses briques indispensables sont disponibles **et compatibles**. Chaque catégorie déclare dans ses données : des briques « toutes », des alternatives « au moins une », un niveau minimal, des interfaces, une qualification, une capacité de production et, éventuellement, un contrat fournisseur. Le moteur explique le blocage (« il manque une mémoire compatible ») **au lieu d'afficher un arbre de dizaines de cases grisées**. L'OS peut être interne ou licencié. Un graphique intégré suffit sans carte dédiée. | `DESIGN_BIBLE.md` §5, l. 85-101 |
| C3 | Public, privé, militaire et spatial sont des **contextes de clients et de contrats** (certification, sécurité, durée de support), pas des moteurs distincts. | §15 |
| C4 | Les dates sont des **repères de diffusion, pas des barrières**. Un besoin de marché apparaît à son année historique **ou** quand le signal technologique global atteint son seuil (`tech_trigger`). | §13 ; `MarketManager.gd:17-30` et `:164-170` |
| C5 | Le logiciel est une voie durable dès le garage. Le matériel est facultatif, et le CPU n'est que la première branche matérielle approfondie. | §2.4, §9 ; `garage-interactions-v031.md` l. 45 |
| C6 | Chaque axe de recherche CPU distingue **connaissance / expérience / confiance**. Il existe trois capacités persistantes : Architecture, Layout et Miniaturisation. Des programmes Concept suivent les étapes étude → prototype → validation → technologie transférable. | `CPU_VERTICAL_SLICE.md` ; `ResearchManager.gd:13-34` |
| C7 | Accéder à un procédé exige de **savoir le miniaturiser ET savoir l'industrialiser**. Une fonderie externe doit réellement maîtriser le procédé choisi. La fab interne se construit par paliers et peut vendre sa capacité libre. | §7B, §10 ; `FoundryManager.gd` |
| C8 | Il existe 18 nœuds de gravure, de 10 µm à 14 nm. Chacun porte un seuil `unlock` (de 0 à 94) sur une capacité scalaire. | `CpuDesign.gd:12-29` |
| C9 | Les « technologies » du code sont un **dictionnaire plat de scalaires** : une entrée par secteur, plus `manufacturing`, `software` et `integration`. Il n'y a ni graphe ni prérequis. | `ResearchManager.gd:61-64` |
| C10 | `GameData.SECTORS` mélange des produits (CPU, GPU, SMARTPHONE, TV), des services (SOFTWARE, CLOUD) et un secteur spatial (SATELLITE). Seul `ACTIVE_SECTORS = ["CPU"]` est actif. Les approches INTERNAL / HYBRID / EXTERNAL s'appliquent à un **projet entier**, pas à une pièce. | `GameData.gd:13-60`, `:184-186` |
| C11 | La voie matérielle suit une ligne unique : GARAGE → FIRST_HIRE → ELECTRONICS → CPU_READY. | `StartupManager.gd:6-9`, `:479`, `:878-879` |
| C12 | Il y a quatre logiciels au catalogue, débloqués par l'année et `programming_level`. `MINI_OS` ne dépend d'aucune machine. | `SoftwareStudioManager.gd:5-10` ; revue logicielle, P4 |
| C13 | La revue logicielle propose six métiers : prestation, maintenance, édition, outils, système, exploitation. Les **plateformes et la compatibilité** y forment la colonne vertébrale du marché : « posséder son CPU revient à posséder sa plateforme ». Elle décrit aussi un parcours de 30 minutes. | `SOFTWARE_CAREER_CLAUDE_REVIEW.md` §2, §3, §8 |
| C14 | Il ne faut pas de boutons grisés pour les systèmes futurs. Les fonctions apparaissent quand un événement concret les rend utiles. | §6A |
| C15 | Périmètre agents : le CPU d'abord, des migrations de sauvegarde explicites et des tests déterministes. La roadmap place un « moteur industriel générique » en Phase 2 (non commencée) et la diversification en Phase 6. | `AGENTS.md` ; `ROADMAP.md` |

**Écarts entre la vision et le code :**
- Le code ne possède **aucune structure de graphe** (C9).
- Le « déblocage » est aujourd'hui un seuil scalaire (C8) ou une étape linéaire (C11).
- La notion de **route d'accès par pièce** (acheter, licencier, etc.) n'existe qu'au niveau du projet (C10).

Le présent document propose de combler ces écarts **par des données**, dans l'esprit de la Phase 2, sans ouvrir de nouveaux secteurs jouables avant la validation de la tranche verticale (C15).

---

## 2. Taxonomie : types de nœuds et trois graphes distincts

### 2.1 Légende des types de nœuds [Proposition]

| Code | Type | Ce que c'est | Comment on l'obtient | Forme de l'acquis | Exemples |
|---|---|---|---|---|---|
| **SAV** | Connaissance | Compréhension théorique | Recherche, recrutement, rachat d'équipe ; une licence transfère une partie | Jauge 0-100 (connaissance / expérience / confiance, C6) | physique MOS, logique numérique |
| **CMP** | Compétence | Ce qu'une **équipe** sait exécuter | Pratique réelle, recrutement | Jauge 0-100 par équipe ou entreprise | layout, validation, intégration thermique |
| **TEC** | Technologie | Solution réutilisable dans plusieurs produits | Recherche, licence, codéveloppement | États discrets (§5.3) et maturité | ISA 16 bits, cache sur puce, rasterisation 3D |
| **PRO** | Procédé | Manière de fabriquer | Développer, sous-traiter, licencier | État et maîtrise par route de fabrication | nœud 1 µm, CMOS, montage en surface |
| **COM** | Composant | Pièce intégrable, matérielle ou logicielle, avec des **specs et des interfaces** | Concevoir, **acheter**, licencier | Instance concrète (génération, modèle) | un CPU, un module mémoire, une alimentation |
| **LOG** | Logiciel / firmware | Code livrable ou intégré | Développer, licencier | Produit versionné | OS, compilateur, firmware |
| **ASM** | Produit assemblé | Produit vendu, composé d'**emplacements** | Recette et composants compatibles | Famille de produits | PC fixe, portable, serveur |
| **SRV** | Service | Offre continue | Infrastructure, équipe, clients | Contrat ou abonnement | maintenance, bureau de services, cloud |
| **INF** | Infrastructure | Actif qui rend une activité possible | Construire, louer, sous-traiter | Palier et capacité | fab, ligne d'assemblage, labo d'essais, datacenter |
| **NOR** | Norme / interface / plateforme | Contrat de compatibilité, parfois doté d'une base installée | Adopter, définir soi-même, licencier | Version | bus d'extension, brochage CPU, plateforme tierce |
| **QUA** | Qualification | Aptitude à satisfaire des exigences de marché | Tests, labo, procédures, audits | Capacité d'entreprise **et** certificat par produit | grade automobile, spatial, CEM |
| **MAR** | Marché / segment | Demande solvable avec ses critères | Émerge par l'époque, le signal technologique ou l'action du joueur | Disponible ou non, taille, attentes | les `MARKET_NEEDS` existants, les publics logiciels |

**Ce qui n'est pas un nœud.** Les **droits et licences** sont des **contrats** : un titulaire, une portée, une durée, une redevance, une exclusivité. Ce sont des objets de registre, pas des nœuds du graphe. Les **fournisseurs** sont des acteurs du monde. Ils publient des **offres** de composants ou de capacité.

### 2.2 Les trois graphes et leurs liens

```
(A) ARBRE TECHNOLOGIQUE — « que sait-on concevoir ? »
    SAV ──► TEC ──► (PRO | LOG | spécifications de COM)
     ▲       │
    CMP ◄────┘  (la pratique fait monter les compétences : c'est un FLUX, pas une arête)

(B) CHAÎNE DE VALEUR — « comment est-ce fabriqué et fourni ? »
    matières (cachées) → plaquette/fab → puce → boîtier + test → COMPOSANT
      → assemblage de cartes → assemblage système → QUALIFICATION → distribution
      → SAV / pièces → fin de vie
    Chaque maillon est tenu soit en interne (INF), soit par un tiers
    (fonderie, EMS/ODM, labo, distributeur).

(C) ARBRE DES PRODUITS — « que vend-on, et à qui ? »
    COM ─► sous-ensemble ─► ASM ─► PLATEFORME (NOR avec base installée) ─► SRV
                               │
                               └─► MARCHÉ (MAR) filtré par les QUALIFICATIONS (QUA)
```

**Règles de liaison :**
- (A) dit si l'on **peut concevoir**.
- (B) dit si l'on **peut obtenir et produire en volume**.
- (C) dit si l'on **peut vendre, à qui et contre quelle concurrence**.
- Une recette de produit (C) interroge (A) **ou** l'offre fournisseur (B) pour chaque emplacement.

C'est ce qui permet de faire un PC **sans** avoir fait de CPU.

### 2.3 Domaines, sous-domaines et technologies transversales

**Domaines :**

| Domaine | Sous-domaines |
|---|---|
| Logiciel et services | applications, outils, OS, firmware, pilotes, réseau logiciel, sécurité, virtualisation, services |
| CPU | ISA, microarchitecture, caches, contrôleurs, énergie, intégration SoC, chiplets |
| Graphique | affichage texte, 2D bitmap, accélération 2D, 3D, programmable, calcul, vidéo |
| Mémoire | SRAM, DRAM, ROM/EPROM, Flash, contrôleurs, ECC, haute bande passante |
| Stockage | amovible, disque dur, SSD, contrôleurs |
| Carte / chipset / interfaces | carte, chipset, brochage, bus, E/S, facteur de forme |
| Réseau / télécom / radio | modem, réseau local, interréseau, sans-fil local, cellulaire |
| Énergie / thermique / boîtier | alimentation, gestion d'énergie, refroidissement, boîtier |
| Interface homme-machine / mobile | écran, tactile, batterie, capteurs |
| Semi / fabrication | physique, procédés, packaging, fonderie, fab, assemblage, test, qualification |

**Technologies transversales.** Elles apparaissent comme **CMP ou TEC partagées** par plusieurs domaines, et une même avancée profite à plusieurs branches :

| Technologie transversale | Domaines qui en profitent |
|---|---|
| Basse consommation | CPU, graphique, mobile, réseau |
| Thermique | tous les domaines matériels |
| Validation / fiabilité | tous les domaines |
| Miniaturisation et packaging | semi, mobile, spatial |
| Outils logiciels et compilateurs | CPU (écosystème), graphique (shaders), OS |
| Normes et compatibilité | toutes les plateformes |
| Sécurité | OS, firmware, serveur, défense |
| Rendement industriel | semi, assemblage |

---

## 3. Les branches, avec leurs jalons indicatifs

Les jalons donnent une **époque suggérée** : c'est le moment où le monde y arrive sans intervention du joueur. Ce ne sont jamais des barrières (C4). Les noms réels servent **uniquement de repères de conception**. En jeu, entreprises, produits et normes restent fictifs (§7, décision D9).

| Branche | Jalons représentatifs (époque indicative) | Ramifications à garder, sans microrecherche |
|---|---|---|
| **CPU** | microprocesseur 4 bits (1971) → 8 bits (1972-74) → 16 bits et gestion mémoire (1978-82) → 32 bits, pipeline, RISC (1985) → cache et FPU sur puce (1989) → superscalaire et désordre (1993-95) → SIMD (fin des années 1990) → 64 bits, contrôleur mémoire intégré (2003) → multicœur, virtualisation (2005) → SoC mobile (années 2000) → chiplets (2019) | ISA **propre vs licenciée** (compatibilité logicielle) ; génération → gamme par tri des puces (C6) ; microcode |
| **Graphique** | affichage de caractères (années 1970) → framebuffer bitmap (fin des années 1970-80) → accélération 2D / GUI (fin des années 1980) → 3D grand public (1996) → pipeline programmable (1999-2001) → calcul général (2007) ; vidéo MPEG (années 1990) | graphique intégré (chipset, puis CPU/SoC) **ou** carte dédiée ; sortie vidéo (norme) |
| **Mémoire** | DRAM 1 kbit (1970) et EPROM (1971) → modules (années 1980-90) → Flash NOR/NAND (fin des années 1980) → SDRAM/DDR (1990-2000) → basse consommation mobile (années 2000) → HBM (2015) | ECC (serveur) ; mémoire graphique ; contrôleur |
| **Stockage** | bande, disquette 8" (1971) → 5,25" (1976) → disque dur dans les micros (1980) → optique (1985) → SSD grand public (vers 2008) → NVMe (2011) | contrôleur et interface, notion par génération |
| **Carte / bus / interfaces** | bus de kit (1975) → bus ouvert du PC (1981) → PCI (1992) → USB (1996) → PCIe et SATA (2003) | brochage CPU = interface ; facteur de forme ; firmware de démarrage |
| **Réseau / radio** | modems (années 1970) → Ethernet inventé (1973), normalisé (1983) → TCP/IP (1983) → GSM (1991) → Wi-Fi (1997-99) → 3G / 4G / 5G (2001-2019) | brevets essentiels à licencier ; homologation radio |
| **Énergie / thermique / boîtier** | alimentations linéaires puis à découpage (années 1970-80) → caloducs dans les portables (années 1990) → gestion d'énergie intégrée mobile (années 2000) | budget thermique (TDP) = contrainte de conception |
| **Écrans / batterie / capteurs** | CRT (acheté) → LCD passif (années 1980) → TFT (années 1990) → tactile capacitif (2007) → OLED (années 2010) ; NiCd → NiMH → Li-ion (1991) ; capteurs MEMS et caméra CMOS (années 2000) | l'industrie se fournit surtout auprès de tiers ; le jeu doit rendre l'**achat** naturel |
| **Logiciel / OS / outils** | assembleurs, applications de gestion (1971), Unix (1969-71) → compilateurs → OS à disque (1975-81) → GUI (1983-84) → piles réseau (années 1980) → web (années 1990) → virtualisation x86 (1999) → cloud (2006) | la plateforme cible décide du marché (C13) |
| **Semi / fabrication** | 10 µm PMOS (1971, **déjà le point de départ du code**, C8) → NMOS → CMOS → cuivre (1997) → FinFET (2011) → EUV (2019) ; boîtier traversant → BGA / flip-chip → 2.5D / 3D | fonderie externe ou fab interne (C7) ; montage en surface pour les cartes ; labo de qualification |
| **Produits aval** | carte de contrôle (1971) → terminal → kit micro (1975) → micro personnel (1977) → PC (1981) → portable (1985-89) → serveur (1988, besoin `SERVER` du code) → console (1977, puis 3D dans les années 1990) → mobile (années 1990, puis smartphone en 2007) ; calculateurs automobiles (années 1980) ; avionique et spatial (dès 1971 comme contextes) | **grade** du produit : commercial / industriel / automobile / spatial / défense |

---

## 4. Tableau des nœuds représentatifs [Proposition]

### 4.1 Conventions

- **Identifiant stable** : `domaine.sous.nom`, en ASCII minuscule. Il n'est **jamais réutilisé ni renommé**, et une table d'alias assure la migration. Le libellé affiché est séparé.
- **Patron** : `<x>` désigne une famille extensible, avec une instance par génération ou variante.
- **Voies d'accès** :
  - D : développer ;
  - A : acheter (offre fournisseur) ;
  - L : licence (droit d'utiliser ou de produire) ;
  - C : codévelopper ;
  - S : sous-traiter (la propriété reste au joueur, un tiers réalise) ;
  - R : racheter une équipe ou une entreprise ;
  - « monde » : norme adoptée librement ou plateforme d'un tiers.
- **Seuils de jauge** : `≥ n` désigne un seuil sur une jauge 0-100. Les valeurs sont **indicatives** [Hypothèse].
- **Époque** : repère de diffusion, jamais une barrière.

### 4.2 Fondations et compétences

| # | ID | Type | Domaine › parent | Acquis débloqué | Prérequis TOUS | Au moins UN | Voies | Époque |
|---|---|---|---|---|---|---|---|---|
| 1 | `k.sw.programming` | SAV | fondations | Programmation (assembleur, langages de l'époque) | — | — | D | 1971 (départ) |
| 2 | `k.logic.digital` | SAV | fondations | Logique numérique, lecture de schémas | — | — | D, R | 1971 |
| 3 | `k.semi.mos` | SAV | semi | Physique MOS, règles de conception | `k.logic.digital` | — | D, L (transfert), R | 1971 |
| 4 | `s.sw.engineering` | CMP | logiciel | Qualité et délais logiciels (jauge) | `k.sw.programming` | — | D (projets), R, embauche | 1971 |
| 5 | `s.hw.board` | CMP | électronique | Conception de cartes (schéma, routage) | `k.logic.digital` | — | D, R, embauche | 1971 |
| 6 | `s.cpu.{architecture,layout,miniaturization}` | CMP | CPU | Les trois capacités **existantes** (C6) | `k.semi.mos` | — | D, programmes Concept, R | 1971 |
| 7 | `s.qa.validation` | CMP | transverse | Couverture de test, confiance des estimations | — | `s.sw.engineering`, `s.hw.board` | D | 1971 |
| 8 | `s.ind.industrialization` | CMP | production | Rendement, défauts, cadence (équipe Production existante) | — | `s.hw.board`, `k.semi.mos` | D, R | 1971 |
| 9 | `s.thermal` | CMP | transverse | Budget thermique, dissipation | `k.logic.digital` | — | D, R | 1971 |
| 10 | `s.power` | CMP | énergie | Conversion et gestion d'énergie | `k.logic.digital` | — | D, R | 1971 |
| 11 | `s.rf` | CMP | radio | Conception RF, antennes | `s.hw.board` | — | D, R, C | ≈1975+ |

### 4.3 Logiciel, firmware, OS, outils, sécurité et services

| # | ID | Type | Domaine › parent | Acquis débloqué | Prérequis TOUS | Au moins UN | Voies | Époque |
|---|---|---|---|---|---|---|---|---|
| 12 | `srv.sw.contract` | SRV | prestations | Contrats sur mesure (**existant**) | `k.sw.programming` | — | D | 1971 |
| 13 | `plat.3p.<nom>` | NOR | plateformes | Plateforme tierce (mini-ordinateur, temps partagé, puis micro) : **cible** logicielle avec base installée | — | — | monde (documentation publique ou accord constructeur) | 1971+ |
| 14 | `plat.own.<nom>` | NOR | plateformes | Plateforme propre = ISA + carte + firmware + interface binaire de l'OS | `cpu.isa.<w>`, `sw.fw.boot` | `mb.board`, `asm.ctrl_board` | D, C | ≈1972+ |
| 15 | `sw.app.business` | LOG | applications | Logiciel de gestion à sa marque (**existant**) | `k.sw.programming` | toute `plat.*` | D, C | 1971 |
| 16 | `srv.sw.maintenance` | SRV | services | Maintenance sous contrat avec niveau de service (revue, métier B) | `s.qa.validation ≥ 10` | un `sw.*` publié, un `asm.*` vendu | D | 1971 |
| 17 | `sw.tools.asm` | LOG | outils | Assembleur et éditeur de liens pour une plateforme | `s.sw.engineering ≥ 20` | toute `plat.*` | D, L | ≈1971-72 |
| 18 | `sw.tools.compiler` | LOG | outils | Compilateur haut niveau, **compilation croisée** | `sw.tools.asm` | — | D, L, R | ≈1973+ |
| 19 | `sw.os.disk` | LOG | OS | OS mono-utilisateur à disque (le niveau 1 « moniteur » est inclus) | `sw.tools.asm`, `sto.removable` (interface connue) | toute `plat.*` | D, L | ≈1975-81 |
| 20 | `sw.os.multiuser` | LOG | OS | OS multitâche avec protection mémoire | `sw.os.disk`, `sw.tools.compiler` | `cpu.mmu` (propre), une `plat.3p` dotée d'une MMU | D, L | minis 1970s / micros ≈1985 |
| 21 | `sw.os.gui` | LOG | OS | Interface graphique fenêtrée | `sw.os.disk`, `gfx.bitmap` (sur la plateforme cible) | — | D, L | ≈1983-84 |
| 22 | `sw.os.mobile` | LOG | OS | OS mobile (énergie, tactile, radio) | `sw.os.multiuser`, `cpu.pm` (sur la cible) | — | D, L | ≈2000-07 |
| 23 | `sw.fw.boot` | LOG | firmware | Firmware de démarrage / BIOS d'une carte | `sw.tools.asm` | `mb.board`, `asm.ctrl_board` | D, L, A | ≈1975+ |
| 24 | `sw.net.stack` | LOG | réseau | Pile réseau (local, puis interréseau) | `net.lan` | `sw.os.disk`, `sw.os.multiuser` | D, L | années 1980 |
| 25 | `sw.sec.<niveau>` | TEC | sécurité | Patron : contrôle d'accès → chiffrement → mises à jour signées | `sw.os.multiuser` | — | D, L | 1970s → 1990s |
| 26 | `sw.virt` | TEC | infra logicielle | Virtualisation | `sw.os.multiuser` | `cpu.virt`, `sw.tools.compiler` (traduction binaire) | D, L | 1970s gros systèmes / 1999 micros |
| 27 | `srv.batch` | SRV | exploitation | Bureau de services (revue, métier F) | `sw.app.business`, `infra.compute` | — | D | 1971 |
| 28 | `infra.compute` | INF | exploitation | Ordinateur loué, salle machine, puis datacenter par paliers | — | — | A (location), D (paliers), S (hébergeur) | 1971+ |
| 29 | `srv.cloud` | SRV | services | Services en ligne, puis cloud (patron à paliers) | `sw.net.stack`, `infra.compute` palier ≥ 2 | `net.modem` (service télématique), `sw.virt` (cloud) | D, R | ≈1980s → 2006 |

### 4.4 CPU

| # | ID | Type | Domaine › parent | Acquis débloqué | Prérequis TOUS | Au moins UN | Voies | Époque |
|---|---|---|---|---|---|---|---|---|
| 30 | `cpu.isa.w4` | TEC | CPU › ISA | ISA 4 bits propre | `k.logic.digital`, `s.cpu.architecture ≥ 15` | — | D, L | 1971 |
| 31 | `cpu.isa.w8` | TEC | CPU › ISA | ISA 8 bits | `s.cpu.architecture ≥ 25` | `cpu.isa.w4` (expérience), droit sur une ISA tierce | D, L | ≈1972-74 |
| 32 | `cpu.isa.w16` | TEC | CPU › ISA | ISA 16 bits (32 et 64 bits suivent le même patron) | `cpu.isa.w8` ou licence équivalente | — | D, L | ≈1978 |
| 33 | `cpu.isa.w32` | TEC | CPU › ISA | ISA 32 bits | `cpu.isa.w16`, `cpu.mmu` | — | D, L | ≈1985 |
| 34 | `cpu.uarch.pipeline` | TEC | microarchitecture | Pipeline | `cpu.isa.w8`, `s.cpu.layout ≥ 30` | — | D, L (cœur IP) | ≈1980s |
| 35 | `cpu.uarch.superscalar` | TEC | microarchitecture | Superscalaire (le niveau 2 « désordre » est inclus) | `cpu.uarch.pipeline`, `cpu.cache` niv. 1 | — | D, C | ≈1993-95 |
| 36 | `cpu.uarch.multicore` | TEC | microarchitecture | Multicœur et cohérence | `cpu.cache` niv. 2, `s.cpu.miniaturization ≥ 84` | — | D | ≈2005 |
| 37 | `cpu.cache` | TEC | caches | Patron à niveaux : 1 = cache sur puce ; 2 = hiérarchie L2/L3 | `s.cpu.layout ≥ 40` | procédé ≤ 1 µm accessible (propre **ou** fonderie) | D | ≈1985-89 → 2000s |
| 38 | `cpu.mmu` | TEC | contrôleurs | Gestion et protection mémoire | `cpu.isa.w16` | — | D, L | ≈1980s |
| 39 | `cpu.pm` | TEC | énergie | États d'énergie, DVFS | `s.power ≥ 30`, `proc.cmos` | — | D, L | ≈1990s |
| 40 | `cpu.virt` | TEC | extensions | Extensions de virtualisation | `cpu.mmu`, `cpu.isa.w32` | — | D | ≈2005 |
| 41 | `cpu.soc` | TEC | intégration | SoC : CPU, graphique, contrôleurs et interfaces sur une puce | `cpu.pm`, `mem.ctrl` | `gfx.2d` (propre), graphique licencié (IP) | D, L, C | ≈2000s |
| 42 | `cpu.chiplet` | TEC | intégration | Chiplets et interconnexion entre puces | `cpu.uarch.multicore`, `pkg.<avancé>` | — | D, C | ≈2019 |
| 43 | `comp.cpu` | COM | produit composant | CPU vendable (génération → gamme, **existant**) | au moins une `cpu.isa.*` utilisable, `proc.node.<x>` accessible | — | D (existant) ; **A** pour les assembleurs ; L (cœur IP) | 1971 |

### 4.5 Semi, fonderie, assemblage et qualification

| # | ID | Type | Domaine › parent | Acquis débloqué | Prérequis TOUS | Au moins UN | Voies | Époque |
|---|---|---|---|---|---|---|---|---|
| 44 | `proc.node.<x>` | PRO | procédés | Nœud de gravure x : **table existante** de 10 µm à 14 nm (C8). Les étapes cuivre, FinFET et EUV sont des sous-exigences des nœuds concernés. | `s.cpu.miniaturization ≥ unlock(x)` pour **savoir miniaturiser** | `infra.fab` à un palier qui supporte x, `infra.foundry` qui maîtrise x (**savoir industrialiser**, C7) | D, S, C | selon x |
| 45 | `proc.cmos` | PRO | procédés | Logique CMOS basse consommation | `k.semi.mos` | — | D, L, S | fin des années 1970-80 |
| 46 | `pkg.<niveau>` | PRO | packaging | Patron : standard → haute densité (BGA / flip-chip) → avancé (2.5D / 3D) | `s.thermal` (niveaux > 1) | — | S, D, C | 1971 → 2010s |
| 47 | `infra.foundry` | INF | fonderie | Contrat de fonderie externe (**existant**) | — | — | S | 1971 |
| 48 | `infra.fab` | INF | fab | Fab interne à paliers (**existante**) | `s.ind.industrialization ≥ seuil` | — | D (construire), R | coûteuse, à tout moment |
| 49 | `proc.pcb.smt` | PRO | assemblage | Montage en surface, cartes denses | `s.hw.board ≥ 35` | — | D, S | ≈1980s |
| 50 | `infra.assembly` | INF | assemblage | Ligne d'assemblage et de test de produits | `s.ind.industrialization ≥ 15` | — | D ; **S** (sous-traitant d'assemblage ou conception déléguée) | 1971 |
| 51 | `infra.lab` | INF | qualification | Labo d'essais (thermique, compatibilité électromagnétique, vibrations, radiations selon le palier) | `s.qa.validation ≥ 20` | — | D (paliers), S (labo tiers) | 1971 |

### 4.6 Mémoire et stockage

| # | ID | Type | Domaine › parent | Acquis débloqué | Prérequis TOUS | Au moins UN | Voies | Époque |
|---|---|---|---|---|---|---|---|---|
| 52 | `mem.dram` | TEC/COM | mémoire | DRAM : puces, puis modules en variante ; la SRAM suit le même patron | `k.semi.mos` | — | **A**, D, L | 1970-71 |
| 53 | `mem.rom` | COM | mémoire | ROM / EPROM pour le firmware | `k.semi.mos` | — | A, D | 1971 |
| 54 | `mem.flash` | TEC/COM | mémoire | Flash NOR / NAND | `mem.rom`, procédé ≤ 1,5 µm accessible | — | A, D, L | fin des années 1980 |
| 55 | `mem.ctrl` | TEC | contrôleurs | Contrôleur mémoire ; la variante « intégré au CPU » est de niveau 2 | `s.hw.board` | `mem.dram` accessible (A/D/L) | D, L | 1971 → 2003 |
| 56 | `mem.ecc` | TEC | fiabilité | Correction d'erreurs | `mem.ctrl` | contrôleur propre, chipset acheté compatible ECC | D, L | 1970s (gros systèmes) → PC serveur 1990s |
| 57 | `mem.bw.<gen>` | TEC/COM | mémoire graphique | Patron : VRAM → GDDR → HBM | `mem.dram` | — | A, D, C | 1980s → 2015 |
| 58 | `sto.removable.<gen>` | COM | stockage | Patron : bande → disquettes → optique | — | — | **A**, D, L | 1971 → |
| 59 | `sto.hdd` | COM | stockage | Disque dur avec son contrôleur et son interface | `s.hw.board ≥ 30` | — | **A**, D, R | ≈1980 (micros) |
| 60 | `sto.ssd` | COM | stockage | SSD | `mem.flash` accessible, `s.hw.board ≥ 50` | — | A, D | ≈2008 |

### 4.7 Carte mère, chipset, bus et interfaces

| # | ID | Type | Domaine › parent | Acquis débloqué | Prérequis TOUS | Au moins UN | Voies | Époque |
|---|---|---|---|---|---|---|---|---|
| 61 | `mb.board` | COM | carte mère | Conception de carte mère | `s.hw.board ≥ 25` | un `comp.cpu` propre, une offre CPU **achetée** avec sa fiche technique | D, S (conception déléguée), A | ≈1975+ |
| 62 | `mb.chipset` | COM | chipset | Logique de liaison, puis ponts | `mb.board`, `mem.ctrl` | — | D, **A**, L | ≈1980s |
| 63 | `std.cpu.socket.<id>` | NOR | interfaces | Brochage ou socket d'un CPU : **interface CPU ↔ carte** | défini par son `comp.cpu` (propre ou fournisseur) | — | D (définir), L (droit d'usage), A | 1971 → |
| 64 | `std.bus.<gen>` | NOR | bus | Patron : bus de kit → bus ouvert → PCI → PCIe ; E/S série → USB | — | — | monde (ouvert), L (licence), D (propriétaire) | 1975 → 2003 |
| 65 | `std.formfactor.<id>` | NOR | boîtier | Format carte / boîtier | — | — | monde, D | ad hoc → ≈1995 |

### 4.8 Graphique

| # | ID | Type | Domaine › parent | Acquis débloqué | Prérequis TOUS | Au moins UN | Voies | Époque |
|---|---|---|---|---|---|---|---|---|
| 66 | `gfx.text` | TEC | affichage | Générateur de caractères, terminal texte | `k.logic.digital`, `mem.rom` accessible | — | D, A | 1971-75 |
| 67 | `gfx.bitmap` | TEC | 2D | Framebuffer bitmap | `gfx.text`, `mem.dram` accessible | — | D, A, L | fin des années 1970-80 |
| 68 | `gfx.2d` | TEC | 2D | Accélération 2D (GUI) | `gfx.bitmap` | — | D, L | ≈1985-90 |
| 69 | `gfx.3d` | TEC | 3D | Rasterisation 3D ; la version programmable est le niveau 2 | `gfx.2d`, `s.cpu.layout ≥ 60` | — | D, L, C, R | ≈1996 → 2001 |
| 70 | `gfx.compute` | TEC | calcul | Calcul général sur GPU (prépare l'IA) | `gfx.3d` niv. 2, `sw.tools.compiler` | — | D | ≈2007 |
| 71 | `gfx.video` | TEC | vidéo | Décodage et encodage vidéo | `gfx.bitmap` | un bloc dédié propre, calcul vectoriel côté CPU | D, **L** (codecs brevetés) | ≈1990s |
| 72 | `comp.gfx.igp` | COM | intégré | Graphique intégré au chipset, puis au CPU/SoC | `gfx.2d` ou licence IP | `mb.chipset`, `cpu.soc` | D, **A** (via chipset/SoC acheté), L | ≈1990s |
| 73 | `comp.gfx.card` | COM | dédié | Carte graphique / GPU | `std.bus.<gen>` compatible | `gfx.bitmap`, `gfx.2d`, `gfx.3d` (définit le niveau) | D, **A** | 1980s → |
| 74 | `std.display.out.<gen>` | NOR | sortie | Patron : RF / composite → analogique → numérique | — | — | monde, L | 1970s → |

### 4.9 Réseau, télécom et radio

| # | ID | Type | Domaine › parent | Acquis débloqué | Prérequis TOUS | Au moins UN | Voies | Époque |
|---|---|---|---|---|---|---|---|---|
| 75 | `net.modem` | TEC/COM | télécom | Modem | `s.hw.board` | — | **A**, D, L | 1970s |
| 76 | `net.lan` | NOR/COM | réseau | Réseau local et contrôleur réseau | — | `s.hw.board` (contrôleur propre), contrôleur acheté | monde + A/D | ≈1980-83 |
| 77 | `radio.wlan` | TEC | radio | Réseau local sans fil | `s.rf ≥ 40`, `net.lan` | — | D, **A**, L | ≈1997-99 |
| 78 | `radio.cell.<gen>` | TEC | radio | Patron : modem cellulaire par génération | `s.rf ≥ 50`, `cpu.pm` (ou modem acheté) | — | D **+ L obligatoire** (brevets essentiels), **A** | 1991 → 2019 |

### 4.10 Énergie, thermique, boîtier, écrans, batterie et capteurs

| # | ID | Type | Domaine › parent | Acquis débloqué | Prérequis TOUS | Au moins UN | Voies | Époque |
|---|---|---|---|---|---|---|---|---|
| 79 | `comp.psu` | COM | énergie | Alimentation ; « linéaire → à découpage » est une variante | `s.power ≥ 10` (conception propre) | — | **A**, D, S | 1971 |
| 80 | `pwr.pmic` | TEC | énergie | Gestion d'énergie intégrée (mobile) | `s.power ≥ 50`, `proc.cmos` | — | D, **A** | ≈2000s |
| 81 | `cool.<niveau>` | TEC | thermique | Patron : passif → ventilé → caloducs / compact | `s.thermal` au seuil du niveau | — | **A**, D, L | 1971 → 1990s |
| 82 | `comp.chassis` | COM | boîtier | Boîtier, avec son format de carte | — | — | D (design) + S (tôlerie), A | 1971 |
| 83 | `comp.display.<tech>` | COM | écrans | Patron : CRT → LCD → TFT → OLED ; tactile en variante | — | — | **A**, C, D, R | 1971 → 2010s |
| 84 | `bat.pack.<chimie>` | COM | batterie | Pack et gestion de batterie ; chimie NiCd → NiMH → Li-ion | `s.power ≥ 30` (pack propre) | — | **A** (cellules), D (pack), S | ≈1980s → 1991 |
| 85 | `sens.<type>` | COM | capteurs | Patron : accéléromètre, caméra CMOS, GPS… | — | — | **A**, D, L | ≈2000s |

### 4.11 Qualifications

Chaque qualification a une **capacité d'entreprise** et un **certificat par produit** (§5.4).

| # | ID | Type | Domaine › parent | Acquis débloqué | Prérequis TOUS | Au moins UN | Voies | Époque |
|---|---|---|---|---|---|---|---|---|
| 86 | `q.consumer` | QUA | grand public | Sécurité électrique et compatibilité électromagnétique | — | `infra.lab`, labo tiers | D, S | 1970s → |
| 87 | `q.industrial` | QUA | industrie | Température étendue, durée de vie, disponibilité longue | `s.qa.validation ≥ 30` | `infra.lab`, labo tiers | D, S | 1971 |
| 88 | `q.radio` | QUA | télécom | Homologation radio, certification opérateur | `q.consumer`, `s.rf ≥ 40` | — | D, S | 1990s |
| 89 | `q.auto` | QUA | automobile | Grade automobile (composants) et sécurité fonctionnelle | `q.industrial`, `s.qa.validation ≥ 60`, audit de procédé | — | D (long), C (équipementier) | mi-1990s → 2011 |
| 90 | `q.aero` | QUA | aéronautique | Assurance de conception avionique (matériel et logiciel) | `q.industrial`, `s.qa.validation ≥ 70` | — | D, C | ≈2000s |
| 91 | `q.space` | QUA | spatial | Tolérance aux radiations, qualification spatiale | `q.industrial`, `infra.lab` palier radiations | procédé durci, **ou** redondance de conception | D, C | 1970s → |
| 92 | `q.defense` | QUA | défense | Qualification défense, habilitation de l'entité, sécurité | `q.industrial`, `sw.sec.<niveau ≥ 2>` | — | D, C, R | 1971 → |

### 4.12 Produits assemblés et marchés

| # | ID | Type | Domaine › parent | Acquis débloqué | Prérequis TOUS | Au moins UN | Voies | Époque |
|---|---|---|---|---|---|---|---|---|
| 93 | `asm.ctrl_board` | ASM | embarqué | Carte de contrôle / boîtier de commande (la **première porte matérielle**, déjà l'étape ELECTRONICS) | `s.hw.board`, `comp.psu` | `comp.cpu` (**toute route**), logique câblée (`k.logic.digital`) | D, S | 1971 |
| 94 | `asm.pc_desktop` | ASM | informatique | PC fixe : recette à emplacements (§5.2) | recette | — | D (intégration), S (conception déléguée) | ≈1977-81 |
| 95 | `asm.pc_laptop` | ASM | informatique | Portable | recette PC + contraintes (chaîne 4) | — | D, S | ≈1985-89 |
| 96 | `asm.server` | ASM | informatique | Serveur | recette (chaîne 5) | — | D, S | ≈1988 |
| 97 | `asm.console` | ASM | loisirs | Console | recette (chaîne 6b) | — | D, S | 1977 → 1990s |
| 98 | `asm.phone` | ASM | mobile | Téléphone, puis smartphone | recette (chaîne 6a) | — | D, S, C | 1990s → 2007 |
| 99 | `asm.ecu` | ASM | automobile | Calculateur embarqué automobile ; aéro, spatial et défense suivent le même patron avec leurs `q.*` | `asm.ctrl_board`, `q.auto` | — | D, C (équipementier) | ≈1980s |
| 100 | `m.<segment>` | MAR | marchés | Patron : besoins CPU existants (12, C4), publics logiciels (revue), PC, mobile, et **contextes** automobile / aéro / spatial / défense (C3) | époque **ou** `tech_trigger` | — | monde | 1971 → |

**100 nœuds.** Les patrons (`<x>`, `<gen>`, `<tech>`, `<niveau>`) couvrent la suite des générations sans créer une microrecherche par norme.

### 4.13 Patron extensible pour les branches trop grandes [Proposition]

Une branche se décrit par **un nœud de famille plus des niveaux**, et non par une case par invention :

```
famille : gfx.3d
niveaux :
  1 fixe ; 2 programmable ; 3 unifié ; 4 lancer de rayons
  (chaque niveau porte : époque_repère, seuil de compétence,
   spécification débloquée, coût d'avance)
```

Une invention précise (un format de cache, une révision de bus) est une **spécification** du niveau, pas un nœud. Elle n'apparaît que dans la couche avancée (C6, « couche avancée »).

---

## 5. Exprimer les exigences : ET/OU, interfaces, maturité, capacité, fournisseurs et droits

### 5.1 Les cinq portes, évaluées dans l'ordre [Proposition]

Chaque produit, ou chaque projet de conception, passe par cinq portes. Chacune produit **son propre message de blocage** et **ses actions correctives**, ce qui prolonge C2.

| Porte | Question | Exemple de message | Actions proposées |
|---|---|---|---|
| **1. Savoir** | Sait-on concevoir ce qui doit l'être en interne ? | « L'équipe ne maîtrise pas encore la gestion d'énergie mobile. » | Rechercher · Recruter · Licencier (transfert) · Acheter la pièce à la place |
| **2. Accès** | Chaque emplacement a-t-il une route (D/A/L/C/S) ? | « Aucune mémoire disponible : pas d'offre fournisseur, pas de conception propre. » | Voir les fournisseurs · Codévelopper · Concevoir |
| **3. Compatibilité** | Les interfaces des pièces choisies concordent-elles ? | « La carte attend le socket K2, le CPU choisi utilise K3. » | Changer de pièce · Nouvelle révision de carte |
| **4. Qualification** | Le produit a-t-il les certificats exigés par le marché ciblé ? | « Marché automobile : qualification auto requise (capacité 42/60). » | Programme de qualification · Partenaire équipementier · Viser un autre marché |
| **5. Capacité et droits** | Peut-on produire et vendre en volume, légalement ? | « Licence OS limitée aux PC de bureau ; fonderie saturée jusqu'en mars. » | Renégocier · Réserver de la capacité · Second fournisseur |

**Séparer déblocage et faisabilité.**
- Le **déblocage** (portes 1 et 2 au niveau de la famille) dit : « je peux ouvrir un projet de portable ».
- La **faisabilité** (portes 3 à 5 et contraintes de specs) dit : « *cette* configuration de portable fonctionne ».

Par exemple, la somme des TDP doit rester inférieure à la capacité du refroidissement, et la capacité de la batterie divisée par la consommation doit atteindre l'autonomie visée. C'est exactement le rôle des jauges vert / orange / rouge du laboratoire CPU (C6, §7B), généralisées.

### 5.2 Grammaire des données [Proposition]

```gdscript
# Atomes d'exigence (tous sérialisables, sans code dans les données)
{"has": "cpu.mmu", "state": "MASTERED"}          # nœud possédé, état minimal
{"skill": "s.thermal", "min": 40}                 # jauge de compétence
{"access": "comp.cpu", "routes": ["D","A","L"]}   # au moins une route active
{"iface": "std.cpu.socket.*", "match": "slot:board.cpu_socket"}  # compatibilité
{"spec": "sum(tdp)", "<=": "slot:chassis.cooling_w"}             # faisabilité
{"qual": "q.auto", "scope": "product"}            # certificat du produit
{"right": "use", "asset": "sw.os.*", "scope": "asm.pc_desktop"}  # droit contractuel
{"supply": "slot:memory", "units_month": ">=plan"}               # capacité fournisseur
{"market": "m.server"}                             # segment disponible

# Composition
{"all": [ ... ]}   {"any": [ ... ]}   # pas de NOT : on évite la logique négative

# Exemple : recette asm.pc_desktop (extrait)
"asm.pc_desktop": {
  "slots": {
    "cpu":     {"accepts": "comp.cpu",   "provides_iface": "cpu_socket"},
    "board":   {"accepts": "mb.board",   "requires": {"iface": "cpu_socket", "match": "slot:cpu"}},
    "memory":  {"accepts": "mem.dram",   "requires": {"iface": "mem_bus", "match": "slot:board"}},
    "graphics":{"any": [ {"accepts": "comp.gfx.igp", "via": ["slot:board", "slot:cpu"]},
                         {"accepts": "comp.gfx.card", "requires": {"iface": "std.bus.*", "match": "slot:board"}} ]},
    "display": {"any": [ {"accepts": "comp.display.*", "mode": "integrated"},
                         {"external": true, "requires": {"iface": "std.display.out.*"}},
                         {"tv_output": true, "markets": ["m.home_pc"]} ]},
    "storage": {"accepts": ["sto.removable.*", "sto.hdd", "sto.ssd"], "min": 1},
    "power":   {"accepts": "comp.psu",   "spec": {"watts": ">= 1.3 * sum(power)"}},
    "chassis": {"accepts": "comp.chassis","spec": {"formfactor": "slot:board.formfactor",
                                                   "cooling_w": ">= sum(tdp)"}},
    "firmware":{"accepts": "sw.fw.boot", "routes": ["D","L","A"]},
    "os":      {"any": [ {"has": "sw.os.disk", "compatible_isa": "slot:cpu"},
                         {"right": "use", "asset": "sw.os.*", "compatible_isa": "slot:cpu"} ]}
  },
  "gates": {"all": [ {"qual": "q.consumer"},
                     {"any": [ {"has": "infra.assembly"}, {"contract": "assembly"} ]} ]},
  "markets": ["m.business_pc", "m.home_pc"]
}
```

### 5.3 Maturité, qualité et capacité

- **État d'un nœud TEC ou PRO**, dans le prolongement des étapes des programmes Concept (C6) :
  1. ENTREVU : piste visible ;
  2. ÉTUDIÉ : prototypable, zone rouge ;
  3. MAÎTRISÉ : conception fiable, zone verte ;
  4. INDUSTRIALISÉ : expérience de production ;
  5. DE RÉFÉRENCE : d'autres paient pour y accéder.
- Chaque nœud conserve le triplet **connaissance / expérience / confiance** existant. L'état est un **seuil de lecture** sur ce triplet, pas un booléen.
- **Qualité et grade** : une pièce porte un grade (commercial, industriel, auto, spatial, défense) qui découle de la validation et du tri des puces. Un marché exige un grade minimal.
- **Capacité** : chaque route porte un plafond mensuel (fab, fonderie, fournisseur, assemblage). C'est déjà vrai pour la fonderie dans le code (C7).
- **Coût d'avance** [Proposition] : utiliser une technologie **avant** son époque repère reste possible. En contrepartie, le coût, le risque et la durée augmentent, et la confiance baisse. Cela respecte C4 sans barrière artificielle.

### 5.4 Droits et licences : un registre séparé [Proposition]

```gdscript
right = {
  "id": "R-0012", "holder": "player", "grantor": "Norda Systems",
  "asset": "sw.os.norda_dos", "kind": "USE",   # USE | MANUFACTURE | SUBLICENSE | ISA | PATENT_POOL
  "scope": {"products": ["asm.pc_desktop"], "markets": ["m.business_pc"]},
  "royalty": {"per_unit": 18, "min_annual": 20000}, "exclusive": false,
  "expires": "1986-12", "knowledge_transfer": 0.25   # part du savoir transmise
}
```

**Règles :**
1. **Acheter** une pièce ne donne ni savoir ni droit de la fabriquer. On obtient une instance de composant et un peu d'expérience d'intégration.
2. Une **licence** donne un droit, et parfois un **transfert partiel de savoir**. Ce transfert est plafonné par la compétence d'absorption de l'équipe.
3. Le **codéveloppement** partage coûts, savoir et droits selon des parts négociées.
4. La **sous-traitance** garde la propriété du design, mais l'apprentissage industriel reste faible. C'est déjà le cas pour la fonderie externe (C7).

Ce registre sert aussi aux ventes du joueur : licences d'OS, de cœurs CPU, services de fonderie. Il prépare également les contrats de la Phase 10.

### 5.5 Deux exemples d'accès par des routes alternatives

**Exemple 1 — « Le PC de l'éditeur de logiciels », vers 1981.** Le joueur n'a **aucune** compétence CPU.

| Emplacement | Route choisie | Porte vérifiée |
|---|---|---|
| CPU | **A** : offre d'un fondeur tiers fictif, fiche technique qui publie le socket « K16 » | Accès ✓, interface fournie |
| Carte mère | **S** : conception déléguée à un sous-traitant, frais d'étude et marge réduite | Pas de savoir propre requis ; compatibilité K16 ✓ |
| Mémoire / stockage / alimentation / boîtier | **A** : catalogue fournisseurs | Capacité : allocation de 3 000 unités par mois |
| Graphique | **A** : chipset avec graphique intégré | Alternative « au moins un » satisfaite |
| Affichage | moniteur externe vendu à part | Sortie vidéo compatible ✓ |
| Firmware | **L** : éditeur de firmware tiers | Droit ✓ |
| OS | **D** : `sw.os.disk` du joueur, porté sur l'ISA achetée | Savoir ✓ ; compatibilité ISA ✓ |
| Qualification | **S** : labo tiers | `q.consumer` ✓ en 2 mois |

Le résultat est un PC viable, **sans CPU maison**. La marge est plus faible et la dépendance au fournisseur plus forte, mais l'OS maison crée une plateforme. Plus tard, le joueur peut **internaliser** la carte (D), puis éventuellement le CPU : c'est une option, pas un passage obligé.

**Exemple 2 — Accéder au procédé 1 µm.** Cet exemple s'appuie sur les mécanismes existants (C7, C8).

| Route | Conditions | Conséquences |
|---|---|---|
| **Fab interne (D)** | `s.cpu.miniaturization ≥ 55` (seuil `unlock` de `CpuDesign.gd:17`), un palier de fab qui supporte 1 µm, `s.ind.industrialization` suffisant | Investissement lourd ; meilleur coût et apprentissage à long terme ; peut vendre de la capacité |
| **Fonderie (S)** | `s.cpu.miniaturization ≥ 55` **et** une fonderie qui maîtrise 1 µm | Peu d'investissement ; coût unitaire plus élevé ; dépendance ; apprentissage réduit |
| **Codéveloppement avec une fonderie (C)** | `s.cpu.miniaturization ≥ 45` (seuil abaissé [Hypothèse]) et un accord de partage | Accès plus tôt ; droits partagés ; la fonderie peut vendre le procédé à des concurrents |

**[À trancher]** Avec une fonderie, le joueur doit-il quand même « savoir miniaturiser » ? La bible (§7B) le laisse entendre. Je propose de garder l'exigence, mais **abaissée**, parce que la fonderie fournit ses règles de conception.

### 5.6 Éviter les cycles et les dépendances impossibles

1. **Sens des arêtes « dures »** : SAV/CMP → TEC → PRO/LOG/COM → ASM → SRV/MAR. Une arête ne remonte jamais vers un type plus fondamental. L'effet de la pratique sur les compétences est un **flux** d'expérience, pas une arête.
2. **Synergies** : ce sont des arêtes **molles** (bonus ou malus), dans une table séparée. Elles peuvent être circulaires, car elles ne bloquent rien.
3. **Amorçage** : le cercle « OS → compilateur → OS » se rompt par la **compilation croisée** sur une plateforme tierce (`sw.tools.compiler` exige seulement une `plat.*`). Le cercle « CPU → outils → CPU » se rompt parce que les outils pour sa propre ISA passent par une plateforme tierce ou un simulateur.
4. **Aucun NOT** dans les exigences. Les exclusions (licence exclusive, embargo) sont des **états du monde** qui retirent une route, pas de la logique négative.

### 5.7 Points de validation automatique

Ce sont des tests déterministes dans `tests/`, dans l'esprit d'`AGENTS.md`.

| # | Vérification | Moment |
|---|---|---|
| V1 | Identifiants uniques, format valide, **aucun ID supprimé sans alias** | chargement et CI |
| V2 | Graphe des arêtes dures **acyclique** (tri topologique) | CI |
| V3 | Types cohérents par arête (par exemple, aucun ASM prérequis d'un SAV) | CI |
| V4 | Chaque atome référence un nœud, une interface ou une qualification existants | CI |
| V5 | **Accessibilité** : depuis l'état de départ 1971, chaque nœud est atteignable par au moins une combinaison de routes | CI |
| V6 | **« Aucun CPU obligatoire »** : pour chaque ASM, il existe une solution où aucun emplacement n'exige un nœud `cpu.*` en route D | CI |
| V7 | **Voie logicielle** : un profil scripté 100 % logiciel atteint `srv.cloud` sans nœud matériel en route D | CI |
| V8 | Cohérence des époques : l'époque repère d'un prérequis ne dépasse pas celle du dépendant de plus de 3 ans (avertissement) | CI |
| V9 | Clôture des interfaces : toute interface consommée a au moins un fournisseur (interne ou offre) dans l'époque visée | CI |
| V10 | Groupes « au moins un » à une seule option = avertissement (odeur de conception) | CI |
| V11 | Chaque porte qui échoue renvoie un message et **au moins une action** | test unitaire du moteur |
| V12 | Migration : une sauvegarde v28 figée charge et convertit `technologies{}` vers les états de nœuds (§6.5) | `save_integrity_test` |

---

## 6. Les six chaînes d'accès illustrées

### 6.1 Chaîne 1 — Joueur logiciel indépendant, sans aucun matériel

```
srv.sw.contract ──► sw.app.business (sur plat.3p.mini) ──► srv.sw.maintenance
      │                    │
      │                    └─► portage vers d'autres plat.3p.* (base installée ×2)
      ▼
sw.tools.asm ─► sw.tools.compiler ─► sw.os.disk ──► LICENCE OEM de l'OS
                                        │            aux constructeurs tiers (redevance/machine)
                                        ├─► sw.os.gui ─► sw.os.multiuser ─► sw.net.stack
                                        │                                   └─► sw.sec.* ─► q.defense (clients publics)
srv.batch (infra.compute loué) ──────────────────────────────► srv.cloud (sw.virt + datacenter)
```

- **Vivre sans CPU** : la plateforme est **toujours tierce**. Le levier du joueur passe par les **droits** : il licencie son OS, ses compilateurs et son SGBD aux constructeurs pilotés par l'IA.
- **Gagner durablement** : maintenance récurrente, redevances OEM, services. La revue a déjà construit la mécanique économique : le parc s'épuise, et le récurrent crée des obligations (C13).
- **Condition de conception** : les constructeurs IA doivent avoir besoin d'OS et d'outils, sinon la route OEM est morte (§7, D6).

### 6.2 Chaîne 2 — CPU vendu comme composant

```
k.logic.digital ─► asm.ctrl_board (conseillée : première expérience matérielle, existe déjà en ELECTRONICS)
k.semi.mos + s.cpu.* ─► cpu.isa.w4 ─► proc.node.10µm (via infra.foundry) + pkg.standard
    ─► comp.cpu ─► m.calculator / m.embedded / m.industrial (existants)
          │
          ├─► ÉCOSYSTÈME : sw.tools.asm pour SA propre ISA (sinon les clients OEM
          │    n'adoptent pas le CPU ; synergie directe avec un studio logiciel)
          ├─► licence de seconde source à un autre fabricant (redevance + crédibilité)
          └─► générations : w8 → w16 + cpu.mmu → cpu.cache → … (existant : plans, gamme, fab)
```

Le client d'un CPU composant est un **assembleur tiers**. Sa décision dépend des performances, du prix, de la disponibilité, de la **documentation et des outils**, et du risque fournisseur. Un CPU sans outils se vend mal : c'est le pont naturel entre les deux voies.

### 6.3 Chaîne 3 — PC fixe

Il suit la recette du §5.2, emplacement par emplacement.

| Emplacement | Route interne | Route externe | Contrainte |
|---|---|---|---|
| CPU | `comp.cpu` | offre CPU (A) | socket |
| Mémoire | `mem.dram` (D) | modules (A) | bus mémoire de la carte, capacité minimale de l'époque |
| Carte mère | `mb.board` (D) | conception déléguée (S), carte achetée (A) | socket, bus, format |
| Graphique | `gfx.*` + `comp.gfx.card` | graphique intégré (A), carte (A) | **l'un OU l'autre** |
| Affichage | écran intégré | moniteur externe, sortie TV (marché domestique) | sortie vidéo |
| Stockage | — | disquette, disque dur ou SSD (A) | interface |
| Alimentation / boîtier | conception (D) + tôlerie (S) | A | W ≥ 1,3 × consommation ; format ; TDP |
| Firmware | `sw.fw.boot` | L | — |
| OS | `sw.os.*` | **licence tierce** | compatibilité ISA et droit |
| Portes | — | — | `q.consumer`, assemblage (interne ou sous-traité), canal de distribution |

### 6.4 Chaîne 4 — Portable

C'est le PC fixe, avec **des composants de catégorie mobile** et **des contraintes de faisabilité** propres :

| Exigence | Nœuds | Alternatives |
|---|---|---|
| Écran intégré plat | `comp.display.lcd` | acheté (courant) ou codéveloppé |
| Batterie et autonomie | `bat.pack.*` + `s.power ≥ 30` | cellules achetées ; pack propre ou sous-traité |
| Faible consommation | `cpu.pm` sur le CPU retenu | CPU basse consommation acheté |
| Thermique compacte | `cool.compact` + `s.thermal ≥ 45` | refroidissement acheté |
| Miniaturisation de carte | `proc.pcb.smt` | conception déléguée spécialisée |
| Contraintes de faisabilité | TDP ≤ capacité du refroidissement ; poids ≤ cible ; autonomie ≥ cible du segment | — |

Le marché `MOBILE_COMPUTING` existe déjà (époque 1997, `tech_trigger` 82). Un portable « de transport » plus lourd peut viser les professionnels plus tôt : l'époque est un repère, pas une barrière.

### 6.5 Chaîne 5 — Serveur

- **Calcul** : CPU (D ou A) avec `mem.ecc` pris en charge, et, au moins un, multiprocesseur **ou** multicœur.
- **Mémoire ECC** : contrôleur propre ou chipset acheté.
- **Stockage** : disques et contrôleur redondant.
- **Réseau** : `net.lan`.
- **Alimentation** : redondante (variante de `comp.psu`).
- **Boîtier** : rack.
- **OS** : `sw.os.multiuser`, propre ou licencié.
- **Service** : `srv.sw.maintenance` avec niveau de service (**obligatoire pour ce marché**).
- **Portes** : exigence de fiabilité du segment `SERVER`, qui valorise déjà la fiabilité dans `MarketManager`.

Un éditeur d'OS multi-utilisateur a ici un avantage naturel : il fournit logiciel **et** support.

### 6.6 Chaîne 6a — Téléphone / smartphone

| Emplacement | Route typique | Alternative |
|---|---|---|
| SoC | acheter un SoC | `cpu.soc` propre (très coûteux) ; licence de cœurs et de graphique |
| Mémoire / Flash | A | — |
| Modem cellulaire | **A** (courant) | D **avec licence obligatoire** des brevets essentiels |
| Écran tactile | A | codéveloppé |
| Batterie / gestion d'énergie | A + pack | `pwr.pmic` propre |
| Capteurs | A | — |
| OS mobile | licence | `sw.os.mobile` propre (atout majeur d'un éditeur) |
| Portes | `q.radio`, certification opérateur, **canal opérateurs** | — |

### 6.7 Chaîne 6b — Console (variante courte)

- Calcul (A ou D) et `gfx.3d` (**souvent codéveloppé** avec un spécialiste graphique).
- Mémoire, stockage amovible (cartouche puis optique), manettes, OS / firmware léger.
- Modèle économique **plateforme** : console vendue à faible marge, redevances sur les jeux de tiers. C'est un service (SRV) plus des droits, la même grammaire que la licence d'OS.

### 6.8 Automobile, aéronautique, spatial et défense : des marchés, pas des branches

Conformément à C3, aucune « technologie automobile » ne se débloque par magie. L'accès demande quatre choses :

1. une **variante de grade** d'un composant existant (validation, tri des puces, plage de température) ;
2. une **qualification** (`q.auto`, `q.aero`, `q.space`, `q.defense`), coûteuse, longue et auditée ;
3. un **client ou partenaire** : équipementier automobile, maître d'œuvre, agence. L'entrée se fait souvent par **codéveloppement** ;
4. des **obligations** : support pendant 10 à 15 ans ou plus, traçabilité des lots (le SAV existant suit déjà les lots), pénalités.

Un joueur logiciel peut entrer par le **logiciel qualifié**, par exemple un OS temps réel avec assurance de conception, sans produire de matériel.

---

## 7. Progression visible, du garage à la croissance

### 7.1 Principe : la carte ne s'affiche jamais en entier [Proposition, fidèle à C14]

| Stade | Ce que le joueur voit de la carte | Nombre visible au maximum |
|---|---|---|
| **Garage** (0-30 min) | Des **objets** de la scène, pas une carte. Terminal = savoirs du fondateur ; tableau de liège = **pistes** (idées, plateformes connues) | 2 savoirs, 3 pistes |
| **Atelier** (2-5 personnes) | Un **carnet technique** : une fiche par domaine ouvert, « acquis / en cours / prochaines pistes » | 1 à 3 domaines, 3 pistes par domaine |
| **PME / divisions** | Un **atlas** par domaine : anneau de familles, brouillard sur l'inconnu, avec des **carrefours stratégiques** mis en avant | 1 domaine à la fois, environ 8 à 12 familles |
| **Groupe** | Atlas complet **filtré**, recettes de produits, carte des fournisseurs (chaîne de valeur), responsables délégués | filtres obligatoires ; vue « ingénieur » sur PC |

**Règles de découverte.** Un nœud devient ENTREVU si l'une de ces conditions est remplie :
- un prérequis est acquis ;
- un **client** le demande (contrat, appel d'offres) ;
- un **concurrent ou fournisseur** le commercialise (presse, rumeur) ;
- une **découverte d'équipe** le révèle (C6) ;
- son époque repère est atteinte **et** il touche un domaine ouvert.

Un nœud inconnu **n'est jamais affiché**, pas même en gris.

### 7.2 Maquettes téléphone (portrait)

**Fiche domaine (carnet technique) :**
```
┌──────────────────────────────┐
│ ◂ Mémoire           Atelier  │
├──────────────────────────────┤
│ ACQUIS                       │
│ ● Contrôleur mémoire  ▮▮▮▯ 72│
│ EN COURS                     │
│ ◐ ECC  — 3 mois · conf. moy. │
│ PISTES (3)                   │
│ ○ Flash      [Étudier][Acheter]
│   « Fournisseur Ardent en vend »
│ ○ Modules    [Concevoir][Acheter]
│ ○ Mém. graphique  🔒 requiert │
│   Graphique 2D  → [Voir]     │
└──────────────────────────────┘
```

**Recette produit (la liste des éléments manquants) :**
```
┌──────────────────────────────┐
│ Projet : PC de bureau  ⚠ 2/11│
├──────────────────────────────┤
│ ✓ CPU       Achat · Helix 16 │
│ ✓ Carte     Sous-traitée     │
│ ✗ Mémoire   Aucune compatible│
│    → [Offres] [Concevoir]    │
│ ✓ Graphique Intégré (chipset)│
│ ✓ OS        Maison · Garage-DOS
│ ✗ Qualif.   Grand public     │
│    → [Labo tiers 2 mois 4 k€]│
│ ⋯ 5 autres ✓   [Tout voir]   │
└──────────────────────────────┘
```

**Carrefour stratégique :** au maximum 3 cartes, avec leurs conséquences et sans « bonne réponse ».
```
┌──────────────────────────────┐
│ CARREFOUR · Jeu d'instructions│
├──────────────────────────────┤
│ [A] ISA propre               │
│  + plateforme à vous         │
│  − logiciels à créer, 14 mois│
│ [B] ISA sous licence         │
│  + logiciels existants       │
│  − redevance 6 %/puce        │
│ [C] Plus tard                │
│  Nora : « Vos 3 clients      │
│  embarqués se moquent de l'ISA»
└──────────────────────────────┘
```

**Sur PC**, les mêmes composants sont posés côte à côte : fiche domaine | recette | détail. Une **vue ingénieur** facultative affiche le sous-graphe filtré d'un domaine ou d'un produit, avec le chemin surligné. Elle n'est jamais obligatoire et jamais globale.

### 7.3 Les 30 premières minutes

Le parcours s'aligne sur la revue logicielle (C13, §3.2).

| Minute | Événement | Choix réel | Rôle de la carte |
|---|---|---|---|
| 0-2 | Garage, téléphone, contrat | Tarif, approche, **propriété du code** | Aucune carte : 2 savoirs de départ (`k.sw.programming`, domaine client) |
| 2-9 | Contrat en cours | Corriger ou noter les défauts ; jalon client | La jauge `s.sw.engineering` progresse de façon visible |
| ≈10 | Idée de produit épinglée | Contrat, produit, ou partage de l'agenda | **Première piste** sur le liège |
| ≈11 | Brief produit | **Plateforme cible** : bureau de temps partagé **ou** mini-ordinateur tiers | **Premier « au moins un »** du jeu : `sw.app.business` exige une `plat.*` |
| 12-20 | Développement | Répartition de l'agenda | Le module réutilisé (si licence de code) réduit la charge |
| ≈20 | Publication | Tester encore ou publier ; prix, licence ou location | — |
| ≈22-27 | Visites commerciales, première vente, premier incident | Argument, correctif ou contournement | `srv.sw.maintenance` devient **acquis** (premier service récurrent) |
| ≈28-30 | Bilan | Épingler un objectif | Le liège montre **2 à 3 pistes**, par exemple : « Outils pour Norda 16 » (métier D) · « Porter vers Calcul-Service » · *si un client industriel a été servi* « Boîtier de commande » (`asm.ctrl_board`, première porte matérielle **proposée, jamais imposée**) |

La **voie gagnante logicielle** est complète : prestations, édition, maintenance, puis outils et OS.

L'établi électronique n'apparaît que sur un **besoin concret** : demande d'un client, proposition d'un partenaire, ou décision du joueur (troisième déclencheur, question ouverte de la revue).

### 7.4 Signalement des éléments manquants

- Toujours sous la forme **« ce qui manque → action »** (portes du §5.1), jamais un simple cadenas.
- Le **bras droit** (Nora) résume au plus une phrase par blocage et signale l'**incertitude**, comme pour les estimations CPU (C6).
- Chaque action indique **coût, délai et dépendance créée**. Par exemple : « Acheter : immédiat, 12 €/u, dépendance fournisseur moyenne ».
- Une alerte « **dépendance critique** » apparaît quand un fournisseur unique tient un emplacement de plusieurs produits. Cela prépare la Phase 9.

### 7.5 Correspondance avec le code existant [Proposition, pour plus tard]

| Existant | Devient |
|---|---|
| `ResearchManager.technologies{}` (scalaires) | Vue **agrégée** calculée depuis les états de nœuds ; migration v28+ : chaque scalaire initialise les jauges du domaine |
| `CPU_CAPABILITIES` | `s.cpu.architecture` / `layout` / `miniaturization` (CMP), sans changement de sens |
| Table des procédés de `CpuDesign` (`unlock`) | `proc.node.<x>` avec l'atome `skill ≥ unlock` **ET** une route fab ou fonderie |
| `MARKET_NEEDS` (`historical_year` / `tech_trigger`) | `m.<segment>` avec le même mécanisme, généralisé au logiciel (corrige l'écart signalé par la revue sur `min_year`) |
| `SoftwareStudioManager.CATALOG` | Nœuds `sw.*` avec exigence de plateforme (corrige P4 : l'OS dépend d'une machine) |
| Approches INTERNAL / HYBRID / EXTERNAL | Routes **par emplacement** ; l'approche de projet devient un préréglage de routes |
| Étapes de `StartupManager` | Premier chemin matériel **parmi d'autres**, via `asm.ctrl_board` |
| `PatentManager` (candidats par secteur) | Brevets rattachés aux **familles** TEC, inscrits au registre des droits |

Conformément à C15, rien de cela n'ouvre un secteur jouable. C'est le **squelette de données** de la Phase 2. On l'alimente d'abord avec les seuls nœuds logiciel, CPU et fabrication.

---

## 8. Sources historiques primaires

Ces liens n'ont **pas pu être ouverts** depuis mon environnement : l'accès réseau sortant y est bloqué. Il faut les vérifier avant de les inscrire dans la bible.

| Fait | Source |
|---|---|
| Intel 4004, 1971, 10 µm | Intel, *The Story of the Intel 4004* — https://www.intel.com/content/www/us/en/history/museum-story-of-intel-4004.html |
| DRAM (1970), EPROM, microprocesseur (1971), jalons du semi-conducteur | Computer History Museum, *The Silicon Engine* — https://www.computerhistory.org/siliconengine/timeline/ |
| IBM PC 5150 (1981) | IBM Heritage — https://www.ibm.com/history/personal-computer |
| Li-ion commercialisé en 1991 | Communiqué du prix Nobel de chimie 2019 — https://www.nobelprize.org/prizes/chemistry/2019/press-release/ |
| Normes d'interfaces | PCI-SIG — https://pcisig.com/specifications · JEDEC (DDR, LPDDR, HBM) — https://www.jedec.org/standards-documents · USB-IF — https://www.usb.org/documents · IEEE 802.3 (Ethernet) et IEEE 754 (virgule flottante) sur standards.ieee.org |
| Qualifications | AEC-Q100 — https://www.aecouncil.com/AECDocuments.html · ISO 26262-1:2018 — https://www.iso.org/standard/68383.html · ECSS (spatial européen) — https://ecss.nl/standards/ · RTCA DO-178C / DO-254 (avionique, catalogue RTCA) |
| Unix | D. M. Ritchie, « The Evolution of the Unix Time-sharing System », *AT&T Bell Laboratories Technical Journal* 63(8), 1984 |

Les autres dates du §3 sont des **repères de conception arrondis** [Hypothèse], à ne pas afficher comme faits en jeu.

---

## 9. Priorités, décisions et pièges

### 9.1 Dix priorités structurantes pour la conception

1. **Typer strictement les nœuds** (§2.1) et **séparer les trois graphes** : technologie, chaîne de valeur, produits.
2. **Des produits assemblés à emplacements et interfaces**, jamais des liens directs de nœud à produit. C'est ce qui rend C2 implémentable.
3. **Cinq portes explicables** (savoir, accès, compatibilité, qualification, capacité et droits), chacune avec son message et ses actions.
4. **Des routes par emplacement** (D/A/L/C/S/R), avec le test V6 « aucun CPU obligatoire » comme garde-fou permanent de la vision.
5. **Les plateformes comme colonne vertébrale commune** au logiciel et au matériel (C13) : l'ISA, l'OS et la base installée décident des marchés.
6. **Généraliser le triplet connaissance / expérience / confiance** et les jauges vert / orange / rouge du CPU à toutes les TEC (C6).
7. **L'époque comme repère** : `historical_year` + `tech_trigger` + **coût d'avance**, jamais comme barrière (C4).
8. **Un registre des droits séparé** (licences, redevances, exclusivités, transfert de savoir). Il sert aux achats **et** aux ventes du joueur.
9. **Une découverte progressive** : pistes (3 au maximum), recettes, carrefours ; aucun nœud inconnu affiché ; atlas seulement au stade PME.
10. **Un validateur de données en CI** (V1-V12) et une croissance **par patrons**, pas par inventaire exhaustif.

### 9.2 Dix décisions à trancher avant implémentation

| # | Décision | Options | Ma recommandation |
|---|---|---|---|
| D1 | Granularité des nœuds | une case par invention / familles à niveaux | familles à niveaux, avec les inventions comme spécifications |
| D2 | État des nœuds | jauge continue / états discrets / hybride | hybride : triplet continu et états comme seuils de lecture |
| D3 | Savoir requis avec une fonderie externe | plein / abaissé / aucun | abaissé (§5.5) |
| D4 | Offre fournisseur disponible dès 1971 pour quels emplacements, et combien de fournisseurs fictifs par composant | — | au moins 2 par composant courant, 1 pour les pièces rares, avec des pénuries scénarisées |
| D5 | Une licence transfère-t-elle du savoir ? | non / oui, plafonné | oui, plafonné par la compétence d'absorption |
| D6 | Les constructeurs IA achètent-ils les OS, outils et CPU du joueur ? | — | **oui**, sinon la chaîne 1 et la route OEM sont mortes ; il faut un modèle de demande B2B |
| D7 | Le signal technologique : global ou par domaine ? Le joueur peut-il accélérer le monde ? | — | par domaine ; le joueur influence, conforme à la bible §7A |
| D8 | Qualification : acquise une fois, ou certificat par produit ? | — | les deux : capacité d'entreprise et certificat par produit |
| D9 | Noms de normes réels ou fictifs en jeu | — | **fictifs** : plusieurs noms (USB, HDMI…) sont des marques sous licence ; même logique que la note INPI de `garage-interactions-v031.md` |
| D10 | Où vit la carte dans l'interface, et quand apparaît-elle ? | objet du garage / onglet / écran de division | tableau de liège au garage, carnet à la première embauche, atlas au stade des divisions |

### 9.3 Cinq pièges de conception

1. **Le mur de 100 cases.** Un arbre global, même joli, contredit C14 et devient illisible sur un téléphone de 360 px. Les recettes et les pistes doivent faire le travail, pas l'arbre.
2. **Confondre déblocage et faisabilité.** « Portable débloqué » ne signifie pas qu'un portable précis fonctionne. Si les contraintes de specs (TDP, autonomie, poids) sont absentes, les recettes deviennent des cases à cocher sans décision.
3. **Déséquilibrer acheter et faire.** Des fournisseurs trop généreux rendent l'intégration verticale inutile. Trop rares, ils rendent le CPU **obligatoire de fait**, ce qui trahit la vision. Chaque route a besoin d'un avantage **et** d'un prix visibles : marge, contrôle, dépendance, délai.
4. **Des dépendances circulaires cachées.** Des synergies traitées comme des prérequis, ou des amorçages oubliés (OS ↔ compilateur ↔ CPU), bloquent silencieusement une partie. Il faut des arêtes dures orientées, des synergies séparées, et les tests V2 et V5.
5. **Barrières de date déguisées et microrecherche.** Un « USB 3.2 débloqué en 2017 », une case par révision de norme, ou une licence qui donne du savoir gratuitement tuent le rythme et l'histoire alternative voulue par la bible. Il faut s'en tenir aux patrons, aux coûts d'avance et aux transferts plafonnés.

---

**En résumé.** Le dépôt pose déjà l'essentiel de la **règle** : briques TOUTES / AU MOINS UNE, interfaces, qualification, capacité, fournisseurs, dates non bloquantes, marchés comme contextes. Il manque une **structure de données** pour l'appliquer. La proposition tient en trois éléments :
- **typer les nœuds et séparer les trois graphes** ;
- **faire des produits des recettes à emplacements** évaluées par cinq portes explicables ;
- **ne montrer que des pistes, des recettes et des carrefours**, jamais l'arbre entier.

Ce socle peut être alimenté d'abord par le logiciel, le CPU et la fabrication, sans ouvrir de nouveau secteur avant la validation de la tranche verticale.

---

# Addendum à la carte technologique : domaines de gameplay, conception paramétrable, spécialisation et marchés

## Statut

- **Source.** Même lecture que la carte précédente : dépôt `vadorus/addonhardwaregame2d`, branche `feature/ui-ux-v0.3.1`, HEAD `b600d20`. Je n'ai modifié aucun fichier, fait aucun commit ni lancé aucun test.
- **Balises.** Je garde les mêmes conventions : **[Constat]** pour ce qui est dans le dépôt, **[Proposition]** pour mes recommandations, **[À trancher]** pour les décisions du créateur, **[Illustratif]** pour les chiffres non équilibrés.

### Ce qui figurait déjà dans la carte et ce qui est nouveau

| Sujet | Déjà dans la carte | Nouveau dans cet addendum |
|---|---|---|
| Types de nœuds, trois graphes, cinq portes, routes D/A/L/C/S/R | ✓ (§2, §5) | — (réutilisés tels quels) |
| Nœuds de recherche CPU, graphique, mémoire, etc. | ✓ (§4, dimension A seulement) | **Dimension B** : conception paramétrable du produit ; **dimension C** : lignées d'architecture et spécialisation d'équipe |
| Chaînes d'accès PC, portable, serveur, téléphone, console | ✓ (§6) | Ouverture à **tous** les domaines de gameplay, pas seulement ceux qui mènent au PC |
| Logiciel | Métiers de la revue, OS, outils, sécurité (§4.3, §6.1) | **Tableau complet** des domaines logiciels, sous-familles, marchés et modèles de revenus |
| Marchés | Patron `m.<segment>`, contextes auto/aéro/spatial/défense (§6.8) | **Tableau des marchés aval** matériels et logiciels, dont **maritime** et tablettes |
| Paramètres produit | Mention du « couche avancée » CPU | **Matrice des curseurs** CPU / GPU / mémoire / stockage / écran / batterie / alimentation / radio, et **règles contre le curseur toujours optimal** |
| Progression | Triplet connaissance / expérience / confiance | **Boucle complète** recherche → XP → architecture → segment → ventes → retour d'expérience, et **trois générations CPU chiffrées** |

---

## 1. Vue grossière pour le joueur : les « ailes » de l'entreprise [Proposition]

Le joueur ne voit jamais une liste de 100 nœuds. Il voit **des ailes d'activité** qui s'ouvrent une à une dans la scène : bureau, atelier, laboratoire, usine, salle serveurs. Chaque aile regroupe des familles. La liste est volontairement **non exhaustive** : on pourra en ajouter.

| Aile (vue joueur) | Ce qu'on y fait | Exemples de familles |
|---|---|---|
| **Studio logiciel** | Éditer, vendre, maintenir des logiciels | gestion, outils, OS, bases de données, création, jeux (plus tard) |
| **Services et exploitation** | Faire tourner des machines pour des clients | bureau de services, hébergement, web, cloud, services gérés |
| **Réseaux et télécoms** | Relier les machines et les gens | équipements réseau, logiciels réseau, radio, opérateur (très tard) |
| **Sécurité et confiance** | Protéger systèmes et données | contrôle d'accès, chiffrement, audit, sécurité défense |
| **Processeurs** | Concevoir des puces de calcul | CPU, microcontrôleurs, DSP, SoC, accélérateurs IA |
| **Graphique et image** | Afficher et calculer des pixels | contrôleurs d'affichage, GPU, vidéo, calcul parallèle |
| **Mémoire et stockage** | Retenir les données | DRAM, SRAM, Flash, disques, SSD, contrôleurs |
| **Électronique système** | Relier et alimenter | cartes mères, chipsets, alimentations, refroidissement, boîtiers |
| **Interfaces et mobilité** | Ce que l'utilisateur touche et emporte | écrans, tactile, batteries, capteurs, caméras, audio |
| **Appareils** | Vendre un produit complet | terminaux, PC, portables, serveurs, consoles, tablettes, téléphones, objets connectés |
| **Systèmes embarqués et critiques** | Mettre le calcul dans des machines | industrie, automobile, avionique, naval, spatial, défense, médical |
| **Fabrication** | Produire soi-même ou pour d'autres | fonderie, packaging, assemblage, test, services de fabrication |

**Règle d'affichage.** Une aile n'apparaît que si le joueur y a un projet, une demande client ou une piste. C'est la règle déjà établie dans la bible (§6A) [Constat]. Les ailes ne sont pas hiérarchisées : le Studio logiciel peut rester l'aile principale d'une partie entière.

---

## 2. Vue détaillée pour la conception : trois dimensions par famille

Chaque famille de composants ou de logiciels possède trois dimensions liées mais distinctes.

| Dimension | Question | Nature | Exemple CPU |
|---|---|---|---|
| **A. Recherche et technologies** | Que sait faire l'entreprise ? | Nœuds du graphe technologique (carte, §4) : jauges et états | pipeline, cache sur puce, gestion d'énergie, procédé 1 µm |
| **B. Conception paramétrable** | Quel produit précis sort-on, avec quels compromis ? | Curseurs bornés par A, évalués par segment | 2 cœurs, 25 MHz, 8 Ko de cache, 3 W, gamme de trois modèles |
| **C. Lignée d'architecture et équipe** | Quelle identité technique accumule-t-on, et pour quels usages ? | Objet persistant qui traverse les générations | la lignée « basse tension » de l'équipe embarquée, sa dette et sa plasticité |

**[Constat]** Le dépôt a déjà une bonne partie de A et B pour le CPU :
- paramètres : cœurs, fréquence, IPC, cache, TDP, gravure, chiplets ;
- cinq axes de lecture ;
- trois plans prudent / équilibré / audacieux ;
- gamme Essentiel / Signature / Apex ;
- rendement et tri des puces (`CPU_VERTICAL_SLICE.md`).

Il **n'a pas encore C** : une génération dérive d'un « brief », pas d'une **lignée** qui aurait sa propre spécialisation.

**[Proposition] La lignée d'architecture est l'élément central qui manque.**

```gdscript
architecture_lineage = {
  "id": "arch.cpu.brise", "family": "CPU", "parent": "arch.cpu.garage1",
  "traits": ["LOW_VOLTAGE", "SMALL_DIE"],   # orientations de conception
  "segment_fit": {"EMBEDDED": 0.9, "MOBILE": 0.7, "SERVER": 0.3},
  "plasticity": 55,        # facilité à se décliner hors de sa cible (0-100)
  "tech_debt": 18,         # accumulée à chaque révision rapide
  "team_xp": {"design": 42, "validation": 35, "segment:EMBEDDED": 60},
  "compat_contract": "isa.brise16",  # ce qui casse si on rompt la lignée
  "generations": ["BR-1", "BR-2"]
}
```

- Une **génération** hérite des traits de sa lignée : elle est rapide et sûre à développer, mais limitée par la plasticité.
- Une **nouvelle lignée** coûte davantage, prend plus de temps et rompt la compatibilité. En échange, elle peut adopter d'autres traits.
- L'équipe **propose** une nouvelle lignée quand les demandes d'un segment dépassent ce que la lignée actuelle peut atteindre. Exemple : « Nos clients serveurs demandent de l'ECC et quatre sockets ; la lignée Brise n'a pas été pensée pour ça. »

C'est ainsi que l'équipe « crée de nouvelles architectures en fonction des usages » au lieu de faire monter une jauge universelle.

**Traits d'architecture proposés.** On les obtient par la recherche (A) **et** par l'expérience dans un segment (C). Liste non exhaustive :

| Famille | Traits possibles |
|---|---|
| CPU | basse tension · haute fréquence · large superscalaire · vectoriel · cache massif · fiabilité en double exécution · temps réel déterministe · durci radiations · multiprocesseur · hétérogène (gros et petits cœurs) · personnalisable pour un client |
| GPU | pipeline fixe économique · programmable · unifié · orienté calcul · orienté vidéo · tuiles basse consommation (mobile) |
| Mémoire | densité · faible latence · bande passante · basse consommation · haute endurance · grade étendu |
| Stockage | capacité · faible latence · endurance · robustesse aux chocs · faible coût par Go |
| Logiciel | portable · optimisé pour une plateforme · modulaire · temps réel · certifiable · multi-utilisateur · orienté réseau |

---

## 3. Domaines logiciels : sous-familles, marchés et revenus

**[Constat]** La revue logicielle a déjà défini six métiers : prestation, maintenance, édition, outils, système, exploitation. Le code ne compte que 4 produits (C12 de la carte).

**[Nouveau]** Le tableau ci-dessous élargit le périmètre. Aucune ligne n'exige de matériel propre. Les époques sont des repères, jamais des barrières.

| Domaine | Sous-familles (non exhaustif) | Marchés principaux | Modèles de revenus | Époque repère |
|---|---|---|---|---|
| **Systèmes d'exploitation** | moniteur, OS à disque, multi-utilisateur, temps réel (RTOS), GUI, serveur, mobile, embarqué certifié, console | constructeurs (OEM), PC, serveurs, embarqué, auto/aéro, consoles, téléphones | licence par machine, redevance OEM, support, mises à jour majeures | 1971 → |
| **Outils de développement** | assembleurs, compilateurs, débogueurs, environnements de développement, bibliothèques, simulateurs, outils de CAO électronique, outils de test | programmeurs, constructeurs de puces, industrie, éducation | licence par poste, maintenance, **contrats constructeur** (outils pour sa puce) | 1971 → |
| **Logiciels métier et gestion** | stock, facturation, paie, comptabilité, planification, gestion commerciale, logiciels sectoriels (santé, banque, logistique) | PME, grands comptes, administrations | licence + maintenance, location, adaptations sur mesure, abonnement (plus tard) | 1971 → |
| **Bases de données** | fichiers indexés, SGBD relationnel, transactionnel, décisionnel, distribué | grands comptes, éditeurs tiers, web, cloud | licence par serveur ou processeur, support, service géré | ≈1978 → |
| **Serveurs et réseaux** | pile réseau, messagerie, serveur de fichiers, annuaire, administration système, supervision | entreprises, opérateurs, hébergeurs | licence serveur, contrats d'administration | ≈1980s → |
| **Navigateurs, web et pages internet** | services télématiques, serveur web, navigateur, **création de sites pour clients**, commerce en ligne, hébergement, moteur de recherche | grand public, entreprises, annonceurs | prestation de sites, hébergement mensuel, publicité, commissions | télématique ≈1980s ; web ≈1991-95 → |
| **Création d'images et de contenus** | traitement de texte, PAO, retouche d'image, dessin vectoriel, CAO industrielle, 3D, montage vidéo, audio | bureaux, imprimeurs, studios, ingénieurs, créatifs | licence premium, versions éducation, abonnement (plus tard) ; **synergie GPU** | ≈1978-85 → |
| **Sécurité** | contrôle d'accès, chiffrement, antivirus, pare-feu, audit, gestion d'identité, sécurité certifiée défense | administrations, banques, défense, grand public | licence, abonnement aux signatures, audits, **contrats publics** | 1970s (accès) → 1990s → |
| **Pilotes et firmware** | BIOS/démarrage, pilotes de périphériques, microcode, firmware de disque ou de modem | fabricants de matériel (**y compris les concurrents IA**) | contrat de développement, redevance par unité, maintenance | 1975 → |
| **Embarqué et critique** | contrôle industriel, logiciel automobile, avionique certifiée, naval, spatial, médical | équipementiers, maîtres d'œuvre, agences | contrats longs, certification facturée, support de 10 à 30 ans | 1971 → |
| **Jeux et loisirs** (proposé) | jeux PC, jeux console (redevance à la plateforme), éducatif | grand public | ventes, éditeur tiers, **redevance plateforme** si le joueur possède la console | ≈1977 → |
| **Services gérés et cloud** | infogérance, hébergement, SaaS, stockage en ligne | entreprises, grand public | abonnement, niveau de service, capacité louée | 1971 (bureau de services) → 2006 |
| **IA (plus tard)** | systèmes experts, reconnaissance, apprentissage, modèles, assistants | entreprises, grand public, défense | licence, API à l'usage, contrats ; **synergie** calcul GPU / accélérateurs | systèmes experts ≈1980s ; moderne ≈2012 → |

### Voies communes à tous les domaines logiciels [Proposition]

Elles prolongent la revue logicielle :

- **Vente** : directe, revendeurs, constructeurs (OEM), catalogues, puis boutiques et téléchargement selon l'époque.
- **Maintenance** : un contrat avec un niveau de service, donc des obligations mesurées en jours d'assistance.
- **Contrats** : sur mesure, adaptation, portage, certification, et la clause de **propriété du code** établie par la revue.
- **Mises à jour** : correctifs gratuits sous maintenance, versions majeures payantes, fin de support annoncée.

La **montée en gamme logicielle** suit les domaines (outils → OS → bases de données → services), jamais le passage au matériel. La plateforme reste tierce tant que le joueur le souhaite (V7 de la carte).

---

## 4. Marchés aval, matériels et logiciels

**[Constat]** `MarketManager` connaît 12 besoins CPU. Les contextes public, militaire et spatial sont définis comme des **contextes de clients** (bible §15).

**[Nouveau]** Le tableau suivant regroupe les marchés grossiers. Une famille, CPU ou logiciel, peut en desservir plusieurs **après adaptation, qualification ou certification**.

| Marché | Critères dominants | Matériel typique demandé | Logiciel typique demandé | Barrière d'entrée | Durée de support |
|---|---|---|---|---|---|
| **PC (bureau)** | performance/prix, compatibilité, marque | CPU, GPU, mémoire, stockage, cartes, PC complets | OS, bureautique, création, jeux, sécurité | compatibilité logicielle, distribution | 3-6 ans |
| **Portables** | autonomie, poids, thermique, robustesse | CPU basse conso, écran, batterie, mémoire mobile | OS avec gestion d'énergie, pilotes | intégration compacte | 3-5 ans |
| **Serveurs et datacenters** | fiabilité, performance/W, coût total de possession | CPU multiprocesseur, ECC, stockage, réseau | OS serveur, bases de données, virtualisation, administration | qualification de fiabilité, support 24/7 | 5-10 ans |
| **Téléphones** | autonomie, intégration, radio, prix | SoC, modem, écran tactile, capteurs, batterie | OS mobile, applications, services | homologation radio, brevets, opérateurs | 2-5 ans |
| **Tablettes** | écran, autonomie, contenu, prix | SoC, grand écran tactile, batterie | OS mobile ou dérivé, applications de création et de lecture | écosystème d'applications | 3-5 ans |
| **Consoles** | coût de fabrication, performance graphique figée, cycle long | CPU/GPU souvent **semi-personnalisés**, mémoire | firmware, kits de développement, jeux | contrat plateforme exclusif | 6-10 ans (production continue) |
| **Industrie et embarqué** | fiabilité, déterminisme, température, disponibilité longue | microcontrôleurs, CPU embarqués, grade industriel | RTOS, contrôle, supervision | qualification industrielle | 10-20 ans |
| **Automobile** | sécurité fonctionnelle, coût, grade automobile, volume | microcontrôleurs, SoC d'infodivertissement puis d'aide à la conduite, capteurs | logiciel embarqué certifié, infodivertissement | qualification auto, audits, équipementiers | 10-15 ans |
| **Aéronautique** | assurance de conception, traçabilité, fiabilité | calculateurs avioniques, grade étendu | avionique certifiée, maintenance | certification très longue, maîtres d'œuvre | 20-30 ans |
| **Spatial** | radiations, masse, consommation, zéro réparation | processeurs durcis, mémoire tolérante aux erreurs | logiciel de vol, segment sol | qualification spatiale, petits volumes, agences | durée de mission |
| **Maritime** | environnement salin, vibrations, navigation, communications | calculateurs durcis, radio et satellite, écrans lisibles au soleil | navigation, gestion de flotte, systèmes de bord | normes maritimes, sociétés de classification (fictives) | 15-25 ans |
| **Défense** | sécurité, souveraineté, durcissement, disponibilité très longue | variantes durcies, chiffrement matériel, radio sécurisée | systèmes sécurisés, simulation, commandement | habilitation, contrôle des exportations, risque d'image | 20-40 ans |
| **Grands comptes et administrations** (logiciel) | fiabilité, conformité, support | serveurs, postes | gestion, bases de données, sécurité | appels d'offres, références | 5-15 ans |
| **Grand public en ligne** (logiciel) | usage, gratuité ou abonnement, audience | — | web, services, jeux, stockage en ligne | acquisition d'utilisateurs | continu |

**Règle d'adaptation [Proposition].** Changer de marché avec la même lignée coûte une **adaptation**, dont le prix dépend de la **plasticité** de la lignée et de l'**expérience** de l'équipe dans ce segment :

- validation supplémentaire ;
- variante de grade (tri des puces, plage de température) ;
- certification (qualification `q.*` de la carte) ;
- éventuellement un portage logiciel.

---

## 5. Matrice des paramètres réglables (dimension B)

Les **bornes** de chaque curseur viennent de la recherche (A) et de la lignée (C). Les **zones** vert / orange / rouge viennent de l'expérience de l'équipe, comme dans le laboratoire CPU existant [Constat bible §7B].

| Famille | Paramètres réglables | Gain principal | Coûts et risques couplés |
|---|---|---|---|
| **Commun à tous** | nom, gamme, esthétique/design industriel, positionnement, prix, volume, garantie, grade (commercial à défense), durée de support | image, adéquation au segment | validation, stock, coût de support |
| **CPU** | ISA (propre ou licenciée), microarchitecture (profondeur de pipeline, largeur), nombre et types de cœurs, fréquence de base et boost, tension, cache (taille, niveaux), TDP, gestion d'énergie, contrôleur mémoire (canaux, ECC), E/S, accélérateurs (flottant, vectoriel, IA), virtualisation, sécurité, nœud de gravure, monolithique ou chiplets, packaging, marge d'overclocking, compatibilité (socket, rétrocompatibilité) | performance mono et multicœur, efficacité | surface → coût et **rendement** ; fréquence × tension² → consommation et chaleur ; complexité → délai et bugs de microcode |
| **GPU** | architecture (fixe ou programmable), nombre d'unités, fréquence, largeur du bus mémoire, type de mémoire, unités de texture et de rendu, vidéo (codecs), calcul général, sorties d'affichage, TDP, format (intégré ou carte), qualité des pilotes | performance graphique, calcul, vidéo | surface et bande passante très coûteuses ; **pilotes** = charge logicielle ; consommation |
| **Mémoire** | type (SRAM, DRAM, Flash), densité par puce, vitesse, latence, largeur, tension, ECC, endurance (Flash), plage de température, format (puces ou modules) | capacité, débit | densité contre rendement ; vitesse contre consommation ; endurance contre coût/Go |
| **Stockage** | capacité, vitesse, latence, interface, endurance, résistance aux chocs, consommation, format | capacité et vitesse | mécanique contre électronique ; coût/Go contre performance |
| **Carte mère / chipset** | sockets et CPU pris en charge, canaux mémoire, emplacements d'extension, E/S, nombre de couches du circuit imprimé, étage d'alimentation, format, firmware | compatibilité, extensibilité | couches → coût ; **validation croisée** avec chaque CPU et chaque mémoire |
| **Écran** | technologie, taille, résolution, luminosité, fréquence, couleurs, tactile, consommation | lisibilité, qualité perçue | coût, consommation (pèse sur la batterie), rendement des dalles |
| **Batterie** | chimie, capacité, densité, cycles, charge rapide, sécurité, format | autonomie | masse, volume, sécurité (rappel produit), vieillissement |
| **Alimentation / refroidissement / boîtier** | puissance, rendement, bruit, redondance, capacité de dissipation, matériaux, esthétique | stabilité, silence, image | coût, encombrement, poids |
| **Radio / réseau** | normes et générations prises en charge, débit, portée, consommation, antennes | connectivité | **licences de brevets**, homologation, consommation |
| **Logiciel** | modules, plateformes ciblées, performance, empreinte mémoire, compatibilité, sécurité, certifiabilité, documentation, localisation, cadence des versions | couverture du besoin, marché accessible | délais, défauts cachés, coût de maintenance, **dette technique** |

### Éviter qu'un curseur soit toujours optimal [Proposition]

Dix mécanismes, à combiner :

1. **Budget de surface partagé.** Cœurs, cache, graphique intégré et E/S se disputent la même surface de puce. Ajouter du cache retire des cœurs, ou agrandit la puce.
2. **Rendement non linéaire.** Par exemple `rendement ≈ exp(−surface × densité_défauts)`. Doubler la surface fait bien plus que doubler le coût par puce bonne.
3. **Consommation quadratique.** `P ∝ C·V²·f`, et la fréquence exige de la tension. Les derniers +10 % de fréquence coûtent environ +25 à 30 % de consommation [Illustratif].
4. **Pondérations par segment.** Un serveur valorise fiabilité et perf/W ; l'overclocking valorise la marge et la fréquence ; l'embarqué valorise coût, consommation et durée. **Aucun profil ne gagne partout.**
5. **Plafonds de prix par segment.** Au-delà du prix acceptable, la performance supplémentaire ne se vend plus.
6. **Délai de mise sur le marché.** Chaque mois de retard réduit la valeur relative, car les concurrents avancent.
7. **Coût de validation.** Chaque option, marché ou variante ajoute des tests, du stock et du support : une gamme trop large coûte cher [Constat : déjà dit dans `CPU_VERTICAL_SLICE.md` §10].
8. **Pénalité de généralisme.** Une lignée qui vise tous les segments reçoit un malus d'adéquation dans chacun. Une lignée spécialisée perd en plasticité.
9. **Compatibilité contre rupture.** Rompre l'ISA ou le socket donne du potentiel mais coûte la base installée, les logiciels et la confiance des partenaires.
10. **Dette technique.** Les révisions rapides accumulent de la dette. Au-delà d'un seuil, bugs et coûts de validation montent jusqu'à ce qu'on finance une nouvelle lignée.

**Signalement au joueur.** L'équipe dit **pour quel segment** un réglage est bon (« Excellent en overclocking, mauvais en portable »), plutôt qu'un score unique. Cela prolonge la règle existante qui affiche l'adéquation au client à part des cinq axes [Constat].

---

## 6. Transposition aux autres familles : technologie, configuration, progression

| Famille | A. Recherche (exemples de nœuds de la carte) | B. Configuration produit | C. Spécialisations de lignée et XP d'équipe |
|---|---|---|---|
| **GPU** | `gfx.bitmap` → `gfx.2d` → `gfx.3d` → `gfx.compute`, `gfx.video` | unités, bus mémoire, pilotes, format intégré ou carte | bureau/jeu, station de travail, mobile basse conso, calcul, console semi-personnalisée ; **XP pilotes** distincte de l'XP silicium |
| **Mémoire** | `mem.dram`, `mem.flash`, `mem.ecc`, `mem.bw.<gen>` | densité, vitesse, latence, tension, grade | densité grand public, faible latence serveur, basse consommation mobile, endurance industrielle, durcie spatiale |
| **Stockage** | `sto.hdd`, `sto.ssd`, contrôleurs | capacité, vitesse, endurance, interface | capacité datacenter, performance, robustesse embarquée ; **XP firmware** du contrôleur |
| **Écran** | `comp.display.<tech>`, tactile | taille, résolution, luminosité, consommation | mobile, professionnel couleur, lisible au soleil (maritime, défense), automobile |
| **Batterie** | `bat.pack.<chimie>`, gestion d'énergie | capacité, cycles, sécurité | densité mobile, longévité industrielle, grade aéro (sécurité) |
| **Radio** | `radio.wlan`, `radio.cell.<gen>` | normes, consommation, portée | grand public, industriel, sécurisé défense, satellite/maritime |
| **Logiciel** | outils, OS, bases de données, sécurité (§3) | modules, plateformes, performance, certifiabilité | par domaine client et par plateforme ; **XP de certification** réutilisable entre auto, aéro et défense |

**Règle d'expérience [Proposition].** L'XP est comptée **par équipe × domaine × segment**, pas globalement :
- une équipe qui a livré trois générations serveur prédit mieux les défauts serveur ;
- elle reste moins précise en mobile ;
- un transfert partiel se fait entre segments proches (bureau ↔ station de travail ; auto ↔ industrie).

C'est une extension directe du triplet connaissance / expérience / confiance existant [Constat `CPU_VERTICAL_SLICE.md`].

---

## 7. La boucle complète

```
          ┌────────────────────────────────────────────────────────────────┐
          │                                                                │
          ▼                                                                │
 [1] RECHERCHE (dimension A)                                               │
     programmes Concept, nœuds technologiques, licences, rachats           │
          │  débloque des bornes de curseurs et des TRAITS possibles       │
          ▼                                                                │
 [2] XP D'ÉQUIPE (dimension C)                                             │
     par domaine × segment : précision des estimations, zones vertes,      │
     propositions spontanées (« nouvelle lignée pour le serveur ? »)       │
          │                                                                │
          ▼                                                                │
 [3] ARCHITECTURE / LIGNÉE                                                 │
     continuer (révision, peu de risque, dette ↑)                          │
     OU fonder une nouvelle lignée (traits choisis, compatibilité rompue)  │
          │                                                                │
          ▼                                                                │
 [4] CONCEPTION DU PRODUIT (dimension B)                                   │
     curseurs couplés, 3 plans proposés (existant), gamme par tri des puces│
          │                                                                │
          ▼                                                                │
 [5] ADAPTATION AU SEGMENT                                                 │
     variante de grade, validation, certification, portage logiciel        │
          │                                                                │
          ▼                                                                │
 [6] CHAÎNE DE PRODUCTION                                                  │
     fonderie ou fab, packaging, rendement, capacité, fournisseurs         │
          │                                                                │
          ▼                                                                │
 [7] COMMERCIALISATION                                                     │
     prix, canaux, contrats B2B (OEM, console, auto), presse, benchmarks   │
          │                                                                │
          ▼                                                                │
 [8] TERRAIN : ventes, retours SAV, incidents, demandes clients            │
          │                                                                │
          └──► RETOUR D'EXPÉRIENCE ────────────────────────────────────────┘
               • XP segment ↑ (même sur un échec)
               • découvertes (existant : découvertes d'équipe)
               • demandes clients → nouveaux traits ou nouvelle lignée
               • dette technique mesurée → décision de rupture
               • brevets et licences vendables
```

**Ce qui existe déjà [Constat] :**
- étapes 1, 4 et 6 pour le CPU ;
- recherche continue, trois plans, gamme, industrialisation, fonderie ;
- étape 8 : SAV par familles d'incidents, expérience terrain réinjectée vers R&D et Production.

**Ce qui est nouveau :**
- étape 3 (lignée) ;
- étape 5 (adaptation au segment comme projet à part entière) ;
- XP par segment ;
- une boucle identique pour chaque famille, **y compris le logiciel**, où « architecture » devient la base de code et sa plateforme.

---

## 8. Trois générations CPU spécialisées

**Tous les chiffres de cette section sont illustratifs [Illustratif].** Ils ne sont pas équilibrés, pas historiques, et servent seulement à montrer les arbitrages. Les trois générations sont conçues par la même entreprise fictive.

**Point de départ commun** : la lignée « Garage-1 », CPU 8 bits pour le contrôle, de 1974. L'équipe a 40 d'XP en conception et 55 dans le segment embarqué. Le procédé est 6 µm, via une fonderie.

### 8.1 « Brise BR-1 » (1979) : embarqué, basse consommation, puis automobile

Nouvelle lignée, traits **LOW_VOLTAGE** et **SMALL_DIE**. Cible : industrie et embarqué, puis automobile après qualification.

| Paramètre | Valeur | Arbitrage |
|---|---|---|
| Largeur, cœurs | 16 bits, 1 cœur | ISA propre, compatible au niveau source avec Garage-1 |
| Fréquence | 4 MHz | volontairement basse pour tenir la tension |
| Cache | aucun (mémoire interne sur puce 2 Ko) | la surface va à la mémoire interne, utile en embarqué |
| Consommation | 0,4 W | environ 1/3 d'un concurrent de bureau |
| Surface / rendement | 18 mm² / 78 % | petite puce = bon rendement |
| Coût unitaire / prix | 6 € / 19 € | marge forte en volume |
| Indice de performance | 38 (bureau = 100) | **mauvais sur PC** : l'équipe le dit clairement |
| Fiabilité / plage de température | 94 / −40 à +105 °C | grade industriel ; auto possible après `q.auto` |
| Développement | 14 mois, 90 k€ | nouvelle lignée = plus long qu'une révision |
| Adaptation automobile | +8 mois, +60 k€, audit | XP segment auto de 0 à 30 ; ouvre des contrats sur 12 ans |

**Retour d'expérience.** L'XP embarqué passe à 70, puis l'XP auto à 30. L'équipe découvre le trait **REALTIME_DETERMINISTIC**, qui ouvre une future variante pour l'avionique.

### 8.2 « Rempart RP-2 » (1988) : serveur et fiabilité

Nouvelle lignée issue de la demande de clients bancaires. Traits **RELIABILITY_LOCKSTEP**, **LARGE_CACHE** et **MULTIPROCESSOR**.

| Paramètre | Valeur | Arbitrage |
|---|---|---|
| Largeur, cœurs | 32 bits, 1 cœur, jusqu'à 4 sockets | le multiprocesseur coûte de la validation |
| Fréquence | 25 MHz | en retrait de 20 % sur le meilleur concurrent de bureau |
| Cache | 64 Ko sur puce + contrôleur de cache externe | 40 % de la surface ; latence mémoire basse |
| Mémoire | contrôleur ECC, 2 canaux | exige une carte et une mémoire compatibles (portes de la carte, §5) |
| Consommation | 9 W | acceptable en salle machine, **inutilisable en portable** |
| Surface / rendement | 160 mm² / 31 % | rendement faible → coût élevé |
| Coût unitaire / prix | 140 € / 1 900 € | marge très forte, volume faible |
| Indice mono / multi (4 sockets) | 85 / 290 | gagne en multiprocesseur, perd en jeu |
| Fiabilité | 98 | pondération serveur maximale |
| Développement | 26 mois, 1,4 M€ | un bug de cohérence de cache coûte +3 mois si l'XP validation est inférieure à 50 |
| Commercialisation | contrats de 5 ans avec support 24/7 | revenus récurrents, mais le SAV doit suivre |

**Arbitrage visible.** Pour une version bureau, il faudrait retirer l'ECC et 3/4 du cache. On obtient un « RP-2D » à 110 € de coût, mais l'adéquation au bureau n'est que de 0,55 : la lignée n'est pas faite pour ça, et sa plasticité est faible (35). **[À trancher]** Faut-il autoriser les dérivés de mauvaise adéquation, ou les faire proposer par l'équipe avec un avertissement ?

### 8.3 « Comète CM-3 » (1994) : console semi-personnalisée, puis bureau performance

Contrat avec un fabricant de consoles fictif. La lignée dérive de Rempart, mais avec une nouvelle orientation : traits **WIDE_SUPERSCALAR**, **VECTOR** et **CUSTOM_FOR_CLIENT**.

| Paramètre | Valeur | Arbitrage |
|---|---|---|
| Cœurs, fréquence | 1 cœur superscalaire, 100 MHz | fréquence fixe imposée par le client : pas de boost |
| Unité vectorielle | 128 bits | 18 % de surface ; inutile en bureautique, excellente en 3D et en jeu |
| Cache | 32 Ko | réduit par rapport à Rempart pour tenir le coût |
| Consommation | 12 W | refroidissement de console bon marché exigé |
| Coût imposé | ≤ 45 € par unité | cible contractuelle ; pénalité si elle est dépassée |
| Volume garanti | 3 M d'unités sur 5 ans | sécurise la fab ou la réservation de fonderie |
| Droits | le client possède les modifications ; l'entreprise garde la lignée | clause type « licence de réutilisation » (revue logicielle) |
| Développement | 20 mois, 2,2 M€ dont 50 % payés par le client | codéveloppement |
| Dérivé bureau « CM-3X » | boost 133 MHz, marge d'overclocking | adéquation jeu/PC 0,85 ; **overclocking** : les meilleurs bins donnent un modèle haut de gamme |

**Retour d'expérience.** L'XP vectoriel sert plus tard au GPU et à l'IA (synergie). En revanche, 5 ans de production figée immobilisent une partie de l'équipe sur le support du client. C'est le coût caché des contrats plateforme.

### Ce que montrent les trois exemples

| | Brise (embarqué/auto) | Rempart (serveur) | Comète (console/jeu) |
|---|---|---|---|
| Critère gagnant | perf/W, coût, température | fiabilité, multiprocesseur | performance vectorielle, coût imposé |
| Le « pire » curseur, volontairement | fréquence | rendement | flexibilité (fréquence fixe) |
| Marché impossible sans adaptation | PC | portable | serveur |
| Revenu | volume, contrats longs | marge, support | contrat garanti, dérivés |

---

## 9. Données minimales supplémentaires [Proposition]

- **`architecture_lineage`** (§2) : traits, plasticité, dette, adéquation par segment, XP, contrat de compatibilité.
- **`segment_profile`** : pondérations des critères, plafond de prix, grade minimal, certifications, durée de support attendue. Il généralise `MARKET_NEEDS` et y ajoute les marchés du §4.
- **`product_design`** : curseurs de la famille, avec leurs dépendances de calcul (surface, consommation, rendement) décrites dans les données et non codées en dur par famille.
- **`adaptation_project`** : source (génération), segment cible, validation, certification, portage, coût et délai.
- **XP** clé par `(équipe, famille, segment)`.
- **Tests déterministes à ajouter aux V1-V12 de la carte :**
  - *V13* : aucun profil de curseurs ne domine tous les segments (balayage automatique) ;
  - *V14* : chaque segment a au moins deux profils viables ;
  - *V15* : une partie 100 % logicielle atteint au moins trois domaines logiciels et deux marchés du §4.

---

## 10. Décisions nouvelles à trancher

1. **Nombre de traits** par lignée : 2 ou 3 au maximum est lisible sur mobile, avec des traits exclusifs entre eux (par exemple haute fréquence ↔ basse tension).
2. **Une lignée peut-elle changer de trait** en cours de route (coût et dette), ou faut-il toujours une nouvelle lignée ?
3. **Granularité de l'XP** : famille × segment (recommandé) ou famille seule (plus simple).
4. **Le design industriel et l'esthétique** : un curseur de coût et d'image seulement, ou un petit éditeur visuel (lien avec la direction artistique) ?
5. **Contrats semi-personnalisés** (consoles, automobile) : qui possède la lignée dérivée ? Il faut une clause type, sur le modèle de la clause de propriété du code.
6. **Marchés maritime et défense** : faut-il les ouvrir d'abord au **logiciel** (navigation, sécurité), ce qui serait cohérent avec la voie logicielle sans matériel ?
7. **Jeux vidéo** : domaine logiciel à part entière, ou débouché des consoles et PC seulement ? Le risque est de trop se rapprocher d'un jeu de référence (voir la note INPI de `garage-interactions-v031.md`).
8. **Profondeur des curseurs sur téléphone** : cinq axes de lecture et trois curseurs visibles par défaut, le reste en panneau dépliable (principe déjà établi pour le CPU).

**En résumé.** La carte précédente disait **quoi débloquer**. Cet addendum ajoute **quoi concevoir et pour qui** :
- chaque famille a une recherche (A), des produits paramétrables (B) et des **lignées d'architecture** portées par des équipes spécialisées par segment (C) ;
- les curseurs sont couplés par la surface, la consommation, le rendement, le prix et les pondérations de marché, si bien qu'aucun réglage n'est universellement optimal ;
- le logiciel dispose de sa propre largeur de domaines et de marchés, sans transition forcée vers le matériel.
