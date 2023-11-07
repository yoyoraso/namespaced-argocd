#!/bin/bash

# Script that checks kubernetes cluster version in order to handle service account secret creation
# Before V1.24 the secret was automatically created, after that version the secret must be manually created
create_serviceaccount_secret=false

# Check kubernetes version on the server 
kube_major_version=$(kubectl version -ojson | jq .serverVersion.major | tr -d '"')
kube_minor_version=$(kubectl version -ojson | jq .serverVersion.minor | tr -d '"')
kube_version=$kube_major_version.$kube_minor_version

check_against_kube_version="1.24"

 # bc will output 1 in case kube_version was greater than 1.24 and if that's the case then service account secret will be created with kubectl
 if (( $(echo "$kube_version >= $check_against_kube_version" | bc -l) )); then
  create_serviceaccount_secret=true
  echo "Service account secret will be created"
fi
