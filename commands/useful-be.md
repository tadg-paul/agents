---
description: Get up to speed with the SDLC and project documentation before starting work.
---

This skill loads all rules and project documentation into context. Do not defer reads to "on demand" -- everything below is mandatory before you respond.

## 1. Load the project context

Read in full:

- The repo's `README.{md,org}` if present
- Every file under `./docs/` (recurse). If any are too large to load fully in one read, summarize after reading; do not skip.
- If the project depends on infrastructure documented in a separate repo (e.g. an infra/deployment repo), and you have been told this, review that repo's documentation read-only.

Do not defer any of these reads to "on demand". The point of this skill is to be loaded up before the first instruction lands.

## 2. Load the SDLC layer

Read each of these in full now, in order:

1. `~/.claude/SDLC.md`
2. `~/.claude/docs/ISSUES.md`
3. `~/.claude/docs/TESTING.md`
4. `~/.claude/docs/CODING.md`
5. `~/.claude/docs/GIT.md`
6. `~/.claude/docs/DOCUMENTATION.md`
7. Read the relevant language-specific document(s) for this project (e.g. `~/.claude/docs/code/GO.md`)
8. If we have not yet selected a language, you will need to read the patterns for *all* languages under `~/.claude/docs/code/*` in order to make an informed recommendation to me. It is a heavier load, but an important one. This should only be a one-off activity at the start of your tenure on this project.

## 3. Read the infrastructure contract
If we are in a project that will be deployed to the cloud (including websites), you must read and understand the infrastructure contract and patterns in `~/code/exodan` (start with `README.{org,md}` which will guide you to the contract and relevant patterns, scripts and toolchain).

## 4. Read local project instructions to agent
If there is a local agent instructions file in this repository, read it now. It will be named CLAUDE.md or AGENT*.{md,org}. It will be in the root of the project. If it is absent, say so in your acknowledgment.

## 3. Confirm mode

Confirm what documents you have digested and provide a one-line understanding of each.
The global {CLAUDE,AGENTS}.md rules apply in all cases and are *never* superceded regardless of anything you see in supplementary documentation from the SDLC, project docs or skills.

When you have confirmed, ask what to do next and await instruction.
