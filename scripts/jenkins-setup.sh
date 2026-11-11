#!/bin/bash
# jenkins-setup.sh
# Run this ONCE from a terminal with sudo to give Jenkins access to
# kubectl, docker, and minikube.
# Usage: sudo bash scripts/jenkins-setup.sh

set -e

echo "=== 1. Copy kubeconfig to Jenkins user ==="
mkdir -p /var/lib/jenkins/.kube
cp /home/user/.kube/config /var/lib/jenkins/.kube/config
chown -R jenkins:jenkins /var/lib/jenkins/.kube
chmod 600 /var/lib/jenkins/.kube/config
echo "kubeconfig copied"

echo "=== 2. Add jenkins to docker group ==="
usermod -aG docker jenkins
echo "jenkins added to docker group"

echo "=== 3. Copy minikube certs (needed for kubectl to reach the cluster) ==="
mkdir -p /var/lib/jenkins/.minikube
cp -r /home/user/.minikube/ca.crt /var/lib/jenkins/.minikube/ 2>/dev/null || true
cp -r /home/user/.minikube/profiles /var/lib/jenkins/.minikube/ 2>/dev/null || true
chown -R jenkins:jenkins /var/lib/jenkins/.minikube
echo "minikube certs copied"

echo "=== 4. Update kubeconfig cert paths for jenkins user ==="
sed -i 's|/home/user/.minikube|/var/lib/jenkins/.minikube|g' \
    /var/lib/jenkins/.kube/config
echo "cert paths updated"

echo "=== 5. Restart Jenkins to pick up group change ==="
systemctl restart jenkins
echo "Jenkins restarted"

echo ""
echo "=== Verify with: ==="
echo "  sudo -u jenkins kubectl get pods -A"
echo "  sudo -u jenkins docker ps"
