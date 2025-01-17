#!/bin/bash

# Use kubeconfig
export KUBECONFIG="${HOME}/.kube/conf"

# Get kubernetes version
source ./utils/check_version.sh

source file.sh


mkdir -pv /tmp/argo-cd
git clone https://github.com/argoproj/argo-cd.git /tmp/argo-cd 

# Cluster Admin must install CRDs first 
# Install appproject CRD
kubectl apply --filename=https://github.com/argoproj/argo-cd/blob/master/manifests/crds/appproject-crd.yaml?raw=true 

# Install application CRD
kubectl apply --filename=https://github.com/argoproj/argo-cd/blob/master/manifests/crds/application-crd.yaml?raw=true 

# Install AppSet CRD
kubectl apply --filename=https://github.com/argoproj/argo-cd/blob/master/manifests/crds/applicationset-crd.yaml?raw=true 


# Take user input for main namespace
#read -p "Enter ArgoCD installation namespace: " main_namespace
# Take user input for targeted namespaces
#read -p "Enter ArgoCD targeted namespaces spereated with commas: "     target_namespaces
# Main namespace is where argocd will be deployed

## Main Namespace setup ##

# Create argocd manager service account in main namespace 
kubectl create serviceaccount argocd-manager --namespace=$main_namespace 

# Create argocd manager role in main namespace
kubectl apply --filename manifests/argocd-manager-role.yaml --namespace=$main_namespace 

# Create argocd manager role binding in main namespace
kubectl create rolebinding argocd-manager-role-binding \
--namespace $main_namespace \
--role argocd-manager-role \
--serviceaccount=$main_namespace:argocd-manager 

if [ $create_serviceaccount_secret == "true" ]; then
  echo "Detected K8S version that's greater to or equal 1.24"
  kubectl apply --filename manifests/argocd-manager-sa-secret.yaml --namespace=$main_namespace
  export argocd_manager_token=$(kubectl get secret argocd-manager --output=json --namespace=$main_namespace | jq --raw-output .data.token | base64 --decode)

else
  echo "Detected K8S version below 1.24"
  export argocd_manager_sa_secret=$(kubectl get serviceaccount argocd-manager --output=json --namespace=$main_namespace | jq --raw-output .secrets[].name)
  export argocd_manager_token=$(kubectl get secret $argocd_manager_sa_secret --output=json --namespace=$main_namespace | jq --raw-output .data.token | base64 --decode)
fi

# Create argocd-managed secret
kubectl  delete secret cluster-kubernetes.default.svc-argocd-managed --ignore-not-found --namespace=$main_namespace 

kubectl  create secret generic cluster-kubernetes.default.svc-argocd-managed \
--namespace=$main_namespace \
--from-literal=config="{\"bearerToken\":\"$argocd_manager_token\",\"tlsClientConfig\":{\"insecure\":true}}" \
--from-literal=name=argocd-managed \
--from-literal=namespaces=$target_namespaces \
--from-literal=server=https://kubernetes.default.svc 

# Label cluster-secret
kubectl label secret cluster-kubernetes.default.svc-argocd-managed \
--namespace=$main_namespace \
--overwrite \
argocd.argoproj.io/secret-type=cluster 

# Annotate cluster-secret
kubectl annotate secret cluster-kubernetes.default.svc-argocd-managed \
--namespace=$main_namespace \
--overwrite \
managed-by=argocd.argoproj.io 

## Target Namespace setup ##
# Create argocd manager role and rolebinding on all target namespaces
# https://stackoverflow.com/a/35894538
for namespace in ${target_namespaces//,/ }
do
  kubectl apply --namespace $namespace \
  --filename manifests/argocd-manager-role.yaml 

  kubectl create rolebinding argocd-manager-role-binding \
  --namespace $namespace \
  --role argocd-manager-role \
  --serviceaccount=$main_namespace:argocd-manager 
done

# Create required service accounts, services and roles
kustomize build /tmp/argo-cd/manifests/base | kubectl apply --namespace=$main_namespace --filename -   

# Replace argocd-cm 
kubectl apply --filename manifests/argocd-cm.yaml --namespace=$main_namespace 
