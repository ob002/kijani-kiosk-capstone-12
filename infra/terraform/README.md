# Terraform — Namespace Provisioning

Provisions `kijani-staging` and `kijani-production` Kubernetes namespaces.

## Prerequisites
- Terraform >= 1.7.0
- `kubectl` configured and pointing at your cluster (`minikube` context)

## Run once before the pipeline

```bash
cd infra/terraform
terraform init
terraform plan
terraform apply -auto-approve
```

## Verify

```bash
kubectl get ns kijani-staging kijani-production
```

Both should show `STATUS: Active`.

## After provisioning

Run Ansible to configure the staging namespace:

```bash
cd infra/ansible
ansible-playbook configure-staging.yml
```
