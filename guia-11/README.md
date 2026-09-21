# TP11 — Terraform

Gestiona la Notes App con Terraform y el provider Docker. Los módulos crean redes, volúmenes y contenedores.

## Requisitos

- Terraform 1.6 o posterior.
- Docker.

## Validar y ejecutar

Desde `guia-11/`:

```bash
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform fmt -check -recursive
terraform validate
terraform plan
```

Revisá el plan antes de aplicar:

```bash
terraform apply
terraform output
bash scripts/verificar.sh
```

La destrucción es una operación separada y voluntaria:

```bash
terraform destroy
```

`terraform.tfvars` y los estados no deben subirse a Git. Para una prueba funcional, `backend_image` debe apuntar a una imagen construida de la Notes App; `python:3.12-slim` no contiene la aplicación.
