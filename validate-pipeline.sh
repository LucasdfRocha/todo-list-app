#!/bin/bash

# Script de validação do pipeline CI/CD
# Este script valida se o pipeline foi configurado corretamente

set -e

echo "=========================================="
echo "Validação do Pipeline CI/CD"
echo "=========================================="
echo ""

# Cores para output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Função para verificar comandos
check_command() {
    if command -v $1 &> /dev/null; then
        echo -e "${GREEN}✓${NC} $1 está instalado"
        return 0
    else
        echo -e "${RED}✗${NC} $1 não está instalado"
        return 1
    fi
}

# Função para verificar recursos AWS
check_aws_resource() {
    local resource_type=$1
    local resource_name=$2
    local description=$3
    
    echo -n "Verificando $description... "
    if aws $resource_type describe-$resource_type --name $resource_name --region us-east-1 &> /dev/null; then
        echo -e "${GREEN}✓${NC} Existe"
        return 0
    else
        echo -e "${RED}✗${NC} Não encontrado"
        return 1
    fi
}

# Verificações de pré-requisitos
echo "1. Verificando pré-requisitos..."
echo ""

check_command "aws" || exit 1
check_command "terraform" || exit 1
check_command "kubectl" || exit 1

echo ""

# Verificar configuração AWS
echo "2. Verificando configuração AWS..."
echo ""

if aws sts get-caller-identity &> /dev/null; then
    echo -e "${GREEN}✓${NC} AWS CLI está configurado"
    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    echo "   Account ID: $ACCOUNT_ID"
else
    echo -e "${RED}✗${NC} AWS CLI não está configurado"
    exit 1
fi

echo ""

# Verificar se os recursos foram criados (após terraform apply)
echo "3. Verificando recursos criados..."
echo ""

# Ler valores do terraform output se disponível
if [ -f "terraform/terraform.tfstate" ]; then
    echo -e "${YELLOW}ℹ${NC} Lendo valores do terraform.tfstate..."
    
    ECR_REPO=$(terraform -chdir=terraform output -raw ecr_repository_name 2>/dev/null || echo "")
    CODEBUILD_PROJECT=$(terraform -chdir=terraform output -raw codebuild_project_name 2>/dev/null || echo "")
    CODEPIPELINE=$(terraform -chdir=terraform output -raw codepipeline_name 2>/dev/null || echo "")
    
    if [ ! -z "$ECR_REPO" ]; then
        echo "   ECR Repository: $ECR_REPO"
        check_aws_resource "ecr" "repositories" "$ECR_REPO" || echo -e "${YELLOW}  ⚠${NC} Execute 'terraform apply' primeiro"
    fi
    
    if [ ! -z "$CODEBUILD_PROJECT" ]; then
        echo "   CodeBuild Project: $CODEBUILD_PROJECT"
        if aws codebuild batch-get-projects --names $CODEBUILD_PROJECT --region us-east-1 &> /dev/null; then
            echo -e "${GREEN}✓${NC} CodeBuild project existe"
        else
            echo -e "${YELLOW}  ⚠${NC} CodeBuild project não encontrado. Execute 'terraform apply' primeiro"
        fi
    fi
    
    if [ ! -z "$CODEPIPELINE" ]; then
        echo "   CodePipeline: $CODEPIPELINE"
        if aws codepipeline get-pipeline --name $CODEPIPELINE --region us-east-1 &> /dev/null; then
            echo -e "${GREEN}✓${NC} CodePipeline existe"
            
            # Verificar estado do pipeline
            echo ""
            echo "   Última execução do pipeline:"
            aws codepipeline list-pipeline-executions \
                --pipeline-name $CODEPIPELINE \
                --region us-east-1 \
                --max-items 1 \
                --query 'pipelineExecutionSummaries[0].[status, startTime]' \
                --output table 2>/dev/null || echo -e "${YELLOW}    ⚠${NC} Nenhuma execução encontrada"
        else
            echo -e "${YELLOW}  ⚠${NC} CodePipeline não encontrado. Execute 'terraform apply' primeiro"
        fi
    fi
else
    echo -e "${YELLOW}ℹ${NC} terraform.tfstate não encontrado. Execute 'terraform apply' primeiro"
fi

echo ""

# Verificar acesso ao EKS
echo "4. Verificando acesso ao EKS..."
echo ""

if aws eks describe-cluster --name eksDeepDiveFrankfurt --region us-east-1 &> /dev/null; then
    echo -e "${GREEN}✓${NC} Cluster EKS 'eksDeepDiveFrankfurt' existe"
    
    # Verificar se kubectl está configurado
    if kubectl cluster-info &> /dev/null; then
        echo -e "${GREEN}✓${NC} kubectl está configurado para o cluster"
        
        # Verificar deployment
        if kubectl get deployment todo-list-app -n default &> /dev/null; then
            echo -e "${GREEN}✓${NC} Deployment 'todo-list-app' existe"
            
            # Verificar status
            echo ""
            echo "   Status do deployment:"
            kubectl get deployment todo-list-app -n default -o jsonpath='{.status.conditions[?(@.type=="Available")].status}' && echo " (Available)" || echo " (Not Available)"
            kubectl get pods -n default -l app=todo-list-app --no-headers 2>/dev/null | wc -l | xargs echo "   Pods rodando:"
        else
            echo -e "${YELLOW}  ⚠${NC} Deployment 'todo-list-app' não encontrado. O pipeline ainda não foi executado ou falhou."
        fi
    else
        echo -e "${YELLOW}  ⚠${NC} kubectl não está configurado. Execute:"
        echo "      aws eks update-kubeconfig --name eksDeepDiveFrankfurt --region us-east-1"
    fi
else
    echo -e "${RED}✗${NC} Cluster EKS 'eksDeepDiveFrankfurt' não encontrado ou sem acesso"
fi

echo ""

# Verificar arquivos de configuração
echo "5. Verificando arquivos de configuração..."
echo ""

if [ -f "todo-list-app/buildspec.yml" ]; then
    echo -e "${GREEN}✓${NC} buildspec.yml existe"
else
    echo -e "${RED}✗${NC} buildspec.yml não encontrado"
fi

if [ -f "todo-list-app/k8s/deployment.yaml" ]; then
    echo -e "${GREEN}✓${NC} deployment.yaml existe"
else
    echo -e "${RED}✗${NC} deployment.yaml não encontrado"
fi

if [ -f "terraform/terraform.tfvars" ]; then
    echo -e "${GREEN}✓${NC} terraform.tfvars existe"
else
    echo -e "${YELLOW}  ⚠${NC} terraform.tfvars não encontrado. Crie a partir de terraform.tfvars.example"
fi

echo ""
echo "=========================================="
echo "Validação concluída!"
echo "=========================================="
echo ""
echo "Próximos passos:"
echo "1. Configure o terraform.tfvars com seus valores"
echo "2. Execute 'terraform apply' no diretório terraform/"
echo "3. Configure o acesso do CodeBuild ao EKS (veja eks-setup.md)"
echo "4. Faça um push para a branch main do repositório GitHub"
echo "5. Monitore o pipeline no AWS Console"

