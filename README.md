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

**Phase 4: Surveillance**

1. **nstaller Prometheus et Grafana :**

   Installez Prometheus et Grafana pour surveiller votre application.

   **Installation de Prometheus :**

   Créez un utilisateur Linux dédié pour Prometheus et téléchargez Prometheus :

   ```bash
   sudo useradd --system --no-create-home --shell /bin/false prometheus
   wget https://github.com/prometheus/prometheus/releases/download/v2.47.1/prometheus-2.47.1.linux-amd64.tar.gz
   ```

   Décompressez les fichiers et configurez Prometheus.

   ```bash
   tar -xvf prometheus-2.47.1.linux-amd64.tar.gz
   cd prometheus-2.47.1.linux-amd64/
   sudo mkdir -p /data /etc/prometheus
   sudo mv prometheus promtool /usr/local/bin/
   sudo mv consoles/ console_libraries/ /etc/prometheus/
   sudo mv prometheus.yml /etc/prometheus/prometheus.yml
   ```

   Définir la propriété des répertoires:

   ```bash
   sudo chown -R prometheus:prometheus /etc/prometheus/ /data/
   ```

   Créer un fichier de configuration d'unité systemd pour Prometheus :

   ```bash
   sudo nano /etc/systemd/system/prometheus.service
   ```

   Ajouter le contenu suivant dans le fichier `prometheus.service` :

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

   Voici une brève explication des parties clés dans ce fichier `prometheus.service`:

   - `User` et `Group` spécifient l'utilisateur et le groupe Linux sous lesquels Prometheus s'exécutera.

   - `ExecStart` est l'endroit où vous spécifiez le chemin du binaire Prometheus, l'emplacement du fichier de configuration  (`prometheus.yml`), e répertoire de stockage et d'autres paramètres.

   - `web.listen-address` configure Prometheus pour écouter sur toutes les interfaces réseau sur le port 9090.

   - `web.enable-lifecycle` permet la gestion de Prometheus via des appels API.


   Activer et démarrer Prometheus :

   ```bash
   sudo systemctl enable prometheus
   sudo systemctl start prometheus
   ```

   Vérifier le statut de Prometheus :

   ```bash
   sudo systemctl status prometheus
   ```

   Vous pouvez accéder à Prometheus via un navigateur web en utilisant l'IP de votre serveur et le port 9090 :

   `http://<your-server-ip>:9090`

   **Installation de Node Exporter :**

   Créer un utilisateur système pour Node Exporter et télécharger Node Exporter :

   ```bash
   sudo useradd --system --no-create-home --shell /bin/false node_exporter
   wget https://github.com/prometheus/node_exporter/releases/download/v1.6.1/node_exporter-1.6.1.linux-amd64.tar.gz
   ```

   Extraire les fichiers de Node Exporter, déplacer le binaire et nettoyer :

   ```bash
   tar -xvf node_exporter-1.6.1.linux-amd64.tar.gz
   sudo mv node_exporter-1.6.1.linux-amd64/node_exporter /usr/local/bin/
   rm -rf node_exporter*
   ```

   Créer un fichier de configuration pour l'unité systemd de Node Exporter :

   ```bash
   sudo nano /etc/systemd/system/node_exporter.service
   ```

   Ajoutez le contenu suivant au fichier `node_exporter.service` :

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

   Remplacez  `--collector.logind` par des options supplémentaires si nécessaire.

   Activez et démarrez Node Exporter :

   ```bash
   sudo systemctl enable node_exporter
   sudo systemctl start node_exporter
   ```

   Vérifiez l'état de Node Exporter :

   ```bash
   sudo systemctl status node_exporter
   ```

   Vous pouvez accéder aux métriques de Node Exporter dans Prometheus.

