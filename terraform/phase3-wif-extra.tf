# FoodTrack - equipe C - phase 3 : droits supplementaires du pipeline
#
# A deposer a la racine terraform/, a cote de votre bloc `module "wif_github"`
# existant (cree en phase 1). Ce fichier n'ecrase rien : il AJOUTE des droits
# au compte de service que ce module a deja cree.
#
# Pourquoi ces droits sont necessaires : le job "qualite" du pipeline joue
# `terraform plan` pour publier un resume des changements avant tout
# `apply` humain (cf. .github/workflows/deploy.yml). Le module wif-github
# fourni ne donne au pipeline que la publication d'images et l'action sur les
# objets Kubernetes - pas de quoi lire l'etat des ressources Google Cloud
# pour calculer un plan. D'ou l'ajout ci-dessous, avec le meme principe de
# moindre privilege : lecture seule au niveau du projet, ecriture seulement
# sur le bucket d'etat (necessaire pour poser/lever le verrou de state).
#
# Si votre bloc `module "wif_github"` porte un autre nom que "wif_github"
# dans votre main.tf, ajustez les deux references ci-dessous en consequence.

# Lecture seule sur les ressources du projet : suffisant pour que
# `terraform plan` compare l'etat desire a l'etat reel. Aucune ecriture.
resource "google_project_iam_member" "ci_viewer_pour_plan" {
  project = var.project_id
  role    = "roles/viewer"
  member  = "serviceAccount:${module.wif_github.ci_service_account_email}"
}

# Le verrouillage de l'etat Terraform ECRIT un objet de verrou dans le
# bucket (cf. phase 1) : une lecture seule ne suffit pas, `terraform plan`
# a besoin de creer et de supprimer ce verrou. Droit limite a CE bucket
# precis, jamais au niveau du projet.
resource "google_storage_bucket_iam_member" "ci_tfstate_access" {
  bucket = "foodtrack-c-tfstate-${var.project_id}"
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${module.wif_github.ci_service_account_email}"
}