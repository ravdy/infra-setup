#!/usr/bin/env bash
###
# This file's name is a working title for now...
### TODO:
### check out ../ansible/controls/roles/ansible-runner and add things if needed?
### I think this tf install is done?? needs testing


_runasroot () {
    # TODO: 
    # modify this section so that it does more than check for root...
    # needs proper user/group checks, OS type check (ubuntu latest LTS only)
    # and other pre-reqs as they come up
    if [[ $EUID -ne 0 ]]; then
    echo "This utility must be run as root... Exiting!" 
    exit 1
    fi
    
}

_install-kubernetes () {
    k8ver="v1.27.1"
    curl -LO https://dl.k8s.io/release/${k8ver}/bin/linux/amd64/kubectl
    curl -LO https://dl.k8s.io/${k8ver}/bin/linux/amd64/kubectl.sha256
    checksum=$(echo "`<kubectl.sha256`" )
    if ! echo "${checksum} kubectl" | sha256sum -c -; then
        echo "Checksum failed, exiting!" >&2
        exit 1
    else
        echo "Checksum passed, continuing!"
    fi 
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    kubectl version --client
}

_install-helm () {
    # Note: "usually up to date" according to https://helm.sh/docs/intro/install/
    curl https://baltocdn.com/helm/signing.asc | gpg --dearmor |  tee /usr/share/keyrings/helm.gpg > /dev/null
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" |  tee /etc/apt/sources.list.d/helm-stable-debian.list
    apt update
    apt install helm

}

_install_terraform() {
  tfver="1.3.4"  # Change this for terraform version
  curl \
    --fail \
    --silent \
    --show-error \
    --location \
    "https://releases.hashicorp.com/terraform/${tfver}/terraform_${tfver}_linux_amd64.zip" \
    --output "/home/ubuntu/terraform_${tfver}_linux_amd64.zip"

  cd /home/ubuntu
    unzip "/home/ubuntu/terraform_${tfver}_linux_amd64.zip"
    chmod a+x terraform
    mv terraform /usr/local/bin
  cd
}
## NOTES: alternative, repo-based install of TF. Need to explore more.
## TODO: Add Terraform Version Control Variables
## Note: Do we even need to handle version control for TF?
#_install-terraform () {
#    wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
#    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list
#    apt update 
#    apt install terraform
#}

_dependency-install () {
    # ensure base system is "common" among all environments with basic utilites.
    apt install \
    ca-certificates \
    lsb-release \
    curl \
    wget \
    gnupg \
    apt-transport-https \
    curl \
    unzip \
    zip \
    jq \
    git \
    awscli
}


_java-runner () {
    # install java dependencies
    # TODO: needs testing, verification, and understanding of the "build/deploy" process for IAM environment.
    ### Investigate if this is a holdover from other repos.
    apt install openjdk-17-jdk-headless maven kotlin
}


_install-gitlab-runner () {
    # needs more work, i'm certain i'm missing a few key steps for gitlab runner creation here...
    curl -L "https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh" | bash
    apt install gitlab-runner
}


_upgrade-gitlab-runner () {
    # things need updating sometimes, 
    # TODO: add version control for gitlab runner here. 
    apt update
    apt install gitlab-runner
}


_install-docker-enginer () {
    # install docker engine and docker-compose v2 

    mkdir -m 0755 -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt update
    apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    curl -SL https://github.com/docker/compose/releases/download/v2.16.0/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose
    ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
}


_install-nodejs () {
    # Using NVM to install Node which allows version control and picking of node versions with it's utilities, as well as selection of builds of NodeJS
    # Currently going to be defaulting to latest LTS release: More info here: https://github.com/nvm-sh/nvm#long-term-support
    # TODO: Add Version Control from CICD Variables.
    #       Fix $NODE_VERSION in echo statement.
    #       Change if-else statement so that it re-sources shell profile to acquire nvm, and continue.
    #       Figure out how to install this without versioning... Might be an upstream issue, we need to keep an eye on this in the future. 
    #
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash
    
    # `command -v` rather than `which nvm` to verify that nvm has been found so we can continue NodeJS installation.
    if command -v nvm; then
        echo "nvm binary found! Continuing..."
        nvm install --lts
    else
        echo "nvm binary not found! Please re-source your configuration and try again..."
        exit 1
    fi

    # verifying NodeJS installation and logging it. 
    if command -v node --version; then
        echo "NodeJS Installed Successfully! Installed Version is: \$NODE_VERSION"
    else  
        echo "NodeJS Not Found... Check for errors and try again!"
        exit 1
    fi
}


### TODO: Finish Help File
show_help () {
    cat << EOF 
Help text here. This script should be sourced and run as root user. Insert Lorum Ipsum Filler Text Here

EOF
}


show_help
