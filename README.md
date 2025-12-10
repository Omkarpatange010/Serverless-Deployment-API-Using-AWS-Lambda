# Serverless-API-Deployment

# Overview :

This project demonstrates a fully automated CI/CD pipeline to deploy a serverless CRUD API using:

* AWS Lambda (Python)

* API Gateway

* S3 (Lambda Zip Storage)

* Terraform (Infrastructure as Code)

* Jenkins (CI/CD Pipeline)

* GitHub Webhooks (Automatic trigger on push)

# Feature :

* Lambda function in Python

* API Gateway with REST endpoints

* Terraform fully provisions AWS resources

* Jenkins pipeline:

Pulls code from GitHub

Zips Lambda code

Uploads to S3

Executes Terraform plan & apply

Validates the live API using curl

Sends console output on success/failure

# Project Structure :

Serverless-API-Deployment/
│
├── lambda_function/         # Python Lambda function directory
│   └── main.py              # Lambda handler
│
├── infra/                   # Terraform IaC
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── provider.tf
│
├── Jenkinsfile              # CI/CD pipeline script
└── README.md

# Technologies Used

* AWS Lambda :- Serverless compute  

* API Gateway :- Expose REST API

* S3 :- Store Lambda ZIP uploaded by Jenkins

* Terraform	:- Create & update AWS resources

* Jenkins :- CI/CD automation

* GitHub :-Source control + Webhook trigger

# Steps to deployment :

### Step 1 : (Repositry)

Clone the repository:

git clone https://github.com/Sharayu1707/Serverless-API-Deployment.git

cd Serverless-API-Deployment

### Step 2 : (Terraform infrastructure)

File

main.tf :- Declares AWS resources (EC2, RDS, Security Groups) 

variables.tf :- Stores variables for reusability

outputs.tf :- Exactly where to change values and what outputs to expect

provider.tf :- AWS provider configuration

iam.tf :- role + policy for Lambda

### Step 3 : (Jenkinsfile)

* Checkout Code

Pulls source code from GitHub.

* Zip Lambda Code 

cd lambda_function

zip -r main.zip .

* Upload ZIP to S3

Uploads Lambda function ZIP.

* Terraform Init & Apply

Creates:

API Gateway

Lambda Function

IAM Roles

DynamoDB Table

jenkinsfile :

pipeline {
    agent any

    environment {
        S3_BUCKET = "serverlessapi12"
        LAMBDA_ZIP = "main.zip"
        AWS_REGION = "ap-south-1"
    }

    triggers {
        githubPush()     // Trigger pipeline when GitHub pushes new code
    }

    stages {

        stage('Checkout Code') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/Sharayu1707/Serverless-API-Deployment.git'
            }
        }

        stage('Zip Lambda Code') {
            steps {
                sh '''
                echo "Zipping Lambda function..."
                cd lambda_function
                zip -r ../main.zip .
                cd ..
                '''
            }
        }

        stage('Upload ZIP to S3') {
            steps {
                withCredentials([
                    [$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-key']
                ]) {
                    sh '''
                    echo "Uploading Lambda ZIP to S3..."
                    aws s3 cp main.zip s3://serverlessapi12/main.zip --region ap-south-1
                    '''
                }
            }
        }

        stage('Terraform Init & Apply') {
            steps {
                withCredentials([
                    [$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-key']
                ]) {
                    sh '''
                    cd infra
                    terraform init
                    terraform apply -auto-approve
                    '''
                }
            }
        }

        stage('Validate API Response') {
            steps {
                sh '''
                echo "Testing API Gateway Endpoint..."
                curl -i https://YOUR_API_URL.execute-api.ap-south-1.amazonaws.com/prod
                '''
            }
        }
    }

    post {
        success {
            echo "🚀 Deployment Successful!"
        }
        failure {
            echo "❌ Deployment Failed!"
        }
    }
}

### Step 4 : (Output After Deployment)

Terraform will output:

API Gateway Invoke URL

DynamoDB Table name

Lambda ARN

Example:

https://abcd1234.execute-api.ap-south-1.amazonaws.com/prod/items

# Conclusion

You now have:

✓ Serverless API 

✓ Fully automated CI/CD

✓ Infrastructure-as-code using Terraform  

✓ AWS-managed scaling, logging, security


# Serverless-Deployment-API-Using-AWS-Lambda
