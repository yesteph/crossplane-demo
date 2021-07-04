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