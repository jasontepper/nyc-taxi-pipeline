terraform {
  required_providers {
    snowflake = {
      source  = "snowflakedb/snowflake"
      version = "~> 1.0"
    }
  }
}

provider "snowflake" {
  account_name      = "OH61284"
  organization_name = "ELYQZVY"
  user              = var.snowflake_user
  authenticator     = "SNOWFLAKE_JWT"
  private_key       = file(var.snowflake_private_key_path)
  role              = "SYSADMIN"
}

# --- Warehouse ---
resource "snowflake_warehouse" "dbt_wh" {
  name           = "DBT_WH"
  warehouse_size = "X-SMALL"
  auto_suspend   = 60
  auto_resume    = true
  comment        = "Warehouse for dbt transformations"
}

# --- Database ---
resource "snowflake_database" "nyc_taxi" {
  name    = "NYC_TAXI"
  comment = "NYC TLC taxi trip data"
}

# --- Schemas ---
resource "snowflake_schema" "raw" {
  database = snowflake_database.nyc_taxi.name
  name     = "RAW"
}

resource "snowflake_schema" "staging" {
  database = snowflake_database.nyc_taxi.name
  name     = "STAGING"
}

resource "snowflake_schema" "marts" {
  database = snowflake_database.nyc_taxi.name
  name     = "MARTS"
}

# --- Role ---
resource "snowflake_account_role" "dbt_role" {
  name    = "DBT_ROLE"
  comment = "Role for dbt pipeline"
}

# --- User ---
resource "snowflake_user" "dbt_user" {
  name              = "DBT_USER"
  default_role      = snowflake_account_role.dbt_role.name
  default_warehouse = snowflake_warehouse.dbt_wh.name
  comment           = "Service account for dbt pipeline"
}

resource "snowflake_grant_account_role" "dbt_user_grant" {
  role_name = snowflake_account_role.dbt_role.name
  user_name = snowflake_user.dbt_user.name
}

# --- Grants ---
resource "snowflake_grant_privileges_to_account_role" "dbt_warehouse_usage" {
  account_role_name = snowflake_account_role.dbt_role.name
  privileges        = ["USAGE"]
  on_account_object {
    object_type = "WAREHOUSE"
    object_name = snowflake_warehouse.dbt_wh.name
  }
}

resource "snowflake_grant_privileges_to_account_role" "dbt_database_usage" {
  account_role_name = snowflake_account_role.dbt_role.name
  privileges        = ["USAGE"]
  on_account_object {
    object_type = "DATABASE"
    object_name = snowflake_database.nyc_taxi.name
  }
}