#!/usr/bin/env bash

##  Variables
LOCAL_BIN="${HOME}/.local/bin"
PATH="$PATH:$HOME/.krew/bin:$LOCAL_BIN"

##  Color config
RED="\e[91m"
GREEN="\e[92m"
YELLOW="\e[93m"
BLUE="\e[94m"
BOLD="\e[1m"
ENDCOLOR="\e[0m"

## Global Vars

PROGRAM_NAME=''
PROGRAM_BIN=''
REMOTE_VERSION=''
LOCAL_VERSION=''
EXTRACT_CMD=''

##  Associative Arrays

declare -A name_array
name_array[oc]=oc
name_array[helm]=Helm
name_array[krew]=Krew
name_array[tekton]=Tekton
name_array[kustomize]=Kustomize
name_array[knative]=knative
name_array[argocd]=ArgoCD

declare -A bin_array
bin_array[oc]=oc
bin_array[helm]=helm
bin_array[krew]=kubectl-krew
bin_array[tekton]=tkn
bin_array[kustomize]=kustomize
bin_array[knative]=kn
bin_array[argocd]=argocd

declare -A remote_array
remote_array[oc]="curl -s https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/release.txt | awk '/Version:/ { print \$NF }'"
remote_array[helm]="curl -s https://github.com/helm/helm/releases/latest | sed -E -n 's/.*tag\/(v[0-9\.]+).*/\1/p'"
remote_array[krew]="curl -s https://github.com/kubernetes-sigs/krew/releases/latest | sed -E -n 's/.*tag\/(v[0-9\.]+).*/\1/p'"
remote_array[tekton]="curl -s https://github.com/tektoncd/cli/releases/latest | sed -E -n 's/.*tag\/v([0-9\.]+).*/\1/p'"
remote_array[kustomize]="curl -s https://github.com/kubernetes-sigs/kustomize/releases/latest | sed -E -n 's/.*kustomize\/(v[0-9\.]+).*/\1/p'"
remote_array[knative]="curl -s https://github.com/knative/client/releases/latest | sed -E -n 's/.*knative-(v[0-9\.]+).*/\1/p'"
remote_array[argocd]="curl -s https://github.com/argoproj/argo-cd/releases/latest | sed -E -n 's/.*tag\/(v[0-9\.]+).*/\1/p'"

declare -A local_array
local_array[oc]="oc version | awk '/Version/ { print \$NF }'"
local_array[helm]="helm version | sed -E -n 's/.*Version:.(v[0-9\.]+)..*/\1/p'"
local_array[krew]="kubectl-krew version | awk '/GitTag/ { print \$NF }'"
local_array[tekton]="tkn version | awk '/version/ { print \$NF }'"
local_array[kustomize]="kustomize version | sed -E -n 's/.*kustomize\/(v[0-9\.]+)\s.*/\1/p'"
local_array[knative]="kn version | awk '/Version/ { print \$NF }'"
local_array[argocd]="argocd version 2>/dev/null| sed -E -n 's/argocd:\s+(v[0-9\.]+).*/\1/p'"

declare -A extract_array
extract_array[oc]="curl -sL https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/openshift-client-linux.tar.gz | tar -C $LOCAL_BIN -xz oc kubectl"
extract_array[helm]="curl -sL https://get.helm.sh/helm-REMOTE_VERSION-linux-amd64.tar.gz | tar -C $LOCAL_BIN --strip-components=1 -xz linux-amd64/helm"
extract_array[krew]="curl -sL https://github.com/kubernetes-sigs/krew/releases/latest/download/krew-linux_amd64.tar.gz | tar -C $LOCAL_BIN -xz ./krew-linux_amd64"
extract_array[tekton]="curl -sL https://github.com/tektoncd/cli/releases/download/vREMOTE_VERSION/tkn_REMOTE_VERSION_Linux_x86_64.tar.gz | tar -C $LOCAL_BIN -xz tkn"
extract_array[kustomize]="curl -sL https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize/REMOTE_VERSION/kustomize_REMOTE_VERSION_linux_amd64.tar.gz | tar -C $LOCAL_BIN -xz kustomize"
extract_array[knative]="curl -sL https://github.com/knative/client/releases/latest/download/kn-linux-amd64 -o ${LOCAL_BIN}/kn ; chmod +x ${LOCAL_BIN}/kn"
extract_array[argocd]="curl -sL https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64 -o ${LOCAL_BIN}/argocd ; chmod +x ${LOCAL_BIN}/argocd"

##  Array with list of tools

tools=(
oc
helm
krew
tekton
kustomize
knative
argocd
)

##  Functions

function deploy {

  local remoteVersion=''
  local localVersion=''

  echo -e "${BOLD}${BLUE}Processing $PROGRAM_NAME${ENDCOLOR}"
  echo -e "- Validating if $PROGRAM_NAME is already installed"
  remoteVersion=$( echo $REMOTE_VERSION | sh )
  if which $PROGRAM_BIN &>/dev/null
    then
    localVersion=$( echo "$LOCAL_VERSION" | sh )
    if [ "$localVersion" == "$remoteVersion" ]
    then
      echo -e "- ${YELLOW}$PROGRAM_BIN found with latest version ${localVersion}${ENDCOLOR}"
      return
    else
      echo "- $PROGRAMB_BIN found with an older version $localVersion"
    fi
  else
    echo "- $PROGRAM_BIN was not found"
  fi

  echo -e "- Installing ${PROGRAM_BIN} ${remoteVersion}"
  if echo $EXTRACT_CMD | sed "s/REMOTE_VERSION/${remoteVersion}/g" | sh
  then
    echo -e "- ${GREEN}$PROGRAM_BIN $remoteVersion installed successfully${ENDCOLOR}"
    return
  else
    echo -e "- ${RED}Unable to extract $PROGRAM_BIN from the remote tarball${ENDCOLOR}"
  fi

}

echo -e "\n${BOLD}Deploying utilities for OpenShift${ENDCOLOR}\n"

for tool in ${tools[@]}
do
  PROGRAM_NAME=${name_array[$tool]}
  PROGRAM_BIN=${bin_array[$tool]}
  REMOTE_VERSION=${remote_array[$tool]}
  LOCAL_VERSION=${local_array[$tool]}
  EXTRACT_CMD=${extract_array[$tool]}
  deploy
  if [ "$tool" == "krew" ]
  then
    krew-linux_amd64 install krew &>/dev/null
    oc krew install neat &>/dev/null
  fi
  echo
done

exit
