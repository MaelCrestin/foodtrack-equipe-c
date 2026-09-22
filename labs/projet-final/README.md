# Lab — Projet final FoodTrack

Tout ce qui vous est fourni pour le projet final. Le reste, vous l'écrivez.

Énoncé complet : [`projets/projet-final/CAHIER_DES_CHARGES.md`](../../projets/projet-final/CAHIER_DES_CHARGES.md).

## Ce que contient ce dossier

| Chemin | Contenu | Statut |
|---|---|---|
| [`manifests/`](manifests/) | L'application FoodTrack, déployable dans un namespace unique | Point de départ, à retravailler |
| [`manifests/07-storageclass-hdd.yaml`](manifests/07-storageclass-hdd.yaml) | Classe de stockage sur disque HDD | Fourni, à appliquer tel quel ou à adapter |
| [`terraform-fourni/wif-github/`](terraform-fourni/wif-github/README.md) | Fédération d'identité GitHub Actions vers Google Cloud | Fourni, clé en main |
| [`ci/deploy.yml.squelette`](ci/deploy.yml.squelette) | Squelette de workflow, authentification remplie | À compléter |

## L'application

| Tier | Objet Kubernetes | Image épinglée | Rôle |
|---|---|---|---|
| Portail | `Deployment/portail-qualite` | `nginx:1.30.5` | Portail de suivi qualité, reverse proxy `/api/` vers l'API capteurs |
| API | `Deployment/api-capteurs` | `us-docker.pkg.dev/google-samples/containers/gke/hello-app:2.0` | API de consultation des relevés de température |
| Cache | `StatefulSet/cache-releves` | `redis:8.10.1` | Cache des derniers relevés, sur volume persistant |

Le cache n'est pas encore alimenté par l'API. À ce stade il porte le volume persistant et sert de support aux manipulations de stockage et de sondes sur une charge avec état.

## Prérequis

- Un cluster GKE joignable, et un contexte `kubectl` actif (`kubectl config current-context`).
- **Cloud NAT en place** : les images `nginx` et `redis` viennent de Docker Hub. Sur un cluster à nœuds privés, sans NAT, les pods restent en `ImagePullBackOff`. L'image `hello-app`, elle, passe par l'accès privé aux services Google.
- La classe de stockage `foodtrack-hdd` appliquée **avant** le StatefulSet.

## Déploiement de départ

```bash
# la classe de stockage d abord : le StatefulSet la reclame
kubectl apply -f manifests/07-storageclass-hdd.yaml

kubectl apply -f manifests/00-namespace.yaml
kubectl apply -f manifests/01-configmap.yaml
kubectl apply -f manifests/02-secret-exemple.yaml

kubectl apply -f manifests/03-deployment-portail-qualite.yaml
kubectl apply -f manifests/04-deployment-api-capteurs.yaml
kubectl apply -f manifests/05-statefulset-cache-releves.yaml
kubectl apply -f manifests/06-services.yaml
```

## Vérification

```bash
kubectl get pods,pvc -n foodtrack
kubectl get storageclass foodtrack-hdd

# le portail repond, sans exposition externe
kubectl port-forward -n foodtrack svc/portail-qualite 8080:8080
# dans un autre terminal :
curl -s http://localhost:8080/healthz
curl -s http://localhost:8080/api/
```

Le disque provisionné doit être de type `pd-standard`. Vérifiez-le, c'est la contrainte la plus facile à rater :

```bash
gcloud compute disks list --filter="name~foodtrack" --format="table(name,type.basename(),sizeGb,zone.basename())"
```

## Ce que ces manifestes ne font pas

Ils ne sont pas le livrable. Il leur manque, et c'est votre travail :

- la séparation en trois environnements, avec une configuration réellement différente dans chacun ;
- l'exposition externe, et le type de Service qu'elle impose ;
- la mise à l'échelle horizontale de l'API capteurs ;
- la sortie des valeurs sensibles hors du dépôt.

## Nettoyage

```bash
kubectl delete namespace foodtrack
kubectl delete storageclass foodtrack-hdd
```

🟨 Supprimer le namespace supprime les PVC, donc les disques : `reclaimPolicy` est réglé sur `Delete`. Vérifiez ensuite qu'aucun disque ne survit, sinon il reste facturé.

```bash
gcloud compute disks list
```
