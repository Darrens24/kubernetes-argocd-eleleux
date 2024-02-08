#!/bin/bash

# Install git, curl and vim
sudo apt update && sudo apt install -y git vim curl
# Add Docker's official GPG key:
sudo apt install -y ca-certificates 
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
# Install k3d
sudo curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

# Install kubectl for amd64, version k8s
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl

# Install Homebrew
echo | /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
(echo; echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"') >> /home/hdiot/.bashrc
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
# Start docker
sudo systemctl restart docker

# Create cluster
sudo k3d cluster create mycluster --port 8888:80@loadbalancer --kubeconfig-write-default
# Create namespaces
sudo kubectl create namespace argocd
sudo kubectl create namespace dev

# Install argocd in his namespace
sudo kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Install argocd client in the machine mdp:lunettes to store in env
brew install argocd
# Open the argocd-server ports and initialize password for admin
sudo kubectl port-forward svc/argocd-server -n argocd 8080:443 &

# cp et chown
sudo cp /root/.kube/config ~/.kube/config
sudo chown $USER:$USER ~/.kube/config

argocd admin initial-password -n argocd > initial-password.txt
# Change the argocd password for admin
argocd login 127.0.0.1:8080 --insecure --username admin --password $(head -n 1 initial-password.txt)
argocd account update-password --current-password $(head -n 1 initial-password.txt) --new-password lunettes
rm initial-password.txt
sudo kubectl apply -f wil-playground.yaml
# To use a specific cluster
# kubectl config use-context k3d-mycluster


