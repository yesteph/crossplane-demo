
See how to share our InfraAsCode on Kubernetes.

One of the benefit of Kubernetes is its ecosystem and developer tools.
Among them: ArgoCD and Helm.

This demo starts with installation of ArgoCD to apply gitOps principles.

Then we will tell ArgoCD to deploy an HELM chart.

# ArgoCD

## Installation

```sh
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

Wait few minutes to get all the pods running.

At this point, you expose the `argocd-server` service:
```sh
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

And connect to the UI with the login / password:
```sh
password=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo "Argo CD login/passwd: admin / ${password}"
```

## Setup

Configura the project ...

OR

Package aws https://github.com/crossplane/crossplane/tree/master/docs/snippets/package

