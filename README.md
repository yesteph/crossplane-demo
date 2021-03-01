# crossplane-demo

## Step 1 - install

### Initiate the control cluster


Get a k8s `control` cluster > v1.17 to provision/manage other clusters and deploy applications on them.

Use your preferred k8s 

For example on your laptop with minikube:

```sh
minikube start --kubernetes-version=v1.20.0 --addons=ingress
```

### install crossplane 1.0.0

```sh
kubectl create namespace crossplane-system
helm repo add crossplane-master https://charts.crossplane.io/master/
helm install crossplane --namespace crossplane-system crossplane-master/crossplane --version 1.0.0 
```

Check Crossplane is installed:
```sh
echo "Crossplane CRD..."
k api-resources --api-group=pkg.crossplane.io
echo ""
echo "Crossplane resources..."
k get all -n crossplane-system
```

Finally, we will instal the crossplane plugin for kubectl
```sh
curl -sL https://raw.githubusercontent.com/crossplane/crossplane/release-1.0/install.sh | sh
```

### Add AWS/GCP/Azure crossplane providers

We need to install a crossplane package for each provider. The list of available providers is [here](https://crossplane.io/docs/v1.0/api-docs/overview.html#api-documentation).

You will note that providers are released independently of the crossplane. In our case, we will install the AWS provider in version 0.16.0, the GCP provider in 0.14.0 and Azure in 0.14.0.

You can do that using a k8s resource file:
```sh
k apply -f providers/
````
**OR**
with the crossplane plugin:
```sh
k crossplane install provider crossplane/provider-aws:v0.16.0
kubectl crossplane install provider crossplane/provider-gcp:v0.14.0
kubectl crossplane install provider crossplane/provider-azure:v0.14.0
```

Ensure the providers are correctly installed.
View the new CRDs brought by each Crossplane provider.

### Configure the AWS provider

The only way to configure the AWS provider on Crossplane is to create k8s resources:
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

**CONGRATULATIONS, You are now ready to manage AWS resources with Crossplane!**

## Step 2 - Manage resources for a cloud provider

### VPC and RDS instance

Doc is [here](https://doc.crds.dev/github.com/crossplane/provider-aws/database.aws.crossplane.io/RDSInstance/v1beta1@v0.16.0)

```sh
k apply -f step2-rds/
```

Inspect the created resources:
```sh
kubectl describe vpc,subnet,rdsinstance
```

Note that each resource has `forProvider` (desired) at `status.atProvider` (current) attributes.

Questions:
* How are the subnets referenced by the DBSubnetGroup ?
* What are the other possibilities?
* Where is the stored the login/password of the RDSInstance `rdspostgresql`?

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
## Step 3 - Abstract cloud provider specifities

We will abstract the high number of parameters for an RDS instance.

### Create the CompositeResourceDefinition

```sh
kubectl apply -f step-3-composistion/resourcedefinition.yaml
kubectl get xrd
kubectl describe xrd #Ensure condition is Established
kubectl api-resources | grep postgresql # Is it cluster of namespace scoped ?
```

### Create a Composition to tell Crossplane what to do with this XRD

labels on composition !!!


* engine
* sizing: S, M, L
* purpose
  * dev: no HA, no backup
  <!-- * prod: HA, backup -->


## Step 4 - Compose an app

## Step 5 - 

## ArgoCD

```sh
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml


password=$(kubectl get pods -n argocd -l app.kubernetes.io/name=argocd-server -o name | cut -d'/' -f 2)
echo "Argo CD login/passwd: admin / ${password}"
kubectl port-forward svc/argocd-server -n argocd 8080:443
```