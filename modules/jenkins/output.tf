output "jenkins-id" {
  value = aws_instance.jenkins.id
}
output "jenkins-dns-name" {
  value = aws_elb.jenkins-lb.dns_name
}
output "jenkins-zone-id" {
  value = aws_elb.jenkins-lb.zone_id
}