# Module fourni — fédération d'identité GitHub Actions vers Google Cloud

Ce module crée tout ce qu'il faut pour qu'un workflow GitHub Actions agisse sur votre projet Google Cloud **sans aucune clé**.

## Pourquoi il vous est fourni

Monter une fédération d'identité de zéro prend une demi-journée, et l'essentiel du temps part en aller-retours sur des messages d'erreur peu bavards. Le projet n'a pas ce temps. En échange, vous devez pouvoir expliquer ce que fait chacune des quatre ressources — la question tombe en soutenance, et lire les commentaires de [`main.tf`](main.tf) suffit à y répondre.

## Le mécanisme en quatre temps

1. GitHub Actions demande à GitHub un jeton OIDC signé, qui décrit l'exécution en cours : dépôt, branche, auteur, identifiant d'exécution.
2. L'action d'authentification présente ce jeton au service de sécurité de Google Cloud.
3. Google vérifie la signature auprès de GitHub, puis applique la condition d'attribut du fournisseur. Si le dépôt ne correspond pas, l'échange est refusé.
4. Google rend un jeton d'accès de courte durée au nom du compte de service, à condition qu'une liaison IAM autorise l'identité fédérée à l'emprunter.

Aucune clé n'existe, donc aucune clé ne fuit.

## Intégration

Copiez le dossier dans vos modules Terraform, puis appelez-le depuis votre racine :

```hcl
module "wif_github" {
  source = "./modules/wif-github"

  project_id   = var.project_id
  github_owner = "votre-organisation"
  github_repo  = "foodtrack-equipe-a"
}
```

Après `terraform apply`, récupérez les deux valeurs à déclarer côté GitHub :

```bash
terraform output wif_provider_name
terraform output ci_service_account_email
```

Elles vont dans `Settings > Secrets and variables > Actions > Variables`, sous les noms `WIF_PROVIDER` et `CI_SERVICE_ACCOUNT`. Ce sont des **variables**, pas des secrets : elles ne contiennent rien de confidentiel.

## Ordre des opérations

Le pipeline ne peut pas créer la fédération dont il a besoin pour exister. Vous appliquez donc ce module **depuis votre poste ou Cloud Shell**, une fois, avant la première exécution du workflow. Ensuite seulement le pipeline devient autonome.

## Ce que le compte de service a le droit de faire

| Rôle | Ce qu'il permet |
|---|---|
| `roles/artifactregistry.writer` | Pousser des images dans vos dépôts d'images |
| `roles/container.developer` | Agir sur les objets Kubernetes du cluster, et récupérer les accès au cluster |

Pas de création de cluster, pas d'administration IAM, pas de `roles/editor`. Si votre pipeline doit faire davantage — jouer un `terraform plan`, par exemple — ajoutez les rôles par `roles_supplementaires` et justifiez chacun d'eux dans votre `README`.

## Diagnostic

| 🟨 Symptôme | Cause probable | Vérification |
|---|---|---|
| L'étape d'authentification échoue immédiatement | `permissions: id-token: write` absent du workflow | Relire l'en-tête du workflow |
| L'échange de jeton est refusé | La condition d'attribut ne correspond pas au dépôt réel | Comparer `github_owner` et `github_repo` au nom complet affiché par GitHub |
| L'échange réussit mais l'emprunt échoue | Liaison `workloadIdentityUser` absente ou mal formée | `terraform output principal_set`, puis `gcloud iam service-accounts get-iam-policy` sur le compte |
| Permission refusée sur Artifact Registry ou le cluster | Rôle manquant, ou dépôt situé dans un autre projet | Lire le nom de ressource cité dans le message d'erreur |
| `Error 409: Requested entity already exists` à la création du pool | Un pool du même identifiant a été supprimé récemment. La suppression est différée : l'identifiant reste réservé | `gcloud iam workload-identity-pools list --location=global --show-deleted` montre le pool en état `DELETED`. Changer `pool_id`, ou restaurer le pool avec `gcloud iam workload-identity-pools undelete` |

Référence : `cloud.google.com/iam/docs/workload-identity-federation-with-deployment-pipelines`.
