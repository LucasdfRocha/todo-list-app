output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = aws_ecr_repository.todo_app.repository_url
}

output "ecr_repository_name" {
  description = "ECR repository name"
  value       = aws_ecr_repository.todo_app.name
}

output "codebuild_project_name" {
  description = "CodeBuild project name"
  value       = aws_codebuild_project.todo_app_build.name
}

output "codepipeline_name" {
  description = "CodePipeline name"
  value       = aws_codepipeline.todo_app_pipeline.name
}

output "s3_bucket_name" {
  description = "S3 bucket for CodePipeline artifacts"
  value       = aws_s3_bucket.codepipeline_artifacts.bucket
}

