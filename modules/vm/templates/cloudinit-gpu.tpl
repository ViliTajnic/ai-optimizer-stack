#cloud-config
# Copyright (c) 2024, 2025, Oracle and/or its affiliates.
# All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl
# spell-checker: disable

users:
  - default
  - name: oracleai
    uid: 10001
    shell: /bin/bash
    homedir: /app

package_update: true
packages:
  - python36-oci-cli
  - python3.11
  - python3.11-devel
  - kernel-devel
  - kernel-headers
  - gcc
  - make
  - dkms
  - epel-release
  - wget
  - curl
  - unzip
  - git

write_files:
  - path: /etc/systemd/system/ai-optimizer.service
    permissions: '0644'
    content: |
      [Unit]
      Description=AI Optimizer Service
      After=network.target nvidia-persistenced.service ollama.service
      Wants=nvidia-persistenced.service ollama.service

      [Service]
      Type=simple
      ExecStart=/bin/bash /app/start.sh
      User=oracleai
      Group=oracleai
      WorkingDirectory=/app
      Environment="HOME=/app"
      Environment="CUDA_VISIBLE_DEVICES=0"
      Environment="NVIDIA_VISIBLE_DEVICES=0"
      Environment="LD_LIBRARY_PATH=/usr/local/cuda/lib64:/usr/lib64"
      Environment="PATH=/usr/local/cuda/bin:/usr/local/bin:/usr/bin:/bin"
      Environment="PYTHONPATH=/app"
      Restart=on-failure
      RestartSec=30
      TimeoutStartSec=300

      [Install]
      WantedBy=multi-user.target

  - path: /tmp/install_nvidia.sh
    permissions: '0755'
    content: |
      #!/bin/bash
      set -e
      
      echo "[$(date)] Starting NVIDIA driver installation..."
      
      # Remove any existing NVIDIA packages
      dnf remove -y nvidia* || true
      
      # Install EPEL and PowerTools
      dnf install -y epel-release
      dnf config-manager --set-enabled powertools || dnf config-manager --set-enabled crb || true
      
      # Add NVIDIA repository
      dnf config-manager --add-repo https://developer.download.nvidia.com/compute/cuda/repos/rhel8/x86_64/cuda-rhel8.repo
      dnf clean all
      
      # Install kernel development packages
      dnf install -y kernel-devel-$(uname -r) kernel-headers-$(uname -r) gcc make dkms
      
      # Install NVIDIA drivers and CUDA
      dnf module install -y nvidia-driver:latest-dkms
      dnf install -y cuda-toolkit-12-4 nvidia-gds
      
      # Install additional NVIDIA tools
      dnf install -y nvidia-container-toolkit
      
      # Set up NVIDIA persistence daemon
      systemctl enable nvidia-persistenced
      
      echo "[$(date)] NVIDIA installation completed"

  - path: /tmp/setup_environment.sh
    permissions: '0755'
    content: |
      #!/bin/bash
      set -e
      
      echo "[$(date)] Setting up system environment..."
      
      # Create app directory
      mkdir -p /app
      chown oracleai:oracleai /app
      
      # Configure CUDA environment
      cat >> /etc/environment << 'EOF'
      CUDA_HOME=/usr/local/cuda
      PATH=/usr/local/cuda/bin:/usr/local/bin:/usr/bin:/bin
      LD_LIBRARY_PATH=/usr/local/cuda/lib64:/usr/lib64
      NVIDIA_VISIBLE_DEVICES=0
      CUDA_VISIBLE_DEVICES=0
      EOF
      
      # Create CUDA symlinks if needed
      if [ ! -L /usr/local/cuda ]; then
        ln -sf /usr/local/cuda-12.4 /usr/local/cuda
      fi
      
      # Configure firewall
      systemctl stop firewalld.service
      firewall-offline-cmd --zone=public --add-port=8501/tcp
      firewall-offline-cmd --zone=public --add-port=8000/tcp
      firewall-offline-cmd --zone=public --add-port=11434/tcp
      systemctl start firewalld.service
      
      echo "[$(date)] Environment setup completed"

  - path: /tmp/install_ollama.sh
    permissions: '0755'
    content: |
      #!/bin/bash
      set -e
      
      echo "[$(date)] Installing Ollama..."
      
      # Install Ollama
      curl -fsSL https://ollama.com/install.sh | sh
      
      # Create Ollama service override directory
      mkdir -p /etc/systemd/system/ollama.service.d
      
      # Configure Ollama for GPU usage
      cat > /etc/systemd/system/ollama.service.d/gpu.conf << 'EOF'
      [Service]
      Environment="CUDA_VISIBLE_DEVICES=0"
      Environment="OLLAMA_GPU_LAYERS=999"
      Environment="OLLAMA_HOST=0.0.0.0:11434"
      EOF
      
      # Enable and start Ollama
      systemctl daemon-reload
      systemctl enable ollama
      systemctl start ollama
      
      echo "[$(date)] Ollama installation completed"

  - path: /tmp/setup_python_env.sh
    permissions: '0755'
    content: |
      #!/bin/bash
      set -e
      
      # Set environment variables
      export OCI_CLI_AUTH=instance_principal
      export CUDA_VISIBLE_DEVICES=0
      export PATH=/usr/local/cuda/bin:$PATH
      export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH
      export CUDA_HOME=/usr/local/cuda
      
      echo "[$(date)] Setting up AI Optimizer..."
      
      # Download AI Optimizer source
      echo "[$(date)] Downloading source code..."
      curl -s https://api.github.com/repos/oracle-samples/ai-optimizer/releases/latest | grep tarball_url | cut -d '"' -f 4 | xargs curl -L -o /tmp/ai-optimizer-source.tar.gz
      
      # Extract source to app directory
      cd /app
      tar zxf /tmp/ai-optimizer-source.tar.gz --strip-components=2 '*/src'
      
      # Create Python virtual environment
      echo "[$(date)] Creating Python virtual environment..."
      python3.11 -m venv .venv
      source .venv/bin/activate
      
      # Upgrade pip and install build tools
      pip install --upgrade pip wheel setuptools
      
      # Install PyTorch with CUDA support
      echo "[$(date)] Installing PyTorch with CUDA support..."
      pip install torch==2.4.0+cu121 torchaudio==2.4.0+cu121 torchvision==0.19.0+cu121 --index-url https://download.pytorch.org/whl/cu121
      
      # Install additional GPU packages
      echo "[$(date)] Installing GPU-accelerated packages..."
      pip install cupy-cuda12x nvidia-ml-py transformers[torch] sentence-transformers accelerate bitsandbytes
      
      # Install AI Optimizer dependencies
      echo "[$(date)] Installing AI Optimizer..."
      pip install -e ".[all]" --quiet
      
      echo "[$(date)] Python environment setup completed"

  - path: /tmp/setup_database.sh
    permissions: '0755'
    content: |
      #!/bin/bash
      set -e
      
      export OCI_CLI_AUTH=instance_principal
      
      echo "[$(date)] Setting up database connection..."
      
      # Wait for database to be available
      timeout=900
      elapsed=0
      while [ $elapsed -lt $timeout ]; do
        echo "[$(date)] Waiting for database ${db_name}... ($elapsed seconds)"
        
        DB_ID=$(oci db autonomous-database list --compartment-id ${compartment_id} --display-name ${db_name} --lifecycle-state AVAILABLE --query 'data[0].id' --raw-output 2>/dev/null || echo "")
        
        if [ -n "$DB_ID" ] && [ "$DB_ID" != "null" ]; then
          echo "[$(date)] Database found. Downloading wallet..."
          oci db autonomous-database generate-wallet --autonomous-database-id "$DB_ID" --password '${db_password}' --file /tmp/wallet.zip
          
          # Extract wallet
          mkdir -p /app/tns_admin
          unzip -o /tmp/wallet.zip -d /app/tns_admin
          chown -R oracleai:oracleai /app/tns_admin
          
          echo "[$(date)] Database wallet configured successfully"
          return 0
        fi
        
        sleep 15
        elapsed=$((elapsed + 15))
      done
      
      echo "[$(date)] Warning: Database setup timed out after $timeout seconds"

  - path: /tmp/install_models.sh
    permissions: '0755'
    content: |
      #!/bin/bash
      set -e
      
      export CUDA_VISIBLE_DEVICES=0
      export OLLAMA_GPU_LAYERS=999
      
      echo "[$(date)] Installing AI models..."
      
      # Wait for Ollama to be ready
      timeout=300
      elapsed=0
      while [ $elapsed -lt $timeout ]; do
        if curl -s http://127.0.0.1:11434/api/version >/dev/null 2>&1; then
          echo "[$(date)] Ollama is ready"
          break
        fi
        echo "[$(date)] Waiting for Ollama to start... ($elapsed seconds)"
        sleep 10
        elapsed=$((elapsed + 10))
      done
      
      if [ $elapsed -ge $timeout ]; then
        echo "[$(date)] Warning: Ollama did not start within timeout"
        return 1
      fi
      
      # Install models
      echo "[$(date)] Pulling llama3.1 model..."
      ollama pull llama3.1
      
      echo "[$(date)] Pulling mxbai-embed-large model..."
      ollama pull mxbai-embed-large
      
      echo "[$(date)] Model installation completed"

  - path: /app/start.sh
    permissions: '0750'
    content: |
      #!/bin/bash
      set -e
      
      # Environment setup
      export OCI_CLI_AUTH=instance_principal
      export DB_USERNAME='ADMIN'
      export DB_PASSWORD='${db_password}'
      export DB_DSN='${db_name}_TP'
      export DB_WALLET_PASSWORD='${db_password}'
      export ON_PREM_OLLAMA_URL=http://127.0.0.1:11434
      export CUDA_VISIBLE_DEVICES=0
      export NVIDIA_VISIBLE_DEVICES=0
      export PATH=/usr/local/cuda/bin:$PATH
      export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH
      export CUDA_HOME=/usr/local/cuda
      export OLLAMA_GPU_LAYERS=999
      export TNS_ADMIN=/app/tns_admin
      
      echo "[$(date)] Starting AI Optimizer..."
      
      # Clean Python cache
      find /app -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
      find /app -type d -name ".numba_cache" -exec rm -rf {} + 2>/dev/null || true
      find /app -name "*.nbc" -delete 2>/dev/null || true
      
      # Activate virtual environment
      cd /app
      source .venv/bin/activate
      
      # Verify GPU availability
      echo "[$(date)] Verifying GPU setup..."
      python -c "import torch; print(f'CUDA available: {torch.cuda.is_available()}'); print(f'Device count: {torch.cuda.device_count()}')" || echo "Warning: GPU verification failed"
      
      # Ensure Ollama is running
      if ! curl -s http://127.0.0.1:11434/api/version >/dev/null 2>&1; then
        echo "[$(date)] Starting Ollama service..."
        sudo systemctl start ollama
        sleep 15
      fi
      
      # Start Streamlit
      echo "[$(date)] Starting Streamlit application..."
      exec streamlit run launch_client.py --server.port 8501 --server.address 0.0.0.0

runcmd:
  - echo "[$(date)] Cloud-init execution started" >> /var/log/cloud-init-custom.log
  - /tmp/install_nvidia.sh 2>&1 | tee -a /var/log/nvidia-install.log
  - /tmp/setup_environment.sh 2>&1 | tee -a /var/log/environment-setup.log
  - /tmp/install_ollama.sh 2>&1 | tee -a /var/log/ollama-install.log
  - su - oracleai -c '/tmp/setup_python_env.sh' 2>&1 | tee -a /var/log/python-setup.log
  - su - oracleai -c '/tmp/setup_database.sh' 2>&1 | tee -a /var/log/database-setup.log
  - su - oracleai -c '/tmp/install_models.sh' 2>&1 | tee -a /var/log/models-install.log
  - chown oracleai:oracleai /app/start.sh
  - systemctl daemon-reload
  - systemctl enable ai-optimizer.service
  - systemctl start nvidia-persistenced
  - sleep 30
  - systemctl start ai-optimizer.service
  - echo "[$(date)] Cloud-init execution completed" >> /var/log/cloud-init-custom.log
  - rm -f /tmp/*.sh /tmp/ai-optimizer-source.tar.gz /tmp/wallet.zip