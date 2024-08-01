output "sonarqube-id" {
  value = aws_instance.SonarQube_Server.id
}
output "sonarqube-dns-name" {
  value = aws_elb.elb-sonar.dns_name
}
output "sonarqube-zone-id" {
  value = aws_elb.elb-sonar.zone_id
}