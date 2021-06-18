# Create XRD and XR

```sh
# Install the HELM provider
kubectl apply -f ../misc/helm-provider.yaml
kubectl apply -R -f network/
kubectl apply -R -f cluster/
# Check XRD and XR are available
kubectl get composition,compositeresourcedefinition
```

See some are `offered` and not others.

# Dynamic provisioning (Claim)

```sh
kubectl apply -f examples/ -n default
# Get the XR status:
kubectl get network,cluster -n default
# Get the managed resources
kubectl get crossplane -l crossplane.io/claim-name=demo-aws-network
//kubectl get crossplane -l networks.aws.platformref.wescale.fr/network-id=demo-aws-network
```

Get the connection credentials.
export kubeconfig and list the pods.



The claim can include a `compositionRef` or `compositionSelector`:

```yaml
compositionSelector:
  matchLabels:
    provider: aws
```


# Static provisioning (Create XR directly)

Create the XR.
```sh
kubectl apply -f network-static-unpublished.yaml
```


# Static provisioning - published

Create the XR.
```sh
kubectl apply -f network-static-published.yaml
```

Create a Claim referencing the XR with a `resourceRef`:

```yaml
resourceRef:
  apiVersion: aws.platformref.wescale.fr/v1alpha1
  kind: CompositeNetwork
  name: demo-static-aws-network
```