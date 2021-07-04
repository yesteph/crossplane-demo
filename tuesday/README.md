# Tuesday - deploy with ArgoCD and Helm

See how to deploy our InfraAsCode on Kubernetes.

One of the benefit of Kubernetes is its ecosystem of tools.
Among them: ArgoCD and Helm.

This demo starts with the installation of ArgoCD to apply gitOps principles.

Then we will tell ArgoCD to deploy an HELM chart.

# ArgoCD - Installation 

```sh
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

Wait few minutes to get all the pods running.

At this point, you can expose the `argocd-server` service:
```sh
kubectl wait --for=condition=ready pod -n argocd -l app.kubernetes.io/name=argocd-server
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

And connect to the [UI](http://localhost:8080) with the following login / password:
```sh
password=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo "Argo CD login/passwd: admin / ${password}"
```

# Helm chart on ArgoCD

The `argocd-app.yaml` file declares an ArgoCD application to deploy the local `vpc` Helm chart:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: declarative-gitops-vpc
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/yesteph/crossplane-demo.git
    targetRevision: HEAD
    path: tuesday/vpc
  syncPolicy:
    syncOptions:
    - CreateNamespace=true
  destination:
    server: https://kubernetes.default.svc
    namespace: crossplane-system
```

Create the application on your ArgoCD instance:

```sh
kubectl apply -f argocd-app.yaml -n argocd
```

On the [ArgoCD UI](http://localhost:8080), you can see all the crossplane resources.
Because the ArgoCD Application is configured for **manual** `sync` operations, run `sync`.

At this point, ArgoCD will create the crossplane resources and so the AWS components.