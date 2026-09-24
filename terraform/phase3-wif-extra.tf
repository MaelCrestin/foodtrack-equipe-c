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
# dans votre main.tf, ajustez les references ci-dessous en consequence.

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
#
# Deux roles, plutot qu un seul "storage.admin" plus large : le pipeline ne
# fait jamais de terraform apply (geste humain volontairement garde hors
# du pipeline, cf. deploy.yml), donc il n a besoin QUE de lire la
# politique IAM du bucket pour calculer le plan - jamais de l ecrire, et
# encore moins de supprimer le bucket. storage.admin donnerait les deux,
# ce qui est plus que necessaire sur le bucket qui contient tout l etat.
resource "google_storage_bucket_iam_member" "ci_tfstate_access" {
  bucket = "foodtrack-c-tfstate-${var.project_id}"
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${module.wif_github.ci_service_account_email}"
}

resource "google_storage_bucket_iam_member" "ci_tfstate_bucket_read" {
  bucket = "foodtrack-c-tfstate-${var.project_id}"
  role   = "roles/storage.legacyBucketReader"
  member = "serviceAccount:${module.wif_github.ci_service_account_email}"
}

# Meme probleme sur tout AUTRE bucket qui porte deja une ressource
# google_storage_bucket_iam_member (ici le bucket de logs cree en phase 1,
# module.stockage) : `terraform plan` lit l'etat ENTIER, donc il doit
# pouvoir lire la politique IAM de ce bucket aussi, meme si le pipeline ne
# la modifie jamais. Lecture seule suffisante ici (le compte CI ne
# modifie jamais cette liaison) : storage.legacyBucketReader inclut
# storage.buckets.getIamPolicy sans donner de droit d'ecriture.
resource "google_storage_bucket_iam_member" "ci_logs_bucket_read" {
  bucket = "foodtrack-c-logs-foodtrack-equipe-c"
  role   = "roles/storage.legacyBucketReader"
  member = "serviceAccount:${module.wif_github.ci_service_account_email}"
}