output "db-endpoint" {
  value = module.az-db.db-endpoint
}
output "sonarqube-id" {
  value = module.sonarqube.sonarqube-id
}
output "nexus-id" {
  value = module.nexus.nexus-id
}
output "jenkins-id" {
  value = module.jenkins.jenkins-id
}