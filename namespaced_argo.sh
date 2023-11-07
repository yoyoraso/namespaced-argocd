#!/bin/bash
# Install PreRequisites
source ./utils/prerequisites.sh


if whiptail  --msgbox "Hi, Welcome to ArgoCD install program!\n\nPress OK to proceed or Esc to exit." 10 80 ; then

 export M_NS=$(whiptail --inputbox "Enter the Namespace where ArgoCD will be  installed" 10 40 3>&1 1>&2 2>&3)

 export T_NS=$(whiptail --inputbox "Enter the Namespaces which ArgoCD will manage separated by commas" 10 40 3>&1 1>&2 2>&3)

 echo "export main_namespace=$M_NS" > ./file.sh
 echo "export target_namespaces=$T_NS" >> ./file.sh

 COUNTER=0
 bash ./argocd.sh  >/dev/null 2>&1 &
 
 
 while [ -n "$(ps aux | grep -v 'grep' | grep argocd.sh)" ]; do
  sleep 4.8
  COUNTER=$(($COUNTER+10))
  if [[ -z "$(ps aux | grep -v 'grep' | grep argocd.sh)" ]];then
        COUNTER=100
        echo ${COUNTER}
        break;
  fi
  echo ${COUNTER}
 done | whiptail --gauge 'Installing ArgoCD...' 6 60 0

else
  TERM=ansi
  whiptail --infobox "Cancelling the process" 10 40
fi
