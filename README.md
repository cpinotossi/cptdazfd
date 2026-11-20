---
title: Azure Front Door labs
description: Project catalog for Azure Front Door demos, private origins and deployment experiments.
---

## Start here

The repository is a collection of independent Azure Front Door scenarios.
Choose a project, read its prerequisites and review its resource names before
deploying. No root-level deployment provisions all projects.

> [!CAUTION]
> Complete the [publication safety requirements](docs/publication-safety.md)
> before sharing this repository. A fresh local history does not revoke
> previously exposed credentials or clean the separate submodule repository.

## Projects

| Project                                                             | Purpose                                               | Technology                         | Status                                    |
| ------------------------------------------------------------------- | ----------------------------------------------------- | ---------------------------------- | ----------------------------------------- |
| [simpledemo](projects/simpledemo/README.md)                         | Front Door Standard, WAF and custom-domain DNS        | Bicep, GitHub Actions              | Documented demo                           |
| [containerapp](projects/containerapp/README.md)                     | Container Apps behind Front Door and Private Link     | Bicep, Bash                        | Experimental scenario                     |
| [afdmove](projects/afdmove/README.md)                               | Front Door moves across subscriptions                 | Terraform, PowerShell              | Documented experiment                     |
| [mtlsupload](projects/mtlsupload/README.md)                         | Private origins, mTLS, signed URLs, Edge and JA4      | Bicep, notebooks, GitHub Actions   | Documented showcase with local tests      |
| [frontdoor-private-link](projects/frontdoor-private-link/README.md) | Private Link Service, load balancer and VM origin     | Bicep, external submodule          | Experimental, existing build blockers     |

These are documentation statuses, not production-readiness claims. Cloud
deployments have not been reverified as part of restructuring.

## Experiments

* [fdpipeline](experiments/fdpipeline/README.md): CARML registry-module deployment and idempotency experiment
* [legacy-frontdoor](experiments/legacy-frontdoor/README.md): older root templates, incomplete fragments and retained diagnostic artifacts

## Layout

```text
.github/       GitHub Actions and Azure federation configuration
projects/      Scenario-specific infrastructure, scripts, tests and notebooks
experiments/   Incomplete or exploratory scenarios
external/      Pinned external Git submodule
docs/          Shared setup, safety guidance and historical reference notes
```

Project names and Azure deployment identifiers are retained. The external
submodule remains pinned to its previous commit and is not fetched automatically.
See [external dependencies](external/README.md) before initializing it.

## Local validation

From the repository root:

```bash
node --test projects/mtlsupload/edge/upload-policy.test.cjs projects/mtlsupload/scripts/new-download-sas.test.cjs
az bicep build --file projects/simpledemo/main.bicep --stdout > /dev/null
az bicep build --file projects/containerapp/main.bicep --stdout > /dev/null
az bicep build --file projects/mtlsupload/base/main.bicep --stdout > /dev/null
```

These commands do not deploy Azure resources. Other checks and known blockers
are described in each project's README.

## Documentation and automation

* [Documentation and structure conventions](docs/README.md)
* [GitHub Actions setup](docs/github-actions-setup.md)
* [Workflows](.github/workflows/)
* [Historical Front Door reference notes](docs/reference/frontdoor-notes.md)

GitHub environments and workflow names are unchanged. Workflow paths now point
to the relocated projects. All deployment and cleanup workflows run only via
`workflow_dispatch`; commits, pushes and pull requests do not start deployments.
Start a workflow explicitly in GitHub under Actions > select workflow > Run workflow.
Repository rules maintained in GitHub, including
external path-based policies, must be reviewed separately.
