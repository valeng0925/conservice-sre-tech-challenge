#!/bin/bash
# User data script for EKS worker nodes

# Set cluster name
CLUSTER_NAME="${cluster_name}"

# Install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

# Install Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Install Docker (for container runtime)
sudo yum update -y
sudo yum install -y docker
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -a -G docker ec2-user

# Configure Docker to use systemd cgroup driver
sudo mkdir -p /etc/docker
cat <<EOF | sudo tee /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF

# Restart Docker
sudo systemctl restart docker

# Install additional monitoring tools
sudo yum install -y htop iotop nethogs

# Set up log rotation for container logs
sudo mkdir -p /etc/logrotate.d
cat <<EOF | sudo tee /etc/logrotate.d/docker-containers
/var/lib/docker/containers/*/*.log {
  rotate 7
  daily
  compress
  size=1M
  missingok
  delaycompress
  copytruncate
}
EOF

# Configure system limits
echo "* soft nofile 65536" | sudo tee -a /etc/security/limits.conf
echo "* hard nofile 65536" | sudo tee -a /etc/security/limits.conf
echo "* soft nproc 65536" | sudo tee -a /etc/security/limits.conf
echo "* hard nproc 65536" | sudo tee -a /etc/security/limits.conf

# Set up monitoring for node health
cat <<EOF | sudo tee /usr/local/bin/node-health-check.sh
#!/bin/bash
# Simple node health check script

# Check disk space
DISK_USAGE=\$(df / | awk 'NR==2 {print \$5}' | sed 's/%//')
if [ \$DISK_USAGE -gt 80 ]; then
    echo "WARNING: Disk usage is \${DISK_USAGE}%"
fi

# Check memory usage
MEM_USAGE=\$(free | awk 'NR==2{printf "%.0f", \$3*100/\$2}')
if [ \$MEM_USAGE -gt 90 ]; then
    echo "WARNING: Memory usage is \${MEM_USAGE}%"
fi

# Check Docker daemon
if ! systemctl is-active --quiet docker; then
    echo "ERROR: Docker daemon is not running"
    exit 1
fi

echo "Node health check passed"
EOF

sudo chmod +x /usr/local/bin/node-health-check.sh

# Set up cron job for health checks
echo "*/5 * * * * /usr/local/bin/node-health-check.sh" | sudo crontab -

# Log the completion
echo "EKS node initialization completed at \$(date)" >> /var/log/eks-init.log
