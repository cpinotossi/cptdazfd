---
title: Repository documentation
description: Shared setup, historical reference notes and repository structure conventions.
---

## Navigation

* [Project catalog](../README.md)
* [GitHub Actions setup notes](github-actions-setup.md)
* [Publication safety requirements](publication-safety.md)
* [Historical Front Door reference notes](reference/frontdoor-notes.md)

## Structure conventions

Runnable scenarios belong under `projects/`; incomplete or exploratory work
belongs under `experiments/`. Each has a README stating its status, prerequisites,
entry points, validation and cleanup considerations.

Keep infrastructure, scripts, notebooks, test fixtures and project-specific
modules with their scenario. Add subdirectories only when the project needs
them. Keep cross-project guidance here and GitHub workflow definitions under
the repository's `.github/workflows/` directory.

Repository-level commands assume the repository root unless stated otherwise.
Notebooks retain their project-local working-directory assumptions.

## Adding or moving a project

1. Add or update its README and the root project catalog.
2. Update workflow deployment paths and script references; keep deployment triggers manual (`workflow_dispatch` only).
3. Check relative Bicep imports, embedded file loads, notebook cells and shell environment helpers.
4. Run existing local tests and compilation checks before any cloud deployment.
5. Review GitHub-side path rules or environment deployment policies separately.

Do not commit notebook outputs, local credentials, Terraform state or saved
plans. Directory moves do not clean previously published Git history.