2. **Configurer l'intégration du plugin Prometheus :**

   Intégrer Jenkins avec Prometheus pour surveiller le pipeline CI/CD.

   **Configuration de Prometheus :**

   Pour configurer Prometheus afin qu'il scrape les métriques de Node Exporter et Jenkins, vous devez modifier le fichier `prometheus.yml` . Voici un exemple de configuration  `prometheus.yml` pour votre installation :

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
         - targets: ['<votre-ip-jenkins>:<votre-port-jenkins>']
   ```

   Assurez-vous de remplacer `<votre-ip-jenkins>` et `<votre-port-jenkins>` par les valeurs appropriées pour votre installation Jenkins.

   Vérifiez la validité du fichier de configuration :

   ```bash
   promtool check config /etc/prometheus/prometheus.yml
   ```

   Rechargez la configuration de Prometheus sans redémarrer :

   ```bash
   curl -X POST http://localhost:9090/-/reload
   ```

   Vous pouvez accéder aux cibles de Prometheus à l'adresse :

   `http://<votre-ip-prometheus>:9090/targets`


####Grafana

**Installer Grafana sur Ubuntu 22.04 et le configurer pour fonctionner avec Prometheus**

**Étape 1 : Installer les dépendances :**

Commencez par vous assurer que toutes les dépendances nécessaires sont installées :

```bash
sudo apt-get update
sudo apt-get install -y apt-transport-https software-properties-common
```

**Étape 2 : Ajouter la clé GPG :**

Ajoutez la clé GPG pour Grafana :

```bash
wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -
```

**Étape 3 : Ajouter le dépôt Grafana :**

Ajoutez le dépôt pour les versions stables de Grafana :

```bash
echo "deb https://packages.grafana.com/oss/deb stable main" | sudo tee -a /etc/apt/sources.list.d/grafana.list
```

**Étape 4 : Mettre à jour et installer Grafana :**

Mettez à jour la liste des paquets et installez Grafana :

```bash
sudo apt-get update
sudo apt-get -y install grafana
```

**Étape 5 : Activer et démarrer le service Grafana :**

Pour démarrer automatiquement Grafana après un redémarrage, activez le service :

```bash
sudo systemctl enable grafana-server
```

Puis, démarrez Grafana :

```bash
sudo systemctl start grafana-server
```

**Étape 6 : Vérifier l'état de Grafana :**

Vérifiez l'état du service Grafana pour vous assurer qu'il fonctionne correctement :

```bash
sudo systemctl status grafana-server
```

**Étape 7 : Accéder à l'interface Web de Grafana :**

Ouvrez un navigateur Web et accédez à Grafana en utilisant l'adresse IP de votre serveur. Le port par défaut de Grafana est le 3000. Par exemple :

`http://<votre-ip-serveur>:3000`

Vous serez invité à vous connecter à Grafana. Le nom d'utilisateur par défaut est "admin", et le mot de passe par défaut est également "admin".

**Étape 8 : Modifier le mot de passe par défaut :**

Lors de votre première connexion, Grafana vous demandera de changer le mot de passe par défaut pour des raisons de sécurité. Suivez les instructions pour définir un nouveau mot de passe.


**Étape 9 : Ajouter une source de données Prometheus :**

Pour visualiser les métriques, vous devez ajouter une source de données. Suivez ces étapes :

- Cliquez sur l'icône en forme de roue dentée (⚙️) dans la barre latérale gauche pour ouvrir le menu "Configuration".
- Sélectionnez "Sources de données".
- Cliquez sur le bouton "Ajouter une source de données".
- Choisissez "Prometheus" comme type de source de données.
Dans la section "HTTP" :
    - Définissez l'URL sur http://localhost:9090 (en supposant que Prometheus fonctionne sur le même serveur).
    - Cliquez sur le bouton "Sauvegarder & Tester" pour vérifier que la source de données fonctionne.

**Étape 10 : Importer un tableau de bord :**

Pour faciliter la visualisation des métriques, vous pouvez importer un tableau de bord pré-configuré. Suivez ces étapes :

- Cliquez sur l'icône "+" (plus) dans la barre latérale gauche pour ouvrir le menu "Créer".
- Sélectionnez "Tableau de bord".
- Cliquez sur l'option "Importer" le tableau de bord.
- Entrez le code du tableau de bord que vous souhaitez importer (par exemple, le code 1860).
- Cliquez sur le bouton "Charger".
- Sélectionnez la source de données que vous avez ajoutée (Prometheus) dans le menu déroulant.
- Cliquez sur le bouton "Importer".

Vous devriez maintenant avoir un tableau de bord Grafana configuré pour visualiser les métriques de Prometheus.

