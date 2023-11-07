#!/bin/bash

# set colors for TUI
export NEWT_COLORS='
window=white,
border=black,
textbox=red,
button=black
'

# define package manager
 YUM_CMD=$(which yum)
 APT_GET_CMD=$(which apt-get)


# check if kustomize is installed
kustomize_installed_whereis=$(whereis kustomize)
kustomize_installed_which=$(which kustomize)

#echo "$kustomize_installed_whereis"
#echo "$kustomize_installed_which"

if [ -z "${kustomize_installed_which}" ] || [ -z "${kustomize_installed_whereis}" ] ; then
  echo "kustomize isn't installed with which"
  echo "Installing kustomize......"
  curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh"  | bash
  sudo mv ./kustomize /usr/local/bin/kustomize
fi

#Install jq and kustomize

tools=("jq" "whiptail")
# use package manager for
for val in "${tools[@]}" ; do 
 if [ -z $(which $val) ];
 then
  echo "installing $val"
  if [[ ! -z $YUM_CMD ]]; then
    yum -y install $val
  elif [[ ! -z $APT_GET_CMD ]]; then
    apt-get install $val
  else
    echo "error can't install package $PACKAGE , please make sure your package manager is listed in prerequisites.sh"
    exit 1;
  fi
 fi
 done
