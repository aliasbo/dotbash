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
INSTALL_CMD=''

##  Associative Arrays
# declare the name of the application
declare -A app_names
app_names[oc]=oc
app_names[helm]=Helm
app_names[krew]=Krew
app_names[tekton]=Tekton
app_names[kustomize]=Kustomize
app_names[knative]=knative
app_names[argocd]=ArgoCD
app_names[az]=AzureCLI
app_names[roxctl]=ACScli

# declare the binary of the application
declare -A app_binaries
app_binaries[oc]=oc
app_binaries[helm]=helm
app_binaries[krew]=kubectl-krew
app_binaries[tekton]=tkn
app_binaries[kustomize]=kustomize
app_binaries[knative]=kn
app_binaries[argocd]=argocd
app_binaries[roxctl]=roxctl

# declare the method to get the latest release of the application
declare -A remote_versions
remote_versions[oc]="curl -s https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/release.txt | awk '/Version:/ { print \$NF }'"
remote_versions[helm]="curl -sL https://github.com/helm/helm/releases/latest | sed -E -n 's/.*tag\/(v[0-9\.]+).*/\1/p' | tail -n1"
remote_versions[krew]="curl -s https://github.com/kubernetes-sigs/krew/releases/latest | sed -E -n 's/.*tag\/(v[0-9\.]+).*/\1/p'"
remote_versions[tekton]="curl -sL https://github.com/tektoncd/cli/releases/latest | sed -E -n 's/.*tag\/v([0-9\.]+).*/\1/p' | tail -n1"
remote_versions[kustomize]="curl -s https://api.github.com/repos/kubernetes-sigs/kustomize/releases | grep browser_download.*linux_amd64 | cut -d '\"' -f 4 | sort -V | tail -n 1 | sed -E -n 's/.*kustomize\/(v[0-9\.]+).*/\1/p'"
remote_versions[knative]="curl -s https://github.com/knative/client/releases/latest | sed -E -n 's/.*knative-(v[0-9\.]+).*/\1/p'"
remote_versions[argocd]="curl -s https://github.com/argoproj/argo-cd/releases/latest | sed -E -n 's/.*tag\/(v[0-9\.]+).*/\1/p'"
remote_versions[roxctl]="curl -s  https://mirror.openshift.com/pub/rhacs/assets/latest/bin/Linux/sha256sum.txt | cut -d' ' -f1"

# declare the method to get the current version of the application
declare -A local_versions
local_versions[oc]="oc version | awk '/Version/ { print \$NF }'"
local_versions[helm]="helm version | sed -E -n 's/.*Version:.(v[0-9\.]+)..*/\1/p'"
local_versions[krew]="kubectl-krew version | awk '/GitTag/ { print \$NF }'"
local_versions[tekton]="tkn version | awk '/version/ { print \$NF }'"
local_versions[kustomize]="kustomize version | sed -E -n 's/.*kustomize\/(v[0-9\.]+)\s.*/\1/p'"
local_versions[knative]="kn version | awk '/Version/ { print \$NF }'"
local_versions[argocd]="argocd version 2>/dev/null| sed -E -n 's/argocd:\s+(v[0-9\.]+).*/\1/p'"
local_versions[roxctl]="which roxctl &>/dev/null && sha256sum $(which roxctl) | cut -d' ' -f1"

# declare the method to install the application
declare -A install_methods
install_methods[oc]="curl -sL https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/openshift-client-linux.tar.gz | tar -C $LOCAL_BIN -xz oc kubectl"
install_methods[helm]="curl -sL https://get.helm.sh/helm-REMOTE_VERSION-linux-amd64.tar.gz | tar -C $LOCAL_BIN --strip-components=1 -xz linux-amd64/helm"
install_methods[krew]="curl -sL https://github.com/kubernetes-sigs/krew/releases/latest/download/krew-linux_amd64.tar.gz | tar -C $LOCAL_BIN -xz ./krew-linux_amd64"
install_methods[tekton]="curl -sL https://github.com/tektoncd/cli/releases/download/vREMOTE_VERSION/tkn_REMOTE_VERSION_Linux_x86_64.tar.gz | tar -C $LOCAL_BIN -xz tkn"
install_methods[kustomize]="curl -sL https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize/REMOTE_VERSION/kustomize_REMOTE_VERSION_linux_amd64.tar.gz | tar -C $LOCAL_BIN -xz kustomize"
install_methods[knative]="curl -sL https://github.com/knative/client/releases/latest/download/kn-linux-amd64 -o ${LOCAL_BIN}/kn ; chmod +x ${LOCAL_BIN}/kn"
install_methods[argocd]="curl -sL https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64 -o ${LOCAL_BIN}/argocd ; chmod +x ${LOCAL_BIN}/argocd"
install_methods[roxctl]="curl -sL https://mirror.openshift.com/pub/rhacs/assets/latest/bin/Linux/roxctl -o ${LOCAL_BIN}/roxctl ; chmod +x ${LOCAL_BIN}/roxctl"


##  Array with the list of tools to install
tools=(
oc
helm
krew
tekton
kustomize
knative
argocd
roxctl
)

##  Array with the list of krew plugins to install
krew_plugins=(
example
explore
eksporter
get-all
htpasswd
lineage
mc
neat
np-viewer
pod-inspect
pod-lens
podevents
score
topology
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
  if echo $INSTALL_CMD | sed "s/REMOTE_VERSION/${remoteVersion}/g" | sh
  then
    echo -e "- ${GREEN}$PROGRAM_BIN $remoteVersion installed successfully${ENDCOLOR}"
    return
  else
    echo -e "- ${RED}Unable to extract $PROGRAM_BIN from the remote tarball${ENDCOLOR}"
  fi

}

echo -e "\n${BOLD}Deploying utilities for OpenShift${ENDCOLOR}\n"

mkdir -p ${HOME}/.local/bin

for tool in ${tools[@]}
do
  PROGRAM_NAME=${app_names[$tool]}
  PROGRAM_BIN=${app_binaries[$tool]}
  REMOTE_VERSION=${remote_versions[$tool]}
  LOCAL_VERSION=${local_versions[$tool]}
  INSTALL_CMD=${install_methods[$tool]}
  deploy
  if [ "$tool" == "krew" ]
  then
    echo -e "- Running krew install krew"
    krew-linux_amd64 install krew &>/dev/null
    for plugin in ${krew_plugins[@]}
    do
      echo -e "- Installing krew plugin $plugin"
      oc krew install $plugin &>/dev/null
    done
  fi
  echo
done

exit
