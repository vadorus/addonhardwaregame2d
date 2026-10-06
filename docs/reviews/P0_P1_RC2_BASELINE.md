# Base locale RC2 reprise le 6 octobre 2026

Cette branche reprend les changements locaux non commités de `TechEmpire-complete`,
à partir de `9233be6`. La copie originale n'a pas été modifiée. Les sondes C4 et de
carrière, qui ne font pas partie de P0/P1, n'ont pas été ajoutées.

Cette base contient la migration des départements mal encodés, les messages de
refus CPU, la réparation du calendrier de sauvegarde, le partage de l'équipe entre
projets, les représentations communes des projets et le correctif de hauteur du QG.
Il s'agit de travail préexistant conservé, pas de changements nouvellement inventés.

Validation fraîche, Godot 4.7.2 : import et tests `second_cpu_budget_test`,
`save_clock_lifecycle_test`, `complete_experience_test`, `software_manager_test`,
`gameplay_r2_test` réussis. Le test CPU charge une copie de la sauvegarde du Pixel
(995 307 €, deux développeurs), crée un deuxième CPU et laisse le fichier source intact.

Limites de cette base : support logiciel encore calculé sur le cumul historique des
licences, devis de refus Software trop vagues. Ces défauts sont traités dans les commits
suivants. La version installée du Pixel est RC2 (code 16) ; aucun remplacement de cette
application n'a été effectué durant la validation de la base.
