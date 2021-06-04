# Monday - setup and first commands

# Step 1 - setup

## Initiate the control cluster

Get a k8s `control` cluster > v1.17 to provision/manage other clusters and deploy applications on them.

Use your preferred k8s 

For example on your laptop with minikube:

```sh
minikube start --kubernetes-version=v1.20.0 --addons=ingress
```

## Install crossplane 1.2.1

```sh
kubectl create namespace crossplane-system
helm repo add crossplane-stable https://charts.crossplane.io/stable/
helm install crossplane --namespace crossplane-system crossplane-stable/crossplane --version 1.2.1
```

Check Crossplane is installed:
```sh
echo "Crossplane CRD..."
kubectl api-resources --api-group=pkg.crossplane.io
echo ""
echo "Crossplane resources..."
kubectl get all -n crossplane-system
```

Finally, we will install the crossplane plugin for kubectl
```sh
curl -sL https://raw.githubusercontent.com/crossplane/crossplane/master/install.sh | sh
# check the plugin is well installed
kubectl crossplane --help
```

## Add AWS crossplane provider

We need to install a crossplane package for each provider. The list of available providers is [here](https://crossplane.io/docs/v1.2/api-docs/overview.html#api-documentation).

You will note that providers are released independently of the crossplane. In our case, we will install the AWS provider in version 0.18.1.

You can do that using a k8s resource file:
```sh
kubectl apply -f providers/
````
---
**NOTE**

Alternatively, you can use the crossplane plugin for kubectl:
```sh
kubectl crossplane install provider crossplane/provider-aws:v0.18.1
```
---

Ensure the providers are correctly installed: view the new CRDs brought by each Crossplane provider.

## Configure the AWS provider

To configure the AWS provider on Crossplane, we will create k8s resources:
* a Secret containing an AK/SK with sufficient permissions on the target AWS account
* a ProviderConfig to reference the Secret and the target region 

```sh
# Indicate your profile if you get multiple ones
AWS_PROFILE=default && echo -e "[default]\naws_access_key_id = $(aws configure get aws_access_key_id --profile $AWS_PROFILE)\naws_secret_access_key = $(aws configure get aws_secret_access_key --profile $AWS_PROFILE)" > creds.conf
# Then create the k8s
kubectl create secret generic aws-creds -n crossplane-system --from-file=key=./creds.conf
# And del the creds.conf file
rm -rf creds.conf
```

Now, we create the ProviderConfig resource:
```sh
k apply -f providers/config/
```

**CONGRATULATIONS: you are now ready to manage AWS resources with Crossplane!**

# Step 2 - Manage resources for a cloud provider

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

## Internet Gateway

## Subnets

### Import existing resources

Crossplane supports import of existing Cloud resources.
You can use the `crossplane.io/external-name`.

To illustrate that, create a subnet with the aws-cli, then import it:
```sh
{
  cd "$(mktemp -d)"
  VPC_ID=$(kubectl -n crossplane-system get vpc crossplane-vpc -o jsonpath='{.metadata.annotations.crossplane\.io/external-name}')
  kubectl get secret aws-creds -n crossplane-system -o jsonpath='{.data.key}' | base64 -d > creds.txt
  AWS_SHARED_CREDENTIALS_FILE=$(pwd)/creds.txt aws ec2 create-subnet --cidr-block 10.0.5.0/24 --vpc-id "${VPC_ID}" --region eu-west-3
}
```

Note the subnet id, then create a new Subnet for Crossplane:

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

Note the tag `Name` has been synced on the AWS side.


### End 

Questions:
* How are the subnets referenced by the DBSubnetGroup ?
* What are the other possibilities?
* Where is the stored the login/password of the RDSInstance `rdspostgresql`?

### Reconcile loops

TODO: change tags, delete objects ?

### Use EIP IP into SG ?

TODO: ??
