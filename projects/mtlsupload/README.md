---
title: Azure Front Door mTLS upload showcase
description: Bicep and GitHub Actions setup for mTLS-protected uploads and private origins behind two Azure Front Door Premium profiles
---

## Overview

Status: documented showcase. Local tests and Bicep builds are available; an
Azure deployment has not been reverified as part of the repository restructure.
See the [project catalog](../../README.md) for the other scenarios.

Two Azure Front Door (AFD) Premium profiles in `rg-cptmtls` (subscription `09808f31-065f-4231-914d-776c2d6bbe34`, `westeurope`). All origins are private except where a use case says otherwise, only AFD is public. DNS lives in the Azure DNS zone `cptdaz.org` (subscription `ff0bb075-6c44-44ee-bb64-d46ce828c62f`, resource group `domains`).

Each use case has its own notebook. The notebook holds the design notes, prerequisites, warnings and the complete walkthrough, so this file only lists them.

| Use case                                   | Profile              | Domain                  | Notebook                                  |
|--------------------------------------------|----------------------|-------------------------|-------------------------------------------|
| Public text file and Node.js page          | `afd-cptmtls-public` | `hello.cptdaz.org`      | [hello](notebooks/hello.ipynb)            |
| Public CSS from a private storage account  | `afd-cptmtls-public` | `media.cptdaz.org`      | [media](notebooks/media.ipynb)            |
| Signed URL downloads with caching          | `afd-cptmtls-public` | generated `azurefd.net` | [signed-url](notebooks/signed-url.ipynb)  |
| mTLS upload to private storage with SAS    | `afd-cptmtls-upload` | `upload.cptdaz.org`     | [upload](notebooks/upload.ipynb)          |
| mTLS upload with managed identity, no SAS  | `afd-cptmtls-upload` | `uploadp.cptdaz.org`    | [uploadp](notebooks/uploadp.ipynb)        |
| Path-scoped Edge Action upload policy      | `afd-cptmtls-upload` | `uploadp.cptdaz.org`    | [upload-edge](notebooks/upload-edge.ipynb) |
| WAF rules with JA4 client fingerprints     | `afd-cptmtls-upload` | `uploadp.cptdaz.org`    | [upload-ja4](notebooks/upload-ja4.ipynb)  |

## Layout

* `base/` network, Bastion, VM, internal load balancer, Private Link Service, storage accounts, Key Vault, Log Analytics, diagnostic settings, both AFD profiles, mTLS CA secret
* `afd/` one Bicep module per use case
* `edge/` Edge Action code and its tests
* `scripts/` PKI, hostname pre-computation, DNS records, private endpoint approval, SAS issuing, Edge Action deployment
* `notebooks/` one Bash notebook per use case
* [Repository workflows](../../.github/workflows/) `base`, `afd-hello`, `afd-media`, `afd-upload`, `afd-uploadp`, `cleanup`

All workflows use one service principal (`sp-cptmtls-github`) with OIDC federation, one GitHub environment per workflow. Review each environment's protection settings to control deployment access. The DNS zone is set once per workflow (`DNS_ZONE`).

## Policies that shape the design

* Shared key access, public network access and anonymous blob access on storage are reset by tenant policies. Storage accounts for `hello`, `media` and `uploadp` carry the exclusion tag `SecurityControl=Ignore`
* Key Vault is private, AFD reads the CA secret as trusted Microsoft service
* `deploymentScripts` are not usable (they need shared key access), the VM seeds blobs through the private endpoints with its managed identity
* AFD origin authentication with managed identity does not work with Private Link, hence the separate `uploadp` setup

## Deployment order

All workflows are manual (`workflow_dispatch` only). Commits, pushes and pull
requests do not deploy resources. In GitHub, open Actions, select the workflow
and choose Run workflow. Environment approvals still apply where configured.

1. `base` workflow
2. `afd-hello`, `afd-media`, `afd-upload`, `afd-uploadp` (independent of each other)
3. Each AFD workflow pre-computes the default hostname, creates the CNAME, deploys, adds the `_dnsauth` TXT record, approves the private endpoint connections and waits for the domain

The `signed-url` and `upload-ja4` use cases are deployed from their notebooks. `upload-edge` is deployed by `afd-uploadp` and explained in its notebook.

## Notebooks

Open notebooks from this project's `notebooks/` directory. Run repository-level
commands, including the local tests below, from the repository root.

The notebooks use the Bash kernel. Set it up once:

```bash
bash <skill>/scripts/setup-bash-kernel.sh --venv .venv
```

Select the kernel `.venv/share/jupyter/kernels/bash` in VS Code. The notebooks expect `az` (logged in), `http`, `jq`, `azcopy`, `openssl` and the test PKI in `~/mtls-pki` (created by `scripts/new-pki.sh`). Some use cases need more tools, which are listed in their notebook. Storage access from the notebooks works from a machine in the peered VNet with the linked private DNS zones. Do not commit executed notebook outputs.

## VS Code access to the VM

`base/vscode-tunnel.sh` installs the VS Code CLI and runs `code tunnel` as the `code-tunnel` systemd service (tunnel name `vm-cptmtls`). Log in once with GitHub, then connect from VS Code with *Remote Tunnels: Connect to Tunnel* or <https://vscode.dev/tunnel/vm-cptmtls>:

```bash
az vm run-command invoke -g rg-cptmtls -n vm-cptmtls --command-id RunShellScript \
  --scripts "journalctl -u code-tunnel -n 5 --no-pager" --query "value[0].message" -o tsv
```

Open the printed `https://github.com/login/device` link and enter the code. If the code expired, run `systemctl restart code-tunnel` on the VM and read the log again. Alternative without GitHub: Bastion SSH tunnel with `az network bastion tunnel`.

## Data plane access

The user in `USER_OBJECT_ID` receives Storage Blob Data Contributor and Delegator on all storage accounts, Key Vault Administrator, Virtual Machine Administrator Login and Log Analytics Contributor. Private resources are reachable only from inside the VNet, for example through Bastion.

## Local validation

From the repository root:

```bash
node --test projects/mtlsupload/edge/upload-policy.test.cjs projects/mtlsupload/scripts/new-download-sas.test.cjs
az bicep build --file projects/mtlsupload/base/main.bicep --stdout > /dev/null
```

The Node.js tests use local mocks and do not require Azure access.

## Cleanup and costs

VM, Bastion, Front Door Premium, storage and monitoring can incur charges.
Use the [cleanup workflow](../../.github/workflows/cleanup.yml) only after
checking its DNS zone and resource group. It requires the confirmation `delete`
and removes the shared resources for all use cases in this project.
