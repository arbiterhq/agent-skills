# Arbiter Agent Skills

Cross-platform agent skills for [Claude Code](https://claude.com/claude-code), [Codex CLI](https://github.com/openai/codex), and [Gemini CLI](https://github.com/google-gemini/gemini-cli). By [Posthuman Resources LLC](https://posthuman.help).

## Skills

### Browser Buddy

Browser automation wrapping Vercel's [agent-browser](https://github.com/vercel-labs/agent-browser) CLI. Navigate pages, fill forms, click buttons, take screenshots, scrape structured data, and automate browser workflows.

### Artistic Vision

Image generation via [Nano Banana](https://github.com/kingbootoshi/nano-banana-2-skill) (Google Gemini image models) and local image processing via Sharp, ImageMagick, and FFmpeg. Generate from prompts, edit existing images, create transparent assets, resize, convert, and batch process.

### Git Ideas

Opinionated git workflow management. Atomic one-idea-per-commit methodology, worktrees for parallel development, change stacking across dependent branches, GitHub PR workflows, and merge strategies.

## Installation

### Claude Code

```
/plugin marketplace add arbiterhq/agent-skills
```

Then install individual plugins:

```
/plugin install browser-buddy@arbiterhq
/plugin install artistic-vision@arbiterhq
/plugin install git-ideas@arbiterhq
```

### Codex CLI

Using the built-in skill installer:

```
$skill-installer install browser-buddy from arbiterhq/agent-skills
```

Or manually:

```bash
git clone https://github.com/arbiterhq/agent-skills.git
cd agent-skills && bash install.sh
```

### Gemini CLI

```
gemini extensions install https://github.com/arbiterhq/agent-skills
```

### Universal (npx)

Works with Claude Code, Codex, Gemini CLI, Cursor, and 40+ other agents:

```
npx skills add arbiterhq/agent-skills
```

## Repository Structure

```
agent-skills/
  .claude-plugin/marketplace.json   # Claude Code marketplace manifest
  gemini-extension.json             # Gemini CLI extension manifest
  plugins/                          # Canonical skill sources (Claude Code plugins)
    browser-buddy/
    artistic-vision/
    git-ideas/
  skills/                           # Symlinks for Codex and Gemini discovery
  CLAUDE.md                         # Claude Code project context
  AGENTS.md                         # Codex project context
  GEMINI.md                         # Gemini CLI project context
```

Skills live in `plugins/<name>/skills/<name>/SKILL.md` with the canonical source of truth. The `skills/` directory at the root contains symlinks for cross-tool compatibility.

## Contributing

1. Fork the repo
2. Create a feature branch
3. Follow the conventions in CLAUDE.md (no em dashes, SKILL.md under 500 lines, scripts use set -e)
4. Submit a PR

To add a new skill:

1. Create a new directory under `plugins/<skill-name>/`
2. Add the `.claude-plugin/plugin.json` manifest
3. Create `skills/<skill-name>/SKILL.md` with YAML frontmatter
4. Add a symlink in the root `skills/` directory
5. Add an entry to `.claude-plugin/marketplace.json`

## License

[MIT](LICENSE) - Posthuman Resources LLC
