#!/usr/bin/env bash
set -Eeuo pipefail

workspace="${GITHUB_WORKSPACE:-$(pwd)}"
cd "$workspace"

# L'agent ne doit jamais pouvoir transformer une configuration Git locale
# en exécution de code sur le runner lors de la collecte.
g() {
  command git -c core.fsmonitor=false -c core.hooksPath=/dev/null "$@"
}

output_dir=".agent-output"
mkdir -p "$output_dir"
: > "$output_dir/validation.txt"
: > "$output_dir/changed-files.txt"
: > "$output_dir/diff-stat.txt"
: > "$output_dir/changes.patch"

fail_validation() {
  printf 'REFUSÉ : %s\n' "$1" | tee -a "$output_dir/validation.txt" >&2
  exit 2
}

actual_base="$(g rev-parse HEAD)"
expected_base="${EXPECTED_BASE_SHA:-${GITHUB_SHA:-}}"
if [[ -z "$expected_base" || ! "$expected_base" =~ ^[0-9a-f]{40}$ ]]; then
  fail_validation "SHA de départ absent ou invalide"
fi
if [[ "$actual_base" != "$expected_base" ]]; then
  fail_validation "l'agent a modifié HEAD ou la copie n'est plus sur le commit attendu"
fi

# Ignore tout changement d'index laissé par l'agent sans toucher aux fichiers de travail.
g reset --quiet

# Rend les nouveaux fichiers visibles dans git diff sans ajouter leur contenu à l'index.
while IFS= read -r -d '' file; do
  case "$file" in
    .agent-output/*|.agent-runtime/*) continue ;;
  esac
  g add --intent-to-add -- "$file"
done < <(g ls-files --others --exclude-standard -z)

mapfile -d '' changed_files < <(g diff --name-only --no-ext-diff -z)
if [[ ${#changed_files[@]} -eq 0 ]]; then
  fail_validation "aucune modification de projet n'a été produite"
fi

for file in "${changed_files[@]}"; do
  [[ -n "$file" ]] || continue
  case "$file" in
    .github/*|tools/agents/*|AGENTS.md|.gitignore|.gitattributes|.gitmodules|.env|.env.*)
      fail_validation "chemin d'infrastructure interdit : $file"
      ;;
  esac
  case "$file" in
    *.gd|*.tscn|*.tres|*.godot|*.md|*.json|*.cfg|*.svg|*.txt|*.uid) ;;
    *) fail_validation "type de fichier non autorisé dans le pilote : $file" ;;
  esac
  if [[ -L "$file" ]]; then
    fail_validation "les liens symboliques sont interdits : $file"
  fi
  if [[ -f "$file" ]]; then
    file_size="$(stat --format='%s' -- "$file")"
    if (( file_size > 1572864 )); then
      fail_validation "fichier supérieur à 1,5 Mio : $file"
    fi
  fi
  printf '%s\n' "$file" >> "$output_dir/changed-files.txt"
done

if ! g diff --check --no-ext-diff; then
  fail_validation "le patch contient des erreurs d'espaces ou des marqueurs de conflit"
fi

g diff --stat --no-ext-diff > "$output_dir/diff-stat.txt"
g diff --binary --full-index --no-ext-diff > "$output_dir/changes.patch"

{
  printf 'base_sha=%s\n' "$actual_base"
  printf 'generated_at=%s\n' "$(date --utc +'%Y-%m-%dT%H:%M:%SZ')"
  printf 'changed_file_count=%s\n' "${#changed_files[@]}"
} > "$output_dir/manifest.txt"

printf 'VALIDÉ : patch local uniquement, revue humaine obligatoire avant création de PR.\n' \
  | tee -a "$output_dir/validation.txt"
