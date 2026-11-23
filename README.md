# motion-video-director

Skill multi-agents pour planifier, réaliser et produire des vidéos et animations motion graphics 2D/3D générées par code (Canvas, SVG, p5.brush, Three.js, GSAP, Motion Canvas/Revideo, ffmpeg, voix off ElevenLabs, Playwright MCP, etc.).

## Installation rapide sur un nouvel ordinateur

### Option 1 : Clone direct dans Antigravity (le plus simple)

#### Linux / macOS
```bash
git clone https://github.com/noumedemtamiflorian/motion-video-director.git ~/.gemini/config/skills/motion-video-director
```

#### Windows (PowerShell)
```powershell
git clone https://github.com/noumedemtamiflorian/motion-video-director.git "$env:USERPROFILE\.gemini\config\skills\motion-video-director"
```

Le skill est immédiatement reconnu par Antigravity à la prochaine session.

---

### Option 2 : Clone centralisé + script multi-agents (`install.sh`)

Utile si tu utilises plusieurs agents sur la même machine (Antigravity, Claude Code, Cursor, Codex / `.agents`).

```bash
git clone https://github.com/noumedemtamiflorian/motion-video-director.git ~/skills/motion-video-director
cd ~/skills/motion-video-director
./install.sh
```

Par défaut, `./install.sh` crée un **lien symbolique** pour Antigravity (`~/.gemini/config/skills/motion-video-director`) ainsi que pour les agents déjà présents (`~/.claude`, `~/.cursor`, `~/.agents`). Ainsi, un simple `git pull` met à jour tous tes agents d'un coup.

Options disponibles :
- `./install.sh --all` : installe dans Antigravity, Claude Code, Cursor et Codex/Agents.
- `./install.sh --antigravity` / `--claude` / `--cursor` / `--agents` : cible un agent précis.
- `./install.sh --copy` : copie `SKILL.md` et `scripts/` au lieu d'utiliser un lien symbolique.
- `./install.sh --skills-json` : enregistre le dépôt dans `~/.gemini/config/skills.json`.
- `./install.sh --force` : sauvegarde (`.bak.<horodatage>`) puis remplace une installation existante.

---

### Option 3 : Enregistrement manuel via `~/.gemini/config/skills.json`

Si tu clones ce dépôt ailleurs (par exemple dans `~/skills/motion-video-director`), tu peux aussi le déclarer manuellement dans `~/.gemini/config/skills.json` :

```json
{
  "entries": [
    {
      "path": "~/skills",
      "include_only": ["motion-video-director"]
    }
  ]
}
```

*(Ou exécute simplement `./install.sh --skills-json` pour fusionner l'entrée automatiquement sans écraser ta configuration existante.)*

---

## Mettre à jour sur tous tes ordinateurs

Dans le dossier où le dépôt a été cloné :

```bash
git pull
```

*(Si tu as utilisé `./install.sh --copy`, relance `./install.sh --copy --force` après le `git pull`.)*

---

## Contenu du dépôt

- `SKILL.md` : instructions complètes du skill `motion-video-director`.
- `scripts/` : utilitaires de préflight, preview et gestion de `.env` (`preflight.sh`, `preview.mjs`, `analyze_ref.sh`, `create_env.sh`, `normalize_env.py`).
- `install.sh` : installateur multi-agents (Antigravity, Claude Code, Cursor, Codex/Agents).

## Sécurité et clés API

Aucune clé API n'est stockée dans ce dépôt. Pour chaque projet vidéo, les clés (Pixabay, Freesound, Pexels, Unsplash, Firecrawl, ElevenLabs) restent exclusivement dans le fichier `.env` local du projet (ignoré par Git).
