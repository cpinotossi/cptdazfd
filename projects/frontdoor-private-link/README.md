---
title: Front Door with a private VM origin
description: Experimental Bicep templates for Front Door, Private Link Service and a VM backend.
---

## Overview

Status: experimental, not currently buildable in this checkout. The templates
already had unresolved dependencies and identifiers before restructuring.
See the [project catalog](../../README.md).

The intended traffic path is Front Door Premium, Private Link Service, internal
load balancer and VM. The templates depend on the external
[azbicep submodule](../../external/azbicep).

## Entry points

* [deploybase.bicep](deploybase.bicep): network, VM, load balancer and Private Link Service
* [deployafd.bicep](deployafd.bicep): Front Door and domain modules
* [deploybasep.bicep](deploybasep.bicep) and [deployafdp.bicep](deployafdp.bicep): alternative experimental templates
* [deploybase.bicepparam](deploybase.bicepparam): existing parameter example requiring reconciliation with the template

## Prerequisites and deployment order

Review the [publication warning](../../docs/publication-safety.md) before
initializing the external submodule. Azure CLI, Bicep, subscription access and
appropriate resource permissions are required.

Reconcile template parameters, unresolved identifiers and the reviewed submodule
version first. The intended order is base infrastructure, Front Door, private
endpoint approval, domain validation, then HTTP verification.

The [historical walkthrough](docs/walkthrough.md) preserves the original
commands. Run project-local template commands from this project directory,
not the repository root. It is not a verified deployment runbook.

## Validation

After preparing the dependencies, run from the repository root:

```bash
az bicep build --file projects/frontdoor-private-link/deploybase.bicep --stdout > /dev/null
az bicep build --file projects/frontdoor-private-link/deployafd.bicep --stdout > /dev/null
```

Build failures are expected until the pre-existing issues are resolved.

## Cleanup and costs

VM, Bastion, load balancer and Front Door Premium can incur charges. Review and
remove scenario-specific external DNS records, then delete only the dedicated
resource group. Confirm that no other scenario uses the resources first.
