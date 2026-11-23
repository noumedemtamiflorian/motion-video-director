#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_NAME="motion-video-director"

USE_COPY=false
FORCE=false
USE_SKILLS_JSON=false
TARGETS=()

usage() {
  cat <<'EOF'
Usage: ./install.sh [OPTIONS]

Installe le skill motion-video-director dans un ou plusieurs agents locaux.
Par défaut (sans option de cible), installe par lien symbolique pour Antigravity
et pour chaque agent déjà présent (~/.claude, ~/.cursor, ~/.agents).

Cibles :
  --antigravity   Installe dans ~/.gemini/config/skills/motion-video-director
  --claude        Installe dans ~/.claude/skills/motion-video-director
  --cursor        Installe dans ~/.cursor/skills/motion-video-director
  --agents        Installe dans ~/.agents/skills/motion-video-director
  --all           Installe dans toutes les cibles ci-dessus
  --skills-json   Enregistre ce dépôt dans ~/.gemini/config/skills.json

Options :
  --copy          Copie SKILL.md et scripts/ au lieu de créer un lien symbolique
  --force         Sauvegarde puis remplace une installation non-symlink existante
  -h, --help      Affiche cette aide et quitte
EOF
}

realpath_safe() {
  local p="$1"
  if command -v python3 >/dev/null 2>&1; then
    python3 -B -c 'import os,sys; print(os.path.realpath(sys.argv[1]))' "$p"
  elif command -v realpath >/dev/null 2>&1; then
    realpath "$p"
  elif [ -d "$p" ]; then
    (cd "$p" && pwd -P)
  else
    printf '%s\n' "$p"
  fi
}

add_target_unique() {
  local new_target="$1"
  local existing
  for existing in "${TARGETS[@]+"${TARGETS[@]}"}"; do
    if [ "$existing" = "$new_target" ]; then
      return 0
    fi
  done
  TARGETS+=("$new_target")
}

install_to_target() {
  local label="$1"
  local skills_root="$2"
  local target="${skills_root}/${SKILL_NAME}"
  local src_real dst_real backup

  src_real="$(realpath_safe "$SCRIPT_DIR")"
  if [ -e "$target" ] || [ -L "$target" ]; then
    dst_real="$(realpath_safe "$target")"
    if [ "$src_real" = "$dst_real" ] && [ ! -L "$target" ]; then
      echo "ℹ️  [$label] Le dépôt est déjà cloné directement à l'emplacement cible : $target"
      return 0
    fi
  fi

  mkdir -p "$skills_root"

  if [ "$USE_COPY" = true ]; then
    if [ -L "$target" ] || [ -e "$target" ]; then
      if [ "$FORCE" = true ]; then
        if [ -L "$target" ]; then
          rm -f "$target"
        else
          backup="${target}.bak.$(date +%Y%m%d-%H%M%S)"
          mv "$target" "$backup"
          echo "📦 [$label] Sauvegarde créée : $backup"
        fi
      else
        echo "⚠️  [$label] Une installation existe déjà à $target (utilisez --force pour remplacer). Ignoré."
        return 0
      fi
    fi

    mkdir -p "$target/scripts"
    cp -f "$SCRIPT_DIR/SKILL.md" "$target/SKILL.md"
    cp -f "$SCRIPT_DIR/scripts/"* "$target/scripts/"
    chmod 644 "$target/SKILL.md"
    chmod 755 "$target/scripts/"*
    echo "✅ [$label] Copié dans $target"
  else
    if [ -e "$target" ] && [ ! -L "$target" ]; then
      if [ "$FORCE" = true ]; then
        backup="${target}.bak.$(date +%Y%m%d-%H%M%S)"
        mv "$target" "$backup"
        echo "📦 [$label] Sauvegarde créée : $backup"
      else
        echo "⚠️  [$label] Un dossier/fichier réel existe déjà à $target (utilisez --force pour sauvegarder et remplacer). Ignoré."
        return 0
      fi
    fi

    ln -sfn "$SCRIPT_DIR" "$target"
    echo "✅ [$label] Lien symbolique créé : $target -> $SCRIPT_DIR"
  fi
}

