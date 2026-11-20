---
title: CARML Front Door deployment experiment
description: Subscription-scoped Front Door module and idempotency experiment.
---

## Overview

Status: experimental. [main.bicep](main.bicep) deploys dependencies and invokes
CARML modules in `init` and `idem` iterations. It is not a repository-wide
pipeline framework. See the [project catalog](../../README.md).

## Prerequisites and deployment

Azure CLI, Bicep, subscription permissions and access to the
`carml.azurecr.io` registry are required. The referenced modules are not available
in the current local cache, so offline builds cannot resolve them.

Review module versions, parameters and resource names before following the
[historical walkthrough](docs/walkthrough.md). Its commands start from the
repository root and change into this experiment's directory.

## Validation

With authorized registry access, restore the modules and build from the
repository root:

```bash
az bicep restore --file experiments/fdpipeline/main.bicep
az bicep build --file experiments/fdpipeline/main.bicep --no-restore --stdout > /dev/null
```

No Azure deployment has been reverified during restructuring.

## Cleanup and costs

Front Door, storage and monitoring can incur charges. The template creates a
`CanNotDelete` resource lock. Review and remove the experiment's lock before
deleting its dedicated resource group. Preserve shared DNS resources.
