# Monday - setup and first commands

# Setup

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

## Add AWS crossplane provider

We need to install a crossplane package for each provider. The list of available providers is [here](https://crossplane.io/docs/v1.2/api-docs/overview.html#api-documentation).

You will note that providers are released independently of the crossplane. In our case, we will install the AWS provider in version 0.18.1.

You can do that using a k8s resource file:
```sh
kubectl apply -f providers/
```

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
kubectl apply -f providers/config/
```

**CONGRATULATIONS: you are now ready to manage AWS resources with Crossplane!**

You can run the [demo](./demo/README.md) or do the [hands-on](./handson/README.md)