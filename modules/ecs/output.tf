output "ecs_dns_name" {
  value = aws_lb.app_loadbalancer.dns_name
}
output "ecs_zone_id" {
  value = aws_lb.app_loadbalancer.zone_id
}
output "ecs-sg" {
  value = aws_security_group.service_security_group.id
}