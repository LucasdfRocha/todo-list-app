variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "todo-list-app"
}

variable "ecr_repository_name" {
  description = "ECR repository name"
  type        = string
  default     = "todo-list-app"
}

variable "codebuild_project_name" {
  description = "CodeBuild project name"
  type        = string
  default     = "todo-app-build"
}

variable "codepipeline_name" {
  description = "CodePipeline name"
  type        = string
  default     = "todo-app-pipeline"
}

variable "github_owner" {
  description = "GitHub repository owner"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
}

variable "github_branch" {
  description = "GitHub branch to use"
  type        = string
  default     = "main"
}

variable "github_repo_url" {
  description = "Full GitHub repository URL"
  type        = string
}

variable "github_token" {
  description = "GitHub personal access token for CodePipeline"
  type        = string
  sensitive   = true
}

variable "eks_cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "eksDeepDiveFrankfurt"
}

variable "kubernetes_namespace" {
  description = "Kubernetes namespace for deployment"
  type        = string
  default     = "default"
}

