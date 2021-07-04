# Create XRD and Compositions

We will use the "Composition" feature of Crossplane to create a `network` and a `cluster` abstractions.

* a `network` will be composed of a VPC, an internet gateway, a set of subnets, a routetable and a security group
* a `cluster` will be composed of `services` and `eks` resources. Both are compositions. Whereas `services` will install the prometheus-operator via an HELM chart, `eks` will aggregate an AWS EKS cluster plus a node group and a set of IAM resources.

## Create XRD and Compositions for a "Network" composite resource.

Now, let's go for our first composition: a `Network`.

We start with a new `CompositeResourceDefinition` (XRD) object, named `compositenetworks.aws.platformref.wescale.fr`.

```sh
kubectl apply -f network/definition.yaml
# Ensure the kubernetes cluster handles new resources in the `wescale` api group.
# You must see a namespace scoped resource type named `Network` and a `CompositeNetwork` which is cluster scoped.
kubectl api-resources|grep wescale
# You can consult the documentation of the new resource
kubectl explain network
kubectl explain network.spec
```

See how the [network/definition.yaml](./network/definition.yaml) file specifies `claimNames`, `group`, `names` and `schema` attributes.


Once the interface (XRD) is created, we indicate a `Composition` (implementation) resource, named `compositenetworks.aws.platformref.wescale.fr`.

```sh
kubectl apply -f network/composition.yaml
```

See how the [network/composition.yaml](./network/composition.yaml) file specifies the implemented XRD.

Finally, look at the `resources` attribute to see the effective managed (cloud) resources.


## Create XRD and a Composition for a "Cluster" composite resource

The steps are similare for the `Cluster` abstraction: interface definition, then at least one composition.

But here, the default composition is also based on Crossplane compositions:

cluster 
  
     |___ EKS.aws.platformref.wescale.fr/v1alpha1
         |___ IAMRole.identity.aws.crossplane.io/v1beta1
         |___ IAMRolePolicyAttachment.identity.aws.crossplane.io/v1beta1
         |___ Cluster.eks.aws.crossplane.io/v1beta1
         |___ IAMRole.identity.aws.crossplane.io/v1beta1
         |___ IAMRolePolicyAttachment.identity.aws.crossplane.io/v1beta1
         |___ IAMRolePolicyAttachment.identity.aws.crossplane.io/v1beta1
         |___ IAMRolePolicyAttachment.identity.aws.crossplane.io/v1beta1
         |___ NodeGroup.eks.aws.crossplane.io/v1alpha1
         |___ ProviderConfig.helm.crossplane.io/v1beta1

     |___ Services.aws.platformref.wescale.fr/v1alpha1
         |___ Release.helm.crossplane.io/v1beta1

Look at the files inside the [cluster](./cluster) folder

```sh
kubectl apply -R -f cluster/
```
## Ensure the XRD and Compositions are available

Finally, you can list all the XRD and compositions:
```sh
kubectl get composition,compositeresourcedefinition
```

Some XRD are `offered` and not others. Why?

## Dynamic provisioning (Claim)

Now, it is time to use the composite resources to create cloud resources:

```sh
kubectl apply -f examples/ -n default
# Get the claims status:
kubectl get network,cluster -n default
# If you want to see the status of the managed resources created by the "network" claim
kubectl get crossplane -l crossplane.io/claim-name=demo-aws-network
# If you want to see the status of the managed resources created by the "cluster" claim
kubectl get crossplane -l crossplane.io/claim-name=demo-aws-cluster
```

Once the claim `demo-aws-cluster` is `Ready`, you can retrieve the Kubeconfig file inside a kubernetes secret.

And so, ensure some prometheus stuff is inside the created kubernetes cluster:
```sh
# Save current KUBECONFIG value
export KUBECONFIG_SAVED=$KUBECONFIG
# Get the Kubeconfig file for the newly created cluster
kubectl get secret demo-aws-cluster -o jsonpath='{.data.kubeconfig}'|base64 -d > .localkubeconfig
# Use this file
export KUBECONFIG=$(pwd)/.localkubeconfig
kubectl get nodes
# Get the prometheurs pods
kubectl get pod -n operators 
# Restore the previous KUBECONFIG value
export KUBECONFIG=$KUBECONFIG_SAVED
```

---
**NOTE**

In this example, we have only one composition per Composite Resource Definition (XRD).
In the case of multiple compositions you can indicate a `compositionRef` or `compositionSelector`:

```yaml
compositionSelector:
  matchLabels:
    provider: aws
```
See the [examples/static-prov/README.md](./examples/static-prov/README.md) to view static provisioning of composite resources.

---
