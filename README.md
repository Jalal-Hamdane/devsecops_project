<div align="center">
  <img src="./public/assets/DevSecOps.png" alt="Logo" width="100%" height="100%">

  <br>
  <a href="http://netflix-clone-with-tmdb-using-react-mui.vercel.app/">
    <img src="./public/assets/netflix-logo.png" alt="Logo" width="100" height="32">
  </a>
</div>

<br />

<div align="center">
  <img src="./public/assets/home-page.png" alt="Logo" width="100%" height="100%">
  <p align="center">Home Page</p>
</div>

# Déployer un Clone de Netflix sur le Cloud avec Jenkins - Projet DevSecOps!

### **Phase 1: Configuration Initiale et Déploiement**

**Étape 1 : Lancer une instance EC2 (Ubuntu 22.04) ou lancer machine virtuelle:**

- Provisionner une instance EC2 sur AWS avec Ubuntu 22.04.
- Se connecter à l'instance via SSH.

**Étape 2: Cloner le Code:**

- Mettre à jour tous les paquets, puis cloner le code.
- Clonez le dépôt de code de votre application sur l'instance EC2 :
    
    ```bash
    git clone https://github.com/Jalal-Hamdane/devsecops_project.git
    ```
    

**Étape 3: Installer Docker et Exécuter l’Application avec un Conteneur :**

- Configurer Docker sur l'instance EC2 :
    
    ```bash
    
    sudo apt-get update
    sudo apt-get install docker.io -y
    sudo usermod -aG docker $USER  # Replace with your system's username, e.g., 'ubuntu'
    newgrp docker
    sudo chmod 777 /var/run/docker.sock
    ```
    
- Construire et exécuter votre application en utilisant des conteneurs Docker :
    
    ```bash
    docker build -t netflix .
    docker run -d --name netflix -p 8081:80 netflix:latest
    
    #to delete
    docker stop <containerid>
    docker rmi -f netflix
    ```

Cela affichera une erreur car vous avez besoin d'une clé API

**Étape 4: Obtenir la Clé API :**

- Ouvrir un navigateur et se rendre sur le site TMDB (The Movie Database).
- Créer un compte en cliquant sur "Login".
- Une fois connecté, allez dans votre profil, puis dans "Settings".
- Cliquez sur "API" dans le panneau de gauche.
- Créez une nouvelle clé API en cliquant sur "Create" et en acceptant les conditions.
- Vous recevrez votre clé API TMDB.


Maintenant, recréez l'image Docker avec votre clé API :
```
docker build --build-arg TMDB_V3_API_KEY=<your-api-key> -t netflix .
```

**Phase 2: Sécurité**

1. **Installer SonarQube et Trivy :**
    - Installez SonarQube et Trivy sur l'instance EC2 pour analyser les vulnérabilités.
        
        sonarqube
        ```
        docker run -d --name sonar -p 9000:9000 sonarqube:lts-community
        ```
        
        
        Pour y accéder :
        
        Allez sur publicIP:9000 (par défaut, le nom d’utilisateur et le mot de passe sont "admin").
        
        Pour installer Trivy:
        ```
        sudo apt-get install wget apt-transport-https gnupg lsb-release
        wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
        echo deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main | sudo tee -a /etc/apt/sources.list.d/trivy.list
        sudo apt-get update
        sudo apt-get install trivy        
        ```
        
        Pour analyser l'image avec Trivy :
        ```
        trivy image <imageid>
        ```
        
        
2. **Intégrer SonarQube et Configurer :**
    - Intégrer SonarQube avec votre pipeline CI/CD.
    - Configurer SonarQube pour analyser le code pour les problèmes de qualité et de sécurité.


**Phase 3: Configuration CI/CD**

