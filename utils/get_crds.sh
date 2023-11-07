# Check if argo CRDs are already installed

argo_crds=$(kubectl api-resources --api-group=argoproj.io --output name)

check_crd(){
  name=$1
  url=$2
  # If the name was found it returns the wc which will be either 1 or more if any matches were found
  crd_exists=$(echo ${argo_crds[@]} | grep -o "$name.argoproj.io" | wc -w)
  # If more than 1 match exists then the CRD is considered installed
  if [ $crd_exists -ne 0 ]; then
    echo "$name CRD is installed"
  else 
    echo "Please reach cluster admin for installing $name CRD\n$url"
  fi
}

check_crd "applicationsets" "https://raw.githubusercontent.com/argoproj/argo-cd/master/manifests/crds/applicationset-crd.yaml"
check_crd "applications" "https://raw.githubusercontent.com/argoproj/argo-cd/master/manifests/crds/application-crd.yaml"
check_crd "appprojects" "https://raw.githubusercontent.com/argoproj/argo-cd/master/manifests/crds/appproject-crd.yaml"
