1. Clone the Application
Step

Clone the given GitHub repository on your system.

git clone https://github.com/Vennilavan12/Brain-Tasks-App.git
cd Brain-Tasks-App

Why?

You need the source code locally before starting Dockerization or any DevOps process.

2. Run the Application Locally
Step

Install dependencies and run application on port 3000:

npm install
npm start

Why?

To verify the application works correctly before containerizing or deploying.

🐳 DOCKER
3. Create a Dockerfile
Step

Create a Dockerfile at project root:

FROM node:16  
WORKDIR /app  
COPY package*.json ./  
RUN npm install  
COPY . .  
EXPOSE 3000  
CMD ["npm", "start"]

Why?

To containerize the application so it can run the same everywhere — locally, ECR, or Kubernetes.

4. Build and Run Docker Image
docker build -t brain-task-app .
docker run -p 3000:3000 brain-task-app

Why?

To check the Dockerized app is working correctly on your machine.

🐳➡️🟧 ECR (Amazon Elastic Container Registry)
5. Create an ECR Repository

AWS Console → ECR → Create Repository → Name: brain-task-app

Step

Login, build, tag & push image:

aws ecr get-login-password --region us-east-2 | docker login --username AWS --password-stdin <AWS_ACCOUNT_ID>.dkr.ecr.us-east-2.amazonaws.com

docker tag brain-task-app:latest <AWS_ACCOUNT_ID>.dkr.ecr.us-east-2.amazonaws.com/brain-task-app:latest

docker push <AWS_ACCOUNT_ID>.dkr.ecr.us-east-2.amazonaws.com/brain-task-app:latest

Why?

ECR stores Docker images so Kubernetes/EKS can pull them during deployment.

☸️ KUBERNETES (AWS EKS)
6. Create an EKS Cluster

Using AWS Console:

AWS EKS → Create Cluster
Name: brain-task-cluster
Node group: brain-task-nodes

kubectl setup
aws eks update-kubeconfig --region us-east-2 --name brain-task-cluster
kubectl get nodes

Why?

EKS is your Kubernetes environment where the application will run.

7. Create Deployment YAML

📌 deployment.yaml

apiVersion: apps/v1
kind: Deployment
metadata:
  name: brain-task-deploy
spec:
  replicas: 2
  selector:
    matchLabels:
      app: brain-task
  template:
    metadata:
      labels:
        app: brain-task
    spec:
      containers:
        - name: brain-task
          image: <AWS_ACCOUNT_ID>.dkr.ecr.us-east-2.amazonaws.com/brain-task-app:latest
          ports:
            - containerPort: 3000

8. Create Service YAML

📌 service.yaml

apiVersion: v1
kind: Service
metadata:
  name: brain-task-service
spec:
  type: LoadBalancer
  selector:
    app: brain-task
  ports:
    - port: 80
      targetPort: 3000

9. Deploy YAML Files
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl get pods
kubectl get svc

Why?

Kubernetes uses Deployment + Service to run and expose the application.

🏗️ CODEBUILD
10. Create CodeBuild Project

Source: GitHub (Connected Repo)

Environment: Amazon Linux

Privileged mode: Enabled (for Docker)

Add IAM Role: codebuild-brain-task-app-role

Create buildspec.yml
version: 0.2

phases:
  pre_build:
    commands:
      - echo Logging into ECR...
      - aws ecr get-login-password --region us-east-2 | docker login --username AWS --password-stdin <AWS_ACCOUNT_ID>.dkr.ecr.us-east-2.amazonaws.com

  build:
    commands:
      - echo Build docker image
      - docker build -t brain-task-app .
      - docker tag brain-task-app:latest <AWS_ACCOUNT_ID>.dkr.ecr.us-east-2.amazonaws.com/brain-task-app:latest

  post_build:
    commands:
      - echo Pushing image to ECR
      - docker push <AWS_ACCOUNT_ID>.dkr.ecr.us-east-2.amazonaws.com/brain-task-app:latest
artifacts:
  files:
    - appspec.yml
    - deployment.yaml
    - service.yaml

Why?

CodeBuild automatically builds and pushes Docker image to ECR.

🚀 CODEDEPLOY (For EKS Deployment)
11. Create CodeDeploy Application

Type: EKS

12. Create appspec.yml
version: 0.0
resources:
  - deploymentConfig:
      name: brain-task-app-deployment
hooks:
  BeforeInstall:
    - location: scripts/clean_old.sh
  AfterInstall:
    - location: scripts/deploy.sh


📌 scripts/deploy.sh runs:

kubectl apply -f deployment.yaml
kubectl apply -f service.yaml

Why?

CodeDeploy automates the deployment to your EKS cluster.

🔗 CODEPIPELINE
13. Create Pipeline

Stages:

✔ Source

GitHub → brain-task-app repo

✔ Build

CodeBuild project created above

✔ Deploy

CodeDeploy (EKS deployment)

📊 MONITORING
14. CloudWatch

Check:

CodeBuild Logs

CodeDeploy Logs

Application Logs (from EKS)

Errors/Success states

Commands for logs
kubectl logs <pod-name>
