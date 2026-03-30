# Browser Buddy

Browser automation skill wrapping Vercel's [agent-browser](https://github.com/vercel-labs/agent-browser) CLI with additional patterns for scraping, testing, form-filling, and visual diffing.

## What It Does

- Navigate and interact with websites using accessibility-tree-based element targeting
- Scrape structured data from pages
- Automate multi-step form workflows
- Take screenshots and generate PDFs
- Save and restore browser sessions for authentication persistence
- Visual regression via screenshot comparison

## Prerequisites

```bash
npm i -g agent-browser && agent-browser install
```

## Usage

This skill is activated automatically when you ask an agent to interact with websites, scrape data, fill forms, take screenshots, or automate browser tasks.

## Structure

```
skills/browser-buddy/
  SKILL.md              # Core skill instructions
  references/           # Detailed docs on auth and session patterns
  scripts/setup.sh      # Installer helper
  templates/            # Reusable workflow templates
```
