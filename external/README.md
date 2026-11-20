---
title: External dependencies
description: Git submodule location and review requirements for shared Bicep modules.
---

## azbicep

[azbicep](azbicep) remains a Git submodule from
<https://github.com/cpinotossi/azbicep>, pinned to the existing commit.
It is not a copy of repository-owned modules.

> [!CAUTION]
> Read the [publication warning](../docs/publication-safety.md) before fetching
> or sharing this dependency. The recorded history requires a separate review.

After reviewing the referenced version, initialize it from the repository root:

```bash
git submodule update --init -- external/azbicep
```

The restructure does not fetch, update or clean the submodule's history.
Project-specific modules stay inside their projects; introduce shared local
modules only when multiple projects actually use the same implementation.
