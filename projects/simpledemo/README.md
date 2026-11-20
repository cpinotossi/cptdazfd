---
title: Simple Azure Front Door demo
description: Bicep deployment of Front Door Standard, WAF and custom-domain DNS.
---

## Overview

Status: documented demo with a local Bicep build. Azure deployment has not been
reverified. See the [project catalog](../../README.md).

[main.bicep](main.bicep) creates the demo resource group and deploys Front Door,
domain validation, CNAME records and WAF. Modules stay local to this project.

## Prerequisites

* Azure CLI with Bicep and an authenticated Azure account
* Subscription deployment permissions and access to the DNS resource group
* An existing storage origin and DNS zone matching the values in the templates

Review the hard-coded resource group, origin and domain names in
[main.bicep](main.bicep) and its modules before deployment.

## Deployment

From the repository root:

```bash
cd projects/simpledemo
az deployment sub create --name simpledemo --location germanywestcentral --template-file main.bicep
```

The subscription location is deployment metadata; resource locations are defined
by the templates. The [GitHub workflow](../../.github/workflows/simpledemo.yml)
uses the `production` environment. Configure its identity using the
[GitHub Actions setup notes](../../docs/github-actions-setup.md).

## Validation

From the repository root, without deploying resources:

```bash
az bicep build --file projects/simpledemo/main.bicep --stdout > /dev/null
```

After deployment, follow the HTTP checks in the
[original walkthrough](docs/walkthrough.md), using your deployed hostname.

## Cleanup and costs

Front Door, WAF and the origin can incur charges. Remove only the CNAME and
validation records created for this demo from the shared DNS zone, then delete
the dedicated demo resource group. Do not delete the shared DNS zone or an
existing storage origin.
