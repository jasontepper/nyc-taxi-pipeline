output "warehouse_name" {
  value = snowflake_warehouse.dbt_wh.name
}

output "database_name" {
  value = snowflake_database.nyc_taxi.name
}

output "dbt_role" {
  value = snowflake_account_role.dbt_role.name
}

output "dbt_user" {
  value = snowflake_user.dbt_user.name
}