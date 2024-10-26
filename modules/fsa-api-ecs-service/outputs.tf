output "alb_dns" {
  description = "application load balancer DNS"
  value       = aws_alb.alb.dns_name
}

output "alb_sg" {
  description = "application load balancer security group id"
  value       = aws_security_group.alb_sg.id
}

output "ecs_service_sg" {
  description = "security group of ecs service"
  value       = aws_security_group.ecs_service_sg.id
}