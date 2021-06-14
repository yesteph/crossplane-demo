## Create infra with crossplane

```sh
kubectl apply -f .
# Then wait they are all 'Ready'
kubectl wait --for=condition=ready -l stack=crossplane-demo --timeout=120s vpc,routetable,address,subnet,natgateway,internetgateway
```

## Reconcile loops

On the AWS console, we will delete the `my-public-crossplane-rt` route table:
* remove the route to the Internet Gateway
* edit the subnet associations to remove all
* delete the route table

Wait one minute and refresh the web browser.

Is the route table present?
