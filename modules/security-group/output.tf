output "sonarqube-sg" {
  value = aws_security_group.sonarqube-sg.id
}
output "jenkins-sg" {
  value = aws_security_group.jenkins-sg.id
}
output "nexus-sg" {
  value = aws_security_group.nexus-sg.id
}
output "asg-sg" {
  value = aws_security_group.asg-sg.id
}
output "rds-sg" {
  value = aws_security_group.rds-sg.id
}