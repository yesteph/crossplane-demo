# Manage resources for a cloud provider

## VPC

See the doc [here](https://doc.crds.dev/github.com/crossplane/provider-aws/ec2.aws.crossplane.io/VPC/v1beta1@v0.18.1) to complete the `basic-vpc.yaml` file.

This VPC must be created in `eu-west-3` region with a CIDR `10.0.0.0/16`.

```sh
kubectl apply -f basic-vpc.yaml
kubectl get vpc
```

Inspect the created resources:
```sh
kubectl describe vpc
```

Note that each resource has `forProvider` (desired) at `status.atProvider` (current) attributes.

## Internet Gateway and objectRef

We will create an Internet Gateway: see the doc [here](https://doc.crds.dev/github.com/crossplane/provider-aws/ec2.aws.crossplane.io/InternetGateway/v1beta1@v0.18.1).

This Internet gateway must be attached to the VPC of the `my-basic-crossplane-vpc` managed resource.
We will use the `vpcIdRef` field to do that.

The given `igw.yaml` file should do the job...

```sh
kubectl apply -f igw.yaml
kubectl get internetgateway
```

```
Inspect the created resources:
```sh
kubectl describe internetgateway
```

Question: 
* Is the IGW ready and synced? Why?

Fix the Yaml file.

## Public subnets

We will create two **public** Subnets attached to the VPC of the `my-basic-crossplane-vpc` managed resource. See the doc [here](https://doc.crds.dev/github.com/crossplane/provider-aws/ec2.aws.crossplane.io/Subnet/v1beta1@v0.18.1).

Each subnet must:
* be in a distinct availability zone
* get a CIDR `10.0.0.0/24` or `10.0.1.0/24`

Complete the `public-subnets.yaml` file.

```sh
kubectl apply -f public-subnets.yaml
kubectl get subnets
```

### Private subnets - import existing resources

Crossplane supports import of existing Cloud resources.
To do that, you can use the `crossplane.io/external-name` annotation inside a managed resource.

With the AWS CLI, we will create two **private** Subnets attached to the VPC of the `my-basic-crossplane-vpc`, then import them:
```sh
VPC_ID=$(kubectl -n crossplane-system get vpc my-basic-crossplane-vpc -o jsonpath='{.metadata.annotations.crossplane\.io/external-name}')
AWS_PROFILE=SET_IT aws ec2 create-subnet --availability-zone eu-west-3a --cidr-block 10.0.2.0/24 --vpc-id "${VPC_ID}" --region eu-west-3
AWS_PROFILE=SET_IT aws ec2 create-subnet --availability-zone eu-west-3b --cidr-block 10.0.3.0/24 --vpc-id "${VPC_ID}" --region eu-west-3
```

Note the subnet ids, then edit the `private-subnets.yaml` file to set the `crossplane.io/external-name` annotation:

```sh
apiVersion: ec2.aws.crossplane.io/v1beta1
kind: Subnet
metadata:
  name: crossplane-imported-subnet
  annotations:
    crossplane.io/external-name: subnet-08ba1dd8960fdedc3 ## subnet ID ??
  labels:
    vpc: crossplane-vpc
    private: 'true'
spec:
 forProvider:
    region: eu-west-3
    availabilityZone: eu-west-3a ## zone ?
    vpcIdRef:
      name: crossplane-vpc
    cidrBlock: 10.0.5.0/24 # CIDR ?
    mapPublicIPOnLaunch: false
    tags:
    - key: Name
      value: crossplane-imported-subnet
```

```
kubectl apply -f private-subnets.yaml
kubectl get subnet 
```

Note the tag `Name` has been synced on the AWS side.
## EIP and Natgateway

We will create an EIP and one NatGateway bound to the EIP for each availability zone.

```sh
kubectl apply -f eip-natgateway.yaml
kubectl get address,natgateway
```

The NatGateways can take few seconds to be ready.

## Route tables and object selectors

We will create three route tables:
* one public is associated to the public subnets and use the Internet Gateway for non local CIDR
* one private for each availability zone. It will route non local CIDR to the NatGateway

```sh
kubectl apply -f route-table.yaml
kubectl get routetable
```

**NOTE**

Look at the `subnetIdSelector` attribute of the route tables.

## Reconcile loops

On the AWS console, we will delete the `my-public-crossplane-rt` route table:
* remove the route to the Internet Gateway
* edit the subnet associations to remove all
* delete the route table

Wait one minute and refresh the web browser.

Is the route table present?
