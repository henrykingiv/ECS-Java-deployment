output "db-endpoint" {
  value = aws_db_instance.rds-database.endpoint
}
output "db-instance" {
  value = aws_db_instance.rds-database.address
}