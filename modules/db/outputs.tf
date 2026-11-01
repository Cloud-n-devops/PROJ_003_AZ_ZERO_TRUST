# 2. The Database Connection Host (FQDN)
output "db_host" {
  value       = azurerm_mssql_server.sql.fully_qualified_domain_name
}
output "db_host_write" {
  value       = azurerm_mssql_server.sql.fully_qualified_domain_name
}
# output "db_host_read" {
#   value       = azurerm_mssql_server.replica.fqdn
# }
output "db_server_id" {
  value       = azurerm_mssql_server.sql.id
}
output "production_db_name" {
  value       = azurerm_mssql_database.db_prod.name
}
output "production_db_id" {
  value       = azurerm_mssql_database.db_prod.id
}
output "staging_db_name" {
  value       = azurerm_mssql_database.db_staging.name
}
output "mssql_server_id" {
  value = azurerm_mssql_server.sql.id
}
