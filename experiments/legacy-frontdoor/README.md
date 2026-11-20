---
title: Legacy Front Door experiments
description: Retained root-level templates, incomplete fragments and historical diagnostic artifacts.
---

## Scope and status

Status: incomplete experiments, not verified deployment entry points.
See the [project catalog](../../README.md).

* [deploy.bicep](deploy.bicep) references storage, DNS and Front Door modules in the external [azbicep submodule](../../external/azbicep).
* [fqdn.fd.bicep](fqdn.fd.bicep) is a custom-domain fragment with undefined identifiers.
* [Historical walkthroughs](docs/walkthrough.md) retain the Traffic Manager and two-origin notes. Their headings do not guarantee that the matching implementation exists.
* [artifacts/](artifacts/) retains the empty former root `-replace` file. The generated `output.txt` dump was removed because it contained sensitive token values.

## Prerequisites and validation

Review the [publication warning](../../docs/publication-safety.md) before using
the external submodule. Do not commit generated diagnostic dumps; they can
contain credentials and environment details.

There is no supported deployment sequence for this collection. The old
two-origin notes refer to an absent `bicep/deploy1.bicep`; that dependency has
not been recreated. Do not run these notes as a deployment script.

Local Bicep builds already failed before restructuring because dependencies
or identifiers were missing. Repair and validate an experiment before promoting
it to the projects directory.

## Cleanup and costs

No cleanup automation is provided. If you deploy a repaired experiment, record
its resource group, DNS changes and dependencies before deployment, then remove
only those resources when finished. Azure resources can incur charges.