Grafana est un outil puissant pour créer des visualisations et des tableaux de bord, et vous pouvez le personnaliser davantage pour répondre à vos besoins de surveillance spécifiques.

Voilà ! Vous avez maintenant installé et configuré Grafana pour travailler avec Prometheus pour la surveillance et la visualisation.

2. **Configurer l'intégration du plugin Prometheus:**
    - Intégrer Jenkins avec Prometheus pour surveiller le pipeline CI/CD.


**Phase 5 : Notifications**

1. **Mettre en place des services de notifications :**
    - Configurez les notifications par e-mail dans Jenkins ou d'autres mécanismes de notification.

# Phase 6: Kubernetes

## Créer un cluster Kubernetes avec des groupes de nœuds

Dans cette phase, vous allez configurer un cluster Kubernetes avec des groupes de nœuds. Cela fournira un environnement évolutif pour déployer et gérer vos applications.

## Surveiller Kubernetes avec Prometheus

Prometheus est un outil puissant de surveillance et d'alerte, et vous l'utiliserez pour surveiller votre cluster Kubernetes. De plus, vous installerez le node exporter via Helm pour collecter des métriques depuis vos nœuds de cluster.

### Install Node Exporter using Helm

Pour commencer à surveiller votre cluster Kubernetes, vous allez installer Prometheus Node Exporter. Ce composant permet de collecter des métriques au niveau du système depuis vos nœuds de cluster. Voici les étapes pour installer le Node Exporter avec Helm :

1. Ajouter le dépôt Helm de la communauté Prometheus :

    ```bash
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    ```

2. Créer un espace de noms Kubernetes pour Node Exporter :

    ```bash
    kubectl create namespace prometheus-node-exporter
    ```

3. Installer Node Exporter avec Helm :

    ```bash
    helm install prometheus-node-exporter prometheus-community/prometheus-node-exporter --namespace prometheus-node-exporter
    ```

Ajoutez un job pour scrapper les métriques sur nodeip:9001/metrics dans  prometheus.yml:

UMettez à jour votre configuration Prometheus (prometheus.yml) pour ajouter un nouveau job afin de scraper les métriques depuis nodeip:9001/metrics. Vous pouvez ajouter la configuration suivante à votre fichier prometheus.yml :


```
  - job_name: 'Netflix'
    metrics_path: '/metrics'
    static_configs:
      - targets: ['node1Ip:9100']
```

Remplacez node1Ip par l'adresse IP de votre noeud. N'oubliez pas de recharger ou redémarrer Prometheus pour appliquer ces modifications à votre configuration.

Pour déployer une application avec ArgoCD, vous pouvez suivre ces étapes, que je vais détailler en format Markdown :

### Déployer une application avec ArgoCD

1. **Install ArgoCD:**

   Vous pouvez installer ArgoCD sur votre cluster Kubernetes en suivant les instructions fournies dans la documentation  [EKS Workshop](https://archive.eksworkshop.com/intermediate/290_argocd/install/) .

2. **Configurer votre référentiel GitHub comme source :**

   Après avoir installé ArgoCD, vous devez configurer votre référentiel GitHub comme source pour le déploiement de votre application. Cela implique généralement de configurer la connexion à votre référentiel et de définir la source de votre application ArgoCD. Les étapes exactes dépendront de votre configuration.

3. **Créer une application ArgoCD :**
   - `name`: Définissez le nom de votre application.
   - `destination`: Définissez la destination où votre application doit être déployée.
   - `project`: Spécifiez le projet auquel l'application appartient.
   - `source`: Définissez la source de votre application, y compris l'URL du référentiel GitHub, la révision et le chemin de l'application dans le référentiel.
   - `syncPolicy`: Configurez la politique de synchronisation, y compris la synchronisation automatique, l'élagage et l'auto-guérison.

4. **Accéder à votre application :**
   - Pour accéder à l'application, assurez-vous que le port 30007 est ouvert dans votre groupe de sécurité, puis ouvrez un nouvel onglet et saisissez NodeIP:30007, Votre application devrait maintenant être en cours d'exécution.

**Phase 7 : Nettoyage**

1. **Nettoyer les instances EC2 AWS**
    - Terminez les instances EC2 AWS qui ne sont plus nécessaires.
