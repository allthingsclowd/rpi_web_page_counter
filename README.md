# rpi_web_page_counter

Build up a Raspberry-Pi cluster using the HashiStack

Based on - https://github.com/allthingsclowd/web_page_counter

However, recreating the installation scripts to align with HashiCorp's current production deployment guides:

- [Consul](https://learn.hashicorp.com/consul/datacenter-deploy/deployment-guide)
- [Vault](https://learn.hashicorp.com/vault/operations/ops-deployment-guide)
- [Nomad](https://www.nomadproject.io/guides/install/production/deployment-guide.html)

The goal when scripting this deployment is to ensure idempotency during redeployments.

