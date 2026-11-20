---
title: Publication safety
description: Local snapshot cleanup and outstanding credential, submodule and remote-history requirements.
---

## Local snapshot cleanup

The local history was restarted from a reviewed snapshot on 2026-11-20.
The old Terraform plan is absent, a generated diagnostic dump containing token
values was removed, and the ACA deployment script now requires its VPN shared
key through `VPN_SHARED_KEY` rather than embedding it.

The local snapshot was scanned with Gitleaks. Findings for the public Azure
Key Vault Administrator and Key Vault Secrets User role-definition IDs are not
credentials. Automated scanning is not a guarantee that every sensitive value
has been detected.

The old history is retained only in a restricted local backup outside the
repository. Do not publish or add that backup to any repository. This cleanup
does not rewrite GitHub, other clones, forks, caches or the independent
`azbicep` repository.

## Before publishing

> [!CAUTION]
> A historical Terraform plan contained credentials, and the `azbicep`
> submodule tracked a private SSH key. A fresh root commit does not revoke
> those credentials or remove the independent submodule's history.

* Revoke and replace the exposed service-principal client secret and rotate both
  affected storage account keys before publishing.
* Replace the exposed SSH key and remove its old public key from authorized
  access wherever it was installed.
* Do not republish old refs containing `afdmove/tfplan` or the removed diagnostic
  dump. Fetching old branches or restoring checkpoints can reintroduce them.
* Clean the independent `azbicep` repository history of `ssh/chpinoto.key` and
  review the submodule commit referenced by this repository before publishing.
* Keep Terraform state, local variable files, saved plans, and private keys
  untracked. Review untracked output files and documents before adding them.
* Recheck the working tree, index, submodule, and publication history before
  publishing. Treat credential rotation, submodule cleanup and remote-history
  cleanup as separate requirements that remain unverified here.
