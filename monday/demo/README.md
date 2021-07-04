## Create infra with crossplane

```sh
kubectl apply -f .
# Then wait they are all 'Ready'
kubectl wait --for=condition=ready -l stack=crossplane-demo --timeout=120s vpc,routetable,address,subnet,natgateway,internetgateway
```

## Reconcile loops

On the AWS console, we will delete the `my-basic-crossplane-igw` internet gateway:
* detach the internet gateway
* delete the internet gateway

Wait one minute and refresh the web browser.

Is the internet gateway present?