register_skills_json() {
  local config_dir="$HOME/.gemini/config"
  local skills_json="$config_dir/skills.json"
  local parent_dir dir_name

  if ! command -v python3 >/dev/null 2>&1; then
    echo "❌ python3 est requis pour mettre à jour $skills_json" >&2
    return 1
  fi

  parent_dir="$(dirname "$SCRIPT_DIR")"
  dir_name="$(basename "$SCRIPT_DIR")"

  if [ "$dir_name" != "$SKILL_NAME" ]; then
    echo "⚠️  Attention : ce dossier s'appelle '$dir_name' et non '$SKILL_NAME'. L'entrée dans skills.json utilisera include_only=['$dir_name']."
  fi

  mkdir -p "$config_dir"

  python3 -B - "$skills_json" "$parent_dir" "$dir_name" <<'PY'
import json
import os
import sys

skills_json_path, parent_dir, dir_name = sys.argv[1], sys.argv[2], sys.argv[3]

data = {}
if os.path.exists(skills_json_path):
    with open(skills_json_path, "r", encoding="utf-8") as f:
        content = f.read().strip()
        if content:
            data = json.loads(content)
            if not isinstance(data, dict):
                raise SystemExit(f"Format JSON inattendu dans {skills_json_path} (objet attendu).")

entries = data.get("entries")
if entries is None:
    entries = []
    data["entries"] = entries
elif not isinstance(entries, list):
    raise SystemExit(f"Champ 'entries' invalide dans {skills_json_path} (liste attendue).")

parent_real = os.path.realpath(parent_dir)
matched = None
for entry in entries:
    if isinstance(entry, dict) and isinstance(entry.get("path"), str):
        expanded = os.path.expanduser(entry["path"])
        if expanded == parent_dir or os.path.realpath(expanded) == parent_real:
            matched = entry
            break

if matched is None:
    entries.append({
        "path": parent_dir,
        "include_only": [dir_name],
    })
else:
    if "include_only" in matched and isinstance(matched["include_only"], list):
        if dir_name not in matched["include_only"]:
            matched["include_only"].append(dir_name)

with open(skills_json_path, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write("\n")
PY

  echo "✅ [Antigravity skills.json] Enregistré dans $skills_json ($parent_dir -> $dir_name)"
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --antigravity)
      add_target_unique "antigravity"
      ;;
    --claude)
      add_target_unique "claude"
      ;;
    --cursor)
      add_target_unique "cursor"
      ;;
    --agents)
      add_target_unique "agents"
      ;;
    --all)
      add_target_unique "antigravity"
      add_target_unique "claude"
      add_target_unique "cursor"
      add_target_unique "agents"
      ;;
    --skills-json)
      USE_SKILLS_JSON=true
      ;;
    --copy)
      USE_COPY=true
      ;;
    --force)
      FORCE=true
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "❌ Option inconnue : $1" >&2
      usage >&2
      exit 1
      ;;
  esac
  shift
done

if [ "${#TARGETS[@]}" -eq 0 ] && [ "$USE_SKILLS_JSON" = false ]; then
  add_target_unique "antigravity"
  if [ -d "$HOME/.claude" ]; then add_target_unique "claude"; fi
  if [ -d "$HOME/.cursor" ]; then add_target_unique "cursor"; fi
  if [ -d "$HOME/.agents" ]; then add_target_unique "agents"; fi
fi

for t in "${TARGETS[@]+"${TARGETS[@]}"}"; do
  case "$t" in
    antigravity)
      install_to_target "Antigravity" "$HOME/.gemini/config/skills"
      ;;
    claude)
      install_to_target "Claude Code" "$HOME/.claude/skills"
      ;;
    cursor)
      install_to_target "Cursor" "$HOME/.cursor/skills"
      ;;
    agents)
      install_to_target "Codex / Agents" "$HOME/.agents/skills"
      ;;
  esac
done

if [ "$USE_SKILLS_JSON" = true ]; then
  register_skills_json
fi