1. **Installer Jenkins pour l’automatisation :**
    - Installez Jenkins sur l’instance EC2 pour automatiser le déploiement.:
    Install Java
    
    ```bash
    sudo apt update
    sudo apt install fontconfig openjdk-17-jre
    java -version
    openjdk version "17.0.8" 2023-07-18
    OpenJDK Runtime Environment (build 17.0.8+7-Debian-1deb12u1)
    OpenJDK 64-Bit Server VM (build 17.0.8+7-Debian-1deb12u1, mixed mode, sharing)
    
    #jenkins
    sudo wget -O /usr/share/keyrings/jenkins-keyring.asc \
    https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
    echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
    https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
    /etc/apt/sources.list.d/jenkins.list > /dev/null
    sudo apt-get update
    sudo apt-get install jenkins
    sudo systemctl start jenkins
    sudo systemctl enable jenkins
    ```
    
    - Accédez à Jenkins via le navigateur avec l'IP publique de votre instance EC2 :
        
        publicIp:8080
        
2. **Installer les Plugins Nécessaires dans Jenkins:**

Allez dans "Manage Jenkins" → "Plugins" → "Available Plugins" et installez les plugins suivants : →

Installer plugins

1 Eclipse Temurin Installer 

2 SonarQube Scanner 

3 NodeJs Plugin

4 Email Extension Plugin

### **Configurer Java et NodeJS dans la Configuration Outils Globale**

Allez dans "Manage Jenkins" → "Tools" → Installez JDK (17) et NodeJS (16).


### SonarQube

Créer le token

Allez sur le tableau de bord Jenkins → Gérer Jenkins → Identifiants → Ajouter un texte secret. Cela devrait ressembler à ceci.

Après avoir ajouté le token Sonar,

Cliquez sur Appliquer et Sauvegarder.

**L'option Configurer le Système** est utilisée dans Jenkins pour configurer différents serveurs.

**Configuration des outils globaux** ist utilisée pour configurer différents outils que nous installons à l'aide de plugins.

Nous allons installer un scanner Sonar dans les outils.

Créer un Webhook Jenkins 

1. **Configurer le Pipeline CI/CD dans Jenkins :**
- Créez un pipeline CI/CD dans Jenkins pour automatiser le déploiement de votre application.

```groovy
pipeline {
    agent any

    tools {
        jdk 'jdk17'
        nodejs 'node16'
    }

    environment {
        SCANNER_HOME = tool 'sonar-scanner'
    }

    stages {
        stage('Clean Workspace') {
            steps {
                cleanWs()
            }
        }

        stage('Checkout from Git') {
            steps {
                git branch: 'master', url: 'https://github.com/Jalal-Hamdane/devsecops_project.git'
            }
        }

        stage("SonarQube Analysis") {
            steps {
                withSonarQubeEnv('sonar-server') {
                    sh '''
                        $SCANNER_HOME/bin/sonar-scanner \
                        -Dsonar.projectName="Netflix" \
                        -Dsonar.projectKey="Netflix"
                    '''
                }
            }
        }

        stage("Quality Gate") {
            steps {
                script {
                    // Wait for the quality gate result before proceeding
                    def qg = waitForQualityGate(credentialsId: 'Sonar-token', abortPipeline: true)
                    if (qg.status != 'OK') {
                        error "SonarQube Quality Gate failed: ${qg.status}"
                    }
                }
            }
        }

        stage('Install Dependencies') {
            steps {
                sh 'npm install'
            }
        }
    }
}
```


Bien sûr, voici les instructions sans les numéros d'étapes 

**Installer Dependency-Check et les outils Docker dans Jenkins**

**Installer le plugin Dependency-Check :**

- Allez dans le "Tableau de bord" de votre interface web Jenkins.
- Naviguez vers "Gérer Jenkins" → "Gérer les plugins."
- Cliquez sur l'onglet "Disponible" et recherchez "OWASP Dependency-Check."
- Cochez la case pour "OWASP Dependency-Check" et cliquez sur le bouton "Installer sans redémarrer."

**Configurer l'outil Dependency-Check :**

- Après avoir installé le plugin Dependency-Check, vous devez configurer l'outil.
- Allez dans "Tableau de bord" → "Gérer Jenkins" → "Configuration des outils globaux."
- Trouvez la section "OWASP Dependency-Check."
- Ajoutez le nom de l'outil, par exemple, "DP-Check."
- Sauvegardez vos paramètres.

**Installer les outils Docker et les plugins Docker :**

- Allez dans le "Tableau de bord" de votre interface web Jenkins.
- Naviguez vers "Gérer Jenkins" → "Gérer les plugins."
- Cliquez sur l'onglet "Disponible" et recherchez "Docker."
- Cochez les plugins Docker suivants :
    - Docker
    - Docker Commons
    - Docker Pipeline
    - Docker API
    - docker-build-step
- Cliquez sur le bouton "Installer sans redémarrer" pour installer ces plugins.

**Ajouter les identifiants DockerHub :**

- Pour gérer de manière sécurisée les identifiants DockerHub dans votre pipeline Jenkins, suivez ces étapes :
    - Allez dans "Tableau de bord" → "Gérer Jenkins" → "Gérer les identifiants."
    - Cliquez sur "Système", puis sur "Identifiants globaux (non restreints)."
    - Cliquez sur "Ajouter des identifiants" sur la gauche.
    - Choisissez "Texte secret" comme type d'identifiant.
    - Entrez vos identifiants DockerHub (Nom d'utilisateur et Mot de passe) et donnez un ID à l'identifiant (par exemple, "docker").
    - Cliquez sur "OK" pour sauvegarder vos identifiants DockerHub.

Vous avez maintenant installé le plugin Dependency-Check, configuré l'outil et ajouté les plugins Docker ainsi que vos identifiants DockerHub dans Jenkins. Vous pouvez maintenant configurer votre pipeline Jenkins pour inclure ces outils et identifiants dans votre processus CI/CD.

```groovy

pipeline{
    agent any
    tools{
        jdk 'jdk17'
        nodejs 'node16'
    }
    environment {
        SCANNER_HOME=tool 'sonar-scanner'
    }
    stages {
        stage('clean workspace'){
            steps{
                cleanWs()
            }
        }
        stage('Checkout from Git'){
            steps{
                git branch: 'master', url: 'https://github.com/Jalal-Hamdane/devsecops_project.git'
            }
        }
        stage("Sonarqube Analysis") {
            steps {
                withSonarQubeEnv('sonar-server') {
                    sh '''
                        $SCANNER_HOME/bin/sonar-scanner \
                        -Dsonar.projectName=Netflix \
                        -Dsonar.projectKey=Netflix
                    '''
                }
            }
        }
        stage("quality gate"){
           steps {
                script {
                    waitForQualityGate abortPipeline: false, credentialsId: 'Sonar-token' 
                }
            } 
        }
        stage('Install Dependencies') {
            steps {
                sh "npm install"
            }
        }
        stage('OWASP FS SCAN') {
            steps {
                dependencyCheck additionalArguments: '--scan ./ --disableYarnAudit --disableNodeAudit', odcInstallation: 'DB-Check'
                dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
            }
        }
        stage('TRIVY FS SCAN') {
            steps {
                sh "trivy fs . > trivyfs.txt"
            }
        }
        stage("Docker Build & Push"){
            steps{
                script{
                   withDockerRegistry(credentialsId: 'dockerhub-credentials', toolName: 'docker'){   
                       sh "docker build --build-arg TMDB_V3_API_KEY=aa9001a9ce8267101412481d2af32799 -t devsecops-project ."
                       sh "docker tag netflix jalalhamdane/devsecops-project:latest "
                       sh "docker push jalalhamdane/devsecops-project:latest "
                    }
                }
            }
        }
    }    
}


Si vous obtenez une erreur "docker login failed", exécutez les commandes suivantes :

sudo su
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins


```

**Phase 4: Monitoring**

1. **Install Prometheus and Grafana:**

   Set up Prometheus and Grafana to monitor your application.

   **Installing Prometheus:**

   First, create a dedicated Linux user for Prometheus and download Prometheus:

   ```bash
   sudo useradd --system --no-create-home --shell /bin/false prometheus
   wget https://github.com/prometheus/prometheus/releases/download/v2.47.1/prometheus-2.47.1.linux-amd64.tar.gz
   ```

   Extract Prometheus files, move them, and create directories:

   ```bash
   tar -xvf prometheus-2.47.1.linux-amd64.tar.gz
   cd prometheus-2.47.1.linux-amd64/
   sudo mkdir -p /data /etc/prometheus
   sudo mv prometheus promtool /usr/local/bin/
   sudo mv consoles/ console_libraries/ /etc/prometheus/
   sudo mv prometheus.yml /etc/prometheus/prometheus.yml
   ```

   Set ownership for directories:

   ```bash
   sudo chown -R prometheus:prometheus /etc/prometheus/ /data/
   ```

   Create a systemd unit configuration file for Prometheus:

   ```bash
   sudo nano /etc/systemd/system/prometheus.service
   ```

   Add the following content to the `prometheus.service` file:

   ```plaintext
   [Unit]
   Description=Prometheus
   Wants=network-online.target
   After=network-online.target

   StartLimitIntervalSec=500
   StartLimitBurst=5

   [Service]
   User=prometheus
   Group=prometheus
   Type=simple
   Restart=on-failure
   RestartSec=5s
   ExecStart=/usr/local/bin/prometheus \
     --config.file=/etc/prometheus/prometheus.yml \
     --storage.tsdb.path=/data \
     --web.console.templates=/etc/prometheus/consoles \
     --web.console.libraries=/etc/prometheus/console_libraries \
     --web.listen-address=0.0.0.0:9090 \
     --web.enable-lifecycle

   [Install]
   WantedBy=multi-user.target
   ```

   Here's a brief explanation of the key parts in this `prometheus.service` file:

   - `User` and `Group` specify the Linux user and group under which Prometheus will run.

   - `ExecStart` is where you specify the Prometheus binary path, the location of the configuration file (`prometheus.yml`), the storage directory, and other settings.

   - `web.listen-address` configures Prometheus to listen on all network interfaces on port 9090.

   - `web.enable-lifecycle` allows for management of Prometheus through API calls.

   Enable and start Prometheus:

   ```bash
   sudo systemctl enable prometheus
   sudo systemctl start prometheus
   ```

   Verify Prometheus's status:

   ```bash
   sudo systemctl status prometheus
   ```

   You can access Prometheus in a web browser using your server's IP and port 9090:

   `http://<your-server-ip>:9090`

   **Installing Node Exporter:**

   Create a system user for Node Exporter and download Node Exporter:

   ```bash
   sudo useradd --system --no-create-home --shell /bin/false node_exporter
   wget https://github.com/prometheus/node_exporter/releases/download/v1.6.1/node_exporter-1.6.1.linux-amd64.tar.gz
   ```

   Extract Node Exporter files, move the binary, and clean up:

   ```bash
   tar -xvf node_exporter-1.6.1.linux-amd64.tar.gz
   sudo mv node_exporter-1.6.1.linux-amd64/node_exporter /usr/local/bin/
   rm -rf node_exporter*
   ```

   Create a systemd unit configuration file for Node Exporter:

   ```bash
   sudo nano /etc/systemd/system/node_exporter.service
   ```

   Add the following content to the `node_exporter.service` file:

   ```plaintext
   [Unit]
   Description=Node Exporter
   Wants=network-online.target
   After=network-online.target

   StartLimitIntervalSec=500
   StartLimitBurst=5

   [Service]
   User=node_exporter
   Group=node_exporter
   Type=simple
   Restart=on-failure
   RestartSec=5s
   ExecStart=/usr/local/bin/node_exporter --collector.logind

   [Install]
   WantedBy=multi-user.target
   ```

   Replace `--collector.logind` with any additional flags as needed.

   Enable and start Node Exporter:

   ```bash
   sudo systemctl enable node_exporter
   sudo systemctl start node_exporter
   ```

   Verify the Node Exporter's status:

   ```bash
   sudo systemctl status node_exporter
   ```

   You can access Node Exporter metrics in Prometheus.

2. **Configure Prometheus Plugin Integration:**

   Integrate Jenkins with Prometheus to monitor the CI/CD pipeline.

   **Prometheus Configuration:**

   To configure Prometheus to scrape metrics from Node Exporter and Jenkins, you need to modify the `prometheus.yml` file. Here is an example `prometheus.yml` configuration for your setup:

   ```yaml
   global:
     scrape_interval: 15s

   scrape_configs:
     - job_name: 'node_exporter'
       static_configs:
         - targets: ['localhost:9100']

     - job_name: 'jenkins'
       metrics_path: '/prometheus'
       static_configs:
         - targets: ['<your-jenkins-ip>:<your-jenkins-port>']
   ```

   Make sure to replace `<your-jenkins-ip>` and `<your-jenkins-port>` with the appropriate values for your Jenkins setup.

   Check the validity of the configuration file:

   ```bash
   promtool check config /etc/prometheus/prometheus.yml
   ```

   Reload the Prometheus configuration without restarting:

   ```bash
   curl -X POST http://localhost:9090/-/reload
   ```

   You can access Prometheus targets at:

   `http://<your-prometheus-ip>:9090/targets`


####Grafana

**Install Grafana on Ubuntu 22.04 and Set it up to Work with Prometheus**

**Step 1: Install Dependencies:**

First, ensure that all necessary dependencies are installed:

```bash
sudo apt-get update
sudo apt-get install -y apt-transport-https software-properties-common
```

**Step 2: Add the GPG Key:**

Add the GPG key for Grafana:

```bash
wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -
```

**Step 3: Add Grafana Repository:**

Add the repository for Grafana stable releases:

```bash
echo "deb https://packages.grafana.com/oss/deb stable main" | sudo tee -a /etc/apt/sources.list.d/grafana.list
```

**Step 4: Update and Install Grafana:**

Update the package list and install Grafana:

```bash
sudo apt-get update
sudo apt-get -y install grafana
```

**Step 5: Enable and Start Grafana Service:**

To automatically start Grafana after a reboot, enable the service:

```bash
sudo systemctl enable grafana-server
```

Then, start Grafana:

```bash
sudo systemctl start grafana-server
```

**Step 6: Check Grafana Status:**

Verify the status of the Grafana service to ensure it's running correctly:

```bash
sudo systemctl status grafana-server
```

**Step 7: Access Grafana Web Interface:**

Open a web browser and navigate to Grafana using your server's IP address. The default port for Grafana is 3000. For example:

`http://<your-server-ip>:3000`

You'll be prompted to log in to Grafana. The default username is "admin," and the default password is also "admin."

**Step 8: Change the Default Password:**

When you log in for the first time, Grafana will prompt you to change the default password for security reasons. Follow the prompts to set a new password.

**Step 9: Add Prometheus Data Source:**

To visualize metrics, you need to add a data source. Follow these steps:

- Click on the gear icon (⚙️) in the left sidebar to open the "Configuration" menu.

- Select "Data Sources."

- Click on the "Add data source" button.

- Choose "Prometheus" as the data source type.

- In the "HTTP" section:
  - Set the "URL" to `http://localhost:9090` (assuming Prometheus is running on the same server).
  - Click the "Save & Test" button to ensure the data source is working.

**Step 10: Import a Dashboard:**

To make it easier to view metrics, you can import a pre-configured dashboard. Follow these steps:

- Click on the "+" (plus) icon in the left sidebar to open the "Create" menu.

- Select "Dashboard."

- Click on the "Import" dashboard option.

- Enter the dashboard code you want to import (e.g., code 1860).

- Click the "Load" button.

- Select the data source you added (Prometheus) from the dropdown.

- Click on the "Import" button.

You should now have a Grafana dashboard set up to visualize metrics from Prometheus.

Grafana is a powerful tool for creating visualizations and dashboards, and you can further customize it to suit your specific monitoring needs.

That's it! You've successfully installed and set up Grafana to work with Prometheus for monitoring and visualization.

2. **Configure Prometheus Plugin Integration:**
    - Integrate Jenkins with Prometheus to monitor the CI/CD pipeline.


**Phase 5: Notification**

1. **Implement Notification Services:**
    - Set up email notifications in Jenkins or other notification mechanisms.

# Phase 6: Kubernetes

## Create Kubernetes Cluster with Nodegroups

In this phase, you'll set up a Kubernetes cluster with node groups. This will provide a scalable environment to deploy and manage your applications.

## Monitor Kubernetes with Prometheus

Prometheus is a powerful monitoring and alerting toolkit, and you'll use it to monitor your Kubernetes cluster. Additionally, you'll install the node exporter using Helm to collect metrics from your cluster nodes.

### Install Node Exporter using Helm

To begin monitoring your Kubernetes cluster, you'll install the Prometheus Node Exporter. This component allows you to collect system-level metrics from your cluster nodes. Here are the steps to install the Node Exporter using Helm:

1. Add the Prometheus Community Helm repository:

    ```bash
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    ```

2. Create a Kubernetes namespace for the Node Exporter:

    ```bash
    kubectl create namespace prometheus-node-exporter
    ```

3. Install the Node Exporter using Helm:

    ```bash
    helm install prometheus-node-exporter prometheus-community/prometheus-node-exporter --namespace prometheus-node-exporter
    ```

Add a Job to Scrape Metrics on nodeip:9001/metrics in prometheus.yml:

Update your Prometheus configuration (prometheus.yml) to add a new job for scraping metrics from nodeip:9001/metrics. You can do this by adding the following configuration to your prometheus.yml file:


```
  - job_name: 'Netflix'
    metrics_path: '/metrics'
    static_configs:
      - targets: ['node1Ip:9100']
```

Replace 'your-job-name' with a descriptive name for your job. The static_configs section specifies the targets to scrape metrics from, and in this case, it's set to nodeip:9001.

Don't forget to reload or restart Prometheus to apply these changes to your configuration.

To deploy an application with ArgoCD, you can follow these steps, which I'll outline in Markdown format:

### Deploy Application with ArgoCD

1. **Install ArgoCD:**

   You can install ArgoCD on your Kubernetes cluster by following the instructions provided in the [EKS Workshop](https://archive.eksworkshop.com/intermediate/290_argocd/install/) documentation.

2. **Set Your GitHub Repository as a Source:**

   After installing ArgoCD, you need to set up your GitHub repository as a source for your application deployment. This typically involves configuring the connection to your repository and defining the source for your ArgoCD application. The specific steps will depend on your setup and requirements.

3. **Create an ArgoCD Application:**
   - `name`: Set the name for your application.
   - `destination`: Define the destination where your application should be deployed.
   - `project`: Specify the project the application belongs to.
   - `source`: Set the source of your application, including the GitHub repository URL, revision, and the path to the application within the repository.
   - `syncPolicy`: Configure the sync policy, including automatic syncing, pruning, and self-healing.

4. **Access your Application**
   - To Access the app make sure port 30007 is open in your security group and then open a new tab paste your NodeIP:30007, your app should be running.

**Phase 7: Cleanup**

1. **Cleanup AWS EC2 Instances:**
    - Terminate AWS EC2 instances that are no longer needed.
